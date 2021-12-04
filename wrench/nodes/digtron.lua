
-- Register wrench support for digtron

wrench:register_node("digtron:battery_holder", {
	lists = {"batteries"}
})

wrench:register_node("digtron:inventory", {
	lists = {"main"}
})

wrench:register_node("digtron:fuelstore", {
	lists = {"fuel"}
})

wrench:register_node("digtron:combined_storage", {
	lists = {"main", "fuel"}
})

-- Blacklist loaded crates to prevent nesting of inventories

wrench:blacklist_item("digtron:loaded_crate")
wrench:blacklist_item("digtron:loaded_locked_crate")
