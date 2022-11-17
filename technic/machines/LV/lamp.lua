
-- LV Lamp - a powerful light source.
-- Illuminates a 7x7x3(H) volume below itself with light bright as the sun.


local S = technic.getter

local desc = S("@1 Lamp", S("LV"))
local active_desc = S("@1 Active", desc)
local unpowered_desc = S("@1 Unpowered", desc)
local off_desc = S("@1 Off", desc)
local demand = 50


-- Invisible light source node used for illumination
minetest.register_node("technic:dummy_light_source", {
	description = S("Dummy light source node"),
	inventory_image = "technic_dummy_light_source.png",
	wield_image = "technic_dummy_light_source.png",
	paramtype = "light",
	drawtype = "airlike",
	light_source = 14,
	sunlight_propagates = true,
	walkable = false,
	buildable_to = true,
	diggable = false,
	pointable = false,
	--drop = "",  -- Intentionally allowed to drop itself
	groups = {not_in_creative_inventory = 1}
})

local content_id_light_source = minetest.get_content_id("technic:dummy_light_source")
local content_id_air = minetest.CONTENT_AIR

local function illuminate(pos, active)
	local pos1 = {x = pos.x - 3, y = pos.y - 3, z = pos.z - 3}
	local pos2 = {x = pos.x + 3, y = pos.y - 1, z = pos.z + 3}

	-- prepare vmanip, voxel-area and node-data
	local vm = minetest.get_voxel_manip()
	local e1, e2 = vm:read_from_map(pos1, pos2)
	local va = VoxelArea:new({MinEdge = e1, MaxEdge = e2})
	local node_data = vm:get_data()

	-- replacements
	local src_node, dst_node
	if active then
		src_node = content_id_air
		dst_node = content_id_light_source
	else
		src_node = content_id_light_source
		dst_node = content_id_air
	end

	-- dirty/changed flag
	local dirty = false

	for x=pos1.x, pos2.x do
	for y=pos1.y, pos2.y do
	for z=pos1.z, pos2.z do
		local index = va:index(x,y,z)
		if node_data[index] == src_node then
			node_data[index] = dst_node
			dirty = true
		end
	end
	end
	end

	if dirty then
		-- write data back to map if changed
		vm:set_data(node_data)
		vm:write_to_map()
	end
end

local function lamp_run(pos, node)
	local meta = minetest.get_meta(pos)

	if meta:get_int("LV_EU_demand") == 0 then
		return  -- Lamp is turned off
	end

	local eu_input = meta:get_int("LV_EU_input")

	if node.name == "technic:lv_lamp_active" then
		if eu_input < demand then
			technic.swap_node(pos, "technic:lv_lamp")
			meta:set_string("infotext", unpowered_desc)
			illuminate(pos, false)
		else
			illuminate(pos, true)
		end
	elseif node.name == "technic:lv_lamp" then
		if eu_input >= demand then
			technic.swap_node(pos, "technic:lv_lamp_active")
			meta:set_string("infotext", active_desc)
			illuminate(pos, true)
		end
	end
end

local function lamp_toggle(pos, node, player)
	if not player or minetest.is_protected(pos, player:get_player_name()) then
		return
	end
	local meta = minetest.get_meta(pos)
	if meta:get_int("LV_EU_demand") == 0 then
		meta:set_string("infotext", active_desc)
		meta:set_int("LV_EU_demand", demand)
	else
		illuminate(pos, false)
		technic.swap_node(pos, "technic:lv_lamp")
		meta:set_string("infotext", off_desc)
		meta:set_int("LV_EU_demand", 0)
	end
end

minetest.register_node("technic:lv_lamp", {
	description = desc,
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {0.5,0.5,0.5,-0.5,-0.2,-0.5}
	},
	collision_box = {
		type = "fixed",
		fixed = {0.5,0.5,0.5,-0.5,-0.2,-0.5}
	},
	selection_box = {
		type = "fixed",
		fixed = {0.5,0.5,0.5,-0.5,-0.2,-0.5}
	},
	tiles = {
		"technic_lv_lamp_top.png",
		"technic_lv_lamp_bottom.png",
		"technic_lv_lamp_side.png",
		"technic_lv_lamp_side.png",
		"technic_lv_lamp_side.png",
		"technic_lv_lamp_side.png"
	},
	groups = {cracky = 2, technic_machine = 1, technic_lv = 1},
	connect_sides = {"front", "back", "left", "right", "top"},
	can_dig = technic.machine_can_dig,
	technic_run = lamp_run,
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("infotext", desc)
		meta:set_int("LV_EU_demand", demand)
	end,
	on_destruct = illuminate,
	on_rightclick = lamp_toggle
})

minetest.register_node("technic:lv_lamp_active", {
	description = active_desc,
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {0.5, 0.5, 0.5, -0.5, -0.2, -0.5}
	},
	collision_box = {
		type = "fixed",
		fixed = {0.5, 0.5, 0.5, -0.5, -0.2, -0.5}
	},
	selection_box = {
		type = "fixed",
		fixed = {0.5, 0.5, 0.5, -0.5, -0.2, -0.5}
	},
	tiles = {
		"technic_lv_lamp_top.png",
		"technic_lv_lamp_bottom.png",
		"technic_lv_lamp_side.png",
		"technic_lv_lamp_side.png",
		"technic_lv_lamp_side.png",
		"technic_lv_lamp_side.png"
	},
	paramtype = "light",
	light_source = 14,
	drop = "technic:lv_lamp",
	groups = {cracky = 2, technic_machine = 1, technic_lv = 1, not_in_creative_inventory = 1},
	connect_sides = {"front", "back", "left", "right", "top"},
	can_dig = technic.machine_can_dig,
	technic_run = lamp_run,
	technic_on_disable = function(pos)
		illuminate(pos, false)
		technic.swap_node(pos, "technic:lv_lamp")
	end,
	on_destruct = illuminate,
	on_rightclick = lamp_toggle,
})

technic.register_machine("LV", "technic:lv_lamp", technic.receiver)
technic.register_machine("LV", "technic:lv_lamp_active", technic.receiver)

minetest.register_craft({
	output = "technic:lv_lamp",
	recipe = {
		{"default:glass", "default:glass", "default:glass"},
		{"technic:lv_led", "technic:lv_led", "technic:lv_led"},
		{"mesecons_materials:glue", "technic:lv_cable", "mesecons_materials:glue"},
	}
})
