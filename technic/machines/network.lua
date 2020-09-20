--
-- Power network specific functions and data should live here
--

technic.networks = {}
technic.cables = {}

function technic.remove_network(network_id)
	local cables = technic.cables
	for pos_hash,cable_net_id in pairs(cables) do
		if cable_net_id == network_id then
			cables[pos_hash] = nil
		end
	end
	technic.networks[network_id] = nil
end

function technic.sw_pos2network(pos)
	return pos and technic.cables[minetest.hash_node_position({x=pos.x,y=pos.y-1,z=pos.z})]
end

function technic.pos2network(pos)
	return pos and technic.cables[minetest.hash_node_position(pos)]
end

function technic.network2pos(network_id)
	return network_id and minetest.get_position_from_hash(network_id)
end

function technic.network2sw_pos(network_id)
	-- Return switching station position for network.
	-- It is not guaranteed that position actually contains switching station.
	local sw_pos = minetest.get_position_from_hash(network_id)
	sw_pos.y = sw_pos.y + 1
	return sw_pos
end

local node_timeout = {}

function technic.get_timeout(tier, pos)
	if node_timeout[tier] == nil then
		-- it is normal that some multi tier nodes always drop here when checking all LV, MV and HV tiers
		return 0
	end
	return node_timeout[tier][minetest.hash_node_position(pos)] or 0
end

function technic.touch_node(tier, pos, timeout)
	if node_timeout[tier] == nil then
		-- this should get built up during registration
		node_timeout[tier] = {}
	end
	node_timeout[tier][minetest.hash_node_position(pos)] = timeout or 2
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
		},
		action = function(pos, node)
			-- Delete all listed metadata key/value pairs from technic machines
			local keys = {
				"LV_EU_timeout", "MV_EU_timeout", "HV_EU_timeout",
				"LV_network", "MV_network", "HV_network",
			}
			local meta = minetest.get_meta(pos)
			for _,key in ipairs(keys) do
				-- Value of `""` will delete the key.
				meta:set_string(key, "")
			end
		end,
	})
end
