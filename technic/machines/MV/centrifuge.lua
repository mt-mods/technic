local S = technic.getter

core.register_craft({
	output = "technic:mv_centrifuge",
	recipe = {
		{"basic_materials:motor",          "technic:copper_plate",   "technic:diamond_drill_head"},
		{"technic:copper_plate",   "technic:machine_casing", "technic:copper_plate"      },
		{"pipeworks:one_way_tube", "technic:mv_cable",       "pipeworks:mese_filter"     },
	}
})

technic.register_base_machine("technic:mv_centrifuge", {
	typename = "separating",
	description = S("@1 Centrifuge", S("MV")),
	tier = "MV",
	demand = { 8000, 7000, 6000 },
	speed = 2,
	upgrade = 1,
	tube = 1,
})
