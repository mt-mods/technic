
--
-- Technic power network administrative functions
--

local active_networks = technic.active_networks
local networks = technic.networks
local cables = technic.cables

-- Enable / disable technic globalstep
technic.powerctrl_state = true
core.register_chatcommand("powerctrl", {
	params = "[on|off]",
	description = "Enables or disables technic network globalstep handler",
	privs = { [technic.config:get("admin_priv")] = true },
	func = function(name, state)
		if state == "on" then
			technic.powerctrl_state = true
		elseif state == "off" then
			technic.powerctrl_state = false
		end
		core.chat_send_player(name, ("Technic network globalstep %s."):format(
			technic.powerctrl_state and "enabled" or "disabled"
		))
	end
})

local function align(s, w)
	s = tostring(s)
	return string.rep(' ', w - #s) .. s
end

local function net2str(id)
	return align(core.pos_to_string(technic.network2pos(id)),21)
end

-- List all active networks with additional data
core.register_chatcommand("technic_get_active_networks", {
	params = "[minlag]",
	description = "Lists all active networks with additional network data",
	privs = { [technic.config:get("admin_priv")] = true },
	func = function(name, minlag)
		minlag = tonumber(minlag) or 0
		local activecount = 0
		local network_info = {}
		local netcount = 0
		local nodecount = 0
		for id,net in pairs(active_networks) do
			activecount = activecount + 1
			if minlag == 0 or (net.lag and net.lag >= minlag * 1000) then
				table.insert(network_info, ("Pos:%s PR:%s RE:%s BA:%s Skip:%s Lag:%sms"):format(
					net2str(id), align(#net.PR_nodes, 4), align(#net.RE_nodes, 4), align(#net.BA_nodes, 4),
					align(net.skip, 3), net.lag and align(("%0.2f"):format(net.lag / 1000), 6) or ""
				))
			end
		end
		for _ in pairs(networks) do netcount = netcount + 1 end
		for _ in pairs(cables) do nodecount = nodecount + 1 end
		core.chat_send_player(name,
			("Cached networks: %d active, %d total, %d nodes, %0.2f max lag.\n%s"):format(
			activecount, netcount, nodecount, technic.get_max_lag(), table.concat(network_info, "\n")
		))
	end
})

-- Clear technic active networks
core.register_chatcommand("technic_flush_switch_cache", {
	description = "Removes all active networks from the cache",
	privs = { [technic.config:get("admin_priv")] = true },
	func = function(name)
		local activecount = 0
		for id in pairs(active_networks) do
			activecount = activecount + 1
			active_networks[id] = nil
		end
		core.chat_send_player(name, ("Network data removed: %d active networks deactivated."):format(activecount))
	end
})

-- Completely clear all technic network caches
core.register_chatcommand("technic_clear_network_data", {
	description = "Removes all networks and network nodes from the cache",
	privs = { [technic.config:get("admin_priv")] = true },
	func = function(name)
		-- Clear all network data keeping all reference links intact
		local activecount = 0
		local netcount = 0
		local nodecount = 0
		for id in pairs(active_networks) do
			activecount = activecount + 1
			active_networks[id] = nil
		end
		for id in pairs(networks) do
			netcount = netcount + 1
			networks[id] = nil
		end
		for id in pairs(cables) do
			nodecount = nodecount + 1
			cables[id] = nil
		end
		core.chat_send_player(name, string.format(
			"Network data removed: %d active networks, %d total networks, %d network nodes.",
			activecount, netcount, nodecount
		))
	end
})
