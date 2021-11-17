
local S = rawget(_G, "intllib") and intllib.Getter() or function(s) return s end

local SERIALIZATION_VERSION = 1

local function get_stored_metadata(itemstack)
	local meta = itemstack:get_meta()
	local data = meta:get("data") or meta:get("")
	data = minetest.deserialize(data)
	if not data or not data.version or not data.name then
		return
	end
	return data
end

function wrench.can_pickup_node(pos, player)
	local def = wrench.registered_nodes[minetest.get_node(pos).name]
	if not def then
		return false
	end
	local meta = minetest.get_meta(pos)
	if def.owned and not minetest.check_player_privs(player, "protection_bypass") then
		local owner = meta:get_string("owner")
		if owner ~= "" and owner ~= player:get_player_name() then
			return false, S("Cannot pickup node. Owned by %s"):format(owner)
		end
	end
	if not player:get_inventory():room_for_item("main", "unique_item") then
		return false, S("No room in inventory to pickup node.")
	end
	local inv = meta:get_inventory()
	for _,listname in pairs(def.lists or {}) do
		for _,stack in pairs(inv:get_list(listname) or {}) do
			local item = stack:get_name()
			if wrench.blacklisted_items[item] then
				local desc = minetest.registered_items[item].description
				return false, S("Cannot pickup node containing %s"):format(desc)
			end
			local data = get_stored_metadata(stack)
			if data and data.lists and next(data.lists) ~= nil then
				return false, S("Cannot pickup node. Nesting inventories is not allowed.")
			end
		end
	end
	return true
end

local function get_description(def, pos, meta, node, player)
	local t = type(def.description)
	if t == "string" then
		return def.description
	elseif t == "function" then
		local desc = def.description(pos, meta, node, player)
		if desc then
			return desc
		end
	end
	return S("%s with items"):format(minetest.registered_nodes[node.name].description)
end

function wrench.pickup_node(pos, player)
	local node = minetest.get_node(pos)
	local def = wrench.registered_nodes[node.name]
	if not def then
		return
	end
	local data = {
		name = node.name,
		version = SERIALIZATION_VERSION,
		lists = {},
		metas = {},
	}
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	for _, listname in pairs(def.lists or {}) do
		local list = inv:get_list(listname)
		for i, stack in pairs(list) do
			list[i] = stack:to_string()
		end
		data.lists[listname] = list
	end
	for name, meta_type in pairs(def.metas or {}) do
		if meta_type == wrench.META_TYPE_FLOAT then
			data.metas[name] = meta:get_float(name)
		elseif meta_type == wrench.META_TYPE_STRING then
			data.metas[name] = meta:get_string(name)
		elseif meta_type == wrench.META_TYPE_INT then
			data.metas[name] = meta:get_int(name)
		end
	end
	local stack = ItemStack(node.name)
	local item_meta = stack:get_meta()
	item_meta:set_string("data", minetest.serialize(data))
	item_meta:set_string("description", get_description(def, pos, meta, node, player))
	minetest.remove_node(pos)
	return stack
end

function wrench.restore_node(pos, player, stack)
	local data = get_stored_metadata(stack)
	if not data then
		return
	end
	local def = wrench.registered_nodes[data.name]
	if not def then
		return
	end
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	for listname, list in pairs(data.lists) do
		inv:set_list(listname, list)
	end
	for name, value in pairs(data.metas) do
		local meta_type = def.metas and def.metas[name]
		if meta_type == wrench.META_TYPE_INT then
			meta:set_int(name, value)
		elseif meta_type == wrench.META_TYPE_FLOAT then
			meta:set_float(name, value)
		elseif meta_type == wrench.META_TYPE_STRING then
			meta:set_string(name, value)
		end
	end
	if def.after_place then
		def.after_place(pos, player, stack)
	end
	return true
end
