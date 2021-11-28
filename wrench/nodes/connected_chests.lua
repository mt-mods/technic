
-- Register wrench support for connected_chests

wrench.register_node("default:chest_connected_left", {
	lists = {"main"},
})

wrench.register_node("default:chest_connected_right", {
	lists = {"main"},
})

wrench.register_node("default:chest_locked_connected_left", {
	lists = {"main"},
        metas = {
                owner = wrench.META_TYPE_STRING,
                infotext = wrench.META_TYPE_STRING
        },
        owned = true,
})

wrench.register_node("default:chest_locked_connected_right", {
	lists = {"main"},
        metas = {
                owner = wrench.META_TYPE_STRING,
                infotext = wrench.META_TYPE_STRING
        },
        owned = true,

})
