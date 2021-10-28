local S = technic.getter

minetest.register_alias("mv_cable", "technic:mv_cable")

minetest.register_craft({
	output = 'technic:mv_cable 3',
	recipe ={
		{'technic:rubber',   'technic:rubber',   'technic:rubber'},
		{'technic:lv_cable', 'technic:lv_cable', 'technic:lv_cable'},
		{'technic:rubber',   'technic:rubber',   'technic:rubber'},
	}
})

minetest.register_craft({
	output = "technic:mv_cable_plate_1 5",
	recipe = {
		{""                , ""                , "technic:mv_cable"},
		{"technic:mv_cable", "technic:mv_cable", "technic:mv_cable"},
		{""                , ""                , "technic:mv_cable"},
	}
})

minetest.register_craft({
	output = "technic:mv_cable",
	recipe = {{"technic:mv_cable_plate_1"}}
})

-- Register cables

technic.register_cable("technic:mv_cable", {
	tier = "MV",
	size = 2.5/16,
	description = S("%s Cable"):format("MV")
})
technic.register_cable_plate("technic:mv_cable_plate", {
	tier = "MV",
	size = 2.5/16,
	description = S("%s Cable Plate"):format("MV"),
	tiles = {"technic_mv_cable.png"},
})

if minetest.get_modpath("digilines") then
	technic.register_cable("technic:mv_digi_cable", {
		tier = "MV",
		size = 2.5/16,
		description = S("%s Digiline Cable"):format("MV"),
		digiline = { wire = { rules = technic.digilines.rules_allfaces } }
	})
	technic.register_cable_plate("technic:mv_digi_cable_plate", {
		tier = "MV",
		size = 2.5/16,
		description = S("%s Digiline Cable Plate"):format("MV"),
		digiline = { wire = { rules = technic.digilines.rules_allfaces } },
		tiles = {"technic_mv_digi_cable.png"}
	})
end
