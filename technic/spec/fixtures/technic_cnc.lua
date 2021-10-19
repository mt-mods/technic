
-- Load technic_cnc mod

minetest.register_node(":default:wood", {
	description = "Wood",
	tiles = { "default_wood.png" },
	groups = {snappy=2, choppy=2, oddly_breakable_by_hand=2},
})

mineunit:set_modpath("technic_cnc", "../technic_cnc")

mineunit:set_current_modname("technic_cnc")
sourcefile("../technic_cnc/init")
mineunit:restore_current_modname()
