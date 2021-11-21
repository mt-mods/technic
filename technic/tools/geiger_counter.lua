
local S = technic.getter

local geiger_counter_max_charge = 30000
technic.register_power_tool("technic:geiger_counter", geiger_counter_max_charge)

minetest.register_tool("technic:geiger_counter", {
	description = S("Geiger counter"),
	inventory_image = "technic_geiger_counter.png",
	stack_max = 1,
	wear_represents = "technic_RE_charge",
	on_refill = technic.refill_RE_charge,
})

minetest.register_craft({
	output = "technic:geiger_counter",
	recipe = {
		{"technic:rubber", "default:glass", "technic:rubber"},
		{"technic:hv_transformer", "technic:battery", "technic:hv_transformer"},
		{"", "technic:battery", ""}
	}
})
