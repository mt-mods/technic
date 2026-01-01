
local S = technic.getter
local mat = technic.materials

technic.register_recipe_type("alloy", {
	description = S("Alloying"),
	icon = "technic_mv_alloy_furnace_front.png",
	input_size = 2,
})

function technic.register_alloy_recipe(data)
	data.time = data.time or 6
	technic.register_recipe("alloy", data)
end

local recipes = {
	{"technic:copper_dust 7",         "technic:tin_dust",           mat.bronze_ingot.." 8", 12},
	{mat.copper_ingot.." 7",        mat.tin_ingot,          mat.bronze_ingot.." 8", 12},
	{"technic:wrought_iron_dust 2",   "technic:coal_dust",          "technic:carbon_steel_ingot 2", 6},
	{"technic:wrought_iron_ingot 2",  "technic:coal_dust",          "technic:carbon_steel_ingot 2", 6},
	{"technic:carbon_steel_dust 4",   "technic:chromium_dust",      "technic:stainless_steel_ingot 5", 7.5},
	{"technic:carbon_steel_ingot 4",  "technic:chromium_ingot",     "technic:stainless_steel_ingot 5", 7.5},
	{"technic:copper_dust 2",         "technic:zinc_dust",          "basic_materials:brass_ingot 3"},
	{mat.copper_ingot.." 2",        "technic:zinc_ingot",         "basic_materials:brass_ingot 3"},
	{mat.sand.." 2",                "technic:coal_dust 2",        "technic:silicon_wafer"},
	{"technic:silicon_wafer",         "technic:gold_dust",          "technic:doped_silicon_wafer"},
	-- from https://en.wikipedia.org/wiki/Carbon_black
	-- The highest volume use of carbon black is as a reinforcing filler in rubber products, especially tires.
	-- "[Compounding a] pure gum vulcanizate … with 50% of its weight of carbon black
	-- improves its tensile strength and wear resistance …"
	{"technic:raw_latex 4",           "technic:coal_dust 2",        "technic:rubber 6", 2},
	{"technic:raw_latex 2",           mat.coal_lump,        "technic:rubber 2", 2},
	{mat.ice,                   mat.bucket_empty,        mat.bucket_water, 1 },
	{mat.obsidian,              mat.bucket_empty,        mat.bucket_lava, 1 },
}

if core.get_modpath("ethereal") then
	table.insert(recipes, {mat.clay, mat.dye_red,    "bakedclay:red"})
	table.insert(recipes, {mat.clay, mat.dye_orange, "bakedclay:orange"})
	table.insert(recipes, {mat.clay, mat.dye_grey,   "bakedclay:grey"})
end

if core.get_modpath("digilines") then
	table.insert(recipes,
		{"technic:lv_cable",         "digilines:wire_std_00000000 2", "technic:lv_digi_cable", 18})
	table.insert(recipes,
		{"technic:lv_cable_plate_1", "digilines:wire_std_00000000 2", "technic:lv_digi_cable_plate_1", 18})
	table.insert(recipes,
		{"technic:mv_cable",         "digilines:wire_std_00000000 2", "technic:mv_digi_cable", 18})
	table.insert(recipes,
		{"technic:mv_cable_plate_1", "digilines:wire_std_00000000 2", "technic:mv_digi_cable_plate_1", 18})
	table.insert(recipes,
		{"technic:hv_cable",         "digilines:wire_std_00000000 2", "technic:hv_digi_cable", 18})
	table.insert(recipes,
		{"technic:hv_cable_plate_1", "digilines:wire_std_00000000 2", "technic:hv_digi_cable_plate_1", 18})
end

for _, data in pairs(recipes) do
	technic.register_alloy_recipe({input = {data[1], data[2]}, output = data[3], time = data[4]})
end
