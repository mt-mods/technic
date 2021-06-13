
mineunit:set_modpath("technic", "../technic")

_G.technic = {
	modpath = minetest.get_modpath("technic"),
	digilines = {
		rules = {
			-- digilines.rules.default
			{x= 1,y= 0,z= 0},{x=-1,y= 0,z= 0}, -- along x beside
			{x= 0,y= 0,z= 1},{x= 0,y= 0,z=-1}, -- along z beside
			{x= 1,y= 1,z= 0},{x=-1,y= 1,z= 0}, -- 1 node above along x diagonal
			{x= 0,y= 1,z= 1},{x= 0,y= 1,z=-1}, -- 1 node above along z diagonal
			{x= 1,y=-1,z= 0},{x=-1,y=-1,z= 0}, -- 1 node below along x diagonal
			{x= 0,y=-1,z= 1},{x= 0,y=-1,z=-1}, -- 1 node below along z diagonal
			-- added rules for digi cable
			{x =  0, y = -1, z = 0}, -- along y below
		}
	}
}

mineunit:set_current_modname("technic")

sourcefile("../technic/config")
sourcefile("../technic/helpers")
sourcefile("../technic/register")
sourcefile("../technic/machines/register/common")

mineunit:restore_current_modname()
