local S = technic.getter
local mat = technic.materials

technic.register_recipe_type("separating", {
	description = S("Separating"),
	icon = "technic_mv_centrifuge_front.png",
	output_size = 4,
})

function technic.register_separating_recipe(data)
	data.time = data.time or 10
	technic.register_recipe("separating", data)
end

local recipes = {
	{ "technic:bronze_dust 8",             "technic:copper_dust 7",       "technic:tin_dust"      },
	{ "technic:stainless_steel_dust 5",    "technic:wrought_iron_dust 4", "technic:chromium_dust" },
	{ "technic:brass_dust 3",              "technic:copper_dust 2",       "technic:zinc_dust"     },
	{ "technic:chernobylite_dust",         mat.sand,                "technic:uranium3_dust" },
	{ mat.dirt.." 4",                    mat.sand,                mat.gravel,       mat.clay_lump.." 4" },
}

local function uranium_dust(p)
	return "technic:uranium"..(p == 7 and "" or p).."_dust"
end
for p = 1, 34 do
	table.insert(recipes, { uranium_dust(p).." 2", uranium_dust(p-1), uranium_dust(p+1) })
end

if core.get_modpath("bushes_classic") then
	for _, berry in ipairs({ "blackberry", "blueberry", "gooseberry", "raspberry", "strawberry" }) do
		table.insert(recipes, { "bushes:"..berry.."_bush", mat.stick.." 20", "bushes:"..berry.." 4" })
	end
end

if core.get_modpath("farming") or core.get_modpath("mcl_farming") then
	if core.get_modpath("cottages") then
		-- work as a mechanized threshing floor
		table.insert(recipes, { "farming:wheat", "farming:seed_wheat", "cottages:straw_mat" })
		table.insert(recipes, { "farming:barley", "farming:seed_barley", "cottages:straw_mat" })
	else
		-- work in a less fancy and less efficient manner
		table.insert(recipes, { mat.wheat.." 4", mat.seed_wheat.." 3", mat.dry_shrub })
		table.insert(recipes, { "farming:barley 4", "farming:seed_barley 3", mat.dry_shrub })
	end
end

for _, data in pairs(recipes) do
	technic.register_separating_recipe({ input = { data[1] }, output = { data[2], data[3], data[4] } })
end
