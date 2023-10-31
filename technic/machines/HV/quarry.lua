
local S = technic.getter

local has_digilines = minetest.get_modpath("digilines")
local has_mesecons = minetest.get_modpath("mesecons")
local has_vizlib = minetest.get_modpath("vizlib")
local has_jumpdrive = minetest.get_modpath("jumpdrive")
local has_mcl = minetest.get_modpath("mcl_formspec")

local quarry_max_depth = technic.config:get_int("quarry_max_depth")
local quarry_dig_particles = technic.config:get_bool("quarry_dig_particles")
local quarry_time_limit = technic.config:get_int("quarry_time_limit")
local quarry_demand = 10000
local network_time_limit = 30000

local infotext
do
	local name = S("@1 Quarry", S("HV"))
	local demand = S("Demand: @1", technic.EU_string(quarry_demand))
	infotext = {
		active = S("@1 Active", name).."\n"..demand,
		disabled = S("@1 Disabled", name),
		finished = S("@1 Finished", name),
		purge = S("@1 Purging Cache", name),
		unpowered = S("@1 Unpowered", name),
	}
end

-- Hard-coded outward-spiral dig pattern for up to 17x17 dig area
local dig_pattern = {
	0,1,2,2,3,3,0,0,0,1,1,1,2,2,2,2,3,3,3,3,0,0,0,0,0,1,1,1,1,1,2,2,
	2,2,2,2,3,3,3,3,3,3,0,0,0,0,0,0,0,1,1,1,1,1,1,1,2,2,2,2,2,2,2,2,
	3,3,3,3,3,3,3,3,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,2,2,2,2,2,2,
	2,2,2,2,3,3,3,3,3,3,3,3,3,3,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,
	1,1,1,1,2,2,2,2,2,2,2,2,2,2,2,2,3,3,3,3,3,3,3,3,3,3,3,3,0,0,0,0,
	0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,2,2,2,2,2,2,2,2,2,2,
	2,2,2,2,3,3,3,3,3,3,3,3,3,3,3,3,3,3,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
	0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
}

-- Convert the dig pattern values to x/z offset vectors
do
	local head = vector.new()
	dig_pattern[0] = head
	for i = 1, #dig_pattern do
		head = vector.add(head, minetest.facedir_to_dir(dig_pattern[i]))
		dig_pattern[i] = {x = head.x, z = head.z}
	end
end

-- Cache of pipeworks fake players
local fake_players = {}

minetest.register_on_leaveplayer(function(player)
	fake_players[player:get_player_name()] = nil
end)

local function get_fake_player(name)
	if not fake_players[name] then
		fake_players[name] = pipeworks.create_fake_player({name = name})
	end
	return fake_players[name]
end

local function player_allowed(pos, name)
	local owner = minetest.get_meta(pos):get_string("owner")
	if owner == "" or owner == name then
		return true
	end
	return not minetest.is_protected(pos, name)
end

local function can_dig_node(pos, dig_pos, node_name, owner, digger)
	if node_name == "air" or node_name == "vacuum:vacuum" then
		return false
	end
	if vector.equals(pos, dig_pos) then
		return false  -- Don't dig self
	end
	local def = minetest.registered_nodes[node_name]
	if not def or not def.diggable or (def.can_dig and not def.can_dig(dig_pos, digger)) then
		return false
	end
	if def._mcl_hardness == -1 then
		return false
	end
	return not minetest.is_protected(dig_pos, owner)
end

local function do_purge(pos, meta)
	local inv = meta:get_inventory()
	for i, stack in ipairs(inv:get_list("cache")) do
		if not stack:is_empty() then
			technic.tube_inject_item(pos, pos, vector.new(0, 1, 0), stack:to_table())
			inv:set_stack("cache", i, "")
			break
		end
	end
	if inv:is_empty("cache") then
		meta:set_int("purge_on", 0)
	end
end

local function spawn_dig_particles(pos, dig_pos, node)
	local end_pos = vector.new(pos.x, pos.y - 0.5, pos.z)
	local dist = vector.distance(dig_pos, end_pos)
	local t = math.sqrt((2 * dist) / 20)
	local acc = vector.multiply(vector.subtract(end_pos, dig_pos), (1 / dist) * 20)
	minetest.add_particlespawner({
		amount = 50,
		time = 0.5,
		minpos = vector.subtract(dig_pos, 0.4),
		maxpos = vector.add(dig_pos, 0.4),
		minacc = acc,
		maxacc = acc,
		minsize = 0.5,
		maxsize = 1.5,
		minexptime = t,
		maxexptime = t,
		node = node,
	})
end

local function do_digging(pos, meta, net_time)
	local us_start = minetest.get_us_time()
	local step = tonumber(meta:get("step") or "")
	if not step then
		-- Missing metadata or not yet updated by conversion LBM, abort digging
		return
	end
	local radius = meta:get_int("size")
	local diameter = radius * 2 + 1
	local num_steps = diameter * diameter
	local dug = meta:get_int("dug")
	local max_depth = meta:get_int("max_depth")
	local offset = {
		x = meta:get_int("offset_x"),
		y = math.floor(step / num_steps) + 1 - meta:get_int("offset_y"),
		z = meta:get_int("offset_z")
	}
	if dug == -1 then
		-- Find ground before digging
		if offset.y > max_depth then
			meta:set_int("finished", 1)
			return
		end
		local pos1 = {
			x = pos.x + offset.x - radius,
			y = pos.y - offset.y,
			z = pos.z + offset.z - radius
		}
		local pos2 = {
			x = pos.x + offset.x + radius,
			y = pos.y - offset.y,
			z = pos.z + offset.z + radius
		}
		minetest.load_area(pos1, pos2)
		local nodes = minetest.find_nodes_in_area(pos1, pos2, {"air", "vacuum:vacuum"})
		if #nodes < num_steps then
			-- There are nodes to dig, start digging at this layer
			meta:set_int("dug", 0)
		else
			-- Move down to next layer
			meta:set_int("step", step + num_steps)
		end
		return
	end
	local owner = meta:get_string("owner")
	local digger = get_fake_player(owner)
	while true do
		-- Search for something to dig
		if offset.y > max_depth then
			-- Finished digging
			meta:set_int("finished", 1)
			meta:set_int("purge_on", 1)
			break
		end
		local dig_offset = dig_pattern[step % num_steps]
		local dig_pos = {
			x = pos.x + offset.x + dig_offset.x,
			y = pos.y - offset.y,
			z = pos.z + offset.z + dig_offset.z,
		}
		step = step + 1
		if step % num_steps == 0 then
			-- Finished this layer, move down
			offset.y = offset.y + 1
		end
		local node = technic.get_or_load_node(dig_pos)
		if can_dig_node(pos, dig_pos, node.name, owner, digger) then
			-- Found something to dig, dig it and stop
			minetest.remove_node(dig_pos)
			if quarry_dig_particles then
				spawn_dig_particles(pos, dig_pos, node)
			end
			local inv = meta:get_inventory()
			local drops = minetest.get_node_drops(node.name, "")
			local full = false
			for _, item in ipairs(drops) do
				local left = inv:add_item("cache", item)
				while not left:is_empty() do
					-- Cache is full, forcibly purge until the item fits
					full = true
					do_purge(pos, meta)
					left = inv:add_item("cache", left)
				end
			end
			dug = dug + 1
			if full or dug % 99 == 0 then
				-- Time to purge the cache
				meta:set_int("purge_on", 1)
			end
			break
		end
		local us_used = minetest.get_us_time() - us_start
		if us_used > quarry_time_limit or net_time + us_used > network_time_limit then
			break
		end
	end
	meta:set_int("dug", dug)
	meta:set_int("step", step)
end

local function quarry_run(pos, _, _, network)
	local meta = minetest.get_meta(pos)
	if meta:get_int("purge_on") == 1 then
		-- Purging
		meta:set_string("infotext", infotext.purge)
		meta:set_int("HV_EU_demand", 0)
		do_purge(pos, meta)
	elseif meta:get_int("finished") == 1 then
		-- Finished
		meta:set_string("infotext", infotext.finished)
		meta:set_int("HV_EU_demand", 0)
	elseif meta:get_int("enabled") == 1 then
		-- Active
		if meta:get_int("HV_EU_input") >= quarry_demand then
			meta:set_string("infotext", infotext.active)
			do_digging(pos, meta, network.lag)
		else
			meta:set_string("infotext", infotext.unpowered)
		end
		meta:set_int("HV_EU_demand", quarry_demand)
	else
		-- Disabled
		meta:set_int("HV_EU_demand", 0)
		meta:set_string("infotext", infotext.disabled)
		if not meta:get_inventory():is_empty("cache") then
			meta:set_int("purge_on", 1)
		end
	end
end

local function reset_quarry(meta)
	meta:set_int("step", 0)
	meta:set_int("dug", -1)
	meta:set_int("purge_on", 1)
	meta:set_int("finished", 0)
end

local base_formspec = "size[9,10]"..
	"label[0,0;"..S("@1 Quarry", S("HV")).."]"..
	"list[context;cache;0,0.7;4,3;]"..
	"button[6,0.6;2,1;restart;"..S("Restart").."]"..
	"field[4.3,2.1;2,1;size;"..S("Radius")..";${size}]"..
	"field[6.3,2.1;2,1;max_depth;"..S("Max Depth")..";${max_depth}]"..
	"field[4.3,3.1;1.333,1;offset_x;"..S("Offset X")..";${offset_x}]"..
	"field[5.633,3.1;1.333,1;offset_y;"..S("Offset Y")..";${offset_y}]"..
	"field[6.966,3.1;1.333,1;offset_z;"..S("Offset Z")..";${offset_z}]"

if has_digilines then
	base_formspec = base_formspec..
	"field[4.3,4.2;4,1;channel;"..S("Digiline Channel")..";${channel}]"
end

if has_mcl then
	base_formspec = base_formspec..
	mcl_formspec.get_itemslot_bg(0,0.7,4,3)..
	-- player inventory
	"list[current_player;main;0,5.5;9,3;9]"..
	mcl_formspec.get_itemslot_bg(0,5.5,9,3)..
	"list[current_player;main;0,8.74;9,1;]"..
	mcl_formspec.get_itemslot_bg(0,8.74,9,1)..
	"listring[current_player;main]"
else
	base_formspec = base_formspec..
	"list[current_player;main;0,5;8,4;]"..
	"listring[]"
end

local function update_formspec(meta)
	local fs = base_formspec
	local status = S("Digging not started")
	if meta:get_int("purge_on") == 1 then
		status = S("Purging cache")
	elseif meta:get_int("finished") == 1 then
		status = S("Digging finished")
	elseif meta:get_int("enabled") == 1 then
		local diameter = meta:get_int("size") * 2 + 1
		local num_steps = diameter * diameter
		local y_level = math.floor(meta:get_int("step") / num_steps) + 1 - meta:get_int("offset_y")
		if y_level < 0 then
			status = S("Digging @1 m above machine", math.abs(y_level))
		else
			status = S("Digging @1 m below machine", y_level)
		end
	end
	if meta:get_int("enabled") == 1 then
		fs = fs.."button[4,0.6;2,1;disable;"..S("Enabled").."]"
	else
		fs = fs.."button[4,0.6;2,1;enable;"..S("Disabled").."]"
	end
	if has_mesecons then
		local selected = meta:get("mesecons") or "true"
		if has_jumpdrive then
			fs = fs.."checkbox[0,3.6;mesecons;"..S("Enable Mesecons Control")..";"..selected.."]"
		else
			fs = fs.."checkbox[0,3.8;mesecons;"..S("Enable Mesecons Control")..";"..selected.."]"
		end
	end
	if has_jumpdrive then
		local selected = meta:get("reset_on_move") or "true"
		if has_mesecons then
			fs = fs.."checkbox[0,4.1;reset_on_move;"..S("Restart When Moved")..";"..selected.."]"
		else
			fs = fs.."checkbox[0,3.8;reset_on_move;"..S("Restart When Moved")..";"..selected.."]"
		end
	end
	meta:set_string("formspec", fs.."label[4,0;"..status.."]")
end

local function clamp(value, min, max, default)
	value = tonumber(value) or default or max
	return math.min(math.max(value, min), max)
end

local function quarry_receive_fields(pos, _, fields, sender)
	local player_name = sender:get_player_name()
	if not player_allowed(pos, player_name) then
		minetest.chat_send_player(player_name, S("You are not allowed to edit this!"))
		return
	end
	local meta = minetest.get_meta(pos)
	if fields.size then
		meta:set_int("size", clamp(fields.size, 0, 8, 4))
	end
	if fields.max_depth then
		local depth = clamp(fields.max_depth, 1, quarry_max_depth)
		meta:set_int("max_depth", depth)
		local ymin = -math.min(10, depth - 1)
		meta:set_int("offset_y", clamp(meta:get_int("offset_y"), ymin, 10, 0))
	end
	if fields.offset_x then
		meta:set_int("offset_x", clamp(fields.offset_x, -10, 10, 0))
	end
	if fields.offset_y then
		local ymin = -math.min(10, meta:get_int("max_depth") - 1)
		meta:set_int("offset_y", clamp(fields.offset_y, ymin, 10, 0))
	end
	if fields.offset_z then
		meta:set_int("offset_z", clamp(fields.offset_z, -10, 10, 0))
	end
	if fields.mesecons then
		meta:set_string("mesecons", fields.mesecons)
	end
	if fields.reset_on_move then
		meta:set_string("reset_on_move", fields.reset_on_move)
	end
	if fields.channel then
		meta:set_string("channel", fields.channel)
	end
	if fields.enable then meta:set_int("enabled", 1) end
	if fields.disable then meta:set_int("enabled", 0) end
	if fields.restart then reset_quarry(meta) end
	update_formspec(meta)
end

local function show_working_area(pos, _, player)
	if not player or player:get_wielded_item():get_name() ~= "" then
		-- Only spawn particles when using an empty hand
		return
	end
	local meta = minetest.get_meta(pos)
	local radius = meta:get_int("size") + 0.5
	local offset = vector.new(meta:get_int("offset_x"), meta:get_int("offset_y"), meta:get_int("offset_z"))
	local depth = meta:get_int("max_depth") + 0.5
	-- Draw area from top corner to bottom corner
	local pos1 = vector.add(pos, vector.new(offset.x - radius, offset.y - 0.5, offset.z - radius))
	local pos2 = vector.add(pos, vector.new(offset.x + radius, -depth, offset.z + radius))
	vizlib.draw_area(pos1, pos2, {player = player})
end

local function digiline_action(pos, _, channel, msg)
	local meta = minetest.get_meta(pos)
	if channel ~= meta:get_string("channel") then
		return
	end
	-- Convert string message to table
	if type(msg) == "string" then
		msg = msg:lower()
		if msg == "get" or msg == "on" or msg == "off" or msg == "restart" then
			msg = {command = msg}
		elseif msg:sub(1, 7) == "radius " then
			msg = {command = "radius", value = msg:sub(8,-1)}
		elseif msg:sub(1,10) == "max_depth " then
			msg = {command = "max_depth", value = msg:sub(11,-1)}
		elseif msg:sub(1,9) == "offset_x " then
			msg = {command = "offset_x", value = msg:sub(10,-1)}
		elseif msg:sub(1,9) == "offset_y " then
			msg = {command = "offset_y", value = msg:sub(10,-1)}
		elseif msg:sub(1,9) == "offset_z " then
			msg = {command = "offset_z", value = msg:sub(10,-1)}
		elseif msg:sub(1,7) == "offset " then
			local s = string.split(msg:sub(8,-1), ",")
			msg = {command = "offset", value = {x = s[1], y = s[2], z = s[3]}}
		end
	end
	if type(msg) ~= "table" then return end
	-- Convert old message format to new format
	if msg.command ~= "set" and msg.command ~= "get" then
		local cmd = msg.command
		if cmd == "restart" then
			msg = {command = "set", restart = true}
		elseif cmd == "on" or cmd == "off" then
			msg = {command = "set", enabled = msg.command == "on"}
		elseif cmd == "radius" or cmd == "max_depth" or cmd == "offset"
				or cmd == "offset_x" or cmd == "offset_y" or cmd == "offset_z" then
			msg = {command = "set", [cmd] = msg.value}
		end
	end
	-- Process message
	if msg.command == "get" then
		local diameter = meta:get_int("size") * 2 + 1
		local num_steps = diameter * diameter
		local offset = {
			x = meta:get_int("offset_x"),
			y = meta:get_int("offset_y"),
			z = meta:get_int("offset_z")
		}
		digilines.receptor_send(pos, technic.digilines.rules, channel, {
			enabled = meta:get_int("enabled") == 1,
			finished = meta:get_int("finished") == 1,
			radius = meta:get_int("size"),
			max_depth = meta:get_int("max_depth"),
			offset_x = offset.x,
			offset_y = offset.y,
			offset_z = offset.z,
			offset = offset,
			dug_nodes = meta:get_int("dug"),
			dig_level = -(math.floor(meta:get_int("step") / num_steps) + 1 - offset.y),
		})
	elseif msg.command == "set" then
		if msg.enabled ~= nil then
			meta:set_int("enabled", msg.enabled == true and 1 or 0)
		end
		if msg.restart == true then
			reset_quarry(meta)
		end
		if msg.radius then
			meta:set_int("size", clamp(msg.radius, 0, 8, 4))
		end
		if msg.max_depth then
			local depth = clamp(msg.max_depth, 1, quarry_max_depth)
			meta:set_int("max_depth", depth)
			local ymin = -math.min(10, depth - 1)
			meta:set_int("offset_y", clamp(meta:get_int("offset_y"), ymin, 10, 0))
		end
		if msg.offset_x then
			meta:set_int("offset_x", clamp(msg.offset_x, -10, 10, 0))
		end
		if msg.offset_y then
			local ymin = -math.min(10, meta:get_int("max_depth") - 1)
			meta:set_int("offset_y", clamp(msg.offset_y, ymin, 10, 0))
		end
		if msg.offset_z then
			meta:set_int("offset_z", clamp(msg.offset_z, -10, 10, 0))
		end
		if msg.offset and type(msg.offset) == "table" then
			local ymin = -math.min(10, meta:get_int("max_depth") - 1)
			meta:set_int("offset_x", clamp(msg.offset.x, -10, 10, 0))
			meta:set_int("offset_y", clamp(msg.offset.y, ymin, 10, 0))
			meta:set_int("offset_z", clamp(msg.offset.z, -10, 10, 0))
		end
	end
end

minetest.register_node("technic:quarry", {
	description = S("@1 Quarry", S("HV")),
	tiles = {
		"technic_carbon_steel_block.png^pipeworks_tube_connection_metallic.png",
		"technic_carbon_steel_block.png^technic_quarry_bottom.png",
		"technic_carbon_steel_block.png^technic_cable_connection_overlay.png",
		"technic_carbon_steel_block.png^technic_cable_connection_overlay.png",
		"technic_carbon_steel_block.png^technic_cable_connection_overlay.png",
		"technic_carbon_steel_block.png^technic_cable_connection_overlay.png"
	},
	groups = {cracky = 2, tubedevice = 1, technic_machine = 1, technic_hv = 1, pickaxey = 2},
	_mcl_blast_resistance = 1,
	_mcl_hardness = 0.8,
	connect_sides = {"front", "back", "left", "right"},
	tube = {
		connect_sides = {top = 1},
		-- Lower priority than tubes, so items will prefer any tube to another quarry
		priority = 10,
		can_go = function(pos, node, velocity, stack)
			-- Always eject up, even if items came in another way
			return { vector.new(0, 1, 0) }
		end
	},
	on_punch = has_vizlib and show_working_area or nil,
	on_rightclick = function(pos)
		local meta = minetest.get_meta(pos)
		update_formspec(meta)
	end,
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_int("size", 4)
		meta:set_int("offset_x", 0)
		meta:set_int("offset_y", 0)
		meta:set_int("offset_z", 0)
		meta:set_int("max_depth", quarry_max_depth)
		meta:set_string("mesecons", "false")
		meta:set_string("reset_on_move", "false")
		meta:get_inventory():set_size("cache", 12)
		reset_quarry(meta)
		update_formspec(meta)
	end,
	on_movenode = has_jumpdrive and function(_, pos)
		local meta = minetest.get_meta(pos)
		if meta:get("reset_on_move") ~= "false" then
			reset_quarry(meta)
		end
	end or nil,
	after_place_node = function(pos, placer, itemstack)
		minetest.get_meta(pos):set_string("owner", placer:get_player_name())
		pipeworks.scan_for_tube_objects(pos)
	end,
	can_dig = function(pos, player)
		return minetest.get_meta(pos):get_inventory():is_empty("cache")
	end,
	after_dig_node = pipeworks.scan_for_tube_objects,
	on_receive_fields = quarry_receive_fields,
	technic_run = quarry_run,
	allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
		return player_allowed(pos, player:get_player_name()) and count or 0
	end,
	allow_metadata_inventory_put = function(pos, listname, index, stack, player)
		return player_allowed(pos, player:get_player_name()) and stack:get_count() or 0
	end,
	allow_metadata_inventory_take = function(pos, listname, index, stack, player)
		return player_allowed(pos, player:get_player_name()) and stack:get_count() or 0
	end,
	mesecons = {
		effector = {
			action_on = function(pos)
				local meta = minetest.get_meta(pos)
				if meta:get("mesecons") ~= "false" then
					meta:set_int("enabled", 1)
				end
			end,
			action_off = function(pos)
				local meta = minetest.get_meta(pos)
				if meta:get("mesecons") ~= "false" then
					meta:set_int("enabled", 0)
				end
			end
		}
	},
	digiline = {
		receptor = {
			rules = technic.digilines.rules,
		},
		effector = {
			rules = technic.digilines.rules,
			action = digiline_action,
		}
	},
})

minetest.register_craft({
	output = "technic:quarry",
	recipe = {
		{"technic:carbon_plate", "pipeworks:filter", "technic:composite_plate"},
		{"basic_materials:motor", "technic:machine_casing", "technic:diamond_drill_head"},
		{"technic:carbon_steel_block", "technic:hv_cable", "technic:carbon_steel_block"}
	}
})

technic.register_machine("HV", "technic:quarry", technic.receiver)

minetest.register_lbm({
	label = "Old quarry conversion",
	name = "technic:old_quarry_conversion",
	nodenames = {"technic:quarry"},
	run_at_every_load = false,
	action = function(pos, node)
		local meta = minetest.get_meta(pos)
		if meta:get("step") then
			-- Quarry v3, don't do anything
			-- This can happen when a quarry is moved with a jumpdrive
			return
		elseif meta:get("quarry_pos") then
			-- Quarry v2, calculate step if quarry is digging below
			local level = meta:get_int("dig_level") - pos.y
			if level < 0 then
				local diameter = meta:get_int("size") * 2 + 1
				local num_steps = diameter * diameter
				-- Convert the negative value to positive, and go back up one level
				level = math.abs(level + 1)
				meta:set_int("step", level * num_steps)
			end
			-- Delete unused meta values
			meta:set_string("quarry_dir", "")
			meta:set_string("quarry_pos", "")
			meta:set_string("dig_pos", "")
			meta:set_string("dig_level", "")
			meta:set_string("dig_index", "")
			meta:set_string("dig_steps", "")
		else
			-- Quarry v1, reset quarry
			reset_quarry(meta)
		end
		local dir = minetest.facedir_to_dir(node.param2)
		local offset = vector.multiply(dir, meta:get_int("size") + 1)
		meta:set_int("offset_x", offset.x)
		meta:set_int("offset_y", 4)
		meta:set_int("offset_z", offset.z)
		if not meta:get("max_depth") then
			meta:set_int("max_depth", quarry_max_depth)
		end
		update_formspec(meta)
	end
})
