require("mineunit")

mineunit("core")
mineunit("player")

describe("CNC digiline API", function()

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

	it("sets size", function()
		action(pos, table.copy(node), "ch1", { size = 2 })
		local meta = minetest.get_meta(pos)
		assert.equals("cylinder", meta:get("program"))
		assert.equals(2, meta:get_int("size"))
	end)

	it("table disables machine", function()
		local meta = minetest.get_meta(pos)
		assert.is_true(technic_cnc.is_enabled(meta))
		action(pos, table.copy(node), "ch1", { enabled = false })
		assert.is_false(technic_cnc.is_enabled(meta))
	end)

	it("table enables machine", function()
		local meta = minetest.get_meta(pos)
		assert.is_false(technic_cnc.is_enabled(meta))
		action(pos, table.copy(node), "ch1", { enabled = true })
		assert.is_true(technic_cnc.is_enabled(meta))
	end)

	it("string disables machine", function()
		local meta = minetest.get_meta(pos)
		assert.is_true(technic_cnc.is_enabled(meta))
		action(pos, table.copy(node), "ch1", "disable")
		assert.is_false(technic_cnc.is_enabled(meta))
	end)

	it("string enables machine", function()
		local meta = minetest.get_meta(pos)
		assert.is_false(technic_cnc.is_enabled(meta))
		action(pos, table.copy(node), "ch1", "enable")
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

	it("returns status", function()
		local count = #digilines._msg_log
		action(pos, table.copy(node), "ch1", "status")
		assert.equals(count + 1, #digilines._msg_log)
		local response = digilines._msg_log[#digilines._msg_log]
		assert.is_table(response)
		assert.is_table(response.msg)
		assert.equals("ch1", response.channel)
		assert.is_boolean(response.msg.enabled)
		assert.is_number(response.msg.time)
		assert.is_number(response.msg.size)
		assert.is_string(response.msg.program)
		assert.is_string(response.msg.user)
		assert.is_table(response.msg.material)
	end)

end)
