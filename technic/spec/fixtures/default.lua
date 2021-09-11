
-- Screwdriver is listed as optional but mod crashes without it
_G.screwdriver = {}

local function register_default(name, def)
	def = def or {}
	def.description = def.description or (name.." description")
	minetest.register_node(":default:"..name, def)
end

register_default("furnace")
register_default("sand")
register_default("sandstone")
register_default("steelblock")
register_default("steel_ingot")
