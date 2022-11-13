local S = technic.getter

local function migrate_meta(meta)
	local data = meta:get("")
	if data then
		local fields = minetest.deserialize(data, true)
		if type(fields) == "table" then
			meta:set_string("target", fields.target)
			meta:set_int("look_radius", fields.look_radius or 1)
			meta:set_int("look_depth", fields.look_depth or 7)
			meta:set_string("", "")
			return meta:get("target")
		end
	end
end

local function get_field(meta)
	return (meta:get("look_depth") or 7), (meta:get("look_radius") or 1)
end

technic.register_power_tool("technic:prospector", {
	description = S("Prospector"),
	inventory_image = "technic_prospector.png",
	max_charge = 300000,
	on_use = function(toolstack, user, pointed_thing)
		if not user or not user:is_player() or user.is_fake_player then return end
		if pointed_thing.type ~= "node" then return end
		local meta = toolstack:get_meta()
		local target = meta:get("target") or migrate_meta(meta)
		if not target then
			minetest.chat_send_player(user:get_player_name(), S("Right-click to set target block type"))
			return toolstack
		end
		local look_depth, look_radius = get_field(meta)
		local look_diameter = look_radius * 2 + 1
		local charge_to_take = look_depth * (look_depth + 1) * look_diameter * look_diameter
		if not technic.use_RE_charge(toolstack, charge_to_take) then
			return toolstack
		end
		local start_pos = pointed_thing.under
		local forward = minetest.facedir_to_dir(minetest.dir_to_facedir(user:get_look_dir(), true))
		local right = forward.x ~= 0 and { x=0, y=1, z=0 } or (forward.y ~= 0 and { x=0, y=0, z=1 } or { x=1, y=0, z=0 })
		local up = forward.x ~= 0 and { x=0, y=0, z=1 } or (forward.y ~= 0 and { x=1, y=0, z=0 } or { x=0, y=1, z=0 })
		local base_pos = vector.add(start_pos, vector.multiply(vector.add(right, up), - look_radius))
		local found = false
		for f = 0, look_depth-1 do
			for r = 0, look_diameter-1 do
				for u = 0, look_diameter-1 do
					if minetest.get_node(vector.add(vector.add(vector.add(base_pos, vector.multiply(forward, f)),
								vector.multiply(right, r)), vector.multiply(up, u))).name == target then
						found = true
					end
				end
			end
		end
		if math.random() < 0.02 then found = not found end
		minetest.chat_send_player(user:get_player_name(),
			S("@1 is "..(found and "present" or "absent").." in @2 region",
				minetest.registered_nodes[target].description,
				look_diameter.."x"..look_diameter.."x"..look_depth))
		minetest.sound_play("technic_prospector_"..(found and "hit" or "miss"),
				{ pos = vector.add(user:get_pos(), { x = 0, y = 1, z = 0 }), gain = 1.0, max_hear_distance = 10 }, true)
		return toolstack
	end,
	on_place = function(toolstack, user, pointed_thing)
		if not user or not user:is_player() or user.is_fake_player then
			return
		end
		local meta = toolstack:get_meta()
		local target = meta:get("target") or migrate_meta(meta)
		local look_depth, look_radius = get_field(meta)
		local pointed
		if pointed_thing.type == "node" then
			local pname = minetest.get_node(pointed_thing.under).name
			local pdef = minetest.registered_nodes[pname]
			if pdef and (pdef.groups.not_in_creative_inventory or 0) == 0 and pname ~= target then
				pointed = pname
			end
		end
		local look_diameter = look_radius * 2 + 1
		minetest.show_formspec(user:get_player_name(), "technic:prospector_control",
			"size[7,8.5]"..
			"item_image[0,0;1,1;"..toolstack:get_name().."]"..
			"label[1,0;"..minetest.formspec_escape(toolstack:get_description()).."]"..
			(target and
				"label[0,1.5;"..S("Current target:").."]"..
				"label[0,2;"..minetest.formspec_escape(minetest.registered_nodes[target].description).."]"..
				"item_image[0,2.5;1,1;"..target.."]" or
				"label[0,1.5;"..S("No target set").."]")..
			(pointed and
				"label[3.5,1.5;"..S("May set new target:").."]"..
				"label[3.5,2;"..minetest.formspec_escape(minetest.registered_nodes[pointed].description).."]"..
				"item_image[3.5,2.5;1,1;"..pointed.."]"..
				"button_exit[3.5,3.65;2,0.5;target_"..pointed..";"..S("Set target").."]" or
				"label[3.5,1.5;"..S("No new target available").."]")..
			"label[0,4.5;"..S("Region cross section:").."]"..
			"label[0,5;"..look_diameter.."x"..look_diameter.."]"..
			"label[3.5,4.5;"..S("Set region cross section:").."]"..
			"button_exit[3.5,5.15;1,0.5;look_radius_0;1x1]"..
			"button_exit[4.5,5.15;1,0.5;look_radius_1;3x3]"..
			"button_exit[5.5,5.15;1,0.5;look_radius_3;7x7]"..
			"label[0,6;"..S("Region depth:").."]"..
			"label[0,6.5;"..look_depth.."]"..
			"label[3.5,6;"..S("Set region depth:").."]"..
			"button_exit[3.5,6.65;1,0.5;look_depth_7;7]"..
			"button_exit[4.5,6.65;1,0.5;look_depth_14;14]"..
			"button_exit[5.5,6.65;1,0.5;look_depth_21;21]"..
			"label[0,7.5;"..S("Accuracy:").."]"..
			"label[0,8;98%]")
		return toolstack
	end,
})

minetest.register_on_player_receive_fields(function(user, formname, fields)
	if formname ~= "technic:prospector_control" then
		return false
	end
	if not user or not user:is_player() or user.is_fake_player then
		return
	end
	local toolstack = user:get_wielded_item()
	if toolstack:get_name() ~= "technic:prospector" then
		return true
	end
	local meta = toolstack:get_meta()
	for field, value in pairs(fields) do
		if field:sub(1, 7) == "target_" then
			meta:set_string("target", field:sub(8))
		elseif field:sub(1, 12) == "look_radius_" then
			meta:set_int("look_radius", field:sub(13))
		elseif field:sub(1, 11) == "look_depth_" then
			meta:set_int("look_depth", field:sub(12))
		end
	end
	user:set_wielded_item(toolstack)
	return true
end)

minetest.register_craft({
	output = "technic:prospector",
	recipe = {
		{"moreores:pick_silver", "moreores:mithril_block", "pipeworks:teleport_tube_1"},
		{"basic_materials:brass_ingot", "technic:control_logic_unit", "basic_materials:brass_ingot"},
		{"", "technic:blue_energy_crystal", ""},
	}
})
