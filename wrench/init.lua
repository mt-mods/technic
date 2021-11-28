
local modpath = minetest.get_modpath("wrench")

wrench = {
	registered_nodes = {},
	blacklisted_items = {},
	META_TYPE_FLOAT = 1,
	META_TYPE_STRING = 2,
	META_TYPE_INT = 3,
}

dofile(modpath.."/legacy.lua")
dofile(modpath.."/functions.lua")
dofile(modpath.."/tool.lua")

function wrench.register_node(name, def)
	assert(type(name) == "string", "wrench.register_node invalid type for name")
	assert(type(def) == "table", "wrench.register_node invalid type for def")
	local node_def = minetest.registered_nodes[name]
	if node_def then
		wrench.registered_nodes[name] = table.copy(def)
		local old_after_place = node_def.after_place_node
		minetest.override_item(name, {
			after_place_node = function(...)
				if not wrench.restore_node(...) and old_after_place then
					return old_after_place(...)
				end
			end
		})
	else
		minetest.log("warning", "Attempt to register unknown node for wrench: "..name)
	end
end

function wrench.blacklist_item(name)
	assert(type(name) == "string", "wrench:blacklist_item invalid type for name")
	local node_def = minetest.registered_items[name]
	if node_def then
		wrench.blacklisted_items[name] = true
	else
		minetest.log("warning", "Attempt to blacklist unknown item for wrench: "..name)
	end
end

local mods = {
	"connected_chests",
	"default",
	"digtron",
	"drawers",
	"technic",
	"technic_chests",
	"technic_cnc",
}

for _, modname in pairs(mods) do
	if minetest.get_modpath(modname) then
		dofile(modpath.."/nodes/"..modname..".lua")
	end
end
