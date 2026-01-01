
local S = technic.getter
local mat = technic.materials
local has_mcl = core.get_modpath("mcl_core")

technic.register_recipe_type("compressing", {
	description = S("Compressing"),
	icon = "technic_hv_compressor_front.png",
})

function technic.register_compressor_recipe(data)
	data.time = data.time or 4
	technic.register_recipe("compressing", data)
end

local recipes = {
	{mat.snowblock,          mat.ice},
	{mat.sand.." 2",             mat.sandstone},
	{mat.desert_sand.." 2",      mat.desert_sandstone},
	{mat.silver_sand.." 2",      mat.silver_sandstone},
	{mat.desert_sandstone,   mat.desert_stone},
	{"technic:mixed_metal_ingot",  "technic:composite_plate"},
	{mat.copper_ingot.." 5",     "technic:copper_plate"},
	{"technic:coal_dust 4",        "technic:graphite"},
	{"technic:carbon_cloth",       "technic:carbon_plate"},
	{"technic:uranium35_ingot 5",  "technic:uranium_fuel"},
	{"technic:graphite 25",        mat.diamond}
}

if core.get_modpath("ethereal") then
	-- the density of charcoal is ~1/10 of coal, otherwise it's pure carbon
	table.insert(recipes, {"ethereal:charcoal_lump 10", mat.coal_lump.." 1"})
end


-- defuse the default sandstone recipe, since we have the compressor to take over in a more realistic manner
if not has_mcl then
	core.clear_craft({
		recipe = {
			{"default:sand", "default:sand"},
			{"default:sand", "default:sand"},
		},
	})
	core.clear_craft({
		recipe = {
			{"default:desert_sand", "default:desert_sand"},
			{"default:desert_sand", "default:desert_sand"},
		},
	})
	core.clear_craft({
		recipe = {
			{"default:silver_sand", "default:silver_sand"},
			{"default:silver_sand", "default:silver_sand"},
		},
	})
end

for _, data in pairs(recipes) do
	technic.register_compressor_recipe({input = {data[1]}, output = data[2]})
end

