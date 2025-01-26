
-- Do not use this fixture when loading full Technic mod.
-- This is made available to allow loading only small part of mod, specifically network core.

-- Load modules required by tests
mineunit("core")
mineunit("player")
mineunit("protection")

-- Load fixtures required by tests
fixture("default")
fixture("pipeworks")

_G.technic = {}
_G.technic.S = string.format
_G.technic.modpath = "."
_G.technic.getter = function(...) return "" end
_G.technic.get_or_load_node = core.get_node
_G.technic.digilines = {
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
_G.technic.sounds = setmetatable({}, {
	__index = function(...) return function(...) return "" end end,
})

sourcefile("config")
sourcefile("materials")
sourcefile("register")
technic.register_tier("LV", "Busted LV")
technic.register_tier("MV", "Busted MV")
technic.register_tier("HV", "Busted HV")

sourcefile("machines/network")
sourcefile("machines/overload")

sourcefile("machines/register/cables")
sourcefile("machines/LV/cables")
sourcefile("machines/MV/cables")
sourcefile("machines/HV/cables")

function get_network_fixture(sw_pos)
	-- Build network
	local net_id = technic.create_network(sw_pos)
	assert.is_number(net_id)
	local net = technic.networks[net_id]
	assert.is_table(net)
	return net
end
