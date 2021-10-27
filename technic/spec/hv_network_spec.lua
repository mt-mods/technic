require("mineunit")
--[[
	Technic network unit tests.
	Execute mineunit at technic source directory.
--]]

-- Load complete technic mod
fixture("technic")

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

	-- Helper function to execute netowork
	local function run_network(times)
		times = times or 1
		for i=1, times do
			-- Globalstep every second instead of every 0.1 seconds
			mineunit:execute_globalstep(1)
		end
	end

	-- Helper function to place itemstack into machine inventory
	local function place_itemstack(pos, itemstack, listname)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		if not inv:room_for_item(listname or "src", itemstack) then
			inv:set_stack(listname or "src", 1, ItemStack())
		end
		inv:add_item(listname or "src", itemstack)
	end

	-- Get itemstack in inventory for inspection without removing it
	local function get_itemstack(pos, listname, index)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		return inv:get_stack(listname or "dst", index or 1)
	end

	it("executes network", function()
		spy.on(technic, "network_run")
		run_network(60)
		assert.spy(technic.network_run).called(60)
		local id = technic.pos2network({x=100,y=0,z=0})
		assert.not_nil(technic.networks[id])
		assert.gt(technic.networks[id].supply, 0)
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
		local machine_pos = {x=8,y=1,z=0}
		place_itemstack(machine_pos, "technic:lead_lump 99")
		run_network(60)
		-- Check results, at least 10 items processed and results in correct stuff
		local stack = get_itemstack(machine_pos)
		assert.gt(stack:get_count(), 10)
		assert.equals(stack:get_name(), "technic:lead_ingot")
	end)

	it("grinds ores", function()
		local machine_pos = {x=9,y=1,z=0}
		place_itemstack(machine_pos, "technic:lead_lump 99")
		run_network(60)
		-- Check results, at least 10 items processed and results in correct stuff
		local stack = get_itemstack(machine_pos)
		assert.gt(stack:get_count(), 10)
		assert.equals(stack:get_name(), "technic:lead_dust")
	end)

end)
