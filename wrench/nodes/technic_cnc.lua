
-- Register wrench support for Technic CNC

local function register_cnc(name, def)
	wrench:register_node(name, def)
	if minetest.registered_nodes[name.."_active"] then
		-- Only available if technic is active
		wrench:register_node(name.."_active", def)
	end
end

register_cnc("technic:cnc", {
	lists = {"src", "dst"},
	metas = {
		infotext = wrench.META_TYPE_STRING,
		formspec = wrench.META_TYPE_STRING,
		LV_EU_demand = wrench.META_TYPE_INT,
		LV_EU_input = wrench.META_TYPE_INT,
		src_time = wrench.META_TYPE_INT,
		size = wrench.META_TYPE_INT,
		program = wrench.META_TYPE_STRING,
		cnc_user = wrench.META_TYPE_STRING,
	},
})

if minetest.registered_nodes["technic:cnc_mk2"] then
	register_cnc("technic:cnc_mk2", {
		lists = {"src", "dst", "upgrade1", "upgrade2"},
		metas = {
			infotext = wrench.META_TYPE_STRING,
			formspec = wrench.META_TYPE_STRING,
			LV_EU_demand = wrench.META_TYPE_INT,
			LV_EU_input = wrench.META_TYPE_INT,
			src_time = wrench.META_TYPE_INT,
			size = wrench.META_TYPE_INT,
			program = wrench.META_TYPE_STRING,
			cnc_user = wrench.META_TYPE_STRING,
		},
	})
end
