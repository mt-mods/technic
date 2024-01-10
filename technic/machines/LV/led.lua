
-- LED - a weak light source.
-- Intended primarily as a core component for LED lamps.

local S = technic.getter

local demand = 5
local desc = S("@1 LED", S("LV"))
local active_desc = S("@1 Active", desc).."\n"..S("Demand: @1", technic.EU_string(demand))
local unpowered_desc = S("@1 Unpowered", desc)


local function led_run(pos, node)
	local meta = minetest.get_meta(pos)
	local eu_input = meta:get_int("LV_EU_input")

	if eu_input < demand and node.name == "technic:lv_led_active" then
		technic.swap_node(pos, "technic:lv_led")
		meta:set_string("infotext", unpowered_desc)
	elseif eu_input >= demand and node.name == "technic:lv_led" then
		technic.swap_node(pos, "technic:lv_led_active")
		meta:set_string("infotext", active_desc)
	end
end

minetest.register_node("technic:lv_led", {
	description = desc,
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {0.2, 0.2, 0.2, -0.2, -0.2, -0.2}
	},
	collision_box = {
		type = "fixed",
		fixed = {0.2, 0.2, 0.2, -0.2, -0.2, -0.2}
	},
	selection_box = {
		type = "fixed",
		fixed = {0.2, 0.2, 0.2, -0.2, -0.2, -0.2}
	},
	tiles = {"technic_lv_led.png"},
	inventory_image = "technic_lv_led_inv.png",
	sunlight_propagates = true,
	groups = {cracky = 2, technic_machine = 1, technic_lv = 1, pickaxey = 2},
	_mcl_blast_resistance = 1,
	_mcl_hardness = 0.8,
	connect_sides = {"front", "back", "left", "right", "top", "bottom"},
	can_dig = technic.machine_can_dig,
	technic_run = led_run,
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("infotext", desc)
		meta:set_int("LV_EU_demand", demand)
	end,
})

minetest.register_node("technic:lv_led_active", {
	description = active_desc,
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {0.2, 0.2, 0.2, -0.2, -0.2, -0.2}
	},
	collision_box = {
		type = "fixed",
		fixed = {0.2, 0.2, 0.2, -0.2, -0.2, -0.2}
	},
	selection_box = {
		type = "fixed",
		fixed = {0.2, 0.2, 0.2, -0.2, -0.2, -0.2}
	},
	tiles = {"technic_lv_led.png"},
	inventory_image = "technic_lv_led_inv.png",
	paramtype = "light",
	light_source = 9,
	drop = "technic:lv_led",
	sunlight_propagates = true,
	groups = {cracky = 2, technic_machine = 1, technic_lv = 1, not_in_creative_inventory = 1, pickaxey = 2},
	_mcl_blast_resistance = 1,
	_mcl_hardness = 0.8,
	connect_sides = {"front", "back", "left", "right", "top", "bottom"},
	can_dig = technic.machine_can_dig,
	technic_run = led_run,
	technic_on_disable = function(pos)
		technic.swap_node(pos, "technic:lv_led")
	end,
})

technic.register_machine("LV", "technic:lv_led", technic.receiver)
technic.register_machine("LV", "technic:lv_led_active", technic.receiver)

minetest.register_craft({
	output = "technic:lv_led 2",
	recipe = {
		{"", "basic_materials:plastic_sheet", ""},
		{"basic_materials:plastic_sheet", "technic:doped_silicon_wafer", "basic_materials:plastic_sheet"},
		{"", "basic_materials:silver_wire", ""},
	},
	replacements = {{"basic_materials:silver_wire", "basic_materials:empty_spool"}},
})
