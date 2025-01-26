require("mineunit")
--[[
	Technic network unit tests.
	Execute mineunit at technic source directory.
--]]

-- Load complete technic mod
fixture("technic")
sourcefile("init")

describe("LV machine network", function()

	local player = Player("SX")

	-- Execute on mods loaded callbacks to finish loading.
	mineunit:mods_loaded()
	-- Tell mods that 1 minute passed already to execute all weird core.after hacks.
	mineunit:execute_globalstep(60)
	world.set_default_node("air")

	-- Execute multiple globalsteps: run_network(times = 1, dtime = 1)
	local run_network = spec_utility.run_globalsteps

	-- Place itemstack into inventory slot 1: place_itemstack(pos, itemstack, listname = "src")
	local place_itemstack = spec_utility.place_itemstack

	-- Get itemstack for inspection without removing it: get_itemstack(pos, listname = "dst", index = 1)
	local get_itemstack = spec_utility.get_itemstack

	-- Execute this many 1 second glopbalstep cycles for each RE machine
	local RUN_CYCLES = 4
	-- Function to calculate amount of items produced by base machines within completed network cycles
	-- usage: base_machine_expected_amount(machine_speed, recipe_time, output_amount)
	local base_machine_expected_amount = spec_utility.base_machine_output_calculator(RUN_CYCLES)

	local machines = {
		"technic:lv_battery_box0",
		"technic:lv_electric_furnace",
		"technic:lv_extractor",
		"technic:lv_grinder",
		"technic:lv_alloy_furnace",
		"technic:lv_compressor",
		"technic:lv_led",
		"technic:lv_lamp",
		"technic:water_mill",
		"technic:lv_generator",
		"technic:geothermal",
		"technic:solar_panel",
		"technic:lv_solar_array",
	}

	local function reset_machine(pos)
		world.place_node(pos, machines[pos.x], player)
	end

	world.clear()
	world.place_node({x=0,y=51,z=0}, "technic:switching_station", player)
	for x = 0, 15 do
		world.place_node({x=x,y=50,z=0}, "technic:lv_cable", player)
	end
	for x, name in ipairs(machines) do
		reset_machine({x=x,y=51,z=0})
	end

	-- Helper to destroy nodes in test world returning list of removed nodes indexed by coordinates
	local function remove_nodes(nodes)
		local removed = {}
		for x = 0, 15 do
			local pos = {x=x,y=51,z=0}
			local node = core.get_node(pos)
			if nodes[node.name] then
				removed[pos] = node
				world.remove_node(pos)
			end
		end
		return removed
	end

	-- Helper to restore nodes removed by remove_nodes function
	local function restore_nodes(nodes)
		for pos, node in ipairs(nodes) do
			world.place_node(pos, node, player)
		end
	end

	it("executes network", function()
		spy.on(technic, "network_run")
		run_network(4)
		assert.spy(technic.network_run).called(4)
		local id = technic.pos2network({x=0,y=50,z=0})
		assert.not_nil(technic.networks[id])
		assert.gt(technic.networks[id].supply, 0)
	end)

	it("kills network when switching station disappear", function()
		local id = technic.pos2network({x=0,y=50,z=0})
		assert.not_nil(technic.networks[id])
		-- Remove switching station and execute globalstep
		world.remove_node({x=0,y=51,z=0})
		run_network()
		-- Network should be gone
		assert.is_nil(technic.networks[id])
		-- Build new switching station to restore network
		world.place_node({x=0,y=51,z=0}, {name="technic:switching_station"})
		run_network()
		assert.not_nil(technic.networks[id])
	end)

	it("charges battery box", function()
		local id = technic.pos2network({x=0,y=50,z=0})
		local net = technic.networks[id]
		assert.gt(net.battery_charge, 1000)
	end)

	it("smelts ores", function()
		local machine_pos = {x=2,y=51,z=0}
		reset_machine(machine_pos)
		place_itemstack(machine_pos, "technic:lead_lump 99")
		-- Extra cycle: powers up the machine but wont produce anything
		run_network(RUN_CYCLES + 1)
		-- Check results
		local stack = get_itemstack(machine_pos)
		assert.equals(stack:get_name(), "technic:lead_ingot")
		-- Expected amount of items produced: machine speed, recipe time, items per cycle
		assert.equals(base_machine_expected_amount(2, 3, 1), stack:get_count())
	end)

	it("grinds ores", function()
		local machine_pos = {x=4,y=51,z=0}
		reset_machine(machine_pos)
		place_itemstack(machine_pos, "technic:lead_lump 99")
		-- Extra cycle: powers up the machine but wont produce anything
		run_network(RUN_CYCLES + 1)
		-- Check results
		local stack = get_itemstack(machine_pos)
		assert.equals(stack:get_name(), "technic:lead_dust")
		-- Expected amount of items produced: machine speed, recipe time, items per cycle
		assert.equals(base_machine_expected_amount(1, 3, 2), stack:get_count())
	end)

	it("comperess sand", function()
		local machine_pos = {x=6,y=51,z=0}
		reset_machine(machine_pos)
		place_itemstack(machine_pos, "default:sand 99")
		-- Extra cycle: powers up the machine but wont produce anything
		run_network(RUN_CYCLES + 1)
		-- Check results
		local stack = get_itemstack(machine_pos)
		assert.equals(stack:get_name(), "default:sandstone")
		-- Expected amount of items produced: machine speed, recipe time, items per cycle
		assert.equals(base_machine_expected_amount(1, 4, 1), stack:get_count())
	end)

	it("cuts power when generators disappear", function()
		place_itemstack({x=2,y=51,z=0}, "technic:lead_lump 99")
		place_itemstack({x=4,y=51,z=0}, "technic:lead_lump 99")
		place_itemstack({x=6,y=51,z=0}, "default:sand 99")
		local id = technic.pos2network({x=0,y=50,z=0})
		assert.not_nil(technic.networks[id])

		-- Remove generators and run network 60 times
		local generators = {
			["technic:solar_panel"] = 1,
			["technic:lv_solar_array"] = 1,
		}
		local restore = remove_nodes(generators)

		-- Verify that network gets immediately powered down
		local net = technic.networks[id]
		run_network()
		assert.equal(net.supply, 0)

		-- Get current battery charge for network and execute few more cycles
		local battery_charge = net.battery_charge
		assert.gt(net.battery_charge, 1000)
		run_network(RUN_CYCLES)

		-- Verify that significant battery charge was used and network still does not generate energy
		assert.lt(net.battery_charge, battery_charge / 2)
		assert.equal(net.supply, 0)

		-- Restore generators to network and run network once
		restore_nodes(restore)
		run_network()
	end)

end)
