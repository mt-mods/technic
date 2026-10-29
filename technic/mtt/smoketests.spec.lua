-- smoke tests

-- check if all required nodenames are registered
mtt.validate_nodenames(core.get_modpath("technic").."/registered_nodes.txt")

-- test mapgen
mtt.emerge_area({x=0, y=0, z=0}, {x=48, y=48, z=48})
