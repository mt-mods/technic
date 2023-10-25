-- LV Electric Furnace
-- This is a faster version of the stone furnace which runs on EUs
local S = technic.getter

-- FIXME: kpoppel I'd like to introduce an induction heating element here also
minetest.register_craft({
	output = 'technic:electric_furnace',
	recipe = {
		{'group:cobble', 'group:cobble',         'group:cobble'},
		{'group:cobble', 'technic:machine_casing', 'group:cobble'},
		{'group:cobble', 'technic:lv_cable',       'group:cobble'},
	}
})

technic.register_base_machine("technic:lv_electric_furnace", {
	typename = "cooking",
	description = S("@1 Furnace", S("LV")),
	tier="LV",
	demand={300},
	speed = 2
})
