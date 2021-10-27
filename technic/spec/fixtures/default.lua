
local function register_node(name)
	minetest.register_node(":default:"..name, {
		description = name.." description",
		tiles = { "default_"..name },
		groups = {snappy=2, choppy=2, oddly_breakable_by_hand=2},
	})
end

local function register_item(name)
	minetest.register_craftitem(":default:"..name, {
		description = name.." description",
	})
end

register_node("furnace")
register_node("stone")
register_node("cobble")
register_node("sand")
register_node("sandstone")
register_node("wood")
register_node("steelblock")

register_item("steel_ingot")
