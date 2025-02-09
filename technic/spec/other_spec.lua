require("mineunit")
--[[
	Technic network unit tests.
	Execute mineunit at technic source directory.
--]]

-- Load complete technic mod
fixture("technic")
sourcefile("init")

describe("Coal alloy furnace", function()

	local player = Player("SX")
	local furnace_pos = {x=0,y=0,z=0}
	local FUEL = "technic:sawdust"

	-- Execute on mods loaded callbacks to finish loading.
	mineunit:mods_loaded()
	-- Tell mods that 1 minute passed already to execute all weird core.after hacks.
	mineunit:execute_globalstep(60)
	world.set_default_node("air")

	-- Execute multiple globalsteps: run_globalstep(times = 1, dtime = 1)
	local run_globalstep = spec_utility.run_globalsteps

	-- Place itemstack into inventory slot 1: place_itemstack(pos, itemstack, listname = "src")
	local place_itemstack = spec_utility.place_itemstack

	-- Get itemstack for inspection without removing it: get_itemstack(pos, listname = "dst", index = 1)
	local get_itemstack = spec_utility.get_itemstack

	-- Execute this many 1 second glopbalstep cycles for each RE machine
	local RUN_CYCLES = 15
	-- Function to calculate amount of items produced by base machines within completed network cycles
	-- usage: base_machine_expected_amount(machine_speed, recipe_time, output_amount)
	local base_machine_expected_amount = spec_utility.base_machine_output_calculator(RUN_CYCLES)

	local function reset_furnace(stack1, stack2, fuel)
		world.place_node(furnace_pos, "technic:coal_alloy_furnace", player)
		if stack1 then place_itemstack(furnace_pos, stack1, "src", 1) end
		if stack2 then place_itemstack(furnace_pos, stack2, "src", 2) end
		if fuel then place_itemstack(furnace_pos, FUEL.." "..tostring(fuel), "fuel") end
	end

	it("wont crash without placement callbacks", function()
		local node = { name = "technic:coal_alloy_furnace", param1 = 0, param2 = 0 }
		world.nodes[core.hash_node_position(furnace_pos)] = node
		run_globalstep(1)
	end)

	it("alloys dusts", function()
		reset_furnace("technic:copper_dust 14", "technic:tin_dust 2", 99)
		-- Extra cycles: fuel stack ignition cycles wont produce anything
		run_globalstep(13)
		-- Check results
		local stack = get_itemstack(furnace_pos, "dst")
		assert.equals(stack:get_name(), "default:bronze_ingot")
		-- Expected amount of items produced: machine speed, recipe time, items per cycle
		assert.equals(base_machine_expected_amount(1, 12, 8), stack:get_count())
	end)

	it("alloys ingots", function()
		reset_furnace("technic:carbon_steel_ingot 12", "technic:chromium_ingot 3", 99)
		-- Extra cycles: fuel stack ignition cycles wont produce anything
		run_globalstep(RUN_CYCLES + 2)
		-- Check results
		local stack = get_itemstack(furnace_pos, "dst")
		assert.equals(stack:get_name(), "technic:stainless_steel_ingot")
		-- Expected amount of items produced: machine speed, recipe time, items per cycle
		assert.equals(base_machine_expected_amount(1, 7.5, 5), stack:get_count())
	end)

end)
