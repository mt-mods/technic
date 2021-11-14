--[[
supported_nodes
This table stores all nodes that are compatible with the wrench mod.
Syntax:
	[<node name>] = {
		lists = {"<inventory list name>"},
		metas = {["<meta name>"] = STRING,
			["<meta name>"] = INT,
			["<meta name>"] = FLOAT},
		owned = true,
		store_meta_always = true,
	}
	owned - nodes that are protected by owner requirements (Ex. locked chests)
	store_meta_always - when nodes are broken this ensures metadata and
	inventory is always stored (Ex. active state for machines)
--]]

wrench.META_TYPE_FLOAT = 1
wrench.META_TYPE_STRING = 2
wrench.META_TYPE_INT = 3

function wrench:original_name(name)
	for key, value in pairs(self.registered_nodes) do
		if name == value.name then
			return key
		end
	end
end

function wrench:register_node(name, def)
	assert(type(name) == "string", "wrench:register_node invalid type for name")
	assert(type(def) == "table", "wrench:register_node invalid type for def")
	if minetest.registered_nodes[name] then
	    self.registered_nodes[name] = def
	else
		minetest.log("warning", "Attempt to register unknown node for wrench: "..tostring(name))
	end
end
