require("mineunit")
--[[
	Technic tool regression tests.
	Execute mineunit at technic source directory.
--]]

-- Load complete technic mod
fixture("technic")

local RUN_TECHNIC_ADDONS_CHAINSAWMK3_TESTS = false

describe("Technic power tool", function()

	if RUN_TECHNIC_ADDONS_CHAINSAWMK3_TESTS then
		-- Load technic_addons mod
		mineunit:set_modpath("technic_addons", "../../technic_addons")
		mineunit:set_current_modname("technic_addons")
		sourcefile("../../technic_addons/init")
		mineunit:restore_current_modname()
	end


	world.set_default_node("air")

	-- HV battery box and some HV solar arrays for charging
	local BB_Charge_POS = {x=0,y=51,z=0}
	local BB_Discharge_POS = {x=0,y=51,z=2}
	world.layout({
		-- Network with generators for charging tools in battery box
		{BB_Charge_POS, "technic:hv_battery_box0"},
		{{x=1,y=51,z=0}, "technic:switching_station"},
		{{{x=2,y=51,z=0},{x=10,y=51,z=0}}, "technic:solar_array_hv"},
		{{{x=0,y=50,z=0},{x=10,y=50,z=0}}, "technic:hv_cable"},
		-- Network without generators for discharging tools in battery box
		{BB_Discharge_POS, "technic:hv_battery_box0"},
		{{x=1,y=51,z=2}, "technic:switching_station"},
		{{{x=0,y=50,z=2},{x=1,y=50,z=2}}, "technic:hv_cable"},
	})

	-- Some helpers to make stack access simpler
	local player = Player("SX")
	local charge_inv = minetest.get_meta(BB_Charge_POS):get_inventory()
	local discharge_inv = minetest.get_meta(BB_Discharge_POS):get_inventory()
	local function set_charge_stack(stack) charge_inv:set_stack("src", 1, stack) end
	local function get_charge_stack() return charge_inv:get_stack("src", 1) end
	local function set_discharge_stack(stack) discharge_inv:set_stack("src", 1, stack) end
	local function get_discharge_stack() return discharge_inv:get_stack("src", 1) end
	local function set_player_stack(stack) return player:get_inventory():set_stack("main", 1, stack) end
	local function get_player_stack() return player:get_inventory():get_stack("main", 1) end

	-- Execute on mods loaded callbacks to finish loading.
	mineunit:mods_loaded()
	-- Tell mods that 1 minute passed already to execute all weird minetest.after hacks.
	mineunit:execute_globalstep(60)

	describe("API", function()

		setup(function()
			set_charge_stack(ItemStack())
			set_discharge_stack(ItemStack())
			mineunit:set_current_modname("mymod")
			mineunit:execute_on_joinplayer(player)
		end)

		teardown(function()
			mineunit:execute_on_leaveplayer(player)
			mineunit:restore_current_modname()
		end)

		local use_RE_charge_result

		it("technic.register_power_tool works", function()
			technic.register_power_tool("mymod:powertool", {
				description = "My Mod Power Tool",
				inventory_image = "mymod_powertool.png",
				max_charge = 1234,
				on_use = function(itemstack, player, pointed_thing)
					use_RE_charge_result = technic.use_RE_charge(itemstack, 123)
					return itemstack
				end,
			})
			local itemdef = minetest.registered_items["mymod:powertool"]
			assert.is_hashed(itemdef)
			assert.is_function(itemdef.on_use)
			assert.is_function(itemdef.on_refill)
			assert.equals("technic_RE_charge", itemdef.wear_represents)
			assert.is_number(itemdef.technic_max_charge)
			assert.gt(itemdef.technic_max_charge, 0)
		end)

		it("technic.use_RE_charge works (zero charge)", function()
			set_player_stack("mymod:powertool")
			spy.on(technic, "use_RE_charge")
			player:do_use(player:get_pos())
			assert.spy(technic.use_RE_charge).called(1)
			assert.equals("boolean", type(use_RE_charge_result))
			assert.is_false(use_RE_charge_result)
		end)

		it("technic.get_RE_charge works (zero charge)", function()
			assert.equals(0, technic.get_RE_charge(ItemStack("mymod:powertool")))
		end)

		it("technic.set_RE_charge works (zero charge -> 123)", function()
			local stack = ItemStack("mymod:powertool")
			technic.set_RE_charge(stack, 123)
			assert.equals(123, technic.get_RE_charge(stack))
		end)

		it("technic.use_RE_charge works (minimum charge)", function()
			-- Add partially charged tool to player inventory
			local stack = ItemStack("mymod:powertool")
			technic.set_RE_charge(stack, 123)
			set_player_stack(stack)

			-- Use tool and verify results
			spy.on(technic, "use_RE_charge")
			player:do_use(player:get_pos())
			assert.spy(technic.use_RE_charge).called(1)
			assert.equals("boolean", type(use_RE_charge_result))
			assert.is_true(use_RE_charge_result)
			assert.equals(0, technic.get_RE_charge(get_player_stack()))
		end)

		it("technic.use_RE_charge works (minimum charge + 1)", function()
			-- Add partially charged tool to player inventory
			local stack = ItemStack("mymod:powertool")
			technic.set_RE_charge(stack, 124)
			set_player_stack(stack)
			-- Use tool and verify results
			player:do_use(player:get_pos())
			assert.equals(1, technic.get_RE_charge(get_player_stack()))
		end)

	end)

	describe("charging and discharging extreme ratios", function()

		local function register_test_tool(name, charge_per_use, max_charge)
			technic.register_power_tool("mymod:"..name, {
				description = name,
				inventory_image = "mymod_powertool.png",
				max_charge = max_charge,
				on_use = function(itemstack, player, pointed_thing)
					technic.use_RE_charge(itemstack, charge_per_use)
					return itemstack
				end,
			})
		end

		setup(function()
			set_charge_stack(ItemStack())
			set_discharge_stack(ItemStack())
			mineunit:set_current_modname("mymod")
			register_test_tool("t1_1", 1, 1)
			register_test_tool("t1_2", 1, 2)
			register_test_tool("t1_10001", 1, 10001)
			register_test_tool("t1_65535", 1, 65535)
			register_test_tool("t1_65536", 1, 65536)
			register_test_tool("t100_6553500", 1, 6553500)
			register_test_tool("t100_6553600", 1, 6553600)
			register_test_tool("t2_3", 2, 3)
			mineunit:restore_current_modname()
			mineunit:execute_on_joinplayer(player)
		end)

		teardown(function()
			mineunit:execute_on_leaveplayer(player)
		end)

		-- Very basic tests for few simple and straightforward max_charge values
		-- Add tool to battery box and test charging, 10kEU / cycle

		it("t1_1 can be charged", function()
			set_charge_stack(ItemStack("mymod:t1_1"))
			assert.equals(0, technic.get_RE_charge(get_charge_stack()))
			mineunit:execute_globalstep(1)
			assert.equals(1, technic.get_RE_charge(get_charge_stack()))
		end)

		it("t1_2 can be charged", function()
			-- Add tool to battery box
			set_charge_stack(ItemStack("mymod:t1_2"))
			-- Test charging, 10kEU / cycle
			assert.equals(0, technic.get_RE_charge(get_charge_stack()))
			mineunit:execute_globalstep(1)
			assert.equals(2, technic.get_RE_charge(get_charge_stack()))
		end)

		it("t1_10001 can be charged", function()
			-- Add tool to battery box
			set_charge_stack(ItemStack("mymod:t1_10001"))
			-- Test charging, 10kEU / cycle
			assert.equals(0, technic.get_RE_charge(get_charge_stack()))
			mineunit:execute_globalstep(1)
			assert.equals(10000, technic.get_RE_charge(get_charge_stack()))
			mineunit:execute_globalstep(1)
			assert.equals(10001, technic.get_RE_charge(get_charge_stack()))
		end)

		it("t1_65535 can be charged", function()
			-- Add tool to battery box
			set_charge_stack(ItemStack("mymod:t1_65535"))
			-- Test charging, 10kEU / cycle
			assert.equals(0, technic.get_RE_charge(get_charge_stack()))
			for i=1,6 do mineunit:execute_globalstep(1) end
			assert.equals(60000, technic.get_RE_charge(get_charge_stack()))
			mineunit:execute_globalstep(1)
			assert.equals(65535, technic.get_RE_charge(get_charge_stack()))
		end)

		it("t1_65536 can be charged", function()
			-- Add tool to battery box
			set_charge_stack(ItemStack("mymod:t1_65536"))
			-- Test charging, 10kEU / cycle
			assert.equals(0, technic.get_RE_charge(get_charge_stack()))
			for i=1,6 do mineunit:execute_globalstep(1) end
			assert.equals(60000, technic.get_RE_charge(get_charge_stack()))
			mineunit:execute_globalstep(1)
			assert.equals(65536, technic.get_RE_charge(get_charge_stack()))
		end)

		it("t100_6553500 can be charged", function()
			-- Add tool to battery box
			set_charge_stack(ItemStack("mymod:t100_6553500"))
			-- Test charging, 10kEU / cycle
			assert.equals(0, technic.get_RE_charge(get_charge_stack()))
			for i=1,6 do mineunit:execute_globalstep(1) end
			assert.equals(60000, technic.get_RE_charge(get_charge_stack()))
			mineunit:execute_globalstep(1)
			assert.equals(70000, technic.get_RE_charge(get_charge_stack()))
		end)

		it("t100_6553600 can be charged", function()
			-- Add tool to battery box
			set_charge_stack(ItemStack("mymod:t100_6553600"))
			-- Test charging, 10kEU / cycle
			assert.equals(0, technic.get_RE_charge(get_charge_stack()))
			for i=1,7 do mineunit:execute_globalstep(1) end
			-- This tool already has small charge error and it is acceptable as long as error stays small
			-- Charge value must be 69999-70001 after 7 charge cycles
			assert.lt(69998, technic.get_RE_charge(get_charge_stack()))
			assert.gt(70002, technic.get_RE_charge(get_charge_stack()))
		end)

		it("t100_6553600 can be used", function()
			-- Add tool to battery box
			local stack = ItemStack("mymod:t100_6553600")
			technic.set_RE_charge(stack, 700)
			set_player_stack(stack)
			-- Test using, 100 / cycle
			for i=1,6 do player:do_use({x=0, y=0, z=0}) end
			assert.equals(100, technic.get_RE_charge(get_player_stack()))
			player:do_use({x=0, y=0, z=0})
			assert.equals(0, technic.get_RE_charge(get_player_stack()))
		end)

	end)

	describe("Flashlight", function()

		local itemname = "technic:flashlight"
		local itemdef = minetest.registered_items[itemname]

		setup(function()
			set_charge_stack(ItemStack())
			set_discharge_stack(ItemStack())
			mineunit:execute_on_joinplayer(player)
		end)

		teardown(function()
			mineunit:execute_on_leaveplayer(player)
		end)

		it("is registered", function()
			assert.is_hashed(itemdef)
			assert.is_function(itemdef.on_refill)
			assert.equals("technic_RE_charge", itemdef.wear_represents)
			assert.is_number(itemdef.technic_max_charge)
			assert.gt(itemdef.technic_max_charge, 0)
		end)

		it("charge is used", function()
			-- Get fully charged item
			local stack = ItemStack(itemname)
			technic.set_RE_charge(stack, itemdef.technic_max_charge)
			set_player_stack(stack)

			-- Use item, flashlight charge is used every globalstep and there's no on_use definition
			spy.on(technic, "use_RE_charge")
			for i=1, 100 do
				mineunit:execute_globalstep(1)
			end
			assert.spy(technic.use_RE_charge).called(100)

			-- Check that item charge was actually used and error is acceptable
			local charge_used = itemdef.technic_max_charge - technic.get_RE_charge(get_player_stack())
			local exact_use = 2 * 100 -- 2 per cycle / 100 cycles
			assert.lt(0.9, charge_used / exact_use)
			assert.gt(1.1, charge_used / exact_use)
		end)

	end)

	describe("Multimeter", function()

		local itemname = "technic:multimeter"
		local itemdef = minetest.registered_items[itemname]

		setup(function()
			set_charge_stack(ItemStack())
			set_discharge_stack(ItemStack())
			mineunit:execute_on_joinplayer(player)
			player:get_inventory():set_stack("main", 1, itemname)
		end)

		teardown(function()
			mineunit:execute_on_leaveplayer(player)
		end)

		it("is registered", function()
			assert.is_hashed(itemdef)
			assert.is_function(itemdef.on_use)
			assert.is_function(itemdef.on_refill)
			assert.equals("technic_RE_charge", itemdef.wear_represents)
			assert.is_number(itemdef.technic_max_charge)
			assert.gt(itemdef.technic_max_charge, 0)
		end)

		it("new item can be used", function()
			spy.on(itemdef, "on_use")
			player:do_use({x=0, y=0, z=0})
			assert.spy(itemdef.on_use).called(1)
		end)

		it("has zero charge", function()
			local stack = player:get_wielded_item()
			assert.is_ItemStack(stack)
			assert.is_false(stack:is_empty())
			assert.equals(0, technic.get_RE_charge(stack))
		end)

		it("can be charged", function()
			-- Put item from player inventory to battery box src inventory
			player:do_metadata_inventory_put(BB_Charge_POS, "src", 1)

			-- Verify that item charge is empty and charge in battery box for 30 seconds
			assert.equals(0, technic.get_RE_charge(get_charge_stack()))
			for i=0, 30 do
				mineunit:execute_globalstep(1)
			end

			-- Take item from battery box and check charge / wear values
			player:do_metadata_inventory_take(BB_Charge_POS, "src", 1)
			assert.gt(itemdef.technic_max_charge, 0)
			assert.equals(itemdef.technic_max_charge, technic.get_RE_charge(get_player_stack()))
		end)

		it("charge is used", function()
			spy.on(itemdef, "on_use")
			player:set_pos(vector.add(BB_Charge_POS, {x=0,y=1,z=0}))
			player:do_use(BB_Charge_POS)
			assert.spy(itemdef.on_use).called(1)

			-- Check that item charge was actually used and is not zero
			local charge = technic.get_RE_charge(get_player_stack())
			assert.is_number(charge)
			assert.gt(charge, 0)
			assert.lt(charge, itemdef.technic_max_charge)
		end)

	end)

	describe("technic_addons:chainsawmk3", function()

		-- Not running technic_addons:chainsawmk3 tests, this tools is just example of
		-- actually available mod where max_charge vs use ratio goes over safe limits.
		if not RUN_TECHNIC_ADDONS_CHAINSAWMK3_TESTS then return end

		local itemname = "technic_addons:chainsawmk3"
		local itemdef = minetest.registered_items[itemname]

		setup(function()
			world.add_layout({
				-- Some wood for chainsaw
				{{{x=-10,y=0,z=-10},{x=10,y=10,z=10}}, "default:wood"},
			})
			set_charge_stack(ItemStack())
			set_discharge_stack(ItemStack())
			mineunit:execute_on_joinplayer(player)
			set_player_stack(itemname)
		end)

		teardown(function()
			mineunit:execute_on_leaveplayer(player)
		end)

		it("is registered", function()
			assert.is_hashed(itemdef)
			assert.is_function(itemdef.on_use)
			assert.is_function(itemdef.on_refill)
			assert.equals("technic_RE_charge", itemdef.wear_represents)
			assert.is_number(itemdef.technic_max_charge)
			assert.gt(itemdef.technic_max_charge, 0)
		end)

		it("new item can be used", function()
			spy.on(itemdef, "on_use")
			player:do_use({x=0, y=0, z=0})
			assert.spy(itemdef.on_use).called(1)
		end)

		it("has zero charge", function()
			local stack = player:get_wielded_item()
			assert.is_ItemStack(stack)
			assert.is_false(stack:is_empty())
			assert.equals(0, technic.get_RE_charge(stack))
		end)

		it("can be charged", function()
			-- Put item from player inventory to battery box src inventory
			player:do_metadata_inventory_put(BB_Charge_POS, "src", 1)

			-- Verify that item charge is empty and charge in battery box for 30 seconds
			assert.equals(0, technic.get_RE_charge(get_charge_stack()))
			for i=0, math.ceil(itemdef.technic_max_charge / 10000) do
				mineunit:execute_globalstep(1)
			end

			-- Take item from battery box and check charge / wear values
			player:do_metadata_inventory_take(BB_Charge_POS, "src", 1)
			assert.gt(itemdef.technic_max_charge, 0)
			assert.equals(itemdef.technic_max_charge, technic.get_RE_charge(get_player_stack()))
		end)

		it("charge is used", function()
			spy.on(itemdef, "on_use")
			player:set_pos({x=0,y=1,z=0})
			player:do_use(player:get_pos())
			assert.spy(itemdef.on_use).called(1)

			-- Check that item charge was actually used and is not zero
			local charge_used = itemdef.technic_max_charge - technic.get_RE_charge(get_player_stack())
			local accurate_use = 21 * 21 * 11 * 10 -- Area times use per node
			local acceptable_error = accurate_use * 0.0001
			assert.gt(accurate_use + acceptable_error, charge_used)
			assert.lt(accurate_use - acceptable_error, charge_used)
			assert.equals(accurate_use, charge_used)
		end)

	end)

end)
