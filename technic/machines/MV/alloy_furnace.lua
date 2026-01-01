-- MV alloy furnace
local S = technic.getter

core.register_craft({
	output = 'technic:mv_alloy_furnace',
	recipe = {
		{'technic:stainless_steel_ingot', 'technic:lv_alloy_furnace', 'technic:stainless_steel_ingot'},
		{'pipeworks:tube_1',              'technic:mv_transformer',   'pipeworks:tube_1'},
		{'technic:stainless_steel_ingot', 'technic:mv_cable',         'technic:stainless_steel_ingot'},
	}
})

technic.register_base_machine("technic:mv_alloy_furnace", {
	typename = "alloy",
	description = S("@1 Alloy Furnace", S("MV")),
	insert_object = technic.insert_object_unique_stack,
	can_insert = technic.can_insert_unique_stack,
	tier = "MV",
	speed = 1.5,
	upgrade = 1,
	tube = 1,
	demand = {3000, 2000, 1000}
})
