require("mineunit")
--[[
	Technic network unit tests.
	Execute mineunit at technic source directory.
--]]

-- Load complete technic mod
fixture("technic")
sourcefile("init")

describe("Technic node placement", function()

	world.set_default_node({name="air",param2=0})

	local function placement_test(player, name, xpos)
		return function()
			player:get_inventory():set_stack("main", 1, name)
			player:do_place({x=xpos, y=1, z=0})
		end
	end

	local player = Player("SX")

	-- Execute on mods loaded callbacks to finish loading.
	mineunit:mods_loaded()
	-- Tell mods that 1 minute passed already to execute all weird core.after hacks.
	mineunit:execute_globalstep(60)

	local nodes = {}
	for nodename, def in pairs(core.registered_nodes) do
		if not (def.groups and def.groups.not_in_creative_inventory) and nodename:find("^technic:") then
			table.insert(nodes, nodename)
		end
	end

	setup(function()
		mineunit:execute_on_joinplayer(player)
	end)

	teardown(function()
		mineunit:execute_on_leaveplayer(player)
	end)

	for x, nodename in ipairs(nodes) do
		it("player can place "..nodename, placement_test(player, nodename, x))
	end

	describe("cable plates", function()

		world.set_node({x=10,y=10,z=10}, "default:stone")
		world.set_node({x=10,y=20,z=10}, "default:stone")
		world.set_node({x=10,y=30,z=10}, "default:stone")
		world.set_node({x=10,y=40,z=10}, "default:stone")

		describe("normal placement", function()

			setup(function()
				player:get_inventory():set_stack("main", 1, "technic:hv_cable_plate_1 6")
				player:_reset_player_controls()
			end)

			it("plate_1", function()
				local pointed_thing = {
					type = "node",
					above = {y = 10,x = 11,z = 10},
					under = {y = 10,x = 10,z = 10}
				}
				player:do_place(pointed_thing)
				assert.equals("technic:hv_cable_plate_1", core.get_node(pointed_thing.above).name)
			end)

			it("plate_2", function()
				local pointed_thing = {
					type = "node",
					above = {y = 11,x = 10,z = 10},
					under = {y = 10,x = 10,z = 10}
				}
				player:do_place(pointed_thing)
				assert.equals("technic:hv_cable_plate_2", core.get_node(pointed_thing.above).name)
			end)

			it("plate_3", function()
				local pointed_thing = {
					type = "node",
					above = {y = 10,x = 10,z = 11},
					under = {y = 10,x = 10,z = 10}
				}
				player:do_place(pointed_thing)
				assert.equals("technic:hv_cable_plate_3", core.get_node(pointed_thing.above).name)
			end)

			it("plate_4", function()
				local pointed_thing = {
					type = "node",
					above = {y = 10,x = 9,z = 10},
					under = {y = 10,x = 10,z = 10}
				}
				player:do_place(pointed_thing)
				assert.equals("technic:hv_cable_plate_4", core.get_node(pointed_thing.above).name)

			end)

			it("plate_5", function()
				local pointed_thing = {
					type = "node",
					above = {y = 9,x = 10,z = 10},
					under = {y = 10,x = 10,z = 10}
				}
				player:do_place(pointed_thing)
				assert.equals("technic:hv_cable_plate_5", core.get_node(pointed_thing.above).name)

			end)

			it("plate_6", function()
				local pointed_thing = {
					type = "node",
					above = {y = 10,x = 10,z = 9},
					under = {y = 10,x = 10,z = 10}
				}
				player:do_place(pointed_thing)
				assert.equals("technic:hv_cable_plate_6", core.get_node(pointed_thing.above).name)
			end)

		end)

		describe("middle aux1 placement", function()

			setup(function()
				player:get_inventory():set_stack("main", 1, "technic:hv_cable_plate_1 6")
				player:_set_player_control_state("aux1", true)
			end)

			it("heading X-", function()
				local pos = {y = 20,x = 11,z = 10}
				player:do_set_pos_fp(vector.add(pos, {y=0, x=2, z=0}))
				player:do_set_look_xyz("X-")
				player:do_place(pos)
				assert.equals("technic:hv_cable_plate_4", core.get_node(pos).name)
			end)

			it("heading Y-", function()
				local pos = {y = 21,x = 10,z = 10}
				player:do_set_pos_fp(vector.add(pos, {y=2, x=0, z=0}))
				player:do_set_look_xyz("Y-")
				player:do_place(pos)
				assert.equals("technic:hv_cable_plate_5", core.get_node(pos).name)
			end)

			it("heading Z-", function()
				local pos = {y = 20,x = 10,z = 11}
				player:do_set_pos_fp(vector.add(pos, {y=0, x=0, z=2}))
				player:do_set_look_xyz("Z-")
				player:do_place(pos)
				assert.equals("technic:hv_cable_plate_6", core.get_node(pos).name)
			end)

			it("heading X+", function()
				local pos = {y = 20,x = 9,z = 10}
				player:do_set_pos_fp(vector.add(pos, {y=0, x=-2, z=0}))
				player:do_set_look_xyz("X+")
				player:do_place(pos)
				assert.equals("technic:hv_cable_plate_1", core.get_node(pos).name)

			end)

			it("heading Y+", function()
				local pos = {y = 19,x = 10,z = 10}
				player:do_set_pos_fp(vector.add(pos, {y=-2, x=0, z=0}))
				player:do_set_look_xyz("Y+")
				player:do_place(pos)
				assert.equals("technic:hv_cable_plate_2", core.get_node(pos).name)
			end)

			it("heading Z+", function()
				local pos = {y = 20,x = 10,z = 9}
				player:do_set_pos_fp(vector.add(pos, {y=0, x=0, z=-2}))
				player:do_set_look_xyz("Z+")
				player:do_place(pos)
				assert.equals("technic:hv_cable_plate_3", core.get_node(pos).name)
			end)

		end)

		describe("aux1 placement pointing X+ edge", function()

			setup(function()
				player:get_inventory():set_stack("main", 1, "technic:hv_cable_plate_1 2")
				player:_set_player_control_state("aux1", true)
			end)

			it("heading Z+", function()
				local pos = {y = 30,x = 10,z = 9}
				player:do_set_pos_fp(vector.add(pos, {y=0, x=0.4, z=-2}))
				player:do_set_look_xyz("Z+")
				player:do_place(pos)
				assert.equals("technic:hv_cable_plate_4", core.get_node(pos).name)
			end)

			it("heading Y-", function()
				local pos = {y = 31,x = 10,z = 10}
				player:do_set_pos_fp(vector.add(pos, {y=2, x=0.4, z=0}))
				player:do_set_look_xyz("Y-")
				player:do_place(pos)
				assert.equals("technic:hv_cable_plate_4", core.get_node(pos).name)
			end)

		end)

		describe("aux1 placement pointing Z+ edge", function()

			setup(function()
				player:get_inventory():set_stack("main", 1, "technic:hv_cable_plate_1 4")
				player:_set_player_control_state("aux1", true)
			end)

			it("heading X-", function()
				local pos = {y = 40,x = 11,z = 10}
				player:do_set_pos_fp(vector.add(pos, {y=0, x=2, z=0.4}))
				player:do_set_look_xyz("X-")
				player:do_place(pos)
				assert.equals("technic:hv_cable_plate_6", core.get_node(pos).name)
			end)

			it("heading Y-", function()
				local pos = {y = 41,x = 10,z = 10}
				player:do_set_pos_fp(vector.add(pos, {y=2, x=0, z=0.4}))
				player:do_set_look_xyz("Y-")
				player:do_place(pos)
				assert.equals("technic:hv_cable_plate_6", core.get_node(pos).name)
			end)

			it("heading X+", function()
				local pos = {y = 40,x = 9,z = 10}
				player:do_set_pos_fp(vector.add(pos, {y=0, x=-2, z=0.4}))
				player:do_set_look_xyz("X+")
				player:do_place(pos)
				assert.equals("technic:hv_cable_plate_6", core.get_node(pos).name)
			end)

			it("heading Y+", function()
				local pos = {y = 39,x = 10,z = 10}
				player:do_set_pos_fp(vector.add(pos, {y=-2, x=0, z=0.4}))
				player:do_set_look_xyz("Y+")
				player:do_place(pos)
				assert.equals("technic:hv_cable_plate_6", core.get_node(pos).name)
			end)

		end)

	end)

	it("gloabalstep works", function()
		for _=1,60 do
			mineunit:execute_globalstep(1)
		end
	end)

end)
