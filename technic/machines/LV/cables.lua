local S = technic.getter
local mat = xcompat.materials

minetest.register_alias("lv_cable", "technic:lv_cable")

minetest.register_craft({
	output = 'technic:lv_cable 6',
	recipe = {
		{mat.paper,        mat.paper,        mat.paper},
		{mat.copper_ingot, mat.copper_ingot, mat.copper_ingot},
		{mat.paper,        mat.paper,        mat.paper},
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
	description = S("@1 Cable", S("LV"))
})
technic.register_cable_plate("technic:lv_cable_plate", {
	tier = "LV",
	size = 2/16,
	description = S("@1 Cable Plate", S("LV")),
	tiles = {"technic_lv_cable.png"},
})

if minetest.get_modpath("digilines") then
	technic.register_cable("technic:lv_digi_cable", {
		tier = "LV",
		size = 2/16,
		description = S("@1 Digiline Cable", S("LV")),
		digiline = { wire = { rules = technic.digilines.rules_allfaces } }
	})
	technic.register_cable_plate("technic:lv_digi_cable_plate", {
		tier = "LV",
		size = 2/16,
		description = S("@1 Digiline Cable Plate", S("LV")),
		digiline = { wire = { rules = technic.digilines.rules_allfaces } },
		tiles = {"technic_lv_digi_cable.png"}
	})
end
