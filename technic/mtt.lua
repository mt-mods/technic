
-- check if all required nodenames are registered
mtt.validate_nodenames(core.get_modpath("technic").."/registered_nodes.txt")

-- test mapgen
mtt.emerge_area({x=0, y=0, z=0}, {x=48, y=48, z=48})

mtt.register("technic.max_lag", function(callback)
	local lag = technic.get_max_lag()
	assert(lag ~= nil and lag > 0)
	callback()
end)

-- switching station tests

local function clear_area(pos1, pos2)
	for x = pos1.x, pos2.x do
		for y = pos1.y, pos2.y do
			for z = pos1.z, pos2.z do
				core.set_node({x=x, y=y, z=z}, {name="air"})
			end
		end
	end
end

local sw_area = { size = { x=10, y=10, z=10 }, emerged = true }

mtt.register_with_area("switching station without cable has no network", sw_area, function(pos1, pos2, callback)
	clear_area(pos1, pos2)
	local sw_pos = vector.offset(pos1, 2, 2, 2)
	core.set_node(sw_pos, {name="technic:switching_station"})

	assert(technic.sw_pos2tier(sw_pos) == nil)
	assert(technic.sw_pos2network(sw_pos) == nil)
	assert(core.get_meta(sw_pos):get_string("infotext") ~= "")

	core.remove_node(sw_pos)
	callback()
end)

mtt.register_with_area("switching station creates and removes network", sw_area, function(pos1, pos2, callback)
	clear_area(pos1, pos2)
	local cable_pos = vector.offset(pos1, 2, 2, 2)
	local sw_pos = vector.offset(cable_pos, 0, 1, 0)
	core.set_node(cable_pos, {name="technic:lv_cable"})
	core.set_node(sw_pos, {name="technic:switching_station"})

	assert(technic.sw_pos2tier(sw_pos) == "LV")
	local network_id = technic.sw_pos2network(sw_pos)
	assert(network_id)
	assert(network_id == core.hash_node_position(cable_pos))
	assert(vector.equals(technic.network2sw_pos(network_id), sw_pos))
	assert(vector.equals(technic.network2pos(network_id), cable_pos))

	local network = technic.networks[network_id]
	assert(network)
	assert(network.tier == "LV")
	assert(#network.swpos == 1)
	assert(vector.equals(network.swpos[1], sw_pos))
	assert(technic.active_networks[network_id])

	-- removing the only station removes the network
	core.remove_node(sw_pos)
	assert(technic.networks[network_id] == nil)
	assert(technic.active_networks[network_id] == nil)
	assert(technic.pos2network(cable_pos) == nil)

	core.remove_node(cable_pos)
	callback()
end)

mtt.register_with_area("switching station network contents", sw_area, function(pos1, pos2, callback)
	clear_area(pos1, pos2)
	local cable_pos = vector.offset(pos1, 2, 2, 2)
	local sw_pos = vector.offset(cable_pos, 0, 1, 0)
	local cable2_pos = vector.offset(cable_pos, 1, 0, 0)
	local cable3_pos = vector.offset(cable_pos, 2, 0, 0)
	local gen_pos = vector.offset(cable_pos, 2, 1, 0)
	local unconnected_pos = vector.offset(cable_pos, 5, 0, 5)

	core.set_node(cable_pos, {name="technic:lv_cable"})
	core.set_node(cable2_pos, {name="technic:lv_cable"})
	core.set_node(cable3_pos, {name="technic:lv_cable"})
	core.set_node(gen_pos, {name="technic:lv_generator"})
	core.set_node(unconnected_pos, {name="technic:lv_cable"})
	core.set_node(sw_pos, {name="technic:switching_station"})

	local network_id = technic.sw_pos2network(sw_pos)
	assert(network_id)
	assert(technic.pos2network(cable2_pos) == network_id)
	assert(technic.pos2network(cable3_pos) == network_id)
	assert(technic.pos2network(unconnected_pos) == nil)

	local network = technic.networks[network_id]
	assert(network)
	assert(#network.PR_nodes == 1)
	assert(vector.equals(network.PR_nodes[1], gen_pos))
	assert(#network.RE_nodes == 0)
	assert(#network.BA_nodes == 0)

	-- build_network returns the cached node lists of a complete network
	local PR, BA, RE = technic.build_network(network_id)
	assert(PR == network.PR_nodes)
	assert(BA == network.BA_nodes)
	assert(RE == network.RE_nodes)

	core.remove_node(sw_pos)
	assert(technic.networks[network_id] == nil)
	for _, p in ipairs({cable_pos, cable2_pos, cable3_pos, gen_pos, unconnected_pos}) do
		core.remove_node(p)
	end
	callback()
end)

mtt.register_with_area("multiple switching stations share a network", sw_area, function(pos1, pos2, callback)
	clear_area(pos1, pos2)
	local cable1_pos = vector.offset(pos1, 2, 2, 2)
	local cable2_pos = vector.offset(cable1_pos, 1, 0, 0)
	local sw1_pos = vector.offset(cable1_pos, 0, 1, 0)
	local sw2_pos = vector.offset(cable2_pos, 0, 1, 0)

	core.set_node(cable1_pos, {name="technic:lv_cable"})
	core.set_node(cable2_pos, {name="technic:lv_cable"})
	core.set_node(sw1_pos, {name="technic:switching_station"})
	core.set_node(sw2_pos, {name="technic:switching_station"})

	local network_id = technic.sw_pos2network(sw1_pos)
	assert(network_id)
	assert(technic.sw_pos2network(sw2_pos) == network_id)
	local network = technic.networks[network_id]
	assert(#network.swpos == 2)

	-- removing one station keeps the network alive
	core.remove_node(sw1_pos)
	assert(technic.networks[network_id] == network)
	assert(#network.swpos == 1)
	assert(vector.equals(network.swpos[1], sw2_pos))

	-- removing the last one removes it
	core.remove_node(sw2_pos)
	assert(technic.networks[network_id] == nil)

	core.remove_node(cable1_pos)
	core.remove_node(cable2_pos)
	callback()
end)

mtt.register("technic.switch_insert/switch_remove", function(callback)
	local net = { swpos = {} }
	local pos = {x=1, y=2, z=3}
	assert(technic.switch_insert(pos, net) == 1)
	-- duplicate insert is ignored
	assert(technic.switch_insert({x=1, y=2, z=3}, net) == 1)
	assert(technic.switch_insert({x=4, y=5, z=6}, net) == 2)
	-- inserted position is a copy
	pos.x = 100
	assert(net.swpos[1].x == 1)
	assert(technic.switch_remove({x=1, y=2, z=3}, net) == 1)
	-- removing unknown position is a no-op
	assert(technic.switch_remove({x=1, y=2, z=3}, net) == 1)
	assert(technic.switch_remove({x=4, y=5, z=6}, net) == 0)
	callback()
end)

mtt.register("technic.network_infotext", function(callback)
	assert(technic.network_infotext(-12345) == nil)
	local id = 424242
	technic.networks[id] = { id = id, all_nodes = {} }
	assert(technic.network_infotext(id, "hello") == "hello")
	assert(technic.network_infotext(id) == "hello")
	technic.networks[id].queue = {}
	assert(technic.network_infotext(id) ~= "hello") -- "Building Network"
	technic.remove_network(id)
	assert(technic.networks[id] == nil)
	callback()
end)

mtt.register("technic.activate_network", function(callback)
	local id = 424243
	technic.networks[id] = { id = id }
	technic.activate_network(id, 10)
	assert(technic.active_networks[id] == technic.networks[id])
	assert(technic.networks[id].timeout > core.get_us_time())
	technic.remove_network(id)
	assert(technic.active_networks[id] == nil)
	-- unknown network is ignored
	technic.activate_network(424244)
	assert(technic.active_networks[424244] == nil)
	callback()
end)
