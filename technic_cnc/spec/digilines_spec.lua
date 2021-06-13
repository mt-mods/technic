require("mineunit")

mineunit("core")
mineunit("player")

describe("CNC API", function()

	fixture("default")
	fixture("basic_materials")
	fixture("digilines")

	sourcefile("init")

	-- Our player Sam will be helping, he promised to place some nodes
	local Sam = Player("Sam")

	-- Construct test world with CNC machines
	world.clear()
	local pos = {x=3,y=2,z=1}
	local node = {name = "technic:cnc_mk2", param2 = 0}
	world.place_node(pos, table.copy(node), Sam)
	minetest.get_meta(pos):set_string("channel", "ch1")

	local action = minetest.registered_nodes["technic:cnc_mk2"].digilines.effector.action
	local program = "stick"
	local size = 1

	it("handles invalid messages", function()
		-- This is meant to only check simple crashes
		action(pos, table.copy(node), "ch1", nil)
		action(pos, table.copy(node), "ch1", 0)
		action(pos, table.copy(node), "ch1", true)
		action(pos, table.copy(node), "ch1", false)
		action(pos, table.copy(node), "ch1", {})
		action(pos, table.copy(node), "ch1", "")
		action(pos, table.copy(node), "ch1", math.huge)
		action(pos, table.copy(node), "ch1", {size=true,program={}})
		action(pos, table.copy(node), "", nil)
		action(pos, table.copy(node), "", 0)
		action(pos, table.copy(node), "", true)
		action(pos, table.copy(node), "", false)
		action(pos, table.copy(node), "", {})
		action(pos, table.copy(node), "", "")
		action(pos, table.copy(node), "", math.huge)
		action(pos, table.copy(node), "", {size=true,program={}})
	end)

	it("sets program and size", function()
		action(pos, table.copy(node), "ch1", {
			program = "cylinder",
			size = 1
		})
		local meta = minetest.get_meta(pos)
		assert.equals("cylinder", meta:get("program"))
		assert.equals(1, meta:get_int("size"))
	end)

	it("disables machine", function()
		action(pos, table.copy(node), "ch1", "disable")
		local meta = minetest.get_meta(pos)
		assert.is_false(technic_cnc.is_enabled(meta))
	end)

	it("enables machine", function()
		action(pos, table.copy(node), "ch1", "enable")
		local meta = minetest.get_meta(pos)
		assert.is_true(technic_cnc.is_enabled(meta))
	end)

	it("returns programs", function()
		local count = #digilines._msg_log
		action(pos, table.copy(node), "ch1", "programs")
		assert.equals(count + 1, #digilines._msg_log)
		local response = digilines._msg_log[#digilines._msg_log]
		assert.is_table(response)
		assert.is_table(response.msg)
		assert.equals("ch1", response.channel)
		assert.not_nil(response.msg.sphere)
	end)

end)
