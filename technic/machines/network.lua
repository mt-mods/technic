--
-- Power network specific functions and data should live here
--
local S = technic.getter

local switch_max_range = tonumber(minetest.settings:get("technic.switch_max_range") or "256")

technic.networks = {}
technic.cables = {}

local poshash = minetest.hash_node_position
local hashpos = minetest.get_position_from_hash

function technic.create_network(sw_pos)
	local network_id = poshash({x=sw_pos.x,y=sw_pos.y-1,z=sw_pos.z})
	technic.build_network(network_id)
	return network_id
end

function technic.activate_network(network_id, timeout)
	assert(network_id)
	local network = technic.networks[network_id]
	if network and (timeout or network.timeout < 4) then
		network.timeout = timeout or 4
	end
end

function technic.sw_pos2tier(pos, use_vm)
	-- Get cable tier for switching station or nil if no cable
	-- use_vm true to use VoxelManip to load node
	local cable_pos = {x=pos.x,y=pos.y-1,z=pos.z}
	if use_vm then
		technic.get_or_load_node(cable_pos)
	end
	return technic.get_cable_tier(minetest.get_node(cable_pos).name)
end

-- Destroy network data
function technic.remove_network(network_id)
	local cables = technic.cables
	for pos_hash,cable_net_id in pairs(cables) do
		if cable_net_id == network_id then
			cables[pos_hash] = nil
		end
	end
	technic.networks[network_id] = nil
	--print(string.format("technic.remove_network(%.17g) at %s", network_id, minetest.pos_to_string(technic.network2pos(network_id))))
end

-- Remove machine or cable from network
local network_node_arrays = {"PR_nodes","BA_nodes","RE_nodes","SP_nodes"}
function technic.remove_network_node(network_id, pos)
	local network = technic.networks[network_id]
	if not network then return end
	-- Clear hash tables, cannot use table.remove
	local node_id = poshash(pos)
	technic.cables[node_id] = nil
	network.all_nodes[node_id] = nil
	-- Clear indexed arrays, do NOT leave holes
	for _,tblname in ipairs(network_node_arrays) do
		local tbl = network[tblname]
		for i=#tbl,1,-1 do
			local mpos = tbl[i]
			if mpos.x == pos.x and mpos.y == pos.y and mpos.z == pos.z then
				table.remove(tbl, i)
				break
			end
		end
	end
end

function technic.sw_pos2network(pos)
	return technic.cables[poshash({x=pos.x,y=pos.y-1,z=pos.z})]
end

function technic.sw_pos2network(pos)
	return technic.cables[poshash({x=pos.x,y=pos.y-1,z=pos.z})]
end

function technic.pos2network(pos)
	return technic.cables[poshash(pos)]
end

function technic.network2pos(network_id)
	return hashpos(network_id)
end

function technic.network2sw_pos(network_id)
	-- Return switching station position for network.
	-- It is not guaranteed that position actually contains switching station.
	local sw_pos = hashpos(network_id)
	sw_pos.y = sw_pos.y + 1
	return sw_pos
end

function technic.network_infotext(network_id, text)
	if technic.networks[network_id] == nil then return end
	if text then
		technic.networks[network_id].infotext = text
	else
		return technic.networks[network_id].infotext
	end
end

local node_timeout = {}

function technic.get_timeout(tier, pos)
	if node_timeout[tier] == nil then
		-- it is normal that some multi tier nodes always drop here when checking all LV, MV and HV tiers
		return 0
	end
	return node_timeout[tier][poshash(pos)] or 0
end

function technic.touch_node(tier, pos, timeout)
	if node_timeout[tier] == nil then
		-- this should get built up during registration
		node_timeout[tier] = {}
	end
	node_timeout[tier][poshash(pos)] = timeout or 2
end

--
-- Network overloading (incomplete cheat mitigation)
--
local overload_reset_time = tonumber(minetest.settings:get("technic.overload_reset_time") or "20")
local overloaded_networks = {}

function technic.overload_network(network_id)
	local network = technic.networks[network_id]
	if network then
		network.supply = 0
		network.battery_charge = 0
	end
	overloaded_networks[network_id] = minetest.get_us_time() + (overload_reset_time * 1000 * 1000)
end

function technic.reset_overloaded(network_id)
	local remaining = math.max(0, overloaded_networks[network_id] - minetest.get_us_time())
	if remaining == 0 then
		-- Clear cache, remove overload and restart network
		technic.remove_network(network_id)
		overloaded_networks[network_id] = nil
	end
	-- Returns 0 when network reset or remaining time if reset timer has not expired yet
	return remaining
end

function technic.is_overloaded(network_id)
	return overloaded_networks[network_id]
end

--
-- Functions to traverse the electrical network
--

local function attach_network_machine(network_id, pos)
	local pos_hash = poshash(pos)
	local net_id_old = technic.cables[pos_hash]
	if net_id_old == nil then
		technic.cables[pos_hash] = network_id
	elseif net_id_old ~= network_id then
		-- do not allow running pos from multiple networks, also disable switch
		technic.overload_network(network_id, pos)
		technic.overload_network(net_id_old, pos)
		technic.cables[pos_hash] = network_id
		local meta = minetest.get_meta(pos)
		meta:set_string("infotext",S("Network Overloaded"))
	end
end

-- Add a machine node to the LV/MV/HV network
local function add_network_node(nodes, pos, network_id, all_nodes)
	table.insert(nodes, pos)
	local node_id = poshash(pos)
	technic.cables[node_id] = network_id
	all_nodes[node_id] = pos
end

-- Add a wire node to the LV/MV/HV network
local function add_cable_node(nodes, pos, network_id, queue)
	local node_id = poshash(pos)
	technic.cables[node_id] = network_id
	if not nodes[node_id] then
		nodes[node_id] = pos
		queue[#queue + 1] = pos
	end
end

-- Generic function to add found connected nodes to the right classification array
local function check_node_subp(PR_nodes, RE_nodes, BA_nodes, all_nodes, pos, machines, tier, sw_pos, from_below, network_id, queue)

	technic.get_or_load_node(pos)
	local name = minetest.get_node(pos).name

	if technic.is_tier_cable(name, tier) then
		add_cable_node(all_nodes, pos, network_id, queue)
	elseif machines[name] then
		--dprint(name.." is a "..machines[name])

		if     machines[name] == technic.producer then
			attach_network_machine(network_id, pos)
			add_network_node(PR_nodes, pos, network_id, all_nodes)
		elseif machines[name] == technic.receiver then
			attach_network_machine(network_id, pos)
			add_network_node(RE_nodes, pos, network_id, all_nodes)
		elseif machines[name] == technic.producer_receiver then
			--attach_network_machine(network_id, pos)
			add_network_node(PR_nodes, pos, network_id, all_nodes)
			add_network_node(RE_nodes, pos, network_id, all_nodes)
		elseif machines[name] == technic.battery then
			attach_network_machine(network_id, pos)
			add_network_node(BA_nodes, pos, network_id, all_nodes)
		end

		technic.touch_node(tier, pos, 2) -- Touch node
	end
end

-- Traverse a network given a list of machines and a cable type name
local function traverse_network(PR_nodes, RE_nodes, BA_nodes, all_nodes, pos, machines, tier, sw_pos, network_id, queue)
	local positions = {
		{x=pos.x+1, y=pos.y,   z=pos.z},
		{x=pos.x-1, y=pos.y,   z=pos.z},
		{x=pos.x,   y=pos.y+1, z=pos.z},
		{x=pos.x,   y=pos.y-1, z=pos.z},
		{x=pos.x,   y=pos.y,   z=pos.z+1},
		{x=pos.x,   y=pos.y,   z=pos.z-1}}
	for i, cur_pos in pairs(positions) do
		if not all_nodes[poshash(cur_pos)] then
			check_node_subp(PR_nodes, RE_nodes, BA_nodes, all_nodes, cur_pos, machines, tier, sw_pos, i == 3, network_id, queue)
		end
	end
end

local function touch_nodes(list, tier)
	local touch_node = technic.touch_node
	for _, pos in ipairs(list) do
		touch_node(tier, pos, 2) -- Touch node
	end
end

local function get_network(network_id, tier)
	local cached = technic.networks[network_id]
	if cached and cached.tier == tier then
		touch_nodes(cached.PR_nodes, tier)
		touch_nodes(cached.BA_nodes, tier)
		touch_nodes(cached.RE_nodes, tier)
		return cached.PR_nodes, cached.BA_nodes, cached.RE_nodes
	end
	return technic.build_network(network_id)
end

function technic.add_network_branch(queue, sw_pos, network)
	--print(string.format("technic.add_network_branch(%s, %s, %.17g)",queue,minetest.pos_to_string(sw_pos),network.id))
	-- Adds whole branch to network, queue positions can be used to bypass sub branches
	local PR_nodes = network.PR_nodes -- Indexed array
	local BA_nodes = network.BA_nodes -- Indexed array
	local RE_nodes = network.RE_nodes -- Indexed array
	local all_nodes = network.all_nodes -- Hash table
	local network_id = network.id
	local tier = network.tier
	local machines = technic.machines[tier]
	while next(queue) do
		local to_visit = {}
		for _, pos in ipairs(queue) do
			if vector.distance(pos, sw_pos) > switch_max_range then
				-- max range exceeded
				return
			end
			traverse_network(PR_nodes, RE_nodes, BA_nodes, all_nodes, pos,
					machines, tier, sw_pos, network_id, to_visit)
		end
		queue = to_visit
	end
end

function technic.build_network(network_id)
	--print(string.format("technic.build_network(%.17g) at %s", network_id, minetest.pos_to_string(technic.network2pos(network_id))))
	technic.remove_network(network_id)
	local sw_pos = technic.network2sw_pos(network_id)
	local tier = technic.sw_pos2tier(sw_pos)
	if not tier then
		--print(string.format("Cannot build network, cannot get tier for switching station at %s", minetest.pos_to_string(sw_pos)))
		return
	end
	local network = {
		id = network_id, tier = tier, all_nodes = {},
		SP_nodes = {}, PR_nodes = {}, RE_nodes = {}, BA_nodes = {},
		supply = 0, demand = 0, timeout = 4, battery_charge = 0, battery_charge_max = 0,
	}
	-- Add first cable (one that is holding network id) and build network
	local queue = {}
	add_cable_node(network.all_nodes, technic.network2pos(network_id), network_id, queue)
	technic.add_network_branch(queue, sw_pos, network)
	network.battery_count = #network.BA_nodes
	-- Add newly built network to cache array
	technic.networks[network_id] = network
	-- And return producers, batteries and receivers (should this simply return network?)
	return network.PR_nodes, network.BA_nodes, network.RE_nodes
end

--
-- Execute technic power network
--

local function run_nodes(list, run_stage)
	for _, pos in ipairs(list) do
		technic.get_or_load_node(pos)
		local node = minetest.get_node_or_nil(pos)
		if node and node.name then
			local nodedef = minetest.registered_nodes[node.name]
			if nodedef and nodedef.technic_run then
				nodedef.technic_run(pos, node, run_stage)
			end
		end
	end
end

local mesecons_path = minetest.get_modpath("mesecons")
local digilines_path = minetest.get_modpath("digilines")

function technic.network_run(network_id)
	--
	-- !!! !!! !!! !!! !!! !!! !!! !!! !!! !!! !!!
	-- TODO: This function requires a lot of cleanup
	-- It is moved here from switching_station.lua and still
	-- contain a lot of switching station specific stuff which
	-- should be removed and/or refactored.
	--
	if not technic.powerctrl_state then return end

	-- Check if network is overloaded / conflicts with another network
	if technic.is_overloaded(network_id) then
		-- TODO: Overload check should happen before technic.network_run is called, overloaded network should not generate any events
		return
	end

	local pos = technic.network2sw_pos(network_id)
	local t0 = minetest.get_us_time()

	local PR_nodes
	local BA_nodes
	local RE_nodes

	local tier = technic.sw_pos2tier(pos)
	local network
	if tier then
		PR_nodes, BA_nodes, RE_nodes = get_network(network_id, tier)
		if technic.is_overloaded(network_id) then return end
		network = technic.networks[network_id]
	else
		--dprint("Not connected to a network")
		technic.network_infotext(network_id, S("%s Has No Network"):format(S("Switching Station")))
		return
	end

	run_nodes(PR_nodes, technic.producer)
	run_nodes(RE_nodes, technic.receiver)
	run_nodes(BA_nodes, technic.battery)

	-- Strings for the meta data
	local eu_demand_str    = tier.."_EU_demand"
	local eu_input_str     = tier.."_EU_input"
	local eu_supply_str    = tier.."_EU_supply"

	-- Distribute charge equally across multiple batteries.
	local charge_total = 0
	local battery_count = 0

	local BA_charge = 0
	local BA_charge_max = 0

	for n, pos1 in pairs(BA_nodes) do
		local meta1 = minetest.get_meta(pos1)
		local charge = meta1:get_int("internal_EU_charge")
		local charge_max = meta1:get_int("internal_EU_charge_max")

		BA_charge = BA_charge + charge
		BA_charge_max = BA_charge_max + charge_max

		if (meta1:get_int(eu_demand_str) ~= 0) then
			charge_total = charge_total + charge
			battery_count = battery_count + 1
		end
	end

	local charge_distributed = math.floor(charge_total / battery_count)

	for n, pos1 in pairs(BA_nodes) do
		local meta1 = minetest.get_meta(pos1)

		if (meta1:get_int(eu_demand_str) ~= 0) then
			meta1:set_int("internal_EU_charge", charge_distributed)
		end
	end

	-- Get all the power from the PR nodes
	local PR_eu_supply = 0 -- Total power
	for _, pos1 in pairs(PR_nodes) do
		local meta1 = minetest.get_meta(pos1)
		PR_eu_supply = PR_eu_supply + meta1:get_int(eu_supply_str)
	end
	--dprint("Total PR supply:"..PR_eu_supply)

	-- Get all the demand from the RE nodes
	local RE_eu_demand = 0
	for _, pos1 in pairs(RE_nodes) do
		local meta1 = minetest.get_meta(pos1)
		RE_eu_demand = RE_eu_demand + meta1:get_int(eu_demand_str)
	end
	--dprint("Total RE demand:"..RE_eu_demand)

	-- Get all the power from the BA nodes
	local BA_eu_supply = 0
	for _, pos1 in pairs(BA_nodes) do
		local meta1 = minetest.get_meta(pos1)
		BA_eu_supply = BA_eu_supply + meta1:get_int(eu_supply_str)
	end
	--dprint("Total BA supply:"..BA_eu_supply)

	-- Get all the demand from the BA nodes
	local BA_eu_demand = 0
	for _, pos1 in pairs(BA_nodes) do
		local meta1 = minetest.get_meta(pos1)
		BA_eu_demand = BA_eu_demand + meta1:get_int(eu_demand_str)
	end
	--dprint("Total BA demand:"..BA_eu_demand)

	technic.network_infotext(network_id, S("@1. Supply: @2 Demand: @3",
			S("Switching Station"), technic.EU_string(PR_eu_supply),
			technic.EU_string(RE_eu_demand)))

	-- If mesecon signal and power supply or demand changed then
	-- send them via digilines.
	if mesecons_path and digilines_path and mesecon.is_powered(pos) then
		if PR_eu_supply ~= network.supply or
				RE_eu_demand ~= network.demand then
			local meta = minetest.get_meta(pos)
			local channel = meta:get_string("channel")
			digilines.receptor_send(pos, technic.digilines.rules, channel, {
				supply = PR_eu_supply,
				demand = RE_eu_demand
			})
		end
	end

	-- Data that will be used by the power monitor
	network.supply = PR_eu_supply
	network.demand = RE_eu_demand
	network.battery_count = #BA_nodes
	network.battery_charge = BA_charge
	network.battery_charge_max = BA_charge_max

	-- If the PR supply is enough for the RE demand supply them all
	if PR_eu_supply >= RE_eu_demand then
	--dprint("PR_eu_supply"..PR_eu_supply.." >= RE_eu_demand"..RE_eu_demand)
		for _, pos1 in pairs(RE_nodes) do
			local meta1 = minetest.get_meta(pos1)
			local eu_demand = meta1:get_int(eu_demand_str)
			meta1:set_int(eu_input_str, eu_demand)
		end
		-- We have a surplus, so distribute the rest equally to the BA nodes
		-- Let's calculate the factor of the demand
		PR_eu_supply = PR_eu_supply - RE_eu_demand
		local charge_factor = 0 -- Assume all batteries fully charged
		if BA_eu_demand > 0 then
			charge_factor = PR_eu_supply / BA_eu_demand
		end
		for n, pos1 in pairs(BA_nodes) do
			local meta1 = minetest.get_meta(pos1)
			local eu_demand = meta1:get_int(eu_demand_str)
			meta1:set_int(eu_input_str, math.floor(eu_demand * charge_factor))
			--dprint("Charging battery:"..math.floor(eu_demand*charge_factor))
		end
		local t1 = minetest.get_us_time()
		local diff = t1 - t0
		if diff > 50000 then
			minetest.log("warning", "[technic] [+supply] switching station abm took " .. diff .. " us at " .. minetest.pos_to_string(pos))
		end

		return
	end

	-- If the PR supply is not enough for the RE demand we will discharge the batteries too
	if PR_eu_supply + BA_eu_supply >= RE_eu_demand then
		--dprint("PR_eu_supply "..PR_eu_supply.."+BA_eu_supply "..BA_eu_supply.." >= RE_eu_demand"..RE_eu_demand)
		for _, pos1 in pairs(RE_nodes) do
			local meta1  = minetest.get_meta(pos1)
			local eu_demand = meta1:get_int(eu_demand_str)
			meta1:set_int(eu_input_str, eu_demand)
		end
		-- We have a deficit, so distribute to the BA nodes
		-- Let's calculate the factor of the supply
		local charge_factor = 0 -- Assume all batteries depleted
		if BA_eu_supply > 0 then
			charge_factor = (PR_eu_supply - RE_eu_demand) / BA_eu_supply
		end
		for n,pos1 in pairs(BA_nodes) do
			local meta1 = minetest.get_meta(pos1)
			local eu_supply = meta1:get_int(eu_supply_str)
			meta1:set_int(eu_input_str, math.floor(eu_supply * charge_factor))
			--dprint("Discharging battery:"..math.floor(eu_supply*charge_factor))
		end
		local t1 = minetest.get_us_time()
		local diff = t1 - t0
		if diff > 50000 then
			minetest.log("warning", "[technic] [-supply] switching station abm took " .. diff .. " us at " .. minetest.pos_to_string(pos))
		end

		return
	end

	-- If the PR+BA supply is not enough for the RE demand: Power only the batteries
	local charge_factor = 0 -- Assume all batteries fully charged
	if BA_eu_demand > 0 then
		charge_factor = PR_eu_supply / BA_eu_demand
	end
	for n, pos1 in pairs(BA_nodes) do
		local meta1 = minetest.get_meta(pos1)
		local eu_demand = meta1:get_int(eu_demand_str)
		meta1:set_int(eu_input_str, math.floor(eu_demand * charge_factor))
	end
	for n, pos1 in pairs(RE_nodes) do
		local meta1 = minetest.get_meta(pos1)
		meta1:set_int(eu_input_str, 0)
	end

	local t1 = minetest.get_us_time()
	local diff = t1 - t0
	if diff > 50000 then
		minetest.log("warning", "[technic] switching station abm took " .. diff .. " us at " .. minetest.pos_to_string(pos))
	end

end

--
-- Technic power network administrative functions
--

technic.powerctrl_state = true

minetest.register_chatcommand("powerctrl", {
	params = "state",
	description = "Enables or disables technic's switching station ABM",
	privs = { basic_privs = true },
	func = function(name, state)
		if state == "on" then
			technic.powerctrl_state = true
		else
			technic.powerctrl_state = false
		end
	end
})

--
-- Metadata cleanup LBM, removes old metadata values from nodes
--
--luacheck: ignore 511
if false then
	minetest.register_lbm({
		name = "technic:metadata-cleanup",
		nodenames = {
			"group:technic_machine",
			"group:technic_all_tiers",
			"technic:switching_station",
			"technic:power_monitor",
		},
		action = function(pos, node)
			-- Delete all listed metadata key/value pairs from technic machines
			local keys = {
				"LV_EU_timeout", "MV_EU_timeout", "HV_EU_timeout",
				"LV_network", "MV_network", "HV_network",
				"active_pos", "supply", "demand",
				"battery_count", "battery_charge", "battery_charge_max",
			}
			local meta = minetest.get_meta(pos)
			for _,key in ipairs(keys) do
				-- Value of `""` will delete the key.
				meta:set_string(key, "")
			end
			if node.name == "technic:switching_station" then
				meta:set_string("active", "")
			end
		end,
	})
end
