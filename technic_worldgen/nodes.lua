
local S = minetest.get_translator("technic_worldgen")

minetest.register_node(":technic:mineral_uranium", {
	description = S("Uranium Ore"),
	tiles = {"default_stone.png^technic_mineral_uranium.png"},
	is_ground_content = true,
	groups = {cracky=3, radioactive=1},
	sounds = default.node_sound_stone_defaults(),
	drop = "technic:uranium_lump",
})

minetest.register_node(":technic:mineral_chromium", {
	description = S("Chromium Ore"),
	tiles = {"default_stone.png^technic_mineral_chromium.png"},
	is_ground_content = true,
	groups = {cracky=3},
	sounds = default.node_sound_stone_defaults(),
	drop = "technic:chromium_lump",
})

minetest.register_node(":technic:mineral_zinc", {
	description = S("Zinc Ore"),
	tiles = {"default_stone.png^technic_mineral_zinc.png"},
	is_ground_content = true,
	groups = {cracky=3},
	sounds = default.node_sound_stone_defaults(),
	drop = "technic:zinc_lump",
})

minetest.register_node(":technic:mineral_lead", {
	description = S("Lead Ore"),
	tiles = {"default_stone.png^technic_mineral_lead.png"},
	is_ground_content = true,
	groups = {cracky=3},
	sounds = default.node_sound_stone_defaults(),
	drop = "technic:lead_lump",
})

minetest.register_node(":technic:mineral_sulfur", {
	description = S("Sulfur Ore"),
	tiles = {"default_stone.png^technic_mineral_sulfur.png"},
	is_ground_content = true,
	groups = {cracky=3},
	sounds = default.node_sound_stone_defaults(),
	drop = "technic:sulfur_lump",
})

minetest.register_node(":technic:granite", {
	description = S("Granite"),
	tiles = {"technic_granite.png"},
	is_ground_content = true,
	groups = {cracky=1},
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node(":technic:granite_bricks", {
	description = S("Granite Bricks"),
	tiles = {"technic_granite_bricks.png"},
	is_ground_content = true,
	groups = {cracky=1},
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node(":technic:marble", {
	description = S("Marble"),
	tiles = {"technic_marble.png"},
	is_ground_content = true,
	groups = {cracky=3, marble=1},
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node(":technic:marble_bricks", {
	description = S("Marble Bricks"),
	tiles = {"technic_marble_bricks.png"},
	is_ground_content = true,
	groups = {cracky=3},
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node(":technic:uranium_block", {
	description = S("Uranium Block"),
	tiles = {"technic_uranium_block.png"},
	is_ground_content = true,
	groups = {uranium_block=1, cracky=1, level=2, radioactive=2},
	sounds = default.node_sound_stone_defaults()
})

minetest.register_node(":technic:chromium_block", {
	description = S("Chromium Block"),
	tiles = {"technic_chromium_block.png"},
	is_ground_content = true,
	groups = {cracky=1, level=2},
	sounds = default.node_sound_stone_defaults()
})

minetest.register_node(":technic:zinc_block", {
	description = S("Zinc Block"),
	tiles = {"technic_zinc_block.png"},
	is_ground_content = true,
	groups = {cracky=1, level=2},
	sounds = default.node_sound_stone_defaults()
})

minetest.register_node(":technic:lead_block", {
	description = S("Lead Block"),
	tiles = {"technic_lead_block.png"},
	is_ground_content = true,
	groups = {cracky=1, level=2},
	sounds = default.node_sound_stone_defaults()
})

minetest.register_node(":technic:cast_iron_block", {
	description = S("Cast Iron Block"),
	tiles = {"technic_cast_iron_block.png"},
	is_ground_content = true,
	groups = {cracky=1, level=2},
	sounds = default.node_sound_stone_defaults()
})

minetest.register_node(":technic:carbon_steel_block", {
	description = S("Carbon Steel Block"),
	tiles = {"technic_carbon_steel_block.png"},
	is_ground_content = true,
	groups = {cracky=1, level=2},
	sounds = default.node_sound_stone_defaults()
})

minetest.register_node(":technic:stainless_steel_block", {
	description = S("Stainless Steel Block"),
	tiles = {"technic_stainless_steel_block.png"},
	is_ground_content = true,
	groups = {cracky=1, level=2},
	sounds = default.node_sound_stone_defaults()
})

minetest.register_node(":technic:sulfur_block", {
	description = S("Sulfur Block"),
	tiles = {"technic_sulfur_block.png"},
	is_ground_content = true,
	groups = {cracky = 3},
	sounds = default.node_sound_stone_defaults()
})

minetest.register_node(":technic:blast_resistant_concrete", {
	description = S("Blast-resistant Concrete Block"),
	tiles = {"technic_blast_resistant_concrete_block.png"},
	groups = {cracky = 1, level = 3, concrete = 1},
	sounds = default.node_sound_stone_defaults(),
	on_blast = function(pos, intensity)
		if intensity > 9 then
			minetest.remove_node(pos)
			return {"technic:blast_resistant_concrete"}
		end
	end
})
