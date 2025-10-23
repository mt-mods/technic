
local S = technic.getter
local mat = xcompat.materials

technic.register_recipe_type("freezing", {
	description = S("Freezing"),
	icon = "technic_mv_freezer_front.png",
})

function technic.register_freezer_recipe(data)
	data.time = data.time or 5
	technic.register_recipe("freezing", data)
end

local recipes = {
	{mat.water_bucket, { mat.ice, mat.empty_bucket } },
	{mat.river_water_bucket, { mat.ice, mat.empty_bucket  } },
	{mat.dirt, mat.dirt_with_snow },
	{mat.lava_bucket, { mat.obsidian, mat.empty_bucket  } }
}

for _, data in pairs(recipes) do
	technic.register_freezer_recipe({input = {data[1]}, output = data[2], hidden = true})
end

