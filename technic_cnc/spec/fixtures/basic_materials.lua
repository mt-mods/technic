mineunit:set_modpath("basic_materials", "spec/fixtures")

minetest.register_node(":basic_materials:concrete_block", {
	description = "Mineunit concrete_block",
	tiles = { "basic_materials_concrete_block.png" },
	is_ground_content = true,
	groups = {cracky=3},
	sounds = default.node_sound_stone_defaults(),
	drop = "basic_materials:concrete_block",
})
