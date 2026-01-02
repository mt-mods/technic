
core.register_craft({
	output = 'technic:mv_solar_array 1',
	recipe = {
		{'technic:lv_solar_array',     'technic:lv_solar_array', 'technic:lv_solar_array'},
		{'technic:carbon_steel_ingot', 'technic:mv_transformer', 'technic:carbon_steel_ingot'},
		{'',                           'technic:mv_cable',       ''},
	}
})

technic.register_solar_array("technic:mv_solar_array", {
	tier="MV",
	power=30
})

-- compatibility alias for upgrading from old versions of technic
core.register_alias("technic:solar_panel_mv", "technic:mv_solar_array")
core.register_alias("technic:solar_array_mv", "technic:mv_solar_array")
