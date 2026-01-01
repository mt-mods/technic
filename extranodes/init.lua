-- Minetest 0.4.6 mod: extranodes
-- namespace: technic
local S = core.get_translator(core.get_current_modname())

if core.get_modpath("moreblocks") then

	-- register stairsplus/circular_saw nodes
	-- we skip blast resistant concrete and uranium intentionally
	-- chrome seems to be too hard of a metal to be actually sawable

	stairsplus:register_all("technic", "marble", "technic:marble", {
		description=S("Marble"),
		groups={cracky=3, not_in_creative_inventory=1},
		tiles={"technic_marble.png"},
	})

	stairsplus:register_all("technic", "marble_bricks", "technic:marble_bricks", {
		description=S("Marble Bricks"),
		groups={cracky=3, not_in_creative_inventory=1},
		tiles={"technic_marble_bricks.png"},
	})

	stairsplus:register_all("technic", "granite", "technic:granite", {
		description=S("Granite"),
		groups={cracky=1, not_in_creative_inventory=1},
		tiles={"technic_granite.png"},
	})

	stairsplus:register_all("technic", "granite_bricks", "technic:granite_bricks", {
		description=S("Granite Bricks"),
		groups={cracky=1, not_in_creative_inventory=1},
		tiles={"technic_granite_bricks.png"},
	})

	stairsplus:register_all("technic", "concrete", "basic_materials:concrete_block", {
		description=S("Concrete"),
		groups={cracky=3, not_in_creative_inventory=1},
		tiles={"basic_materials_concrete_block.png"},
	})

	stairsplus:register_all("technic", "zinc_block", "technic:zinc_block", {
		description=S("Zinc Block"),
		groups={cracky=1, not_in_creative_inventory=1},
		tiles={"technic_zinc_block.png"},
	})

	stairsplus:register_all("technic", "cast_iron_block", "technic:cast_iron_block", {
		description=S("Cast Iron Block"),
		groups={cracky=1, not_in_creative_inventory=1},
		tiles={"technic_cast_iron_block.png"},
	})

	stairsplus:register_all("technic", "carbon_steel_block", "technic:carbon_steel_block", {
		description=S("Carbon Steel Block"),
		groups={cracky=1, not_in_creative_inventory=1},
		tiles={"technic_carbon_steel_block.png"},
	})

	stairsplus:register_all("technic", "stainless_steel_block", "technic:stainless_steel_block", {
		description=S("Stainless Steel Block"),
		groups={cracky=1, not_in_creative_inventory=1},
		tiles={"technic_stainless_steel_block.png"},
	})

	stairsplus:register_all("technic", "blast_resistant_concrete", "technic:blast_resistant_concrete", {
		description = S("Blast-resistant Concrete"),
		tiles = {"technic_blast_resistant_concrete_block.png",},
		groups = {cracky = 1, level = 3, concrete = 1},
		on_blast = function(pos, intensity)
			if intensity > 3 then
				core.remove_node(pos)
				core.add_item(pos, "technic:blast_resistant_concrete")
			end
		end
	})

	-- FIXME: Clean this function up somehow
	local function register_technic_stairs_alias(modname, origname, newmod, newname)
		core.register_alias(modname .. ":slab_" .. origname, newmod..":slab_" .. newname)
		core.register_alias(modname .. ":slab_" .. origname ..
								"_inverted", newmod..":slab_" .. newname .. "_inverted")
		core.register_alias(modname .. ":slab_" .. origname .. "_wall", newmod..":slab_" .. newname .. "_wall")
		core.register_alias(modname .. ":slab_" .. origname ..
								"_quarter", newmod..":slab_" .. newname .. "_quarter")
		core.register_alias(modname .. ":slab_" .. origname ..
								"_quarter_inverted", newmod..":slab_" .. newname .. "_quarter_inverted")
		core.register_alias(modname .. ":slab_" .. origname ..
								"_quarter_wall", newmod..":slab_" .. newname .. "_quarter_wall")
		core.register_alias(modname .. ":slab_" .. origname ..
								"_three_quarter", newmod..":slab_" .. newname .. "_three_quarter")
		core.register_alias(modname .. ":slab_" .. origname ..
								"_three_quarter_inverted", newmod..":slab_" .. newname .. "_three_quarter_inverted")
		core.register_alias(modname .. ":slab_" .. origname ..
								"_three_quarter_wall", newmod..":slab_" .. newname .. "_three_quarter_wall")
		core.register_alias(modname .. ":stair_" .. origname, newmod..":stair_" .. newname)
		core.register_alias(modname .. ":stair_" .. origname ..
								"_inverted", newmod..":stair_" .. newname .. "_inverted")
		core.register_alias(modname .. ":stair_" .. origname .. "_wall", newmod..":stair_" .. newname .. "_wall")
		core.register_alias(modname .. ":stair_" .. origname ..
								"_wall_half", newmod..":stair_" .. newname .. "_wall_half")
		core.register_alias(modname .. ":stair_" .. origname ..
								"_wall_half_inverted", newmod..":stair_" .. newname .. "_wall_half_inverted")
		core.register_alias(modname .. ":stair_" .. origname .. "_half", newmod..":stair_" .. newname .. "_half")
		core.register_alias(modname .. ":stair_" .. origname ..
								"_half_inverted", newmod..":stair_" .. newname .. "_half_inverted")
		core.register_alias(modname .. ":stair_" .. origname ..
								"_right_half", newmod..":stair_" .. newname .. "_right_half")
		core.register_alias(modname .. ":stair_" .. origname ..
								"_right_half_inverted", newmod..":stair_" .. newname .. "_right_half_inverted")
		core.register_alias(modname .. ":stair_" .. origname ..
								"_wall_half", newmod..":stair_" .. newname .. "_wall_half")
		core.register_alias(modname .. ":stair_" .. origname ..
								"_wall_half_inverted", newmod..":stair_" .. newname .. "_wall_half_inverted")
		core.register_alias(modname .. ":stair_" .. origname .. "_inner", newmod..":stair_" .. newname .. "_inner")
		core.register_alias(modname .. ":stair_" .. origname ..
								"_inner_inverted", newmod..":stair_" .. newname .. "_inner_inverted")
		core.register_alias(modname .. ":stair_" .. origname .. "_outer", newmod..":stair_" .. newname .. "_outer")
		core.register_alias(modname .. ":stair_" .. origname ..
								"_outer_inverted", newmod..":stair_" .. newname .. "_outer_inverted")
		core.register_alias(modname .. ":panel_" .. origname ..
								"_bottom", newmod..":panel_" .. newname .. "_bottom")
		core.register_alias(modname .. ":panel_" .. origname .. "_top", newmod..":panel_" .. newname .. "_top")
		core.register_alias(modname .. ":panel_" .. origname ..
								"_vertical", newmod..":panel_" .. newname .. "_vertical")
		core.register_alias(modname .. ":micro_" .. origname ..
								"_bottom", newmod..":micro_" .. newname .. "_bottom")
		core.register_alias(modname .. ":micro_" .. origname .. "_top", newmod..":micro_" .. newname .. "_top")
	end

	register_technic_stairs_alias("stairsplus", "concrete", "technic", "concrete")
	register_technic_stairs_alias("stairsplus", "marble", "technic", "marble")
	register_technic_stairs_alias("stairsplus", "granite", "technic", "granite")
	register_technic_stairs_alias("stairsplus", "marble_bricks", "technic", "marble_bricks")

end

local iclip_def = {
	description = S("Insulator/cable clip"),
	drawtype = "mesh",
	mesh = "technic_insulator_clip.obj",
	tiles = {"technic_insulator_clip.png"},
	paramtype = "light",
	is_ground_content = false,
	groups = {choppy=1, snappy=1, oddly_breakable_by_hand=1 },
	sounds = default.node_sound_stone_defaults(),
}

local iclipfence_def = {
	description = S("Insulator/cable clip"),
	tiles = {"technic_insulator_clip.png"},
	is_ground_content = false,
	paramtype = "light",
	drawtype = "nodebox",
	node_box = {
		type = "connected",
		fixed = {
			{ -0.25,   0.75,   -0.25,   0.25,   1.25,   0.25   }, -- the clip on top
			{ -0.125, 0.6875, -0.125, 0.125, 0.75,   0.125 },
			{ -0.1875,  0.625,  -0.1875,  0.1875,  0.6875, 0.1875  },
			{ -0.125, 0.5625, -0.125, 0.125, 0.625,  0.125 },
			{ -0.1875,  0.5,    -0.1875,  0.1875,  0.5625, 0.1875  },
			{ -0.125, 0.4375, -0.125, 0.125, 0.5,    0.125 },
			{ -0.1875,  0.375,  -0.1875,  0.1875,  0.4375, 0.1875  },
			{ -0.125, -0.5,    -0.125,  0.125,  0.375,  0.125  }, -- the post, slightly short
		},
		-- connect_top =
		-- connect_bottom =
		connect_front = {{-1/16,3/16,-1/2,1/16,5/16,-1/8},
			{-1/16,-5/16,-1/2,1/16,-3/16,-1/8}},
		connect_left = {{-1/2,3/16,-1/16,-1/8,5/16,1/16},
			{-1/2,-5/16,-1/16,-1/8,-3/16,1/16}},
		connect_back = {{-1/16,3/16,1/8,1/16,5/16,1/2},
			{-1/16,-5/16,1/8,1/16,-3/16,1/2}},
		connect_right = {{1/8,3/16,-1/16,1/2,5/16,1/16},
			{1/8,-5/16,-1/16,1/2,-3/16,1/16}},
	},
	connects_to = {"group:fence", "group:wood", "group:tree"},
	groups = {fence=1, choppy=1, snappy=1, oddly_breakable_by_hand=1 },
	sounds = default.node_sound_stone_defaults(),
}

local sclip_tex = {
	"technic_insulator_clip.png",
	{ name = "strut.png^technic_steel_strut_overlay.png", color = "white" },
	{ name = "strut.png", color = "white" }
}

local streetsmod = core.get_modpath("streets") or core.get_modpath ("steelsupport")
-- cheapie's fork breaks it into several individual mods, with differernt names for the same content.

if streetsmod then
	sclip_tex = {
		"technic_insulator_clip.png",
		{ name = "streets_support.png^technic_steel_strut_overlay.png", color = "white" },
		{ name = "streets_support.png", color = "white" }
	}
end

local sclip_def = {
	description = S("Steel strut with insulator/cable clip"),
	drawtype = "mesh",
	mesh = "technic_steel_strut_with_insulator_clip.obj",
	tiles = sclip_tex,
	paramtype = "light",
	paramtype2 = "wallmounted",
	is_ground_content = false,
	sounds = default.node_sound_stone_defaults(),
	groups = { choppy=1, cracky=1 },
	backface_culling = false
}

if core.get_modpath("unifieddyes") then
	iclip_def.paramtype2 = "colorwallmounted"
	iclip_def.palette = "unifieddyes_palette_colorwallmounted.png"
	iclip_def.after_place_node = function(pos, placer, itemstack, pointed_thing)
		unifieddyes.fix_rotation(pos, placer, itemstack, pointed_thing)
	end
	iclip_def.groups = {choppy=1, snappy=1, oddly_breakable_by_hand=1, ud_param2_colorable = 1}
	iclip_def.on_dig = unifieddyes.on_dig

	iclipfence_def.paramtype2 = "color"
	iclipfence_def.palette = "unifieddyes_palette_extended.png"
	iclipfence_def.on_construct = unifieddyes.on_construct
	iclipfence_def.groups = {fence=1, choppy=1, snappy=1, oddly_breakable_by_hand=1, ud_param2_colorable = 1}
	iclipfence_def.on_dig = unifieddyes.on_dig

	sclip_def.paramtype2 = "colorwallmounted"
	sclip_def.palette = "unifieddyes_palette_colorwallmounted.png"
	sclip_def.after_place_node = function(pos, placer, itemstack, pointed_thing)
		unifieddyes.fix_rotation(pos, placer, itemstack, pointed_thing)
	end
	sclip_def.on_dig = unifieddyes.on_dig
	sclip_def.groups = {choppy=1, cracky=1, ud_param2_colorable = 1}
end

core.register_node(":technic:insulator_clip", iclip_def)
core.register_node(":technic:insulator_clip_fencepost", iclipfence_def)

core.register_craft({
	output = "technic:insulator_clip",
	recipe = {
		{ "", "dye:white", ""},
		{ "", "technic:raw_latex", ""},
		{ "technic:raw_latex", "default:stone", "technic:raw_latex"},
	}
})

core.register_craft({
	output = "technic:insulator_clip_fencepost 2",
	recipe = {
		{ "", "dye:white", ""},
		{ "", "technic:raw_latex", ""},
		{ "technic:raw_latex", "default:fence_wood", "technic:raw_latex"},
	}
})

local steelmod = core.get_modpath("steel")

if streetsmod or steelmod then
	core.register_node(":technic:steel_strut_with_insulator_clip", sclip_def)

	if steelmod then
		core.register_craft({
			output = "technic:steel_strut_with_insulator_clip",
			recipe = {
				{"technic:insulator_clip_fencepost"},
				{"steel:strut_mount"}
			}
		})

		core.register_craft({
			output = "technic:steel_strut_with_insulator_clip",
			recipe = {
				{"technic:insulator_clip_fencepost", ""                    },
				{"steel:strut",                      "default:steel_ingot" },
			}
		})

	elseif streetsmod then
		core.register_craft({
			output = "technic:steel_strut_with_insulator_clip",
			recipe = {
				{"technic:insulator_clip_fencepost", ""                   },
				{"streets:steel_support",           "default:steel_ingot" },
			}
		})
	end
end

if core.get_modpath("unifieddyes") then

	unifieddyes.register_color_craft({
		output = "technic:insulator_clip_fencepost",
		palette = "extended",
		type = "shapeless",
		neutral_node = "technic:insulator_clip_fencepost",
		recipe = {
			"NEUTRAL_NODE",
			"MAIN_DYE"
		}
	})

	unifieddyes.register_color_craft({
		output = "technic:insulator_clip",
		palette = "wallmounted",
		type = "shapeless",
		neutral_node = "technic:insulator_clip",
		recipe = {
			"NEUTRAL_NODE",
			"MAIN_DYE"
		}
	})

	unifieddyes.register_color_craft({
		output = "technic:steel_strut_with_insulator_clip",
		palette = "wallmounted",
		type = "shapeless",
		neutral_node = "",
		recipe = {
			"technic:steel_strut_with_insulator_clip",
			"MAIN_DYE"
		}
	})

	if steelmod then
		unifieddyes.register_color_craft({
			output = "technic:steel_strut_with_insulator_clip",
			palette = "wallmounted",
			neutral_node = "",
			recipe = {
				{ "technic:insulator_clip_fencepost", "MAIN_DYE" },
				{ "steel:strut_mount",                ""         },
			}
		})
	end

	if streetsmod then
		unifieddyes.register_color_craft({
			output = "technic:steel_strut_with_insulator_clip",
			palette = "wallmounted",
			neutral_node = "technic:steel_strut_with_insulator_clip",
			recipe = {
				{ "technic:insulator_clip_fencepost", "MAIN_DYE"            },
				{ "streets:steel_support",            "default:steel_ingot" },
			}
		})
	end
end

for i = 0, 31 do
	core.register_alias("technic:concrete_post"..i,
			"technic:concrete_post")
end
for i = 32, 63 do
	core.register_alias("technic:concrete_post"..i,
			"technic:concrete_post_with_platform")
end

core.register_craft({
	output = 'technic:concrete_post_platform 6',
	recipe = {
		{'basic_materials:concrete_block','technic:concrete_post','basic_materials:concrete_block'},
	}
})

core.register_craft({
	output = 'technic:concrete_post 12',
	recipe = {
		{'basic_materials:concrete_block','basic_materials:steel_bar','basic_materials:concrete_block'},
		{'basic_materials:concrete_block','basic_materials:steel_bar','basic_materials:concrete_block'},
		{'basic_materials:concrete_block','basic_materials:steel_bar','basic_materials:concrete_block'},
	}
})

local box_platform = {-0.5,  0.3,  -0.5,  0.5,  0.5, 0.5}
local box_post     = {-0.15, -0.5, -0.15, 0.15, 0.5, 0.15}
local box_front    = {-0.1,  -0.3, -0.5,  0.1,  0.3, 0}
local box_back     = {-0.1,  -0.3, 0,     0.1,  0.3, 0.5}
local box_left     = {-0.5,  -0.3, -0.1,  0,    0.3, 0.1}
local box_right    = {0,     -0.3, -0.1,  0.5,  0.3, 0.1}

core.register_node(":technic:concrete_post_platform", {
	description = S("Concrete Post Platform"),
	tiles = {"basic_materials_concrete_block.png",},
	groups={cracky=1, level=2},
	is_ground_content = false,
	sounds = default.node_sound_stone_defaults(),
	paramtype = "light",
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {box_platform}
	},
	on_place = function (itemstack, placer, pointed_thing)
		local node = core.get_node(pointed_thing.under)
		if node.name ~= "technic:concrete_post" then
			return core.item_place_node(itemstack, placer, pointed_thing)
		end
		core.set_node(pointed_thing.under, {name="technic:concrete_post_with_platform"})
		itemstack:take_item()
		placer:set_wielded_item(itemstack)
		return itemstack
	end,
})

for platform = 0, 1 do
	local after_dig_node = nil
	if platform == 1 then
		after_dig_node = function(pos, old_node)
			old_node.name = "technic:concrete_post"
			core.set_node(pos, old_node)
		end
	end

	core.register_node(":technic:concrete_post"..(platform == 1 and "_with_platform" or ""), {
		description = S("Concrete Post"),
		tiles = {"basic_materials_concrete_block.png"},
		groups = {cracky=1, level=2, concrete_post=1, not_in_creative_inventory=platform},
		is_ground_content = false,
		sounds = default.node_sound_stone_defaults(),
		drop = (platform == 1 and "technic:concrete_post_platform" or
				"technic:concrete_post"),
		paramtype = "light",
		sunlight_propagates = true,
		drawtype = "nodebox",
		connects_to = {"group:concrete", "group:concrete_post"},
		node_box = {
			type = "connected",
			fixed = {box_post, (platform == 1 and box_platform or nil)},
			connect_front = box_front,
			connect_back  = box_back,
			connect_left  = box_left,
			connect_right = box_right,
		},
		after_dig_node = after_dig_node,
	})
end
