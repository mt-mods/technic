
local function register_node(name, additional_groups)
	local groups = {snappy=2, choppy=2, oddly_breakable_by_hand=2}
	for k,v in pairs(additional_groups or {}) do
		groups[k] = v
	end
	minetest.register_node(":default:"..name, {
		description = name.." description",
		tiles = { "default_"..name },
		groups = groups,
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
register_node("wood", {tree=1})
register_node("steelblock")

register_item("steel_ingot")
