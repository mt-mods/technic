
local S = minetest.get_translator(minetest.get_current_modname())

local SERIALIZATION_VERSION = 1

local errors = {
	owned = function(owner) return S("Cannot pickup node. Owned by @1.", owner) end,
	full_inv = S("Not enough room in inventory to pickup node."),
	bad_item = function(item) return S("Cannot pickup node containing @1.", item) end,
	nested = S("Cannot pickup node. Nesting inventories is not allowed."),
	metadata = S("Cannot pickup node. Node contains too much metadata."),
}

local function get_stored_metadata(itemstack)
	local meta = itemstack:get_meta()
	local data = meta:get("data") or meta:get("")
	if not data then
		return
	end
	data = minetest.deserialize(data)
	if not data or not data.version or not data.name then
		return
	end
	return data
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
	return S("@1 with items", minetest.registered_nodes[node.name].description)
end

function wrench.pickup_node(pos, player)
	local node = minetest.get_node(pos)
	local def = wrench.registered_nodes[node.name]
	if not def then
		return
	end
	local meta = minetest.get_meta(pos)
	if def.owned and not minetest.check_player_privs(player, "protection_bypass") then
		local owner = meta:get_string("owner")
		if owner ~= "" and owner ~= player:get_player_name() then
			return false, errors.owned(owner)
		end
	end
	local data = {
		name = node.name,
		version = SERIALIZATION_VERSION,
		lists = {},
		metas = {},
	}
	local inv = meta:get_inventory()
	for _, listname in pairs(def.lists or {}) do
		local list = inv:get_list(listname)
		for i, stack in pairs(list) do
			if wrench.blacklisted_items[stack:get_name()] then
				local desc = stack:get_definition().description
				return false, errors.bad_item(desc)
			end
			local sdata = get_stored_metadata(stack)
			if sdata and sdata.lists and next(sdata.lists) ~= nil then
				return false, errors.nested
			end
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
	if #stack:to_string() > 65000 then
		return false, errors.metadata
	end
	local player_inv = player:get_inventory()
	if not player_inv:room_for_item("main", stack) then
		return false, errors.full_inv
	end
	player_inv:add_item("main", stack)
	minetest.remove_node(pos)
	return true
end

function wrench.restore_node(pos, player, stack)
	if not stack then
		return
	end
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
