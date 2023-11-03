-- MV freezer
local S = technic.getter

minetest.register_craft({
	output = 'technic:mv_freezer',
	recipe = {
		{'technic:stainless_steel_ingot', 'basic_materials:motor',          'technic:stainless_steel_ingot'},
		{'pipeworks:pipe_1_empty',        'technic:mv_transformer', 'pipeworks:pipe_1_empty'},
		{'technic:stainless_steel_ingot', 'technic:mv_cable',       'technic:stainless_steel_ingot'},
	}
})

technic.register_base_machine("technic:mv_freezer", {
	typename = "freezing",
	description = S("@1 Freezer", S("MV")),
	tier = "MV",
	demand = {800, 600, 400},
	speed = 0.5,
	upgrade = 1,
	tube = 1
})
