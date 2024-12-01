
-- LV Lamp - a powerful light source.
-- Illuminates a 7x7x3(H) volume below itself with light bright as the sun.

local S = technic.getter
local mat = xcompat.materials

local demand = 50
local desc = S("@1 Lamp", S("LV"))
local active_desc = S("@1 Active", desc).."\n"..S("Demand: @1", technic.EU_string(demand))
local unpowered_desc = S("@1 Unpowered", desc)
local off_desc = S("@1 Off", desc)

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

local cid_light = minetest.get_content_id("technic:dummy_light_source")
local cid_air = minetest.CONTENT_AIR

local function illuminate(pos, active)
	local pos1 = {x = pos.x - 3, y = pos.y - 3, z = pos.z - 3}
	local pos2 = {x = pos.x + 3, y = pos.y - 1, z = pos.z + 3}

	local vm = minetest.get_voxel_manip()
	local emin, emax = vm:read_from_map(pos1, pos2)
	local va = VoxelArea:new({MinEdge = emin, MaxEdge = emax})
	local node_data = vm:get_data()

	local find_node = active and cid_air or cid_light
	local set_node = active and cid_light or cid_air

	local dirty = false
	for i in va:iterp(pos1, pos2) do
		if node_data[i] == find_node then
			node_data[i] = set_node
			dirty = true
		end
	end
	if dirty then
		vm:set_data(node_data)
		vm:write_to_map()
	end
end

local function set_random_timer(pos, mint, maxt)
	local t = math.random(mint * 10, maxt * 10) * 0.1
	minetest.get_node_timer(pos):start(t)
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
			set_random_timer(pos, 0.2, 1)
		end
	elseif node.name == "technic:lv_lamp" then
		if eu_input >= demand then
			technic.swap_node(pos, "technic:lv_lamp_active")
			meta:set_string("infotext", active_desc)
			set_random_timer(pos, 0.2, 2)
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
		technic.swap_node(pos, "technic:lv_lamp")
		meta:set_string("infotext", off_desc)
		meta:set_int("LV_EU_demand", 0)
		set_random_timer(pos, 0.2, 1)
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
	groups = {cracky = 2, technic_machine = 1, technic_lv = 1, pickaxey = 2},
	is_ground_content = false,
	_mcl_blast_resistance = 1,
	_mcl_hardness = 0.8,
	connect_sides = {"front", "back", "left", "right", "top"},
	can_dig = technic.machine_can_dig,
	technic_run = lamp_run,
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("infotext", desc)
		meta:set_int("LV_EU_demand", demand)
	end,
	on_destruct = illuminate,
	on_rightclick = lamp_toggle,
	on_timer = function(pos)
		illuminate(pos, false)
		-- Don't start the timer again, otherwise lights will fight each other
	end,
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
	groups = {cracky = 2, technic_machine = 1, technic_lv = 1, not_in_creative_inventory = 1, pickaxey = 2},
	is_ground_content = false,
	_mcl_blast_resistance = 1,
	_mcl_hardness = 0.8,
	connect_sides = {"front", "back", "left", "right", "top"},
	can_dig = technic.machine_can_dig,
	technic_run = lamp_run,
	technic_on_disable = function(pos)
		technic.swap_node(pos, "technic:lv_lamp")
		set_random_timer(pos, 0.2, 1)
	end,
	on_destruct = illuminate,
	on_rightclick = lamp_toggle,
	on_timer = function(pos, elapsed)
		if elapsed < 60 then  -- Don't check immediately after being unloaded
			illuminate(pos, true)
		end
		set_random_timer(pos, 30, 60)  -- Check every 30-60 seconds
	end,
})

technic.register_machine("LV", "technic:lv_lamp", technic.receiver)
technic.register_machine("LV", "technic:lv_lamp_active", technic.receiver)

minetest.register_craft({
	output = "technic:lv_lamp",
	recipe = {
		{mat.glass, mat.glass, mat.glass},
		{"technic:lv_led", "technic:lv_led", "technic:lv_led"},
		{"mesecons_materials:glue", "technic:lv_cable", "mesecons_materials:glue"},
	}
})
