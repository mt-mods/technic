
fixture("minetest")

_G.ProtectedPos = function()
	return { x = 123, y = 123, z = 123 }
end

_G.UnprotectedPos = function()
	return { x = -123, y = -123, z = -123 }
end

minetest.is_protected = function(pos, name)
	return pos.x == 123 and pos.y == 123 and pos.z == 123
end

minetest.record_protection_violation = function(pos, name)
	-- noop
end
