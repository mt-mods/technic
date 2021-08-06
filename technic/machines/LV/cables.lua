
minetest.register_alias("lv_cable", "technic:lv_cable")

minetest.register_craft({
	output = 'technic:lv_cable 6',
	recipe = {
		{'default:paper',        'default:paper',        'default:paper'},
		{'default:copper_ingot', 'default:copper_ingot', 'default:copper_ingot'},
		{'default:paper',        'default:paper',        'default:paper'},
	}
})

technic.register_cable("LV", 2/16)

if minetest.get_modpath("digilines") then

	local S = technic.getter

	technic.register_cable("LV", 2/16, S("LV Cable (digiline)"), "_digi", {
		digiline = {
			wire = {
				rules = {
					{x = 1, y = 0, z = 0},
					{x =-1, y = 0, z = 0},
					{x = 0, y = 1, z = 0},
					{x = 0, y =-1, z = 0},
					{x = 0, y = 0, z = 1},
					{x = 0, y = 0, z =-1}
				}
			}
		}
	})
end
