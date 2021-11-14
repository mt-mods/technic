
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

wrench:register_node("default:sign_wall", {
	metas = {
		infotext = wrench.META_TYPE_STRING,
		text = wrench.META_TYPE_STRING
	},
})
