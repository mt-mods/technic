--
-- Compatibility hacks for digtron to work well with technic plus new network system
--
-- More information:
-- https://github.com/mt-mods/technic/issues/100
--

local function power_connector_compat()
	local digtron_technic_run = minetest.registered_nodes["digtron:power_connector"].technic_run
	minetest.override_item("digtron:power_connector",{
		technic_run = function(pos, node)
			local network_id = technic.cables[minetest.hash_node_position(pos)]
			local sw_pos = network_id and minetest.get_position_from_hash(network_id)
			if sw_pos then sw_pos.y = sw_pos.y + 1 end
			local meta = minetest.get_meta(pos)
			meta:set_string("HV_network", sw_pos and minetest.pos_to_string(sw_pos) or "")
			return digtron_technic_run(pos, node)
		end,
	})
end

minetest.register_on_mods_loaded(function()
	if minetest.registered_nodes["digtron:power_connector"] then
		power_connector_compat()
	end
end)
