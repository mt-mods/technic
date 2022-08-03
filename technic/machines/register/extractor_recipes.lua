
local S = technic.getter

technic.register_recipe_type("extracting", { description = S("Extracting") })

function technic.register_extractor_recipe(data)
	data.time = data.time or 4
	technic.register_recipe("extracting", data)
end

if minetest.get_modpath("dye") then
	-- check if we are using dye or unifieddyes
	local unifieddyes = minetest.get_modpath("unifieddyes")

	-- register recipes with the same crafting ratios as `dye` provides
	local dye_recipes = {
		{"technic:coal_dust",                 "dye:black 2"},
		{"default:blueberries",               "dye:violet 2"},
		{"default:grass_1",                   "dye:green 1"},
		{"default:dry_shrub",                 "dye:brown 4"},
		{"default:junglegrass",               "dye:green 2"},
		{"default:cactus",                    "dye:green 4"},
		{"default:coral_green",               "dye:green 4"},
		{"default:coral_pink",                "dye:pink 4"},
		{"default:coral_cyan",                "dye:cyan 4"},
		{"default:coral_brown",               "dye:brown 4"},
		{"default:coral_orange",              "dye:orange 4"},
		{"default:coral_skeleton",            "dye:white 8"},
		{"flowers:chrysanthemum_green",       "dye:green 4"},
		{"flowers:geranium",                  "dye:blue 4"},
		{"flowers:dandelion_white",           "dye:white 4"},
		{"flowers:dandelion_yellow",          "dye:yellow 4"},
		{"flowers:tulip",                     "dye:orange 4"},
		{"flowers:tulip_black",               "dye:black 8"},
		{"flowers:rose",                      "dye:red 4"},
		{"flowers:viola",                     "dye:violet 4"},
		{"bushes:blackberry",                 unifieddyes and "unifieddyes:magenta_s50 4" or "dye:violet 4"},
		{"bushes:blueberry",                  unifieddyes and "unifieddyes:magenta_s50 4" or "dye:magenta 4"},
	}

	if minetest.get_modpath("hunger") and minetest.get_modpath("ethereal") then
		table.insert(dye_recipes, {"ethereal:willow_twig 12", "technic:aspirin_pill"})
	end

	if minetest.get_modpath("farming") then
		-- Dyes ---
		-- better recipes for farming's crafting methods (twice the output)
		table.insert(dye_recipes, {"farming:chili_pepper", "dye:red 4"})
		table.insert(dye_recipes, {"farming:beans", "dye:green 4"})
		table.insert(dye_recipes, {"farming:grapes", "dye:violet 4"})
		table.insert(dye_recipes, {"farming:cocoa_beans", "dye:brown 4"})
		-- Some extra recipes:
		table.insert(dye_recipes, {"farming:onion", "dye:yellow 4"})
		table.insert(dye_recipes, {"farming:blueberries", "dye:blue 4"})
		table.insert(dye_recipes, {"farming:raspberries", "dye:red 4"})
		table.insert(dye_recipes, {"farming:blackberry", "dye:violet 4"})
		-- Himalayan rhubarb root can give yellow dye IRL
		table.insert(dye_recipes, {"farming:rhubarb", "dye:yellow 4"})
		-- https://pubmed.ncbi.nlm.nih.gov/25401128
		-- Biobleaching of industrial important dyes with peroxidase partially purified from garlic
		table.insert(dye_recipes, {"farming:garlic", "dye:white 2"})
	end

	if minetest.get_modpath("ethereal") then
		table.insert(dye_recipes, {"ethereal:seaweed", "dye:dark_green 6"})
		table.insert(dye_recipes, {"ethereal:coral2", "dye:cyan 6"})
		table.insert(dye_recipes, {"ethereal:coral3", "dye:orange 6"})
		table.insert(dye_recipes, {"ethereal:coral4", "dye:pink 6"})
		table.insert(dye_recipes, {"ethereal:coral5", "dye:green 6"})
		table.insert(dye_recipes, {"ethereal:fern", "dye:dark_green 4"})
		table.insert(dye_recipes, {"ethereal:snowygrass", "dye:grey 4"})
		table.insert(dye_recipes, {"ethereal:crystalgrass", "dye:blue 4"})
	end

	if minetest.get_modpath("bakedclay") then
		table.insert(dye_recipes, {"bakedclay:delphinium", "dye:cyan 8"})
		table.insert(dye_recipes, {"bakedclay:thistle", "dye:magenta 8"})
		table.insert(dye_recipes, {"bakedclay:lazarus", "dye:pink 8"})
		table.insert(dye_recipes, {"bakedclay:mannagrass", "dye:dark_green 8"})
	end


	if minetest.get_modpath("bonemeal") then
		table.insert(dye_recipes, {"bonemeal:bone", "dye:white 8"})
		table.insert(dye_recipes, {"bonemeal:bonemeal", "dye:white 4"})
	end

	for _, data in ipairs(dye_recipes) do
		technic.register_extractor_recipe({input = {data[1]}, output = data[2]})
	end

	-- overwrite the existing crafting recipes
	local dyes = {"white", "red", "yellow", "blue", "violet", "orange"}
	for _, color in ipairs(dyes) do
		minetest.clear_craft({
			recipe = {
				{"group:flower,color_"..color}
			},
		})
		minetest.register_craft({
			output = "dye:"..color.." 1",
			recipe = {
				{"group:flower,color_"..color}
			},
		})
	end

	minetest.clear_craft({
		recipe = {
			{"group:coal"}
		},
	})
	minetest.register_craft({
		output = "dye:black 1",
		recipe = {
			{"group:coal"}
		},
	})

	if unifieddyes then
		minetest.clear_craft({
			recipe = {
				{"default:cactus"}
			},
		})
		minetest.register_craft({
			output = "dye:green 1",
			recipe = {
				{"default:cactus"}
			},
		})
	end
end
