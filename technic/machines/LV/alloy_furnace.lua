-- LV Alloy furnace
local S = technic.getter
local mat = xcompat.materials

-- FIXME: kpoppel: I'd like to introduce an induction heating element here...
minetest.register_craft({
	output = 'technic:lv_alloy_furnace',
	recipe = {
		{mat.brick, mat.brick,          mat.brick},
		{mat.brick, 'technic:machine_casing', mat.brick},
		{mat.brick, 'technic:lv_cable',       mat.brick},
	}
})

technic.register_base_machine("technic:lv_alloy_furnace", {
	typename = "alloy",
	description = S("@1 Alloy Furnace", S("LV")),
	insert_object = technic.insert_object_unique_stack,
	can_insert = technic.can_insert_unique_stack,
	tier = "LV",
	speed = 1,
	demand = {300}
})
