
local world = {
	{{x=100,y=100,z=100}, "technic:lv_cable"},
	{{x=101,y=100,z=100}, "technic:lv_cable"},
	{{x=102,y=100,z=100}, "technic:lv_cable"},
	{{x=103,y=100,z=100}, "technic:lv_cable"},
	{{x=100,y=101,z=100}, "technic:switching_station"},

	{{x=100,y=200,z=100}, "technic:mv_cable"},
	{{x=101,y=200,z=100}, "technic:mv_cable"},
	{{x=102,y=200,z=100}, "technic:mv_cable"},
	{{x=103,y=200,z=100}, "technic:mv_cable"},
	{{x=100,y=201,z=100}, "technic:switching_station"},

	{{x=100,y=300,z=100}, "technic:hv_cable"},
	{{x=101,y=300,z=100}, "technic:hv_cable"},
	{{x=102,y=300,z=100}, "technic:hv_cable"},
	{{x=103,y=300,z=100}, "technic:hv_cable"},
	{{x=100,y=301,z=100}, "technic:switching_station"},
}

-- Build world for tests
for _,node in ipairs(world) do
	_G.world.set_node(node[1], {name=node[2], param2=0})
end

_G.technic = {}
_G.technic.S = string.format
_G.technic.getter = function(...) return "" end

sourcefile("register")

sourcefile("machines/register/cables")

sourcefile("machines/LV/cables")
sourcefile("machines/MV/cables")
sourcefile("machines/HV/cables")
