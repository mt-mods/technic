require("mineunit")
--[[
	Technic machine API regression tests.
	Execute mineunit at technic source directory.
--]]

-- Load fixtures required by tests
fixture("technic")
sourcefile("init")

describe("Technic API", function()

	world.set_default_node({name="air",param2=0})

	describe("Machine registration", function()

		-- Textures for test machines
		local function get_test_tiles()
			local tiles = {
				"test_top", "test_bottom", "test_right",
				"test_left", "test_back", "test_front"
			}
			setmetatable(tiles, {__newindex=function()error("Attempt to modify tiles")end})
			local tiles_active = {
				"top_active", "bottom_active", "right_active",
				"left_active", "back_active", "front_active"
			}
			setmetatable(tiles_active, {__newindex=function()error("Attempt to modify tiles_active")end})
			return tiles, tiles_active
		end

		setup(function()
			-- Change mod name for machine registration
			mineunit:set_current_modname("my_mod")
		end)

		teardown(function()
			-- Restore mod name
			mineunit:restore_current_modname()
		end)

		it("registers my_mod:my_solar_array", function()
			-- Textures for test machine
			local tiles, tiles_active = get_test_tiles()

			-- Just something to allow checking references
			local test_function = function() error("Filler called?") end

			-- Just something else to allow checking unexpected keys
			local imaginary_object = setmetatable({}, {
				__newindex=error,
				__index=function() return "check" end,
				__call=error,
			})

			-- Register machine
			local data = {
				description = "My Mod - My Solar Array",
				tier = "MV",
				digilines = { wire = { rules = technic.digilines.rules_allfaces } },
				on_receive_fields = test_function,
				any_imaginary_key = imaginary_object,
				tiles = tiles,
				tiles_active = tiles_active,
				technic_run = function(pos)
					local meta = minetest.get_meta(pos)
					meta:set_int("MV_EU_supply", 4242)
				end,
			}
			-- Make sure that original definition will not be changed during registration
			setmetatable(data, { __newindex = function() error("Attempt to modify original definition") end })
			technic.register_solar_array("my_mod:my_solar_array", data)

			-- Verify node registration
			local nodedef = minetest.registered_nodes["my_mod:my_solar_array"]
			assert.is_table(nodedef)
			-- Input definition should not be same as actual definition
			assert.not_equals(data, nodedef)
			-- Functions and objects should be equal to not limit creativity
			assert.equals(test_function, nodedef.on_receive_fields)
			assert.equals(imaginary_object, nodedef.any_imaginary_key)
			-- All properties should be similar while not necessarily equal
			assert.same(imaginary_object, nodedef.any_imaginary_key)
			assert.same(tiles, nodedef.tiles)
			assert.same(tiles_active, nodedef.tiles_active)
			assert.same(technic.digilines.rules_allfaces, nodedef.digilines.wire.rules)
		end)

		it("registers my_mod:my_battery", function()
			-- Textures for test machine
			local tiles, tiles_active = get_test_tiles()

			-- Just something to allow checking references
			local test_function = function() error("Filler called?") end

			-- Just something else to allow checking unexpected keys
			local imaginary_object = setmetatable({}, {
				__newindex=error,
				__index=function() return "check" end,
				__call=error,
			})

			-- Register machine
			local data = {
				description = "My Mod - My Battery Box",
				tier = "MV",
				max_charge = 1337,
				charge_rate = 1337,
				discharge_rate = 1337,
				digilines = { wire = { rules = technic.digilines.rules_allfaces } },
				on_receive_fields = test_function,
				any_imaginary_key = imaginary_object,
				tiles = tiles,
				tiles_active = tiles_active,
				technic_run = function(pos, node, run_state, network)
					local meta = minetest.get_meta(pos)
					meta:set_int("MV_EU_demand", 4242)
					network:update_battery(1337, 1337, 0, 0)
				end,
			}
			-- Make sure that original definition will not be changed during registration
			setmetatable(data, { __newindex = function() error("Attempt to modify original definition") end })
			technic.register_battery_box("my_mod:my_battery", data)

			-- Verify node registration
			local nodedef = minetest.registered_nodes["my_mod:my_battery0"]
			assert.is_table(nodedef)
			-- Input definition should not be same as actual definition
			assert.not_equals(data, nodedef)

			-- FIXME: Reminder to fix API, rest of validation will not pass currently.
			-- Comment out next line to execute complete registration API test:
			pending("Battery box registration does not include all fields")

			-- Functions and objects should be equal to not limit creativity
			assert.equals(test_function, nodedef.on_receive_fields)
			assert.equals(imaginary_object, nodedef.any_imaginary_key)
			-- All properties should be similar while not necessarily equal
			assert.same(imaginary_object, nodedef.any_imaginary_key)
			assert.same(tiles, nodedef.tiles)
			assert.same(tiles_active, nodedef.tiles_active)
			assert.same(technic.digilines.rules_allfaces, nodedef.digilines.wire.rules)
		end)

		it("registers my_mod:machine_base", function()
			-- Textures for test machine
			local tiles, tiles_active = get_test_tiles()

			-- Just something to allow checking references
			local test_function = function() error("Filler called?") end

			-- Just something else to allow checking unexpected keys
			local imaginary_object = setmetatable({}, {
				__newindex=error,
				__index=function() return "check" end,
				__call=error,
			})

			-- Register machine
			local data = {
				description = "My Mod - My Machine Base",
				tier = "MV",
				typename = "cooking",
				max_charge = 1337,
				charge_rate = 1337,
				discharge_rate = 1337,
				digilines = { wire = { rules = technic.digilines.rules_allfaces } },
				on_receive_fields = test_function,
				any_imaginary_key = imaginary_object,
				tiles = tiles,
				tiles_active = tiles_active,
				technic_run = function(pos, node, run_state, network)
					local meta = minetest.get_meta(pos)
					meta:set_int("MV_EU_demand", 4242)
					network:update_battery(1337, 1337, 0, 0)
				end,
			}
			-- Make sure that original definition will not be changed during registration
			setmetatable(data, { __newindex = function() error("Attempt to modify original definition") end })
			technic.register_base_machine("my_mod:machine_base", data)

			-- Verify node registration
			local nodedef = minetest.registered_nodes["my_mod:machine_base"]
			assert.is_table(nodedef)
			-- Input definition should not be same as actual definition
			assert.not_equals(data, nodedef)

			-- FIXME: Reminder to fix API, rest of validation will not pass currently.
			-- Comment out next line to execute complete registration API test:
			pending("Base machine registration does not include all fields")

			-- Functions and objects should be equal to not limit creativity
			assert.equals(test_function, nodedef.on_receive_fields)
			assert.equals(imaginary_object, nodedef.any_imaginary_key)
			-- All properties should be similar while not necessarily equal
			assert.same(imaginary_object, nodedef.any_imaginary_key)
			assert.same(tiles, nodedef.tiles)
			assert.same(tiles_active, nodedef.tiles_active)
			assert.same(technic.digilines.rules_allfaces, nodedef.digilines.wire.rules)
		end)

	end)

	describe("Machine use", function()

		local Sam = Player("Sam")
		local net

		setup(function()
			world.layout({
				{{{x=0,y=49,z=-5},{x=0,y=49,z=5}}, "technic:mv_cable"}, -- 11 cables for machine tests
				{{x=0,y=50,z=-5}, "technic:switching_station"}, -- And switching station to build network
			})
			mineunit:mods_loaded()
			-- Build network for tests
			mineunit:execute_globalstep(60)
			local net_id = technic.pos2network({x=0,y=49,z=0})
			assert.not_nil(net_id)
			net = technic.networks[net_id]
			assert.not_nil(net)
			mineunit:execute_on_joinplayer(Sam)
		end)

		teardown(function()
			-- Restore mod name
			mineunit:execute_on_leaveplayer(Sam)
		end)

		it("runs my_mod:my_solar_array", function()
			-- Try to place it and execute network
			Sam:get_inventory():set_stack("main", 1, "my_mod:my_solar_array")
			Sam:do_place({type = "node", above = {x=0, y=50, z=0}, under = {x=0, y=49, z=0}})

			-- Verify placement
			assert.nodename("my_mod:my_solar_array", {x=0,y=50,z=0})

			-- Execute network and verify output
			mineunit:execute_globalstep(1)
			assert.equals(4242, net.supply)
		end)

		it("runs my_mod:my_battery", function()
			-- Try to place it and execute network
			Sam:get_inventory():set_stack("main", 1, "my_mod:my_battery0")
			Sam:do_place({type = "node", above = {x=0, y=50, z=1}, under = {x=0, y=49, z=1}})

			-- Verify placement
			assert.nodename("my_mod:my_battery0", {x=0,y=50,z=1})

			-- Execute network and verify output, first round is just to get warning if behavior changes
			-- Currently battery box charge is always handled on second network cycle, not immediately
			-- This is because charge values / supply / demand are collected during first cycle
			mineunit:execute_globalstep(1)
			assert.equals(0, net.battery_charge)

			-- This is to check actual expected battery_charge value
			mineunit:execute_globalstep(1)
			assert.equals(1337, net.battery_charge)
		end)

	end)

end)

describe("Technic API internals", function()

	it("technic.machines contain only machines", function()
		local types = {PR=1, RE=1, PR_RE=1, BA=1}
		for tier, machines in pairs(technic.machines) do
			assert.is_hashed(machines)
			for nodename, machine_type in pairs(machines) do
				assert.is_hashed(minetest.registered_nodes[nodename])
				local groups = minetest.registered_nodes[nodename].groups
				local tier_group
				for group,_ in pairs(groups) do
					assert.is_nil(group:find("technic_.*_cable$"), "Cable in machines table: "..tostring(nodename))
				end
				assert.not_nil(groups.technic_machine, "Missing technic_machine group for "..tostring(machine_type))
				assert.not_nil(types[machine_type], "Missing type for "..tostring(machine_type))
			end
		end
	end)

	it("technic.cables TBD, misleading name and should be updated", function()
		pending("TBD technic.cables naming and need, see technic networks data for possible options")
	end)

end)
