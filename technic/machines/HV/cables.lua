local S = technic.getter

minetest.register_craft({
	output = 'technic:hv_cable 3',
	recipe = {
		{'homedecor:plastic_sheeting', 'homedecor:plastic_sheeting', 'homedecor:plastic_sheeting'},
		{'technic:mv_cable',           'technic:mv_cable',           'technic:mv_cable'},
		{'homedecor:plastic_sheeting', 'homedecor:plastic_sheeting', 'homedecor:plastic_sheeting'},
	}
})

minetest.register_craft({
	output = "technic:hv_cable_plate_1 5",
	recipe = {
		{""                , ""                , "technic:hv_cable"},
		{"technic:hv_cable", "technic:hv_cable", "technic:hv_cable"},
		{""                , ""                , "technic:hv_cable"},
	}
})

minetest.register_craft({
	output = "technic:hv_cable",
	recipe = {{"technic:hv_cable_plate_1"}}
})

-- Register cables

technic.register_cable("technic:hv_cable", {
	tier = "HV",
	size = 3/16,
	description = S("@1 Cable", S("HV"))
})
technic.register_cable_plate("technic:hv_cable_plate", {
	tier = "HV",
	size = 3/16,
	description = S("@1 Cable Plate", S("HV")),
	tiles = {"technic_hv_cable.png"},
})

if minetest.get_modpath("digilines") then
	technic.register_cable("technic:hv_digi_cable", {
		tier = "HV",
		size = 3/16,
		description = S("@1 Digiline Cable", S("HV")),
		digiline = { wire = { rules = technic.digilines.rules_allfaces } }
	})
	technic.register_cable_plate("technic:hv_digi_cable_plate", {
		tier = "HV",
		size = 3/16,
		description = S("@1 Digiline Cable Plate", S("HV")),
		digiline = { wire = { rules = technic.digilines.rules_allfaces } },
		tiles = {"technic_hv_digi_cable.png"}
	})
end
