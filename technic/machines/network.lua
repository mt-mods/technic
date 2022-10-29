--
-- Power network specific functions and data should live here
--
local S = technic.getter

local off_delay_seconds = tonumber(technic.config:get("switch_off_delay_seconds"))

local network_node_arrays = {"PR_nodes","BA_nodes","RE_nodes"}

technic.active_networks = {}
local networks = {}
technic.networks = networks
local technic_cables = {}
technic.cables = technic_cables

local poshash = minetest.hash_node_position
local hashpos = minetest.get_position_from_hash

function technic.create_network(sw_pos)
	local network_id = poshash({x=sw_pos.x,y=sw_pos.y-1,z=sw_pos.z})
	technic.build_network(network_id)
	return network_id
end

local function pos_in_array(pos, array)
	for _,pos2 in ipairs(array) do
		if pos.x == pos2.x and pos.y == pos2.y and pos.z == pos2.z then
			return true
		end
	end
	return false
end

function technic.merge_networks(net1, net2)
	-- TODO: Optimize for merging small network into larger by first checking network
	-- node counts for both networks and keep network id with most nodes.
	assert(type(net1) == "table", "Invalid net1 for technic.merge_networks")
	assert(type(net2) == "table", "Invalid net2 for technic.merge_networks")
	assert(net1 ~= net2, "Deadlock recipe: net1 & net2 equals for technic.merge_networks")
	-- Move data in cables table
	for node_id,cable_net_id in pairs(technic_cables) do
		if cable_net_id == net2.id then
			technic_cables[node_id] = net1.id
		end
	end
	-- Move data in machine tables
	for _,tablename in ipairs(network_node_arrays) do
		for _,pos in ipairs(net2[tablename]) do
			table.insert(net1[tablename], pos)
		end
	end
	-- Move data in all_nodes table
	for node_id,pos in pairs(net2.all_nodes) do
		net1.all_nodes[node_id] = pos
	end
	-- Merge queues for incomplete networks
	if net1.queue and net2.queue then
		for _,pos in ipairs(net2.queue) do
			if not pos_in_array(pos, net1.queue) then
				table.insert(net1.queue, pos)
			end
		end
	else
		net1.queue = net1.queue or net2.queue
	end
	-- Remove links to net2
	networks[net2.id] = nil
	technic.active_networks[net2.id] = nil
end

function technic.activate_network(network_id, timeout)
	-- timeout is optional ttl for network in seconds, if not specified use default
	local network = networks[network_id]
	if network then
		-- timeout is absolute time in microseconds
		network.timeout = minetest.get_us_time() + ((timeout or off_delay_seconds) * 1000 * 1000)
		technic.active_networks[network_id] = network
	end
end

function technic.sw_pos2tier(pos, load_node)
	-- Get cable tier for switching station or nil if no cable
	-- load_node true to use minetest.load_area to load node
	local cable_pos = {x=pos.x,y=pos.y-1,z=pos.z}
	if load_node then
		minetest.load_area(cable_pos)
	end
	return technic.get_cable_tier(minetest.get_node(cable_pos).name)
end

-- Destroy network data
function technic.remove_network(network_id)
	for pos_hash,cable_net_id in pairs(technic_cables) do
		if cable_net_id == network_id then
			technic_cables[pos_hash] = nil
		end
	end
	networks[network_id] = nil
	technic.active_networks[network_id] = nil
end

local function switch_index(pos, net)
	for index, spos in ipairs(net.swpos) do
		if pos.x == spos.x and pos.y == spos.y and pos.z == spos.z then
			return index
		end
	end
end

function technic.switch_insert(pos, net)
	if not switch_index(pos, net) then
		table.insert(net.swpos, table.copy(pos))
	end
	return #net.swpos
end

function technic.switch_remove(pos, net)
	local swindex = switch_index(pos, net)
	if swindex then
		table.remove(net.swpos, swindex)
	end
	return #net.swpos
end

function technic.sw_pos2network(pos)
	return technic_cables[poshash({x=pos.x,y=pos.y-1,z=pos.z})]
end

function technic.pos2network(pos)
	return technic_cables[poshash(pos)]
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
	local network = networks[network_id]
	if network then
		if text then
			network.infotext = text
		elseif network.queue then
			local count = 0
			for _ in pairs(network.all_nodes) do count = count + 1 end
			return S("Building Network: @1 Nodes", count)
		else
			return network.infotext
		end
	end
end

local node_timeout = {}
local default_timeout = 2

function technic.set_default_timeout(timeout)
	default_timeout = timeout or 2
end

function technic.get_timeout(tier, pos)
	if node_timeout[tier] == nil then
		-- it is normal that some multi tier nodes always drop here when checking all LV, MV and HV tiers
		return 0
	end
	return node_timeout[tier][poshash(pos)] or 0
end

local function touch_node(tier, pos, timeout)
	if node_timeout[tier] == nil then
		-- this should get built up during registration
		node_timeout[tier] = {}
	end
	node_timeout[tier][poshash(pos)] = timeout or default_timeout
end
technic.touch_node = touch_node

function technic.disable_machine(pos, node)
	local nodedef = minetest.registered_nodes[node.name]
	if nodedef then
		local meta = minetest.get_meta(pos)
		meta:set_string("infotext", S("@1 Has No Network", nodedef.description))
	end
	if nodedef and nodedef.technic_disabled_machine_name then
		node.name = nodedef.technic_disabled_machine_name
		minetest.swap_node(pos, node)
	end
	if nodedef and nodedef.technic_on_disable then
		nodedef.technic_on_disable(pos, node)
	end
	local node_id = poshash(pos)
	for _,nodes in pairs(node_timeout) do
		nodes[node_id] = nil
	end
end

local function match_cable_tier_filter(name, tiers)
	-- Helper to check for set of cable tiers
	if tiers then
		for _, tier in ipairs(tiers) do if technic.is_tier_cable(name, tier) then return true end end
		return false
	end
	return technic.get_cable_tier(name) ~= nil
end

local function get_neighbors(pos, tiers)
	local tier_machines = tiers and technic.machines[tiers[1]]
	local is_cable = match_cable_tier_filter(minetest.get_node(pos).name, tiers)
	local network = is_cable and technic.networks[technic.pos2network(pos)]
	local cables = {}
	local machines = {}
	local positions = {
		{x=pos.x+1, y=pos.y,   z=pos.z},
		{x=pos.x-1, y=pos.y,   z=pos.z},
		{x=pos.x,   y=pos.y+1, z=pos.z},
		{x=pos.x,   y=pos.y-1, z=pos.z},
		{x=pos.x,   y=pos.y,   z=pos.z+1},
		{x=pos.x,   y=pos.y,   z=pos.z-1},
	}
	for _,connected_pos in ipairs(positions) do
		local name = minetest.get_node(connected_pos).name
		if tier_machines and tier_machines[name] then
			table.insert(machines, connected_pos)
		elseif match_cable_tier_filter(name, tiers) then
			local cable_network = technic.networks[technic.pos2network(connected_pos)]
			table.insert(cables,{
				pos = connected_pos,
				network = cable_network,
			})
			if not network then network = cable_network end
		end
	end
	return network, cables, machines
end

function technic.place_network_node(pos, tiers, name)
	-- Get connections and primary network if there's any
	local network, cables, machines = get_neighbors(pos, tiers)
	if not network then
		-- We're evidently not on a network, nothing to add ourselves to
		return
	end

	-- Attach to primary network, this must be done before building branches from this position
	technic.add_network_node(pos, network)
	if not match_cable_tier_filter(name, tiers) then
		if technic.machines[tiers[1]][name] == technic.producer_receiver then
			-- FIXME: Multi tier machine like supply converter should also attach to other networks around pos.
			--      Preferably also with connection rules defined for machine.
			--      nodedef.connect_sides could be used to generate these rules.
			--		For now, assume that all multi network machines belong to technic.producer_receiver group:
			-- Get cables and networks around PR_RE machine
			local _, machine_cables, _ = get_neighbors(pos)
			for _,connection in ipairs(machine_cables) do
				if connection.network and connection.network.id ~= network.id then
					-- Attach PR_RE machine to secondary networks (last added is primary until above note is resolved)
					technic.add_network_node(pos, connection.network)
				end
			end
		else
			-- Check connected cables for foreign networks, overload if machine was connected to multiple networks
			for _, connection in ipairs(cables) do
				if connection.network and connection.network.id ~= network.id then
					technic.overload_network(connection.network.id)
					technic.overload_network(network.id)
				end
			end
		end
		-- Machine added, skip all network building
		return
	end

	-- Attach neighbor machines if cable was added
	for _,machine_pos in ipairs(machines) do
		technic.add_network_node(machine_pos, network)
	end

	-- Attach neighbor cables
	for _,connection in ipairs(cables) do
		if connection.network then
			if connection.network.id ~= network.id then
				-- Remove network if position belongs to another network
				-- FIXME: Network requires partial rebuild but avoid doing it here if possible.
				-- This might cause problems when merging two active networks into one
				technic.remove_network(network.id)
				technic.remove_network(connection.network.id)
				connection.network = nil
			end
		else
			-- There's cable that does not belong to any network, attach whole branch
			technic.add_network_node(connection.pos, network)
			technic.add_network_branch({connection.pos}, network)
		end
	end
end

-- Remove machine or cable from network
local function remove_network_node(network_id, pos)
	local network = networks[network_id]
	if not network then return end
	-- Clear hash tables, cannot use table.remove
	local node_id = poshash(pos)
	technic_cables[node_id] = nil
	network.all_nodes[node_id] = nil
	-- TODO: All following things can be skipped if node is not machine
	--   check here if it is or is not cable
	--   or add separate function to remove cables and move responsibility to caller
	-- Clear indexed arrays, do NOT leave holes
	local machine_removed = false
	for _,tblname in ipairs(network_node_arrays) do
		local tbl = network[tblname]
		for i=#tbl,1,-1 do
			local mpos = tbl[i]
			if mpos.x == pos.x and mpos.y == pos.y and mpos.z == pos.z then
				table.remove(tbl, i)
				machine_removed = true
				break
			end
		end
	end
	if machine_removed then
		-- Machine can still be in world, just not connected to any network. If so then disable it.
		local node = minetest.get_node(pos)
		technic.disable_machine(pos, node)
	end
end

function technic.remove_network_node(pos, tiers, name)
	-- Get the network and neighbors
	local network, cables, machines = get_neighbors(pos, tiers)
	if not network then return end

	if not match_cable_tier_filter(name, tiers) then
		-- Machine removed, skip cable checks to prevent unnecessary network cleanups
		for _,connection in ipairs(cables) do
			if connection.network then
				-- Remove machine from all networks around it
				remove_network_node(connection.network.id, pos)
			end
		end
		return
	end

	if #cables == 1 then
		-- Dead end cable removed, remove it from the network
		remove_network_node(network.id, pos)
		-- Remove neighbor machines from network if cable was removed
		if match_cable_tier_filter(name, tiers) then
			for _,machine_pos in ipairs(machines) do
				local net, _, _ = get_neighbors(machine_pos, tiers)
				if not net then
					-- Remove machine from network if it does not have other connected cables
					remove_network_node(network.id, machine_pos)
				end
			end
		end
	else
		-- TODO: Check branches around and switching stations for branches:
		--   remove branches that do not have switching station. Switching stations not tracked but could be easily tracked.
		--   remove branches not connected to another branch. Individual branches not tracked, requires simple AI heuristics.
		--   move branches that have switching station to new networks without checking or loading actual nodes in world.
		--   To do all this network must be aware of individual branches and switching stations, might not be worth it...
		-- For now remove whole network and let ABM rebuild it
		technic.remove_network(network.id)
	end
end

--
-- Functions to traverse the electrical network
--

-- Add a machine node to the LV/MV/HV network
local function add_network_machine(nodes, pos, network_id, all_nodes, multitier)
	local node_id = poshash(pos)
	local net_id_old = technic_cables[node_id]
	if net_id_old == nil or (multitier and net_id_old ~= network_id and all_nodes[node_id] == nil) then
		-- Add machine to network only if it is not already added
		table.insert(nodes, pos)
		-- FIXME: Machines connecting to multiple networks should have way to store multiple network ids
		technic_cables[node_id] = network_id
		all_nodes[node_id] = pos
		return true
	elseif not multitier and net_id_old ~= network_id then
		-- Do not allow running from multiple networks, trigger overload
		technic.overload_network(network_id)
		technic.overload_network(net_id_old)
		local meta = minetest.get_meta(pos)
		meta:set_string("infotext",S("Network Overloaded"))
	end
end

-- Add a wire node to the LV/MV/HV network
local function add_cable_node(pos, network)
	local node_id = poshash(pos)
	if not technic_cables[node_id] then
		technic_cables[node_id] = network.id
		network.all_nodes[node_id] = pos
		if network.queue then
			table.insert(network.queue, pos)
		end
	elseif technic_cables[node_id] ~= network.id then
		-- Conflicting network connected, merge networks if both are still in building stage
		local net2 = networks[technic_cables[node_id]]
		if net2 and net2.queue then
			technic.merge_networks(network, net2)
		end
	end
end

-- Generic function to add found connected nodes to the right classification array
local function add_network_node(network, pos, machines)
	local name = technic.get_or_load_node(pos).name

	if technic.get_cable_tier(name) == network.tier then
		add_cable_node(pos, network)
	elseif machines[name] then
		if     machines[name] == technic.producer then
			add_network_machine(network.PR_nodes, pos, network.id, network.all_nodes)
		elseif machines[name] == technic.receiver then
			add_network_machine(network.RE_nodes, pos, network.id, network.all_nodes)
		elseif machines[name] == technic.producer_receiver then
			if add_network_machine(network.PR_nodes, pos, network.id, network.all_nodes, true) then
				table.insert(network.RE_nodes, pos)
			end
		elseif machines[name] == technic.battery then
			add_network_machine(network.BA_nodes, pos, network.id, network.all_nodes)
		end
	end
end

-- Generic function to add single nodes to the right classification array of existing network
function technic.add_network_node(pos, network)
	add_network_node(network, pos, technic.machines[network.tier])
end

-- Traverse a network given a list of machines and a cable type name
local function traverse_network(network, pos, machines)
	local positions = {
		{x=pos.x+1, y=pos.y,   z=pos.z},
		{x=pos.x-1, y=pos.y,   z=pos.z},
		{x=pos.x,   y=pos.y+1, z=pos.z},
		{x=pos.x,   y=pos.y-1, z=pos.z},
		{x=pos.x,   y=pos.y,   z=pos.z+1},
		{x=pos.x,   y=pos.y,   z=pos.z-1}}
	for i, cur_pos in pairs(positions) do
		if not network.all_nodes[poshash(cur_pos)] then
			add_network_node(network, cur_pos, machines)
		end
	end
end

local function touch_nodes(list, tier)
	for _, pos in ipairs(list) do
		touch_node(tier, pos) -- Touch node
	end
end

local function get_network(network_id, tier)
	local cached = networks[network_id]
	if cached and not cached.queue and cached.tier == tier then
		touch_nodes(cached.PR_nodes, tier)
		touch_nodes(cached.BA_nodes, tier)
		touch_nodes(cached.RE_nodes, tier)
		return cached.PR_nodes, cached.BA_nodes, cached.RE_nodes
	end
	return technic.build_network(network_id)
end

function technic.add_network_branch(queue, network)
	-- Adds whole branch to network, queue positions can be used to bypass sub branches
	local machines = technic.machines[network.tier]
	--print(string.format("technic.add_network_branch(%s, %s, %.17g)",queue,minetest.pos_to_string(sw_pos),network.id))
	local t1 = minetest.get_us_time()
	while next(queue) do
		local to_visit = {}
		for _, pos in ipairs(queue) do
			network.queue = to_visit
			traverse_network(network, pos, machines)
		end
		queue = to_visit
		if minetest.get_us_time() - t1 > 10000 then
			-- time limit exceeded
			break
		end
	end
	-- Set build queue for network if network build was not finished within time limits
	network.queue = #queue > 0 and queue
end

-- Battery charge status updates for network
local function update_battery(self, charge, max_charge, supply, demand)
	self.battery_charge = self.battery_charge + charge
	self.battery_charge_max = self.battery_charge_max + max_charge
	self.battery_supply = self.battery_supply + supply
	self.battery_demand = self.battery_demand + demand
	if demand ~= 0 then
		self.BA_count_active = self.BA_count_active + 1
		self.BA_charge_active = self.BA_charge_active + charge
	end
end

-- Moving average function generator
local function sma(period)
	local values = {}
	local index = 1
	local sum = 0
	return function(n)
		-- Add new value and return average
		sum = sum - (values[index] or 0) + n
		values[index] = n
		index = index ~= period and index + 1 or 1
		return sum / #values
	end
end

function technic.build_network(network_id)
	local network = networks[network_id]
	if network and not network.queue then
		-- Network exists complete and cached
		return network.PR_nodes, network.BA_nodes, network.RE_nodes
	elseif not network then
		-- Build new network if network does not exist
		technic.remove_network(network_id)
		local sw_pos = technic.network2sw_pos(network_id)
		local tier = sw_pos and technic.sw_pos2tier(sw_pos)
		if not tier then
			-- Failed to get initial cable node for network
			return
		end
		network = {
			-- Build queue
			queue = {},
			-- Basic network data and lookup table for attached nodes
			id = network_id, tier = tier, all_nodes = {}, swpos = {},
			-- Indexed arrays for iteration by machine type
			PR_nodes = {}, RE_nodes = {}, BA_nodes = {},
			-- Power generation, usage and capacity related variables
			supply = 0, demand = 0, battery_charge = 0, battery_charge_max = 0,
			BA_count_active = 0, BA_charge_active = 0, battery_supply = 0, battery_demand = 0,
			-- Battery status update function
			update_battery = update_battery,
			-- Network activation and excution control
			timeout = 0, skip = 0, lag = 0, average_lag = sma(5)
		}
		-- Add first cable (one that is holding network id) and build network
		add_cable_node(technic.network2pos(network_id), network)
	end
	-- Continue building incomplete network
	technic.add_network_branch(network.queue, network)
	network.battery_count = #network.BA_nodes
	-- Add newly built network to cache array
	networks[network_id] = network
	if not network.queue then
		-- And return producers, batteries and receivers (should this simply return network?)
		return network.PR_nodes, network.BA_nodes, network.RE_nodes
	end
end

--
-- Execute technic power network
--
local node_technic_run = {}
minetest.register_on_mods_loaded(function()
	for name, tiers in pairs(technic.machine_tiers) do
		local nodedef = minetest.registered_nodes[name]
		local on_construct = type(nodedef.on_construct) == "function" and nodedef.on_construct
		local on_destruct = type(nodedef.on_destruct) == "function" and nodedef.on_destruct
		local place_node = technic.place_network_node
		local remove_node = technic.remove_network_node
		minetest.override_item(name, {
			on_construct = on_construct
				and function(pos) on_construct(pos) place_node(pos, tiers, name) end
				or  function(pos) place_node(pos, tiers, name) end,
			on_destruct = on_destruct
				and function(pos) on_destruct(pos) remove_node(pos, tiers, name) end
				or  function(pos) remove_node(pos, tiers, name) end,
		})
	end
	for name, _ in pairs(technic.machine_tiers) do
		if type(minetest.registered_nodes[name].technic_run) == "function" then
			node_technic_run[name] = minetest.registered_nodes[name].technic_run
		end
	end
end)

local function run_nodes(list, vm, run_stage, network)
	for _, pos in ipairs(list) do
		local node = minetest.get_node_or_nil(pos)
		if not node then
			vm:read_from_map(pos, pos)
			node = minetest.get_node_or_nil(pos)
		end
		if node and node.name and node_technic_run[node.name] then
			node_technic_run[node.name](pos, node, run_stage, network)
		end
	end
end

function technic.network_run(network_id)
	--
	-- !!! !!! !!! !!! !!! !!! !!! !!! !!! !!! !!!
	-- TODO: This function requires a lot of cleanup
	-- It is moved here from switching_station.lua and still
	-- contain a lot of switching station specific stuff which
	-- should be removed and/or refactored.
	--

	local t0 = minetest.get_us_time()

	local PR_nodes
	local BA_nodes
	local RE_nodes

	local network = networks[network_id]
	if network then
		PR_nodes, BA_nodes, RE_nodes = get_network(network_id, network.tier)
		if not PR_nodes or technic.is_overloaded(network_id) then return end
	else
		--dprint("Not connected to a network")
		technic.network_infotext(network_id, S("@1 Has No Network", S("Switching Station")))
		return
	end

	-- Reset battery data for updates
	network.battery_charge = 0
	network.battery_charge_max = 0
	network.battery_supply = 0
	network.battery_demand = 0
	network.BA_count_active = 0
	network.BA_charge_active = 0

	local vm = VoxelManip()
	run_nodes(PR_nodes, vm, technic.producer, network)
	run_nodes(RE_nodes, vm, technic.receiver, network)
	run_nodes(BA_nodes, vm, technic.battery, network)

	-- Strings for the meta data
	local eu_demand_str = network.tier.."_EU_demand"
	local eu_input_str  = network.tier.."_EU_input"
	local eu_supply_str = network.tier.."_EU_supply"

	-- Distribute charge equally across multiple batteries.
	local charge_distributed = math.floor(network.BA_charge_active / network.BA_count_active)
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

	technic.network_infotext(network_id, S("@1. Supply: @2 Demand: @3",
			S("Switching Station"), technic.EU_string(PR_eu_supply),
			technic.EU_string(RE_eu_demand)))

	-- Data that will be used by the power monitor
	network.supply = PR_eu_supply
	network.demand = RE_eu_demand
	network.battery_count = #BA_nodes

	-- If the PR supply is enough for the RE demand supply them all
	local BA_eu_demand = network.battery_demand
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
		-- TODO: EU input for all batteries: math.floor(BA_eu_demand * charge_factor * #BA_nodes)
		for n, pos1 in pairs(BA_nodes) do
			local meta1 = minetest.get_meta(pos1)
			local eu_demand = meta1:get_int(eu_demand_str)
			meta1:set_int(eu_input_str, math.floor(eu_demand * charge_factor))
			--dprint("Charging battery:"..math.floor(eu_demand*charge_factor))
		end
		local t1 = minetest.get_us_time()
		local diff = t1 - t0
		if diff > 50000 then
			minetest.log("warning", "[technic] [+supply] technic_run took " .. diff .. " us at "
				.. minetest.pos_to_string(hashpos(network_id)))
		end

		return
	end

	-- If the PR supply is not enough for the RE demand we will discharge the batteries too
	local BA_eu_supply = network.battery_supply
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
			minetest.log("warning", "[technic] [-supply] technic_run took " .. diff .. " us at "
				.. minetest.pos_to_string(hashpos(network_id)))
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
		minetest.log("warning", "[technic] technic_run took " .. diff .. " us at "
			.. minetest.pos_to_string(hashpos(network_id)))
	end

end
