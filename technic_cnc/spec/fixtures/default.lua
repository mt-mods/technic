
minetest.register_node(":default:stone", {
	description = "Mineunit stone",
	tiles = { "default_stone.png" },
	is_ground_content = true,
	groups = {cracky=3},
	sounds = default.node_sound_stone_defaults(),
	drop = "default:cobble",
})
