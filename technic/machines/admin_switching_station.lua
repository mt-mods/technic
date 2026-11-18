local modstorage = core.get_mod_storage()
local server_step = tonumber(core.settings:get("dedicated_server_step")) or 0.09
local off_delay_seconds = tonumber(technic.config:get("switch_off_delay_seconds"))
local S = technic.getter

local cable_entry = "^technic_cable_connection_overlay.png"
local no_network_infotext = S("@1 Has No Network", S("Switching Station"))

local function save_admin_networks(data)
	modstorage:set_string("admin_networks", core.write_json(data))
end

local function load_admin_networks()
	local data = modstorage:get_string("admin_networks")
	return core.parse_json(data) or {}
end

-- Indexed admin_networks table holds basic information about admin networks.
-- Each row is a hash table with following keys:
--   autorun      Whether network should be automatically started and kept running all the time.
--   switching    Indexed table contains known switching station positions.
--   supply       Networks supply configuration for how much energy network should provide by itself.
--   zerolag      Makes players happy, generates better revenue and redirects complaints to other servers.
--   ttl          Custom TTL value for network, uses default TTL if not set.
local admin_networks

local function create_admin_network(pos, config)
	config = config or {}
	config.switching = { pos }
	table.insert(admin_networks, config)
	return #admin_networks
end

local function switch_pos_to_admin_net_index(pos)
	-- This search could be cached easily but unlikely to be worth it so maybe don't
	for index, net in ipairs(admin_networks) do
		for _, swpos in ipairs(net.switching) do
			if vector.equals(pos, swpos) then
				return index
			end
		end
	end
end

-- Remove admin switching station from admin network. Also removes admin
-- network configuration after last switching station has been removed.
local function admin_switch_remove(pos, network)
	local index = switch_pos_to_admin_net_index(pos)
	if admin_networks[index] then
		local switching = admin_networks[index].switching
		for swindex = #switching, 1, -1 do
			if vector.equals(pos, switching[swindex]) then
				table.remove(switching, swindex)
				break
			end
		end
		if #switching < 1 then
			-- Destroy admin network after all admin switching stations been removed.
			-- Power network won't be affected as there might still be regular switching stations.
			-- Autorun has to be disabled so that timers maintaining TTL can be stopped and network forgotten.
			-- If admin network had zerolag configured then also network.average_lag should be reset to sma.
			admin_networks[index].autorun = nil
			table.remove(admin_networks, index)
			network.admin_network_config = nil
		end
		save_admin_networks(admin_networks)
	end
	return technic.switch_remove(pos, network)
end

local function admin_switch_insert(pos, network)
	local result = technic.switch_insert(pos, network)
	if result > 0 then
		if network.admin_network_config then
			table.insert(network.admin_network_config.switching, pos)
		else
			local index = switch_pos_to_admin_net_index(pos)
			network.admin_network_config = admin_networks[index] or admin_networks[create_admin_network(pos)]
		end
		save_admin_networks(admin_networks)
	end
	return result
end

local function start_admin_network_autorun(network_id, network)
	local delay = math.max(2, (network.admin_network_config.ttl or off_delay_seconds) - math.max(2, server_step * 10))
	local ttl_refresh
	function ttl_refresh()
		if network.admin_network_config.autorun then
			technic.activate_network(network_id, network.admin_network_config.ttl)
			core.after(delay, ttl_refresh)
		end
	end
	core.after(delay, ttl_refresh)
end

-- Similar to regular switching station based network start but with more options and configuration
local function start_network(pos)
	local tier = technic.sw_pos2tier(pos, true)
	if not tier then
		local meta = core.get_meta(pos)
		meta:set_string("infotext", no_network_infotext)
	else
		local network_id = technic.sw_pos2network(pos) or technic.create_network(pos)
		local network = network_id and technic.networks[network_id]
		if network and admin_switch_insert(pos, network) > 0 then
			if network.admin_network_config.zerolag then
				-- network.lag is based on average_lag(t) sma method, our version ignores input and returns zero
				network.average_lag = function(_) return 0 end
			end
			-- Activate network and, if configured, set our own TTL.
			technic.activate_network(network_id, network.admin_network_config.ttl)
			-- Activate globalstep TTL refresh
			if network.admin_network_config.autorun then
				start_admin_network_autorun(network_id, network)
			end
		end
	end
end

-- Start all admin networks that have autorun flag set
local function start_autorun_admin_networks()
	local function get_switching_station_pos(net)
		for swindex = #net.switching, 1, -1 do
			local sw_pos = net.switching[swindex]
			-- Following node validation is important in order to get rid of admin networks removed
			-- in a way that did not respect node destructors, direct mapblock deletion for example
			local node = technic.get_or_load_node(sw_pos)
			if node and node.name == "technic:admin_switching_station" then
				return sw_pos
			else
				table.remove(net.switching, swindex)
			end
		end
	end

	-- Validate stored admin network and attempt to start it
	local function start_admin_network(index)
		local sw_pos = get_switching_station_pos(admin_networks[index])
		if sw_pos then
			-- Switch found, start network
			start_network(sw_pos, admin_networks[index])
			return true
		else
			-- Could not load valid admin switching station, remove network
			table.remove(admin_networks, index)
		end
	end

	-- Use async loop to start all admin networks with autorun flag set
	local async_start_admin_networks
	function async_start_admin_networks(index)
		core.after(1, function()
			-- Find next admin network with autorun enabled and attempt to start it
			while index > 0 do
				if admin_networks[index].autorun and start_admin_network(index) then
					return async_start_admin_networks(index - 1)
				else
					index = index - 1
				end
			end
		end)
	end

	async_start_admin_networks(#admin_networks)
end

core.register_node("technic:admin_switching_station",{
	description = S("Switching Station"),
	tiles  = {
		"technic_power_monitor_sides.png^[colorize:#FFFFFF:15",
		"technic_water_mill_top_active.png^[colorize:#000000:40"..cable_entry,
		"technic_water_mill_top_active.png^[colorize:#000000:40",
		"technic_water_mill_top_active.png^[colorize:#000000:40",
		"technic_water_mill_top_active.png^[colorize:#000000:40",
		"technic_water_mill_top_active.png^[colorize:#000000:40"},
	groups = {snappy=2, choppy=2, oddly_breakable_by_hand=2, technic_all_tiers=1, technic_machine=1, axey=2, handy=1},
	is_ground_content = core.registered_nodes["technic:switching_station"].is_ground_content,
	_mcl_blast_resistance = core.registered_nodes["technic:switching_station"]._mcl_blast_resistance,
	_mcl_hardness = core.registered_nodes["technic:switching_station"]._mcl_hardness,
	connect_sides = {"bottom"},
	sounds = core.registered_nodes["technic:switching_station"].sounds,
	on_construct = function(pos)
		local meta = core.get_meta(pos)
		meta:set_string("infotext", S("Switching Station"))
		meta:set_string("formspec", "field[channel;"..S("Digiline Channel")..";${channel}]")
		start_network(pos)
		core.get_node_timer(pos):start(1.0)
	end,
	on_destruct = function(pos)
		-- Remove network when last switching stations is removed
		local network_id = technic.sw_pos2network(pos)
		local network = network_id and technic.networks[network_id]
		if network and admin_switch_remove(pos, network) < 1 then
			technic.remove_network(network_id)
		end
	end,
	technic_run = function(pos, node, run_stage, network)
		local meta = core.get_meta(pos)
		meta:set_int(network.tier.."_EU_supply", network.admin_switching_station_supply or 5000000)
	end,
	on_receive_fields = function(pos, formname, fields, sender)
		if not fields.channel then
			return
		end
		local plname = sender:get_player_name()
		if core.is_protected(pos, plname) then
			core.record_protection_violation(pos, plname)
			return
		end
		local meta = core.get_meta(pos)
		meta:set_string("channel", fields.channel)
	end,
	-- nodetimer for network activation
	on_timer = core.registered_nodes["technic:switching_station"].on_timer,
	mesecons = core.registered_nodes["technic:switching_station"].mesecons,
	digiline = core.registered_nodes["technic:switching_station"].digiline,
})

for tier, machines in pairs(technic.machines) do
	technic.register_machine(tier, "technic:admin_switching_station", technic.producer)
end

core.register_on_mods_loaded(function()
	admin_networks = load_admin_networks()
	start_autorun_admin_networks()
end)
