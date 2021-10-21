-- HV compressor
local S = technic.getter

minetest.register_craft({
	output = 'technic:hv_compressor',
	recipe = {
		{'technic:carbon_plate',          'technic:mv_compressor',   'technic:composite_plate'},
		{'pipeworks:tube_1',              'technic:hv_transformer', 'pipeworks:tube_1'},
		{'technic:stainless_steel_ingot', 'technic:hv_cable',       'technic:stainless_steel_ingot'},
	}
})

technic.register_base_machine("technic:hv_compressor", {
	typename = "compressing",
	description = S("%s Compressor"),
	tier = "HV",
	demand = {1500, 1000, 750},
	speed = 5,
	upgrade = 1,
	tube = 1
})
