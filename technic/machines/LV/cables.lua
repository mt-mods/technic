local S = technic.getter

minetest.register_alias("lv_cable", "technic:lv_cable")

minetest.register_craft({
	output = 'technic:lv_cable 6',
	recipe = {
		{'default:paper',        'default:paper',        'default:paper'},
		{'default:copper_ingot', 'default:copper_ingot', 'default:copper_ingot'},
		{'default:paper',        'default:paper',        'default:paper'},
	}
})

minetest.register_craft({
	output = "technic:lv_cable_plate_1 5",
	recipe = {
		{""                , ""                , "technic:lv_cable"},
		{"technic:lv_cable", "technic:lv_cable", "technic:lv_cable"},
		{""                , ""                , "technic:lv_cable"},
	}
})

minetest.register_craft({
	output = "technic:lv_cable",
	recipe = {{"technic:lv_cable_plate_1"}}
})

-- Register cables

technic.register_cable("technic:lv_cable", {
	tier = "LV",
	size = 2/16,
	description = S("%s Cable"):format("LV")
})
technic.register_cable_plate("technic:lv_cable_plate", {
	tier = "LV",
	size = 2/16,
	description = S("%s Cable Plate"):format("LV"),
	tiles = {"technic_lv_cable.png"},
})

if minetest.get_modpath("digilines") then
	technic.register_cable("technic:lv_digi_cable", {
		tier = "LV",
		size = 2/16,
		description = S("%s Digiline Cable"):format("LV"),
		digiline = { wire = { rules = technic.digilines.rules_allfaces } }
	})
	technic.register_cable_plate("technic:lv_digi_cable_plate", {
		tier = "LV",
		size = 2/16,
		description = S("%s Digiline Cable Plate"):format("LV"),
		digiline = { wire = { rules = technic.digilines.rules_allfaces } },
		tiles = {"technic_lv_digi_cable.png"}
	})
end
