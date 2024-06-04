
-- check if all required nodenames are registered
mtt.validate_nodenames(minetest.get_modpath("technic").."/registered_nodes.txt")

-- test mapgen
mtt.emerge_area({x=0, y=0, z=0}, {x=48, y=48, z=48})

mtt.register("technic.max_lag", function(callback)
	local lag = technic.get_max_lag()
	assert(lag ~= nil and lag > 0)
	callback()
end)