require("mineunit")
--[[
	Technic tool regression tests.
	Execute mineunit at technic source directory.
--]]

-- Load complete technic mod
fixture("technic")

describe("Technic power tool", function()

	world.set_default_node("air")

	-- HV battery box and some HV solar arrays for charging
	local BB_POS = {x=0,y=51,z=0}
	world.layout({
		{BB_POS, "technic:hv_battery_box0"},
		{{x=1,y=51,z=0}, "technic:switching_station"},
		{{{x=2,y=51,z=0},{x=10,y=51,z=0}}, "technic:solar_array_hv"},
		{{{x=0,y=50,z=0},{x=10,y=50,z=0}}, "technic:hv_cable"},
	})

	local player = Player("SX")

	-- Execute on mods loaded callbacks to finish loading.
	mineunit:mods_loaded()
	-- Tell mods that 1 minute passed already to execute all weird minetest.after hacks.
	mineunit:execute_globalstep(60)

	describe("API", function()

		setup(function()
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
			assert.is_number(itemdef.max_charge)
			assert.gt(itemdef.max_charge, 0)
		end)

		it("technic.use_RE_charge works (zero charge)", function()
			player:get_inventory():set_stack("main", 1, "mymod:powertool")
			spy.on(technic, "use_RE_charge")
			player:do_use(player:get_pos())
			assert.spy(technic.use_RE_charge).called(1)
			assert.equals("boolean", type(use_RE_charge_result))
			assert.is_false(use_RE_charge_result)
		end)

		it("technic.get_RE_charge works (zero charge)", function()
			local stack = player:get_wielded_item()
			assert.equals(0, technic.get_RE_charge(stack))
		end)

		it("technic.set_RE_charge works (zero charge -> 123)", function()
			local stack = player:get_wielded_item()
			technic.set_RE_charge(stack, 123)
			assert.equals(123, technic.get_RE_charge(stack))
		end)

		it("technic.use_RE_charge works (minimum charge)", function()
			-- Add partially charged tool to player inventory
			local stack = ItemStack("mymod:powertool")
			technic.set_RE_charge(stack, 123)
			player:get_inventory():set_stack("main", 1, stack)
			assert.equals(123, technic.get_RE_charge(player:get_wielded_item()))

			-- Use tool and verify results
			spy.on(technic, "use_RE_charge")
			player:do_use(player:get_pos())
			assert.spy(technic.use_RE_charge).called(1)
			assert.equals("boolean", type(use_RE_charge_result))
			assert.is_true(use_RE_charge_result)
			assert.equals(0, technic.get_RE_charge(player:get_wielded_item()))
		end)

	end)

	describe("Multimeter", function()

		setup(function()
			mineunit:execute_on_joinplayer(player)
			player:get_inventory():set_stack("main", 1, "technic:multimeter")
		end)

		teardown(function()
			mineunit:execute_on_leaveplayer(player)
		end)

		local itemdef = minetest.registered_items["technic:multimeter"]

		it("is registered", function()
			assert.is_hashed(itemdef)
			assert.is_function(itemdef.on_use)
			assert.is_function(itemdef.on_refill)
			assert.equals("technic_RE_charge", itemdef.wear_represents)
			assert.is_number(itemdef.max_charge)
			assert.gt(itemdef.max_charge, 0)
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
			player:do_metadata_inventory_put(BB_POS, "src", 1)

			-- Verify that item charge is empty and charge in battery box for 30 seconds
			local stack = minetest.get_meta(BB_POS):get_inventory():get_stack("src", 1)
			assert.equals(0, technic.get_RE_charge(stack))
			for i=0, 30 do
				mineunit:execute_globalstep(1)
			end

			-- Take item from battery box and check charge / wear values
			player:do_metadata_inventory_take(BB_POS, "src", 1)
			stack = player:get_inventory():get_stack("main", 1)

			assert.gt(itemdef.max_charge, 0)
			assert.equals(itemdef.max_charge, technic.get_RE_charge(stack))
		end)

		it("charge is used", function()
			spy.on(itemdef, "on_use")
			player:set_pos(vector.add(BB_POS, {x=0,y=1,z=0}))
			player:do_use(BB_POS)
			assert.spy(itemdef.on_use).called(1)

			-- Check that item charge was actually used and is not zero
			local charge = technic.get_RE_charge(player:get_inventory():get_stack("main", 1))
			assert.is_number(charge)
			assert.gt(charge, 0)
			assert.lt(charge, itemdef.max_charge)
		end)

	end)

end)
