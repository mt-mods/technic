
local S = technic.getter
local mat = technic.materials

technic.register_recipe_type("freezing", {
	description = S("Freezing"),
	icon = "technic_mv_freezer_front.png",
})

function technic.register_freezer_recipe(data)
	data.time = data.time or 5
	technic.register_recipe("freezing", data)
end

local recipes = {
	{mat.bucket_water, { mat.ice, mat.bucket_empty } },
	{mat.bucket_river_water, { mat.ice, mat.bucket_empty } },
	{mat.dirt, mat.dirt_with_snow },
	{mat.bucket_lava, { mat.obsidian, mat.bucket_empty } }
}

for _, data in pairs(recipes) do
	technic.register_freezer_recipe({input = {data[1]}, output = data[2]})
end

