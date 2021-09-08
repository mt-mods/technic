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

	local player = Player("SX")

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
		"technic:lv_led",
		"technic:lv_lamp",
		"technic:water_mill",
	}

	world.clear()
	world.place_node({x=100,y=1,z=0}, "technic:switching_station", player)
	for x = 1, 100 do
		world.place_node({x=x,y=0,z=0}, "technic:lv_cable", player)
	end
	for x, name in ipairs(machines) do
		world.place_node({x=x,y=1,z=0}, name, player)
	end

	-- Helper to destroy nodes in test world returning list of removed nodes indexed by coordinates
	local function remove_nodes(nodes)
		local removed = {}
		for x = 1, 100 do
			local pos = {x=x,y=1,z=0}
			local node = minetest.get_node(pos)
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
		world.remove_node({x=100,y=1,z=0})
		run_network()
		-- Network should be gone
		assert.is_nil(technic.networks[id])
		-- Build new switching station to restore network
		world.place_node({x=100,y=1,z=0}, {name="technic:switching_station"})
		run_network()
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
		local machine_pos = {x=10,y=1,z=0}
		place_itemstack(machine_pos, "technic:lead_lump 99")
		run_network(60)
		-- Check results, at least 10 items processed and results in correct stuff
		local stack = get_itemstack(machine_pos)
		assert.gt(stack:get_count(), 10)
		assert.equals(stack:get_name(), "technic:lead_dust")
	end)

	it("comperess sand", function()
		local machine_pos = {x=12,y=1,z=0}
		place_itemstack(machine_pos, "default:sand 99")
		run_network(60)
		-- Check results, at least 10 items processed and results in correct stuff
		local stack = get_itemstack(machine_pos)
		assert.gt(stack:get_count(), 10)
		assert.equals(stack:get_name(), "default:sandstone")
	end)

	it("cuts power when generators disappear", function()
		place_itemstack({x=8,y=1,z=0}, "technic:lead_lump 99")
		place_itemstack({x=10,y=1,z=0}, "technic:lead_lump 99")
		place_itemstack({x=12,y=1,z=0}, "default:sand 99")
		local id = technic.pos2network({x=100,y=0,z=0})
		assert.not_nil(technic.networks[id])

		-- Remove generators and run network 60 times
		local generators = {
			["technic:solar_panel"] = 1,
			["technic:solar_array_lv"] = 1,
		}
		local restore = remove_nodes(generators)

		-- Verify that network power is down immediately
		local net = technic.networks[id]
		run_network(1)
		assert.equal(net.supply, 0)

		-- Get current battery charge for network and execute few more cycles
		local battery_charge = net.battery_charge
		assert.gt(net.battery_charge, 1000)
		run_network(60)

		-- Verify that significant battery charge was used and network still does not generate energy
		assert.lt(net.battery_charge, battery_charge / 2)
		assert.equal(net.supply, 0)

		-- Restore generators to network and run network once
		restore_nodes(restore)
		run_network()
	end)

end)
