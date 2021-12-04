
-- Register nodes from default / minetest_game

wrench:register_node("default:chest", {
	lists = {"main"},
})

wrench:register_node("default:chest_locked", {
	lists = {"main"},
	metas = {
		owner = wrench.META_TYPE_STRING,
		infotext = wrench.META_TYPE_STRING
	},
	owned = true,
})

wrench:register_node("default:furnace", {
	lists = {"fuel", "src", "dst"},
	metas = {
		infotext = wrench.META_TYPE_STRING,
		fuel_totaltime = wrench.META_TYPE_FLOAT,
		fuel_time = wrench.META_TYPE_FLOAT,
		src_totaltime = wrench.META_TYPE_FLOAT,
		src_time = wrench.META_TYPE_FLOAT
	},
})

wrench:register_node("default:furnace_active", {
	lists = {"fuel", "src", "dst"},
	metas = {
		infotext = wrench.META_TYPE_STRING,
		fuel_totaltime = wrench.META_TYPE_FLOAT,
		fuel_time = wrench.META_TYPE_FLOAT,
		src_totaltime = wrench.META_TYPE_FLOAT,
		src_time = wrench.META_TYPE_FLOAT
	},
	store_meta_always = true,
})

local function get_sign_description(pos, meta, node)
	local desc = minetest.registered_nodes[node.name].description
	local text = meta:get_string("text")
	if #text > 32 then
		text = text:sub(1, 24).."..."
	end
	return string.format("%s with text \"%s\"", desc, text)
end

wrench:register_node("default:sign_wall_wood", {
	metas = {
		infotext = wrench.META_TYPE_STRING,
		text = wrench.META_TYPE_STRING
	},
	description = get_sign_description,
})

wrench:register_node("default:sign_wall_steel", {
	metas = {
		infotext = wrench.META_TYPE_STRING,
		text = wrench.META_TYPE_STRING
	},
	description = get_sign_description,
})
