
minetest.register_alias("mv_cable", "technic:mv_cable")

minetest.register_craft({
	output = 'technic:mv_cable 3',
	recipe ={
		{'technic:rubber',   'technic:rubber',   'technic:rubber'},
		{'technic:lv_cable', 'technic:lv_cable', 'technic:lv_cable'},
		{'technic:rubber',   'technic:rubber',   'technic:rubber'},
	}
})

technic.register_cable("MV", 2.5/16)

if minetest.get_modpath("digilines") then

	local S = technic.getter

	technic.register_cable("MV", 2.5/16, S("MV Cable (digiline)"), "_digi", {
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
