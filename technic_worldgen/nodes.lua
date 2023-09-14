
local S = minetest.get_translator("technic_worldgen")

local has_mcl = minetest.get_modpath("mcl_core")

minetest.register_node(":technic:mineral_uranium", {
	description = S("Uranium Ore"),
	tiles = {"default_stone.png^technic_mineral_uranium.png"},
	is_ground_content = true,
	groups = {cracky=3, radioactive=1, pickaxey=1},
	_mcl_hardness = 0.8,
	_mcl_blast_resistance = 1,
	sounds = technic.sounds.node_sound_stone_defaults(),
	drop = "technic:uranium_lump",
})

minetest.register_node(":technic:mineral_chromium", {
	description = S("Chromium Ore"),
	tiles = {"default_stone.png^technic_mineral_chromium.png"},
	is_ground_content = true,
	groups = {cracky=3, pickaxey=1},
	_mcl_hardness = 0.8,
	_mcl_blast_resistance = 1,
	sounds = technic.sounds.node_sound_stone_defaults(),
	drop = "technic:chromium_lump",
})

minetest.register_node(":technic:mineral_zinc", {
	description = S("Zinc Ore"),
	tiles = {"default_stone.png^technic_mineral_zinc.png"},
	is_ground_content = true,
	groups = {cracky=3, pickaxey=1},
	_mcl_hardness = 0.8,
	_mcl_blast_resistance = 1,
	sounds = technic.sounds.node_sound_stone_defaults(),
	drop = "technic:zinc_lump",
})

minetest.register_node(":technic:mineral_lead", {
	description = S("Lead Ore"),
	tiles = {"default_stone.png^technic_mineral_lead.png"},
	is_ground_content = true,
	groups = {cracky=3, pickaxey=1},
	_mcl_hardness = 0.8,
	_mcl_blast_resistance = 1,
	sounds = technic.sounds.node_sound_stone_defaults(),
	drop = "technic:lead_lump",
})

minetest.register_node(":technic:mineral_sulfur", {
	description = S("Sulfur Ore"),
	tiles = {"default_stone.png^technic_mineral_sulfur.png"},
	is_ground_content = true,
	groups = {cracky=3, pickaxey=1},
	_mcl_hardness = 0.8,
	_mcl_blast_resistance = 1,
	sounds = technic.sounds.node_sound_stone_defaults(),
	drop = "technic:sulfur_lump",
})

if has_mcl then
	minetest.register_alias("technic:granite", "mcl_core:granite")
	minetest.register_alias("technic:granite_bricks", "mcl_core:granite_smooth")
else
	minetest.register_node(":technic:granite", {
		description = S("Granite"),
		tiles = {"technic_granite.png"},
		is_ground_content = true,
		groups = {cracky=1},
		sounds = technic.sounds.node_sound_stone_defaults(),
	})
	
	minetest.register_node(":technic:granite_bricks", {
		description = S("Granite Bricks"),
		tiles = {"technic_granite_bricks.png"},
		is_ground_content = true,
		groups = {cracky=1},
		sounds = technic.sounds.node_sound_stone_defaults(),
	})
end

minetest.register_node(":technic:marble", {
	description = S("Marble"),
	tiles = {"technic_marble.png"},
	is_ground_content = true,
	groups = {cracky=3, marble=1, pickaxey=1},
	_mcl_hardness = 0.8,
	_mcl_blast_resistance = 1,
	sounds = technic.sounds.node_sound_stone_defaults(),
})

minetest.register_node(":technic:marble_bricks", {
	description = S("Marble Bricks"),
	tiles = {"technic_marble_bricks.png"},
	is_ground_content = true,
	groups = {cracky=3, pickaxey=1},
	_mcl_hardness = 0.8,
	_mcl_blast_resistance = 1,
	sounds = technic.sounds.node_sound_stone_defaults(),
})

minetest.register_node(":technic:uranium_block", {
	description = S("Uranium Block"),
	tiles = {"technic_uranium_block.png"},
	is_ground_content = true,
	groups = {uranium_block=1, cracky=1, level=has_mcl and 0 or 2, radioactive=2, pickaxey=4},
	_mcl_hardness = 1,
	_mcl_blast_resistance = 1,
	sounds = technic.sounds.node_sound_stone_defaults()
})

minetest.register_node(":technic:chromium_block", {
	description = S("Chromium Block"),
	tiles = {"technic_chromium_block.png"},
	is_ground_content = true,
	groups = {cracky=1, level=has_mcl and 0 or 2, pickaxey=4},
	_mcl_hardness = 1,
	_mcl_blast_resistance = 1,
	sounds = technic.sounds.node_sound_stone_defaults()
})

minetest.register_node(":technic:zinc_block", {
	description = S("Zinc Block"),
	tiles = {"technic_zinc_block.png"},
	is_ground_content = true,
	groups = {cracky=1, level=has_mcl and 0 or 2, pickaxey=4},
	_mcl_hardness = 1,
	_mcl_blast_resistance = 1,
	sounds = technic.sounds.node_sound_stone_defaults()
})

minetest.register_node(":technic:lead_block", {
	description = S("Lead Block"),
	tiles = {"technic_lead_block.png"},
	is_ground_content = true,
	groups = {cracky=1, level=has_mcl and 0 or 2, pickaxey=4},
	_mcl_hardness = 1,
	_mcl_blast_resistance = 1,
	sounds = technic.sounds.node_sound_stone_defaults()
})

minetest.register_node(":technic:cast_iron_block", {
	description = S("Cast Iron Block"),
	tiles = {"technic_cast_iron_block.png"},
	is_ground_content = true,
	groups = {cracky=1, level=has_mcl and 0 or 2, pickaxey=4},
	_mcl_hardness = 1,
	_mcl_blast_resistance = 1,
	sounds = technic.sounds.node_sound_stone_defaults()
})

minetest.register_node(":technic:carbon_steel_block", {
	description = S("Carbon Steel Block"),
	tiles = {"technic_carbon_steel_block.png"},
	is_ground_content = true,
	groups = {cracky=1, level=has_mcl and 0 or 2, pickaxey=4},
	_mcl_hardness = 1,
	_mcl_blast_resistance = 1,
	sounds = technic.sounds.node_sound_stone_defaults()
})

minetest.register_node(":technic:stainless_steel_block", {
	description = S("Stainless Steel Block"),
	tiles = {"technic_stainless_steel_block.png"},
	is_ground_content = true,
	groups = {cracky=1, level=has_mcl and 0 or 2, pickaxey=4},
	_mcl_hardness = 1,
	_mcl_blast_resistance = 1,
	sounds = technic.sounds.node_sound_stone_defaults()
})

minetest.register_node(":technic:sulfur_block", {
	description = S("Sulfur Block"),
	tiles = {"technic_sulfur_block.png"},
	is_ground_content = true,
	groups = {cracky = 3, pickaxey=1, handy=1},
	_mcl_hardness = 1,
	_mcl_blast_resistance = 1,
	sounds = technic.sounds.node_sound_stone_defaults()
})

minetest.register_node(":technic:blast_resistant_concrete", {
	description = S("Blast-resistant Concrete Block"),
	tiles = {"technic_blast_resistant_concrete_block.png"},
	groups = {cracky = 1, level = has_mcl and 0 or 3, concrete = 1, pickaxey=5},
	_mcl_hardness = 5,
	_mcl_blast_resistance = 9,
	sounds = technic.sounds.node_sound_stone_defaults(),
	on_blast = function(pos, intensity)
		if intensity > 9 then
			minetest.remove_node(pos)
			return {"technic:blast_resistant_concrete"}
		end
	end
})
