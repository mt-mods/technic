require("mineunit")
--[[
	Technic tool regression tests.
	Execute mineunit at technic source directory.
--]]

-- Load complete technic mod
fixture("technic")
sourcefile("init")

describe("Technic power tool compatibility", function()

	fixture("old_powertool")

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
	local function set_discharge_stack(stack) discharge_inv:set_stack("dst", 1, stack) end
	local function get_discharge_stack() return discharge_inv:get_stack("dst", 1) end
	local function set_player_stack(stack) return player:get_inventory():set_stack("main", 1, stack) end
	local function get_player_stack() return player:get_inventory():get_stack("main", 1) end

	-- Execute on mods loaded callbacks to finish loading.
	mineunit:mods_loaded()
	-- Tell mods that 1 minute passed already to execute all weird minetest.after hacks.
	mineunit:execute_globalstep(60)

	local function test(itemname, callback)
		describe(itemname, function()

			local itemdef = minetest.registered_items[itemname]

			setup(function()
				mineunit:execute_on_joinplayer(player)
			end)

			teardown(function()
				mineunit:execute_on_leaveplayer(player)
			end)

			before_each(function()
				set_charge_stack(ItemStack())
				set_discharge_stack(ItemStack())
			end)

			it("is registered", function()
				assert.is_hashed(itemdef)
				assert.is_function(itemdef.on_use)
				assert.is_function(itemdef.on_refill)
				assert.equals("technic_RE_charge", itemdef.wear_represents)
				assert.is_number(itemdef.technic_max_charge)
				assert.gt(itemdef.technic_max_charge, 0)
			end)

			it("can be used (zero charge)", function()
				set_player_stack(itemname)
				spy.on(itemdef, "on_use")
				player:do_use(player:get_pos())
				assert.spy(itemdef.on_use).called(1)
			end)

			it("itemdef.technic_get_charge works (zero charge)", function()
				assert.equals(0, itemdef.technic_get_charge(ItemStack(itemname)))
			end)

			it("itemdef.technic_set_charge works (zero charge -> 123)", function()
				local stack = ItemStack(itemname)
				itemdef.technic_set_charge(stack, 123)
				assert.equals(123, itemdef.technic_get_charge(stack))
			end)

			it("can be used (minimum charge)", function()
				-- Add partially charged tool to player inventory
				local stack = ItemStack(itemname)
				itemdef.technic_set_charge(stack, 1000)
				set_player_stack(stack)
				spy.on(itemdef, "on_use")
				-- Use tool twice
				player:do_use(player:get_pos())
				player:do_use(player:get_pos())
				-- and verify results
				assert.spy(itemdef.on_use).called(2)
				assert.equals(0, itemdef.technic_get_charge(get_player_stack()))
			end)

			it("can be used (minimum charge + 1)", function()
				-- Add partially charged tool to player inventory
				local stack = ItemStack(itemname)
				itemdef.technic_set_charge(stack, 1001)
				set_player_stack(stack)
				spy.on(itemdef, "on_use")
				-- Use tool twice
				player:do_use(player:get_pos())
				player:do_use(player:get_pos())
				-- and verify results
				assert.spy(itemdef.on_use).called(2)
				assert.equals(1, itemdef.technic_get_charge(get_player_stack()))
			end)

			it("can be charged", function()
				-- Stack without charge to battery box charge slot
				local stack = ItemStack(itemname)
				itemdef.technic_set_charge(stack, 0)
				assert.equals(0, stack:get_wear())
				set_charge_stack(stack)

				-- Verify that item charge is empty and charge in battery box for 8 seconds
				assert.equals(0, itemdef.technic_get_charge(get_charge_stack()))
				for i=1, 8 do
					mineunit:execute_globalstep(1)
				end

				-- Check charge / wear values
				assert.equals(itemdef.technic_max_charge, itemdef.technic_get_charge(get_charge_stack()))
				assert.equals(1, get_charge_stack():get_wear())
			end)

			it("can be discharged", function()
				-- Fully charged stack to battery box discharge slot
				local stack = ItemStack(itemname)
				itemdef.technic_set_charge(stack, itemdef.technic_max_charge)
				assert.equals(1, stack:get_wear())
				set_discharge_stack(stack)

				-- Verify that item is fully charged and discharge in battery box for 2 seconds
				assert.equals(itemdef.technic_max_charge, itemdef.technic_get_charge(get_discharge_stack()))
				for i=1, 2 do
					mineunit:execute_globalstep(1)
				end

				-- Take item from battery box and check charge / wear values
				assert.equals(0, itemdef.technic_get_charge(get_discharge_stack()))
				assert.equals(0, get_discharge_stack():get_wear())
			end)

			if callback then callback() end

		end)

	end

	-- Register test set for tools using different registration and compatibility methods
	test("oldlegacy:powertool")
	test("oldminimal:powertool")
	test("oldhalfway:powertool")

end)
