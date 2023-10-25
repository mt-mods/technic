-- check if we have the necessary dependencies to allow actually using these materials in the crafts

local mat = technic.materials
local has_mcl = minetest.get_modpath("mcl_core")

-- Remove some recipes
-- Bronze
if not has_mcl then
	minetest.clear_craft({
		type = "shapeless",
		output = "default:bronze_ingot"
	})
	-- Restore recipe for bronze block to ingots
	minetest.register_craft({
		output = "default:bronze_ingot 9",
		recipe = {
			{"default:bronzeblock"}
		}
	})
end

-- Accelerator tube
if pipeworks.enable_accelerator_tube then
	minetest.clear_craft({
		output = "pipeworks:accelerator_tube_1",
	})

	minetest.register_craft({
		output = 'pipeworks:accelerator_tube_1',
		recipe = {
			{'technic:copper_coil', 'pipeworks:tube_1', 'technic:copper_coil'},
			}
	})
end

-- Teleport tube
if pipeworks.enable_teleport_tube then
	minetest.clear_craft({
		output = "pipeworks:teleport_tube_1",
	})

	minetest.register_craft({
		output = 'pipeworks:teleport_tube_1',
		recipe = {
			{mat.mese_crystal, 'technic:copper_coil', mat.mese_crystal},
			{'pipeworks:tube_1', 'technic:control_logic_unit', 'pipeworks:tube_1'},
			{mat.mese_crystal, 'technic:copper_coil', mat.mese_crystal},
			}
	})
end

-- basic materials' brass ingot

minetest.clear_craft({
	output = "basic_materials:brass_ingot",
})

minetest.register_craft( {
	type = "shapeless",
	output = "basic_materials:brass_ingot 9",
	recipe = { "basic_materials:brass_block" },
})

-- tubes crafting recipes

minetest.register_craft({
	output = 'technic:diamond_drill_head',
	recipe = {
		{'technic:stainless_steel_ingot', mat.diamond, 'technic:stainless_steel_ingot'},
		{mat.diamond,               '',                mat.diamond},
		{'technic:stainless_steel_ingot', mat.diamond, 'technic:stainless_steel_ingot'},
	}
})

minetest.register_craft({
	output = 'technic:green_energy_crystal',
	recipe = {
		{mat.gold_ingot, 'technic:battery', mat.dye_green},
		{'technic:battery', 'technic:red_energy_crystal', 'technic:battery'},
		{mat.dye_green, 'technic:battery', mat.gold_ingot},
	}
})

minetest.register_craft({
	output = 'technic:blue_energy_crystal',
	recipe = {
		{mat.mithril_ingot, 'technic:battery', mat.dye_blue},
		{'technic:battery', 'technic:green_energy_crystal', 'technic:battery'},
		{mat.dye_blue, 'technic:battery', mat.mithril_ingot},
	}
})

minetest.register_craft({
	output = 'technic:red_energy_crystal',
	recipe = {
		{mat.silver_ingot, 'technic:battery', mat.dye_red},
		{'technic:battery', 'basic_materials:energy_crystal_simple', 'technic:battery'},
		{mat.dye_red, 'technic:battery', mat.silver_ingot},
	}
})

minetest.register_craft({
	output = 'technic:copper_coil 1',
	recipe = {
		{'basic_materials:copper_wire', 'technic:wrought_iron_ingot', 'basic_materials:copper_wire'},
		{'technic:wrought_iron_ingot', '', 'technic:wrought_iron_ingot'},
		{'basic_materials:copper_wire', 'technic:wrought_iron_ingot', 'basic_materials:copper_wire'},
	},
	replacements = {
		{"basic_materials:copper_wire", "basic_materials:empty_spool"},
		{"basic_materials:copper_wire", "basic_materials:empty_spool"},
		{"basic_materials:copper_wire", "basic_materials:empty_spool"},
		{"basic_materials:copper_wire", "basic_materials:empty_spool"}
	},
})

minetest.register_craft({
	output = 'technic:lv_transformer',
	recipe = {
		{mat.isolation,                    'technic:wrought_iron_ingot', mat.isolation},
		{'technic:copper_coil',        'technic:wrought_iron_ingot', 'technic:copper_coil'},
		{'technic:wrought_iron_ingot', 'technic:wrought_iron_ingot', 'technic:wrought_iron_ingot'},
	}
})

minetest.register_craft({
	output = 'technic:mv_transformer',
	recipe = {
		{mat.isolation,                    'technic:carbon_steel_ingot', mat.isolation},
		{'technic:copper_coil',        'technic:carbon_steel_ingot', 'technic:copper_coil'},
		{'technic:carbon_steel_ingot', 'technic:carbon_steel_ingot', 'technic:carbon_steel_ingot'},
	}
})

minetest.register_craft({
	output = 'technic:hv_transformer',
	recipe = {
		{mat.isolation,                       'technic:stainless_steel_ingot', mat.isolation},
		{'technic:copper_coil',           'technic:stainless_steel_ingot', 'technic:copper_coil'},
		{'technic:stainless_steel_ingot', 'technic:stainless_steel_ingot', 'technic:stainless_steel_ingot'},
	}
})

minetest.register_craft({
	output = 'technic:control_logic_unit',
	recipe = {
		{'', 'basic_materials:gold_wire', ''},
		{mat.bronze_ingot, 'technic:silicon_wafer', mat.bronze_ingot},
		{'', 'technic:chromium_ingot', ''},
	},
	replacements = { {"basic_materials:gold_wire", "basic_materials:empty_spool"}, },
})

minetest.register_craft({
	output = 'technic:mixed_metal_ingot 9',
	recipe = {
		{'technic:stainless_steel_ingot', 'technic:stainless_steel_ingot', 'technic:stainless_steel_ingot'},
		{mat.bronze_ingot,          mat.bronze_ingot,          mat.bronze_ingot},
		{mat.tin_ingot,             mat.tin_ingot,             mat.tin_ingot},
	}
})

minetest.register_craft({
	output = 'technic:carbon_cloth',
	recipe = {
		{'technic:graphite', 'technic:graphite', 'technic:graphite'}
	}
})

minetest.register_craft({
	output = "technic:machine_casing",
	recipe = {
		{ "technic:cast_iron_ingot", "technic:cast_iron_ingot", "technic:cast_iron_ingot" },
		{ "technic:cast_iron_ingot", "basic_materials:brass_ingot", "technic:cast_iron_ingot" },
		{ "technic:cast_iron_ingot", "technic:cast_iron_ingot", "technic:cast_iron_ingot" },
	},
})


minetest.register_craft({
	output = mat.dirt.." 2",
	type = "shapeless",
	replacements = {{"bucket:bucket_water","bucket:bucket_empty"}},
	recipe = {
		"technic:stone_dust",
		"group:leaves",
		"bucket:bucket_water",
		"group:sand",
	},
})
