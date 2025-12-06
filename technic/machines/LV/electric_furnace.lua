-- LV Electric Furnace
-- This is a faster version of the stone furnace which runs on EUs
local S = technic.getter
local mat = xcompat.materials

-- FIXME: kpoppel I'd like to introduce an induction heating element here also
minetest.register_craft({
	output = 'technic:lv_electric_furnace',
	recipe = {
		{mat.cobble, mat.cobble,         mat.cobble},
		{mat.cobble, 'technic:machine_casing', mat.cobble},
		{mat.cobble, 'technic:lv_cable',       mat.cobble},
	}
})

technic.register_base_machine("technic:lv_electric_furnace", {
	typename = "cooking",
	description = S("@1 Furnace", S("LV")),
	tier="LV",
	demand={300},
	speed = 2
})
