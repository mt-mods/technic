
local S = technic.getter

local has_digilines = minetest.get_modpath("digilines")

local quarry_dig_above_nodes = tonumber(technic.config:get("quarry_dig_above_nodes"))
local quarry_max_depth = tonumber(technic.config:get("quarry_max_depth"))
local quarry_time_limit = tonumber(technic.config:get("quarry_time_limit"))

local quarry_demand = 10000
local quarry_eject_dir = vector.new(0, 1, 0)
local machine_name = S("@1 Quarry", S("HV"))
local quarry_formspec =
	"size[8,9]"..
	"item_image[7,0;1,1;technic:quarry]"..
	"list[context;cache;0,1;4,3;]"..
	"listring[context;cache]"..
	"list[current_player;main;0,5;8,4;]"..
	"listring[current_player;main]"..
	"label[0,0;"..machine_name.."]"..
	"button[6,0.9;2,1;restart;"..S("Restart").."]"

local mesecons_checkbox = minetest.get_modpath("mesecons")
	and function(state) return "checkbox[4.3,3.9;mesecons;"..S("Controlled by Mesecon Signal")..";"..state.."]" end
	or function() return "" end

if has_digilines then
	quarry_formspec = quarry_formspec .. "field[4.3,3.4;4,1;channel;Channel;${channel}]"
end

-- hard-coded spiral dig pattern for up to 17x17 dig area
local quarry_dig_pattern = {
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

local quarry_dig_particles = technic.config:get_bool("quarry_dig_particles")

local function is_player_allowed(pos, name)
	local owner = minetest.get_meta(pos):get_string("owner")
	if owner == "" or owner == name then
		return true
	end
	if not minetest.is_protected(pos, name) then
		return true
	end
	return false
end

local function reset_quarry(pos)
	local meta = minetest.get_meta(pos)
	local node = technic.get_or_load_node(pos) or minetest.get_node(pos)
	meta:set_int("quarry_dir", node.param2)
	meta:set_string("quarry_pos", minetest.pos_to_string(pos))
	meta:set_string("dig_pos", "")
	meta:set_int("dig_level", pos.y + quarry_dig_above_nodes)
	local radius = meta:get_int("size")
	local diameter = (radius*2)+1
	meta:set_int("dig_steps", diameter*diameter)
	meta:set_int("dig_index", 0)
	meta:set_int("purge_on", 1)
	meta:set_int("finished", 0)
	meta:set_int("dug", 0)
end

local function set_quarry_status(pos)
	local meta = minetest.get_meta(pos)
	local max_depth = meta:get_int("max_depth")
	if max_depth == 0 then
		-- max-depth not configured, use max-value from setting
		max_depth = quarry_max_depth
	end
	local formspec = quarry_formspec..
		"field[4.3,2.4;2,1;size;"..S("Radius:")..";"..meta:get_int("size").."]" ..
		"field[6.3,2.4;2,1;max_depth;"..S("Max-Depth:")..";"..max_depth.."]"

	local status = S("Digging not started")
	if meta:get_int("enabled") == 1 then
		formspec = formspec.."button[4,0.9;2,1;disable;"..S("Enabled").."]"
		if meta:get_int("purge_on") == 1 then
			status = S("Purging cache")
			meta:set_string("infotext", S("@1 purging cache", machine_name))
			meta:set_int("HV_EU_demand", 0)
		elseif meta:get_int("finished") == 1 then
			status = S("Digging finished")
			meta:set_string("infotext", S("@1 Finished", machine_name))
			meta:set_int("HV_EU_demand", 0)
		else
			local rel_y = meta:get_int("dig_level") - pos.y
			status = (rel_y > 0) and
				S("Digging @1 m above machine", math.abs(rel_y)) or
				S("Digging @1 m below machine", math.abs(rel_y))
			if meta:get_int("HV_EU_input") >= quarry_demand then
				meta:set_string("infotext", S("@1 Active", machine_name) .. " " .. status)
			else
				meta:set_string("infotext", S("@1 Unpowered", machine_name))
			end
			meta:set_int("HV_EU_demand", quarry_demand)
		end
	else
		formspec = formspec.."button[4,0.9;2,1;enable;"..S("Disabled").."]"
		meta:set_string("infotext", S("@1 Disabled", machine_name))
		meta:set_int("HV_EU_demand", 0)
	end
	formspec = formspec .. mesecons_checkbox(meta:get("mesecons") or "true")
	meta:set_string("formspec", formspec.."label[0,4.1;"..minetest.formspec_escape(status).."]")
end

local function quarry_receive_fields(pos, formname, fields, sender)
	local player_name = sender:get_player_name()
	if not is_player_allowed(pos, player_name) then
		minetest.chat_send_player(player_name, "You are not allowed to edit this!")
		minetest.record_protection_violation(pos, player_name)
		return
	end
	local meta = minetest.get_meta(pos)
	if fields.size and string.find(fields.size, "^[0-9]+$") then
		local size = tonumber(fields.size)
		if size >= 1 and size <= 8 and size ~= meta:get_int("size") then
			meta:set_int("size", size)
			reset_quarry(pos)
		end
	end

	if fields.max_depth then
		-- apply max-depth config
		local max_depth = tonumber(fields.max_depth)
		if max_depth and max_depth > 0 then
			-- use value or upper bounds if it exceeds the current max-setting
			meta:set_int("max_depth", math.min(max_depth, quarry_max_depth))
		end
	end

	if fields.mesecons then
		meta:set_string("mesecons", fields.mesecons == "false" and "false" or "")
	end
	if fields.channel then
		meta:set_string("channel", fields.channel)
	end
	if fields.enable then meta:set_int("enabled", 1) end
	if fields.disable then meta:set_int("enabled", 0) end
	if fields.restart then reset_quarry(pos) end
	set_quarry_status(pos)
end

local function quarry_handle_purge(pos)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	local cache = inv:get_list("cache")
	if not cache then
		inv:set_size("cache", 12)
		return
	end
	local i = 0
	for _,stack in ipairs(cache) do
		i = i + 1
		if stack then
			local item = stack:to_table()
			if item then
				technic.tube_inject_item(pos, pos, quarry_eject_dir, item)
				stack:clear()
				inv:set_stack("cache", i, stack)
				break
			end
		end
	end
	if inv:is_empty("cache") then
		meta:set_int("purge_on", 0)
	end
end

local function can_dig_node(pos, node_name, owner, digger)
	if node_name == "air" or node_name == "vacuum:vacuum" then
		return false
	end
	local def = minetest.registered_nodes[node_name]
	if not def or not def.diggable or (def.can_dig and not def.can_dig(pos, digger)) then
		return false
	end
	if minetest.is_protected(pos, owner) then
		return false
	end
	return true
end

local function find_ground(quarry_pos, quarry_dir, meta)
	local dir = minetest.facedir_to_dir(quarry_dir % 4)
	local radius = meta:get_int("size")
	local dig_level = meta:get_int("dig_level")
	local middle_pos = vector.add(quarry_pos, vector.multiply(dir, radius + 1))
	local pos1 = vector.new(middle_pos.x - radius, dig_level, middle_pos.z - radius)
	local pos2 = vector.new(middle_pos.x + radius, dig_level, middle_pos.z + radius)
	local nodes = minetest.find_nodes_in_area(pos1, pos2, {"air", "vacuum:vacuum"})
	if #nodes < meta:get_int("dig_steps") then
		return vector.new(middle_pos.x, dig_level, middle_pos.z)
	end
	meta:set_int("dig_level", dig_level - 1)
	return nil
end

local function get_dig_pos(quarry_pos, quarry_dir, dig_pos, dig_index, dig_steps, meta)
	local max_depth = meta:get_int("max_depth")
	if max_depth <= 0 or max_depth > quarry_max_depth then
		-- invalid max-depth config, use default
		max_depth = quarry_max_depth
	end

	local dig_level = meta:get_int("dig_level")
	if (quarry_pos.y - dig_level) > max_depth then
		return nil, dig_index
	end

	if dig_index > 0 and dig_index < dig_steps then
		local facedir = (quarry_dir + quarry_dig_pattern[dig_index]) % 4
		dig_pos = vector.add(dig_pos, minetest.facedir_to_dir(facedir))
	elseif dig_index >= dig_steps then
		if (quarry_pos.y - dig_level) >= max_depth then
			return nil, dig_index
		end
		local dir = minetest.facedir_to_dir(quarry_dir % 4)
		dig_pos = vector.add(quarry_pos, vector.multiply(dir, meta:get_int("size") + 1))
		dig_pos.y = dig_level - 1
		meta:set_int("dig_level", dig_pos.y)
		dig_index = 0
	end
	dig_index = dig_index + 1
	return dig_pos, dig_index
end

local function dig_particles(quarry_pos, dig_pos, dig_node)
	local param2 = minetest.get_node(quarry_pos).param2
	quarry_pos = vector.add(quarry_pos, minetest.facedir_to_dir(param2))
	local t = 0.5
	local a = 50
	local vec = vector.direction(dig_pos, quarry_pos)
	local mag = vector.distance(dig_pos, quarry_pos)
	vec = vector.multiply(vec, (mag - 0.5) / t)
	local acc = vector.new(0, 0, 0)
	if param2 == 0 then
		acc.z = -a
		vec.z = vec.z + (a * t / 2)
	elseif param2 == 1 then
		acc.x = -a
		vec.x = vec.x + (a * t / 2)
	elseif param2 == 2 then
		acc.z = a
		vec.z = vec.z - (a * t / 2)
	elseif param2 == 3 then
		acc.x = a
		vec.x = vec.x - (a * t / 2)
	end
	minetest.add_particlespawner({
		amount = 50,
		time = 0.5,
		minpos = vector.subtract(dig_pos, 0.5),
		maxpos = vector.add(dig_pos, 0.5),
		minvel = vec,
		maxvel = vec,
		minacc = acc,
		maxacc = acc,
		minsize = 1,
		maxsize = 2,
		minexptime = t,
		maxexptime = t,
		node = dig_node
	})
end

local function execute_dig(pos, node, meta, network)
	local dig_pos = minetest.string_to_pos(meta:get_string("dig_pos"))
	local quarry_dir = meta:get_int("quarry_dir")
	if not dig_pos then
		-- quarry has not hit ground yet
		dig_pos = find_ground(pos, quarry_dir, meta)
	else
		local owner = meta:get_string("owner")
		local digger = pipeworks.create_fake_player({name = owner})
		local dig_steps = meta:get_int("dig_steps")
		local dig_index = meta:get_int("dig_index")
		local t0 = minetest.get_us_time()
		local us_used = 0
		-- search for something to dig
		while us_used < quarry_time_limit do
			dig_pos, dig_index = get_dig_pos(pos, quarry_dir, dig_pos, dig_index, dig_steps, meta)
			if not dig_pos then
				-- finished digging
				meta:set_int("finished", 1)
				meta:set_int("purge_on", 1)
				break
			end
			local dig_node = technic.get_or_load_node(dig_pos) or minetest.get_node(dig_pos)
			if can_dig_node(dig_pos, dig_node.name, owner, digger) then
				-- found something to dig, dig it and stop searching
				minetest.remove_node(dig_pos)
				if quarry_dig_particles and network.lag < 35000 then
					dig_particles(pos, dig_pos, dig_node)
				end
				local inv = meta:get_inventory()
				local drops = minetest.get_node_drops(dig_node.name, "")
				for _, dropped_item in ipairs(drops) do
					local left = inv:add_item("cache", dropped_item)
					while not left:is_empty() do
						meta:set_int("purge_on", 1)
						quarry_handle_purge(pos)
						left = inv:add_item("cache", left)
					end
				end
				local dug_nodes = meta:get_int("dug") + 1
				meta:set_int("dug", dug_nodes)
				if dug_nodes % 100 == 0 then
					meta:set_int("purge_on", 1)
				end
				break
			end
			us_used = minetest.get_us_time() - t0
		end
		meta:set_int("dig_index", dig_index)
	end
	if dig_pos then
		meta:set_string("dig_pos", minetest.pos_to_string(dig_pos))
	end
end

local function quarry_run(pos, node, run_state, network)
	local meta = minetest.get_meta(pos)
	if minetest.pos_to_string(pos) ~= meta:get_string("quarry_pos") then
		-- quarry has been moved since last dig
		reset_quarry(pos)
	elseif meta:get_int("purge_on") == 1 then
		quarry_handle_purge(pos)
	elseif meta:get_int("enabled") and meta:get_int("HV_EU_input") >= quarry_demand and meta:get_int("finished") == 0 then
		execute_dig(pos, node, meta, network)
	elseif not meta:get_inventory():is_empty("cache") then
		meta:set_int("purge_on", 1)
	end
	set_quarry_status(pos)
end

local digiline_def = function(pos, _, channel, msg)
	local meta = minetest.get_meta(pos)
	if channel ~= meta:get_string("channel") then
		return
	end
	-- Convert string messages to tables:
	if type(msg) == "string" then
		local smsg = msg:lower()
		msg = {}
		if smsg == "get" then
			msg.command = "get"
		elseif smsg:sub(1,7) == "radius " then
			msg.command = "radius"
			msg.value = smsg:sub(8,-1)
		elseif smsg:sub(1,10) == "max_depth " then
			msg.command = "max_depth"
			msg.value = smsg:sub(11,-1)
		elseif smsg == "on" then
			msg.command = "on"
		elseif smsg == "off" then
			msg.command = "off"
		elseif smsg == "restart" then
			msg.command = "restart"
		end
	end

	if type(msg) ~= "table" then
		return
	end

	if msg.command == "get" then
		digilines.receptor_send(pos, technic.digilines.rules, channel, {
			enabled = meta:get_int("enabled"),
			radius = meta:get_int("size"),
			max_depth = meta:get_int("max_depth"),
			finished = meta:get_int("finished"),
			dug_nodes = meta:get_int("dug"),
			dig_level = meta:get_int("dig_level") - pos.y
		})
	elseif msg.command == "radius" then
		local size = tonumber(msg.value)
		if not size or size < 1 or size > 8 or size == meta:get_int("size") then
			return
		end
		meta:set_int("size", size)
		reset_quarry(pos)
		set_quarry_status(pos)
	elseif msg.command == "max_depth" then
		local max_depth = tonumber(msg.value)
		if not max_depth or max_depth < 0 then
			-- invalid or negative number
			return
		end
		if max_depth > quarry_max_depth then
			-- over the limit, set to max-setting
			max_depth = quarry_max_depth
		end
		meta:set_int("max_depth", max_depth)
		reset_quarry(pos)
		set_quarry_status(pos)
	elseif msg.command == "on" then
		meta:set_int("enabled", 1)
		set_quarry_status(pos)
	elseif msg.command == "off" then
		meta:set_int("enabled", 0)
		set_quarry_status(pos)
	elseif msg.command == "restart" then
		reset_quarry(pos)
		set_quarry_status(pos)
	end

end

minetest.register_node("technic:quarry", {
	description = S("@1 Quarry", S("HV")),
	tiles = {
		"technic_carbon_steel_block.png^pipeworks_tube_connection_metallic.png",
		"technic_carbon_steel_block.png^technic_cable_connection_overlay.png",
		"technic_carbon_steel_block.png^technic_cable_connection_overlay.png",
		"technic_carbon_steel_block.png^technic_cable_connection_overlay.png",
		"technic_carbon_steel_block.png^default_tool_mesepick.png",
		"technic_carbon_steel_block.png^technic_cable_connection_overlay.png"
	},
	paramtype2 = "facedir",
	groups = {cracky=2, tubedevice=1, technic_machine=1, technic_hv=1},
	connect_sides = {"bottom", "front", "left", "right"},
	tube = {
		connect_sides = {top = 1},
		-- lower priority than other tubes, so that quarries will prefer any
		-- other tube to another quarry, which could lead to server freezes
		-- in certain quarry placements (2x2 for example would never eject)
		priority = 10,
		can_go = function(pos, node, velocity, stack)
			-- always eject the same, even if items came in another way
			-- this further mitigates loops and generally avoids random sideway movement
			-- that can be expected in certain quarry placements
			return { quarry_eject_dir }
		end
	},
	on_punch = function(pos, node, puncher)
		local stack = puncher and puncher:get_wielded_item()
		if not stack then
			return
		end
		local itemname = stack and (not stack:is_empty() and stack:get_name())
		if itemname and itemname ~= "default:stick" then
			return
		end
		-- Continue to particle spawner with empty hand or default:stick
		local meta = minetest.get_meta(pos)
		local dir = minetest.facedir_to_dir(meta:get_int("quarry_dir") % 4)
		local radius = meta:get_int("size")
		local middle_pos = vector.add(pos, vector.multiply(dir, radius + 1))
		local pos1 = vector.new(middle_pos.x - radius, pos.y + quarry_dig_above_nodes, middle_pos.z - radius)
		local pos2 = vector.new(middle_pos.x + radius, pos.y + quarry_dig_above_nodes, middle_pos.z + radius)
		-- Engine seems to copy definition anyway so skip additional table constructors
		local particle = {
			expirationtime = 5,
			size = 12,
			vertical = false,
			texture = "technic_carbon_steel_block.png^default_tool_mesepick.png^[opacity:215",
			playername = puncher:get_player_name(),
			glow = 7
		}
		-- Individual particle parameters
		local v0 = {x=0, y=0, z=0}
		local a0 = {x=0, y=0, z=0}
		local v1 = {x=0, y=-0.4, z=0}
		local a1 = {x=0, y=-1.5, z=0}
		for x=pos1.x,pos2.x do
			for z=pos1.z,pos2.z do
				particle.pos = vector.new(x, pos1.y, z)
				particle.velocity = v0
				particle.acceleration = a0
				minetest.add_particle(particle)
				if itemname == "default:stick" or x == pos1.x or z == pos1.z or x == pos2.x or z == pos2.z then
					particle.velocity = v1
					particle.acceleration = a1
					minetest.add_particle(particle)
				end
			end
		end
	end,
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_int("size", 4)
		meta:get_inventory():set_size("cache", 12)
		reset_quarry(pos)
		set_quarry_status(pos)
	end,
	on_rotate = function(pos, node, player, click, new_param2)
		local meta = minetest.get_meta(pos)
		if meta:get_int("enabled") == 1 then
			return false
		end

		-- only allow rotation around y-axis
		node.param2 = new_param2 % 4

		minetest.swap_node(pos, node)
		reset_quarry(pos)
		set_quarry_status(pos)
		return true
	end,
	after_place_node = function(pos, placer, itemstack)
		minetest.get_meta(pos):set_string("owner", placer:get_player_name())
		pipeworks.scan_for_tube_objects(pos)
	end,
	can_dig = function(pos,player)
		return minetest.get_meta(pos):get_inventory():is_empty("cache")
	end,
	after_dig_node = pipeworks.scan_for_tube_objects,
	on_receive_fields = quarry_receive_fields,
	technic_run = quarry_run,
	allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
		return is_player_allowed(pos, player:get_player_name()) and count or 0
	end,
	allow_metadata_inventory_put = function(pos, listname, index, stack, player)
		return is_player_allowed(pos, player:get_player_name()) and stack:get_count() or 0
	end,
	allow_metadata_inventory_take = function(pos, listname, index, stack, player)
		return is_player_allowed(pos, player:get_player_name()) and stack:get_count() or 0
	end,
	mesecons = {
		effector = {
			action_on = function(pos)
				local meta = minetest.get_meta(pos)
				if meta:get("mesecons") ~= "false" then
					meta:set_int("enabled", 1)
					set_quarry_status(pos)
				end
			end,
			action_off = function(pos)
				local meta = minetest.get_meta(pos)
				if meta:get("mesecons") ~= "false" then
					meta:set_int("enabled", 0)
					set_quarry_status(pos)
				end
			end
		}
	},
	digiline = {
		receptor = {
			rules = technic.digilines.rules,
			action = function() end,
		},
		effector = {
			rules = technic.digilines.rules,
			action = digiline_def,
		},
	},
})

minetest.register_craft({
	recipe = {
		{"technic:carbon_plate", "pipeworks:filter", "technic:composite_plate"},
		{"basic_materials:motor", "technic:machine_casing", "technic:diamond_drill_head"},
		{"technic:carbon_steel_block", "technic:hv_cable", "technic:carbon_steel_block"}},
	output = "technic:quarry"
})

technic.register_machine("HV", "technic:quarry", technic.receiver)
