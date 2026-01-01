-- The high voltage solar array is an assembly of medium voltage arrays.
-- Solar arrays are not able to store large amounts of energy.

core.register_craft({
	output = 'technic:hv_solar_array 1',
	recipe = {
		{'technic:mv_solar_array',     'technic:mv_solar_array', 'technic:mv_solar_array'},
		{'technic:carbon_plate',       'technic:hv_transformer', 'technic:composite_plate'},
		{'',                           'technic:hv_cable',       ''},
	}
})

technic.register_solar_array("technic:hv_solar_array", {
	tier="HV",
	power=100
})

core.register_alias("technic:solar_array_hv", "technic:hv_solar_array")
