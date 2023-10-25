-- The electric generator.
-- A simple device to get started on the electric machines.
-- Inefficient and expensive in fuel (200EU per tick)
-- Also only allows for LV machinery to run.

local mat = technic.materials

minetest.register_alias("lv_generator", "technic:lv_generator")

minetest.register_craft({
	output = 'technic:lv_generator',
	recipe = {
		{'group:stone', mat.furnace,        'group:stone'},
		{'group:stone', 'technic:machine_casing', 'group:stone'},
		{'group:stone', 'technic:lv_cable',       'group:stone'},
	}
})

technic.register_generator({tier="LV", supply=200})

