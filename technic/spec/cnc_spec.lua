require("mineunit")
--[[
	Technic network unit tests.
	Execute mineunit at technic source directory.
--]]

-- Load complete technic mod
fixture("technic")

describe("Technic CNC", function()

	fixture("technic_cnc")

	local player = Player("SX")

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

	-- Execute on mods loaded callbacks to finish loading.
	mineunit:mods_loaded()
	-- Tell mods that 1 minute passed already to execute all weird minetest.after hacks.
	mineunit:execute_globalstep(60)

	local cnc_pos = {x=0,y=1,z=0}
	local program = next(technic_cnc.products)
	local product_count = technic_cnc.products[program]

	describe("technic:cnc", function()

		setup(function()
			world.clear()
			for x = 0, 4 do
				world.place_node({x=x,y=0,z=0}, "technic:lv_cable", player)
			end
			world.place_node(cnc_pos, "technic:cnc", player)
			world.place_node({x=1,y=1,z=0}, "technic:lv_solar_array", player)
			world.place_node({x=2,y=1,z=0}, "technic:lv_solar_array", player)
			world.place_node({x=3,y=1,z=0}, "technic:lv_solar_array", player)
			world.place_node({x=4,y=1,z=0}, "technic:switching_station", player)
		end)

		it("produces items", function()
			local id = technic.pos2network(cnc_pos)
			local net = technic.networks[id]
			assert.not_nil(net)

			-- Fill input inventory and select program
			local on_receive_fields = minetest.registered_nodes["technic:cnc"].on_receive_fields
			assert.equals("function", type(on_receive_fields))
			place_itemstack(cnc_pos, "default:wood 99")
			on_receive_fields(cnc_pos, nil, {[program] = true}, player)

			-- Run network and check results
			run_network(10)
			local products = get_itemstack(cnc_pos)
			assert.is_ItemStack(products)
			assert.gt(products:get_count(), product_count)
		end)

		it("uses energy", function()
			place_itemstack(cnc_pos, "default:wood 99")
			local id = technic.pos2network(cnc_pos)
			local net = technic.networks[id]
			assert.not_nil(net)

			-- Run network and check results
			run_network()
			assert.equal(net.demand, 450)
		end)

	end)

	describe("technic:cnc_mk2", function()

		setup(function()
			world.clear()
			for x = 0, 7 do
				world.place_node({x=x,y=0,z=0}, "technic:lv_cable", player)
			end
			world.place_node(cnc_pos, "technic:cnc_mk2", player)
			world.place_node({x=1,y=1,z=0}, "technic:lv_solar_array", player)
			world.place_node({x=2,y=1,z=0}, "technic:lv_solar_array", player)
			world.place_node({x=3,y=1,z=0}, "technic:lv_solar_array", player)
			world.place_node({x=4,y=1,z=0}, "technic:lv_solar_array", player)
			world.place_node({x=5,y=1,z=0}, "technic:lv_solar_array", player)
			world.place_node({x=6,y=1,z=0}, "technic:lv_solar_array", player)
			world.place_node({x=7,y=1,z=0}, "technic:switching_station", player)
		end)

		it("produces items", function()
			local id = technic.pos2network(cnc_pos)
			local net = technic.networks[id]
			assert.not_nil(net)

			-- Fill input inventory and select program
			local on_receive_fields = minetest.registered_nodes["technic:cnc_mk2"].on_receive_fields
			assert.equals("function", type(on_receive_fields))
			place_itemstack(cnc_pos, "default:wood 99")
			on_receive_fields(cnc_pos, nil, {[program] = true}, player)

			-- Run network and check results
			run_network(10)
			local products = get_itemstack(cnc_pos)
			assert.is_ItemStack(products)
			assert.gt(products:get_count(), product_count)
		end)

		it("uses energy", function()
			place_itemstack(cnc_pos, "default:wood 99")
			local id = technic.pos2network(cnc_pos)
			local net = technic.networks[id]
			assert.not_nil(net)

			-- Run network and check results
			run_network()
			assert.equal(net.demand, 900)
		end)

	end)

end)
