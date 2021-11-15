-- MV grinder
local S = technic.getter

minetest.register_craft({
	output = 'technic:mv_grinder',
	recipe = {
		{'technic:stainless_steel_ingot', 'technic:lv_grinder',     'technic:stainless_steel_ingot'},
		{'pipeworks:tube_1',              'technic:mv_transformer', 'pipeworks:tube_1'},
		{'technic:stainless_steel_ingot', 'technic:mv_cable',       'technic:stainless_steel_ingot'},
	}
})

technic.register_base_machine("technic:mv_grinder", {
	typename = "grinding",
	description = S("%s Grinder"),
	tier="MV",
	demand={600, 450, 300},
	speed=2,
	upgrade=1,
	tube=1
})
