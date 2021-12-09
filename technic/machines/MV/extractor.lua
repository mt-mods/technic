-- MV extractor
local S = technic.getter

minetest.register_craft({
	output = 'technic:mv_extractor',
	recipe = {
		{'technic:stainless_steel_ingot', 'technic:lv_extractor',   'technic:stainless_steel_ingot'},
		{'pipeworks:tube_1',              'technic:mv_transformer', 'pipeworks:tube_1'},
		{'technic:stainless_steel_ingot', 'technic:mv_cable',       'technic:stainless_steel_ingot'},
	}
})

technic.register_base_machine("technic:mv_extractor", {
	typename = "extracting",
	description = S("@1 Extractor", S("MV")),
	tier = "MV",
	demand = {800, 600, 400},
	speed = 2,
	upgrade = 1,
	tube = 1
})
