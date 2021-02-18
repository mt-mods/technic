dofile("spec/mineunit/init.lua")
--[[
	Technic network unit tests.
	Execute busted at technic source directory.
--]]

-- Load fixtures required by tests
mineunit("core")
mineunit("player")
mineunit("protection")

fixture("pipeworks")
fixture("network")

sourcefile("machines/network")

sourcefile("machines/register/cables")
sourcefile("machines/LV/cables")
sourcefile("machines/MV/cables")
sourcefile("machines/HV/cables")

sourcefile("machines/register/generator")
sourcefile("machines/HV/generator")

world.layout({
	{{x=100,y=100,z=100}, "technic:lv_cable"},
	{{x=101,y=100,z=100}, "technic:lv_cable"},
	{{x=102,y=100,z=100}, "technic:lv_cable"},
	{{x=103,y=100,z=100}, "technic:lv_cable"},
	{{x=104,y=100,z=100}, "technic:lv_cable"},
	{{x=100,y=101,z=100}, "technic:switching_station"},

	{{x=100,y=200,z=100}, "technic:mv_cable"},
	{{x=101,y=200,z=100}, "technic:mv_cable"},
	{{x=102,y=200,z=100}, "technic:mv_cable"},
	{{x=103,y=200,z=100}, "technic:mv_cable"},
	{{x=104,y=200,z=100}, "technic:mv_cable"},
	{{x=100,y=201,z=100}, "technic:switching_station"},

	{{x=100,y=300,z=100}, "technic:hv_cable"},
	{{x=101,y=300,z=100}, "technic:hv_cable"},
	{{x=102,y=300,z=100}, "technic:hv_cable"},
	{{x=103,y=300,z=100}, "technic:hv_cable"},
	{{x=104,y=300,z=100}, "technic:hv_cable"},
	{{x=100,y=301,z=100}, "technic:switching_station"},

	-- For network lookup function -> returns correct network for position
	{{x=100,y=500,z=100}, "technic:hv_cable"},
	{{x=101,y=500,z=100}, "technic:hv_cable"},
	{{x=102,y=500,z=100}, "technic:hv_cable"},
	{{x=103,y=500,z=100}, "technic:hv_cable"},
	{{x=104,y=500,z=100}, "technic:hv_cable"},
	{{x=100,y=501,z=100}, "technic:hv_generator"},
	{{x=101,y=501,z=100}, "technic:hv_cable"},
	{{x=102,y=501,z=100}, "technic:switching_station"},
	{{x=100,y=502,z=100}, "technic:hv_cable"},
	{{x=101,y=502,z=100}, "technic:hv_cable"},
})

describe("Power network helper", function()

	-- Simple network position fixtures
	local net_id = 65536
	local pos    = { x = -32768, y = -32767, z = -32768 }
	local sw_pos = { x = -32768, y = -32766, z = -32768 }

	describe("network lookup functions", function()

		it("does not fail if network missing", function()
			assert.is_nil( technic.remove_network(9999) )
		end)

		it("returns correct position for network", function()
			assert.same(pos,    technic.network2pos(net_id) )
			assert.same(sw_pos, technic.network2sw_pos(net_id) )
		end)

		it("returns correct network for position", function()
			local net_id = technic.create_network({x=100,y=501,z=100})
			assert.same(net_id, technic.pos2network({x=100,y=500,z=100}) )
			assert.same(net_id, technic.sw_pos2network({x=100,y=501,z=100}) )
		end)

		it("returns nil tier for empty position", function()
			assert.is_nil(technic.sw_pos2tier({x=9999,y=9999,z=9999}))
		end)

		it("returns correct tier for switching station position", function()
			-- World is defined in fixtures/network.lua
			assert.same("LV", technic.sw_pos2tier({x=100,y=101,z=100}))
			assert.same("MV", technic.sw_pos2tier({x=100,y=201,z=100}))
			assert.same("HV", technic.sw_pos2tier({x=100,y=301,z=100}))
		end)

	end)

	describe("network constructors/destructors", function()

		-- Build network
		local net_id = technic.create_network({x=100,y=501,z=100})
		assert.is_number(net_id)

		it("creates network", function()
			assert.is_hashed(technic.networks[net_id])
		end)

		it("builds network", function()
			local net = technic.networks[net_id]
			-- Network table is valid
			assert.is_indexed(net.PR_nodes)
			assert.is_indexed(net.RE_nodes)
			assert.is_indexed(net.BA_nodes)
			assert.equals(9, count(net.all_nodes))
			assert.is_hashed(net.all_nodes)
		end)

		it("does not add duplicates to network", function()
			local net = technic.networks[net_id]
			-- Local network table is still valid
			assert.equals(1, count(net.PR_nodes))
			assert.equals(0, count(net.RE_nodes))
			assert.equals(0, count(net.BA_nodes))
			assert.equals(9, count(net.all_nodes))
			-- FIXME: This might be wrong if technic.cables should contain only cables and not machines
			assert.equals(9, count(technic.cables))
		end)

		it("removes network", function()
			technic.remove_network(net_id)
			assert.is_nil(technic.networks[net_id])
			-- TODO: Verify that there's no lefover positions in technic.cables
		end)

	end)

	--[[ TODO:
	technic.remove_network_node
	--]]

	describe("Power network timeout functions technic.touch_node and technic.get_timeout", function()

		it("returns zero if no data available", function()
			assert.equals(0,
				technic.get_timeout("LV", {x=9999,y=9999,z=9999})
			)
			assert.equals(0,
				technic.get_timeout("HV", {x=9999,y=9999,z=9999})
			)
		end)

		it("returns timeout if data is available", function()
			technic.touch_node("LV", {x=123,y=123,z=123}, 42)
			assert.equals(42,
				technic.get_timeout("LV", {x=123,y=123,z=123})
			)
			technic.touch_node("HV", {x=123,y=123,z=123}, 74)
			assert.equals(74,
				technic.get_timeout("HV", {x=123,y=123,z=123})
			)
		end)

	end)

end)

describe("technic.merge_networks", function()

	describe("function behavior", function()

		world.layout({
			{{x=100,y=110,z=170}, "technic:hv_cable"},
			{{x=101,y=110,z=170}, "technic:hv_cable"},
			{{x=102,y=110,z=170}, "technic:hv_cable"},
			{{x=103,y=110,z=170}, "technic:hv_cable"},
			{{x=104,y=110,z=170}, "technic:hv_cable"},
			{{x=100,y=111,z=170}, "technic:switching_station"},
			{{x=101,y=111,z=170}, "technic:hv_generator"},
			{{x=102,y=111,z=170}, "technic:hv_generator"},

			{{x=100,y=120,z=180}, "technic:hv_cable"},
			{{x=101,y=120,z=180}, "technic:hv_cable"},
			{{x=102,y=120,z=180}, "technic:hv_cable"},
			{{x=103,y=120,z=180}, "technic:hv_cable"},
			{{x=104,y=120,z=180}, "technic:hv_cable"},
			{{x=100,y=121,z=180}, "technic:switching_station"},
			{{x=101,y=121,z=180}, "technic:hv_generator"},
			{{x=102,y=121,z=180}, "technic:hv_generator"},

			{{x=110,y=130,z=190}, "technic:hv_cable"},
			{{x=111,y=130,z=190}, "technic:hv_cable"},
			{{x=112,y=130,z=190}, "technic:hv_cable"},
			{{x=113,y=130,z=190}, "technic:hv_cable"},
			{{x=114,y=130,z=190}, "technic:hv_cable"},
			{{x=110,y=131,z=190}, "technic:switching_station"},
			{{x=111,y=131,z=190}, "technic:hv_generator"},
			{{x=112,y=131,z=190}, "technic:hv_generator"},
		})

		local net1_id = technic.create_network({x=100,y=111,z=170})
		local net2_id = technic.create_network({x=100,y=121,z=180})
		local net3_id = technic.create_network({x=110,y=131,z=190})
		assert.is_number(net1_id)
		assert.is_number(net2_id)
		assert.is_number(net3_id)
		local net1 = technic.networks[net1_id]
		local net2 = technic.networks[net2_id]
		local net3 = technic.networks[net3_id]
		assert.is_table(net1)
		assert.is_table(net2)
		assert.is_table(net3)

		it("merges networks", function()
			-- Verify generated data before starting
			assert.equals(2, #net1.PR_nodes)
			assert.equals(7, count(net1.all_nodes))
			assert.equals(2, #net2.PR_nodes)
			assert.equals(7, count(net2.all_nodes))
			-- Merge networks
			technic.merge_networks(net1, net2)
			-- Either one of merged networks disappeared
			assert.is_nil(technic.networks[net1_id] and technic.networks[net2_id])
			assert.is_table(technic.networks[net1_id] or technic.networks[net2_id])
			-- Merged network exists
			assert.is_table(technic.networks[net1_id])
			-- Nodes have been moved to other network
			assert.equals(4, #net1.PR_nodes)
			assert.equals(14, count(net1.all_nodes))
		end)

		it("merges networks again", function()
			local merged_net_id = technic.sw_pos2network({x=100,y=111,z=170})
			local merged_net = technic.networks[merged_net_id]
			-- Verify generated data before starting
			assert.equals(2, #net3.PR_nodes)
			assert.equals(7, count(net3.all_nodes))
			assert.equals(4, #merged_net.PR_nodes)
			assert.equals(14, count(merged_net.all_nodes))
			-- Merge networks
			technic.merge_networks(merged_net, net3)
			-- Either one of merged networks disappeared
			assert.is_nil(technic.networks[merged_net_id] and technic.networks[net3_id])
			assert.is_table(technic.networks[merged_net_id] or technic.networks[net3_id])
			-- Merged network exists
			assert.is_table(technic.networks[merged_net_id])
			-- Nodes have been moved to other network
			assert.equals(6, #merged_net.PR_nodes)
			assert.equals(21, count(merged_net.all_nodes))
		end)

	end)

	describe("network building behavior", function()

		-- Hijack `minetest.get_us_time` for this test set.
		-- insulate(...) does not seem to work here and finally(...) can apparently
		-- only be used inside it(...) so we go with strict_setup/strict_teardown.

		local old_minetest_get_us_time = _G.minetest.get_us_time
		strict_setup(function()
			local fake_us_time = 0
			local fake_us_time_increment = 1000 * 1000 * 10 -- 10 seconds
			_G.minetest.get_us_time = function()
				fake_us_time = fake_us_time + fake_us_time_increment
				return fake_us_time
			end
		end)

		strict_teardown(function()
			_G.minetest.get_us_time = old_minetest_get_us_time
		end)

		local layout = {
			{{x=180,y=10,z=190}, "technic:hv_cable"},
			{{x=181,y=10,z=190}, "technic:hv_cable"},
			{{x=182,y=10,z=190}, "technic:hv_cable"},
			{{x=180,y=11,z=190}, "technic:switching_station"},
			{{x=181,y=11,z=190}, "technic:hv_generator"},
			{{x=182,y=11,z=190}, "technic:hv_generator"},
		}
		world.clear()
		world.add_layout(layout)
		world.add_layout(layout, {x=3,y=0,z=0})
		world.add_layout(layout, {x=6,y=0,z=0})

		local net1_id
		local net2_id

		it("stops network building after first iteration", function()
			net1_id = technic.create_network({x=180,y=11,z=190})
			assert.is_number(net1_id)
			local net1 = technic.networks[net1_id]
			assert.is_table(net1)

			-- Only first iteration passed, 2 cables (initial + iteration) added
			assert.equals(0, #net1.PR_nodes)
			assert.equals(2, count(net1.all_nodes))
			-- And queue contains next cable
			assert.is_table(net1.queue)
			assert.equals(1, #net1.queue)
			assert.same({x=181,y=10,z=190}, net1.queue[1])
		end)

		it("continues network building", function()
			technic.build_network(net1_id)
			local net1 = technic.networks[net1_id]
			assert.is_table(net1)

			-- Only first iteration passed, nodes around queue added: 1 cable and 1 generator
			assert.equals(1, #net1.PR_nodes)
			assert.equals(4, count(net1.all_nodes))
			-- And queue contains next cable
			assert.is_table(net1.queue)
			assert.equals(1, #net1.queue)
			assert.same({x=182,y=10,z=190}, net1.queue[1])
		end)

		it("merges with second network", function()
			-- Execute 2 build iterations
			net2_id = technic.create_network({x=183,y=11,z=190})
			technic.build_network(net2_id)
			assert.is_number(net2_id)

			-- Networks merged
			local net1 = technic.networks[net1_id]
			assert.is_nil(net1)
			local net2 = technic.networks[net2_id]
			assert.is_table(net2)

			-- Check that ned count is higher than last net1 node count
			assert.is_true(#net2.PR_nodes > 1)
			assert.is_true(count(net2.all_nodes) > 4)

			-- No duplicates added
			for k1,v1 in pairs(net2.PR_nodes) do for k2,v2 in pairs(net2.PR_nodes) do
				assert.is_true(k1 == k2 or v1.x ~= v2.x or v1.y ~= v2.y or v1.z ~= v2.z)
			end end
		end)

		it("finishes network build", function()
			local net3_id = technic.create_network({x=186,y=11,z=190})
			technic.build_network(net3_id)
			technic.build_network(net3_id)

			-- Networks merged
			local net1 = technic.networks[net1_id]
			assert.is_nil(net1)
			local net2 = technic.networks[net2_id]
			assert.is_nil(net2)
			local net3 = technic.networks[net3_id]
			assert.is_table(net3)

			-- Check that network build is completed and all nodes added to network
			assert.equals(6, #net3.PR_nodes)
			assert.equals(15, count(net3.all_nodes))

			-- No duplicates added
			for k1,v1 in pairs(net3.PR_nodes) do for k2,v2 in pairs(net3.PR_nodes) do
				assert.is_true(k1 == k2 or v1.x ~= v2.x or v1.y ~= v2.y or v1.z ~= v2.z)
			end end
		end)

	end)

end)
