local S = technic.getter
local mat = technic.materials

core.register_alias("grinder", "technic:lv_grinder")
core.register_craft({
	output = 'technic:lv_grinder',
	recipe = {
		{mat.desert_stone, mat.diamond, mat.desert_stone},
		{mat.desert_stone, 'technic:machine_casing', mat.desert_stone},
		{'technic:granite', 'technic:lv_cable', 'technic:granite'},
	}
})

technic.register_base_machine("technic:lv_grinder", {
	typename = "grinding",
	description = S("@1 Grinder", S("LV")),
	tier="LV",
	demand={200},
	speed=1
})
