require("mineunit")
--[[
	Technic network unit tests.
	Execute busted at technic source directory.
--]]

-- Load fixtures required by tests
mineunit("core")
mineunit("player")
mineunit("protection")
mineunit("common/after")
mineunit("server")
mineunit("voxelmanip")

fixture("pipeworks")
fixture("network")
fixture("default")
fixture("technic_worldgen")

-- Screwdriver is listed as optional but mod crashes without it
_G.screwdriver = {}

sourcefile("helpers")
sourcefile("machines/init")
--sourcefile("machines/switching_station")

describe("LV machine network", function()

	sourcefile("max_lag")

	-- Execute on mods loaded callbacks to finish loading.
	mineunit:mods_loaded()
	-- Tell mods that 1 minute passed already to execute all weird minetest.after hacks.
	mineunit:execute_globalstep(60)

	local machines = {
		"technic:lv_generator",
		"technic:geothermal",
		"technic:solar_panel",
		"technic:solar_array_lv",
		"technic:solar_array_lv",
		"technic:solar_array_lv",
		"technic:lv_battery_box0",
		"technic:lv_electric_furnace",
		"technic:lv_extractor",
		"technic:lv_grinder",
		"technic:lv_alloy_furnace",
		"technic:lv_compressor",
	}

	world.clear()
	world.place_node({x=100,y=1,z=0}, {name="technic:switching_station"})
	for x = 1, 100 do
		world.place_node({x=x,y=0,z=0}, {name="technic:lv_cable"})
	end
	for x, name in ipairs(machines) do
		world.place_node({x=x,y=1,z=0}, {name=name})
	end

	it("executes network", function()
		local function place_itemstack(pos, itemstack)
			local meta = minetest.get_meta(pos)
			local inv = meta:get_inventory()
			inv:add_item("src", itemstack)
		end
		place_itemstack({x=8,y=1,z=0}, "technic:lead_lump 99")

		spy.on(technic, "network_run")
		for i=1, 60 do
			-- Globalstep every second instead of every 0.1 seconds
			mineunit:execute_globalstep(1)
		end
		assert.spy(technic.network_run).called(60)
	end)

	it("charges battery box", function()
		local id = technic.pos2network({x=100,y=0,z=0})
		local net = technic.networks[id]
		assert.gt(net.battery_charge, 1000)
	end)

	it("smelts ores", function()
		local meta = minetest.get_meta({x=8,y=1,z=0})
		local inv = meta:get_inventory()
		local stack = inv:get_stack("dst", 1)
		assert.is_true(stack:get_count() > 10)
	end)

	it("grinds ores", function()
		local id = technic.pos2network({x=100,y=0,z=0})
		local net = technic.networks[id]
		assert.gt(net.battery_charge, 1000)
	end)

end)
