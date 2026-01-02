-- MV compressor
local S = technic.getter

core.register_craft({
	output = 'technic:mv_compressor',
	recipe = {
		{'technic:stainless_steel_ingot', 'technic:lv_compressor',  'technic:stainless_steel_ingot'},
		{'pipeworks:tube_1',              'technic:mv_transformer', 'pipeworks:tube_1'},
		{'technic:stainless_steel_ingot', 'technic:mv_cable',       'technic:stainless_steel_ingot'},
	}
})

technic.register_base_machine("technic:mv_compressor", {
	typename = "compressing",
	description = S("@1 Compressor", S("MV")),
	tier = "MV",
	demand = {800, 600, 400},
	speed = 2,
	upgrade = 1,
	tube = 1
})
