require("mineunit")
--[[
	Technic network unit tests.
	Execute mineunit at technic source directory.
--]]

-- Load complete technic mod
fixture("technic")
sourcefile("init")

describe("HV machine network", function()

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
		"technic:hv_generator",
		"technic:hv_battery_box0",
		"technic:hv_electric_furnace",
		"technic:hv_grinder",
		"technic:hv_compressor",
		"technic:hv_nuclear_reactor_core",
		"technic:quarry",
		"technic:hv_solar_array",
	}

	local function reset_machine(pos)
		world.place_node(pos, machines[pos.x], player)
	end

	world.clear()
	world.place_node({x=0,y=51,z=0}, "technic:switching_station", player)
	for x = 0, 10 do
		world.place_node({x=x,y=50,z=0}, "technic:hv_cable", player)
	end
	for x = 1, #machines do
		reset_machine({x=x,y=51,z=0})
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
		world.set_node({x=0,y=51,z=0}, {name="air"})
		mineunit:execute_globalstep(1)
		-- Network should be gone
		assert.is_nil(technic.networks[id])
		-- Build new switching station to restore network
		world.place_node({x=0,y=51,z=0}, {name="technic:switching_station"})
		mineunit:execute_globalstep(1)
		assert.not_nil(technic.networks[id])
	end)

	it("charges battery box", function()
		local id = technic.pos2network({x=0,y=50,z=0})
		local net = technic.networks[id]
		assert.gt(net.battery_charge, 1000)
	end)

	it("smelts ores", function()
		local machine_pos = {x=3,y=51,z=0}
		reset_machine(machine_pos)
		place_itemstack(machine_pos, "technic:lead_lump 99")
		-- Extra cycle: powers up the machine but wont produce anything
		run_network(RUN_CYCLES + 1)
		-- Check results
		local stack = get_itemstack(machine_pos)
		assert.equals(stack:get_name(), "technic:lead_ingot")
		-- Expected amount of items produced: machine speed, recipe time, items per cycle
		assert.equals(base_machine_expected_amount(12, 3, 1), stack:get_count())
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
		assert.equals(base_machine_expected_amount(5, 3, 2), stack:get_count())
	end)

	it("accepts battery upgrades", function()
		local machine_pos = {x=4,y=51,z=0}
		reset_machine(machine_pos)
		place_itemstack(machine_pos, "technic:battery 1", "upgrade1")
		place_itemstack(machine_pos, "technic:battery 1", "upgrade2")
		place_itemstack(machine_pos, "technic:lead_lump 99")
		-- Extra cycle: powers up the machine but wont produce anything
		run_network(RUN_CYCLES + 1)
		-- Check results
		local stack = get_itemstack(machine_pos)
		assert.equals(stack:get_name(), "technic:lead_dust")
		-- Expected amount of items produced: machine speed, recipe time, items per cycle
		assert.equals(base_machine_expected_amount(5, 3, 2), stack:get_count())
	end)

	it("accepts control logic upgrades", function()
		local machine_pos = {x=4,y=51,z=0}
		reset_machine(machine_pos)
		place_itemstack(machine_pos, "technic:control_logic_unit 1", "upgrade1")
		place_itemstack(machine_pos, "technic:control_logic_unit 1", "upgrade2")
		place_itemstack(machine_pos, "technic:lead_lump 99")
		-- Extra cycle: powers up the machine but wont produce anything
		run_network(RUN_CYCLES + 1)
		-- Check results
		local stack = get_itemstack(machine_pos)
		assert.equals(stack:get_name(), "technic:lead_dust")
		-- Expected amount of items produced: machine speed, recipe time, items per cycle
		-- Minus items sent away by CLUs: single item per cycle except first cycle which only produces
		local expected_amount = base_machine_expected_amount(5, 3, 2) - RUN_CYCLES + 1
		assert.equals(expected_amount, stack:get_count())
		-- Pipeworks isn't loaded and tubes are handled with no-op functions, sent items are lost
	end)

end)
