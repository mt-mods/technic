-- The electric generator.
-- A simple device to get started on the electric machines.
-- Inefficient and expensive in fuel (200EU per tick)
-- Also only allows for LV machinery to run.

local mat = technic.materials

core.register_alias("lv_generator", "technic:lv_generator")

core.register_craft({
	output = 'technic:lv_generator',
	recipe = {
		{mat.stone, mat.furnace,        mat.stone},
		{mat.stone, 'technic:machine_casing', mat.stone},
		{mat.stone, 'technic:lv_cable',       mat.stone},
	}
})

technic.register_generator({tier="LV", supply=200})

