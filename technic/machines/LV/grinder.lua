local S = technic.getter

minetest.register_alias("grinder", "technic:lv_grinder")
minetest.register_craft({
	output = 'technic:lv_grinder',
	recipe = {
		{'default:desert_stone', 'default:diamond',        'default:desert_stone'},
		{'default:desert_stone', 'technic:machine_casing', 'default:desert_stone'},
		{'technic:granite',      'technic:lv_cable',       'technic:granite'},
	}
})

technic.register_base_machine("technic:lv_grinder", {
	typename = "grinding",
	description = S("@1 Grinder", S("LV")),
	tier="LV",
	demand={200},
	speed=1
})
