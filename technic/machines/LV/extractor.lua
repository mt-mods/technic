local S = technic.getter

minetest.register_alias("extractor", "technic:lv_extractor")

if technic.config:get_bool("enable_tree_tap") then

	minetest.register_craft({
		output = 'technic:lv_extractor',
		recipe = {
			{'technic:treetap', 'basic_materials:motor',          'technic:treetap'},
			{'technic:treetap', 'technic:machine_casing', 'technic:treetap'},
			{'',                'technic:lv_cable',       ''},
		}
	})

else

	minetest.register_craft({
		output = 'technic:lv_extractor',
		recipe = {
			{'basic_materials:motor', 'pipeworks:tube_1', 'basic_materials:motor'},
			{'technic:carbon_steel_ingot', 'technic:machine_casing', 'technic:carbon_steel_ingot'},
			{'', 'technic:lv_cable', ''},
		}
	})

end

technic.register_base_machine("technic:lv_extractor", {
	typename = "extracting",
	description = S("%s Extractor"),
	tier = "LV",
	demand = {300},
	speed = 1
})
