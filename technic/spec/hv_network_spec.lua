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

sourcefile("init")

describe("HV machine network", function()

	local player = Player("SX")

	-- Execute on mods loaded callbacks to finish loading.
	mineunit:mods_loaded()
	-- Tell mods that 1 minute passed already to execute all weird minetest.after hacks.
	mineunit:execute_globalstep(60)

	local machines = {
		"technic:hv_generator",
		"technic:solar_array_hv",
		"technic:solar_array_hv",
		"technic:solar_array_hv",
		"technic:solar_array_hv",
		"technic:solar_array_hv",
		"technic:hv_battery_box0",
		"technic:hv_electric_furnace",
		"technic:hv_grinder",
		"technic:hv_compressor",
		"technic:hv_nuclear_reactor_core",
		"technic:quarry",
	}

	world.clear()
	world.place_node({x=100,y=1,z=0}, "technic:switching_station", player)
	for x = 1, 100 do
		world.place_node({x=x,y=0,z=0}, "technic:hv_cable", player)
	end
	for x, name in ipairs(machines) do
		world.place_node({x=x,y=1,z=0}, name, player)
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

	it("kills network when switching station disappear", function()
		local id = technic.pos2network({x=100,y=0,z=0})
		assert.not_nil(technic.networks[id])
		-- Remove switching station and execute globalstep
		world.set_node({x=100,y=1,z=0}, {name="air"})
		mineunit:execute_globalstep(1)
		-- Network should be gone
		assert.is_nil(technic.networks[id])
		-- Build new switching station to restore network
		world.place_node({x=100,y=1,z=0}, {name="technic:switching_station"})
		mineunit:execute_globalstep(1)
		assert.not_nil(technic.networks[id])
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
