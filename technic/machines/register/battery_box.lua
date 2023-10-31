
local digilines_path = minetest.get_modpath("digilines")

local S = technic.getter
local tube_entry = "^pipeworks_tube_connection_metallic.png"
local cable_entry = "^technic_cable_connection_overlay.png"
local mat = technic.materials

-- Battery recipes:
-- Tin-copper recipe:
minetest.register_craft({
	output = "technic:battery",
	recipe = {
		{"group:wood", mat.copper_ingot, "group:wood"},
		{"group:wood", mat.tin_ingot,    "group:wood"},
		{"group:wood", mat.copper_ingot, "group:wood"},
	}
})
-- Sulfur-lead-water recipes:
-- With sulfur lumps:
-- With water:
minetest.register_craft({
	output = "technic:battery",
	recipe = {
		{"group:wood",         "technic:sulfur_lump", "group:wood"},
		{"technic:lead_ingot", "bucket:bucket_water", "technic:lead_ingot"},
		{"group:wood",         "technic:sulfur_lump", "group:wood"},
	},
	replacements = {
		{"bucket:bucket_water", "bucket:bucket_empty"}
	}
})
-- With oil extract:
minetest.register_craft({
	output = "technic:battery",
	recipe = {
		{"group:wood",         "technic:sulfur_lump",   "group:wood"},
		{"technic:lead_ingot", "homedecor:oil_extract", "technic:lead_ingot"},
		{"group:wood",         "technic:sulfur_lump",   "group:wood"},
	}
})
-- With sulfur dust:
-- With water:
minetest.register_craft({
	output = "technic:battery",
	recipe = {
		{"group:wood",         "technic:sulfur_dust", "group:wood"},
		{"technic:lead_ingot", "bucket:bucket_water", "technic:lead_ingot"},
		{"group:wood",         "technic:sulfur_dust", "group:wood"},
	},
	replacements = {
		{"bucket:bucket_water", "bucket:bucket_empty"}
	}
})
-- With oil extract:
minetest.register_craft({
	output = "technic:battery",
	recipe = {
		{"group:wood",         "technic:sulfur_dust",   "group:wood"},
		{"technic:lead_ingot", "homedecor:oil_extract", "technic:lead_ingot"},
		{"group:wood",         "technic:sulfur_dust",   "group:wood"},
	}
})

technic.register_power_tool("technic:battery", {
	description = S("RE Battery"),
	inventory_image = "technic_battery.png",
	groups = { disable_repair = 1 },
})

-- x+2 + (z+2)*2
local dirtab = {
	[4] = 2,
	[5] = 3,
	[7] = 1,
	[8] = 0
}

local tube = {
	insert_object = function(pos, node, stack, direction)
		if direction.y == 1
			or (direction.y == 0 and dirtab[direction.x+2+(direction.z+2)*2] == node.param2) then
			return stack
		end
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		if direction.y == 0 then
			return inv:add_item("src", stack)
		else
			return inv:add_item("dst", stack)
		end
	end,
	can_insert = function(pos, node, stack, direction)
		if direction.y == 1
			or (direction.y == 0 and dirtab[direction.x+2+(direction.z+2)*2] == node.param2) then
			return false
		end
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		if direction.y == 0 then
			return inv:room_for_item("src", stack)
		else
			return inv:room_for_item("dst", stack)
		end
	end,
	connect_sides = {left=1, right=1, back=1, top=1},
}

function technic.register_battery_box(nodename, data)
	local colon, modname, name, def = technic.register_compat_v1_to_v2(nodename, data, "battery_box")
	local texture_prefix = modname.."_"..name
	nodename = modname..":"..name

	local tier = def.tier
	local ltier = string.lower(tier)

	local formspec =
		"size[9,9]"..
		"image[1,1;1,2;technic_power_meter_bg.png]"..
		"list[context;src;3,1;1,1;]"..
		"image[4,1;1,1;technic_battery_reload.png]"..
		"list[context;dst;5,1;1,1;]"..
		"label[0,0;"..S("@1 Battery Box", S(tier)).."]"..
		"label[3,0;"..S("Charge").."]"..
		"label[5,0;"..S("Discharge").."]"..
		"label[1,3;"..S("Power level").."]"..
		"listring[context;dst]"..
		"listring[current_player;main]"..
		"listring[context;src]"..
		"listring[current_player;main]"..
		(def.upgrade and
			"list[context;upgrade1;3.5,3;1,1;]"..
			"list[context;upgrade2;4.5,3;1,1;]"..
			"label[3.5,4;"..S("Upgrade Slots").."]"..
			"listring[context;upgrade1]"..
			"listring[current_player;main]"..
			"listring[context;upgrade2]"..
			"listring[current_player;main]"
			or "")

	if minetest.get_modpath("mcl_formspec") then
		formspec = formspec..
			mcl_formspec.get_itemslot_bg(3,1,1,1)..
			mcl_formspec.get_itemslot_bg(5,1,1,1)..
			-- player inventory
			"list[current_player;main;0,4.5;9,3;9]"..
			mcl_formspec.get_itemslot_bg(0,4.5,9,3)..
			"list[current_player;main;0,7.74;9,1;]"..
			mcl_formspec.get_itemslot_bg(0,7.74,9,1)..
			"listring[current_player;main]"..
			-- upgrade
			(def.upgrade and
				mcl_formspec.get_itemslot_bg(3.5,3,1,1)..
				mcl_formspec.get_itemslot_bg(4.5,3,1,1)
			or "")
	else
		formspec = formspec..
		"list[current_player;main;0,5;8,4;]"
	end


	--
	-- Generate formspec with power meter
	--
	local function get_formspec(charge_ratio, channel)
		return formspec .. "image[1,1;1,2;technic_power_meter_bg.png^[lowpart:" ..
			math.floor(charge_ratio * 100) .. ":technic_power_meter_fg.png]" ..
			(digilines_path and
				("field[0.3,4;2.2,1;channel;"..S("Digiline Channel")..";${channel}]"..
				"button[2,3.7;1,1;setchannel;"..S("Save").."]") or "")

	end

	--
	-- Update fields not affecting internal network calculations and behavior in any way
	--
	local function update_node(pos, update_formspec)
		-- Read metadata and calculate actual values based on upgrades
		local meta = minetest.get_meta(pos)
		local current_charge = meta:get_int("internal_EU_charge")
		local EU_upgrade = 0
		if def.upgrade then
			EU_upgrade = technic.handle_machine_upgrades(meta)
		end
		local max_charge = def.max_charge * (1 + EU_upgrade / 10)
		-- Select node textures
		local charge_ratio = current_charge / max_charge
		local charge_count = math.ceil(charge_ratio * 8)
		charge_count = math.min(charge_count, 8)
		charge_count = math.max(charge_count, 0)
		local last_count = meta:get_float("last_side_shown")
		if charge_count ~= last_count then
			technic.swap_node(pos, nodename .. charge_count)
			meta:set_float("last_side_shown", charge_count)
		end
		-- Update formspec and infotext
		local eu_input = meta:get_int(tier.."_EU_input")
		local infotext = S("@1 Battery Box: @2 / @3", tier,
			technic.EU_string(current_charge), technic.EU_string(max_charge))
		if eu_input == 0 then
			infotext = S("@1 Idle", infotext)
		end
		meta:set_string("infotext", infotext)
		if update_formspec then
			local channel = meta:get_string("channel")
			meta:set_string("formspec", get_formspec(charge_ratio, channel))
		end
	end

	local function get_tool(inventory, listname)
		-- Get itemstack and check if it is registered tool
		if inventory:is_empty(listname) then
			return
		end
		-- Get itemstack and check if it is registered tool
		local toolstack = inventory:get_stack(listname, 1)
		local tooldef = toolstack:get_definition()
		if not tooldef.technic_max_charge then
			return
		end
		return toolstack, tooldef
	end

	local function charge_tools(meta, batt_charge, charge_step)
		-- Get tool metadata
		local inv = meta:get_inventory()
		local toolstack, tooldef = get_tool(inv, "src")
		if not toolstack then
			return batt_charge, false
		end
		-- Do the charging
		local charge = tooldef.technic_get_charge(toolstack)
		if charge >= tooldef.technic_max_charge then
			return batt_charge, true
		elseif batt_charge <= 0 then
			return batt_charge, false
		end
		local oldcharge = charge
		charge_step = math.min(charge_step, batt_charge, tooldef.technic_max_charge - charge)
		charge = charge + charge_step
		if charge ~= oldcharge then
			tooldef.technic_set_charge(toolstack, charge)
			inv:set_stack("src", 1, toolstack)
		end
		return batt_charge - charge_step, (charge == tooldef.technic_max_charge)
	end

	local function discharge_tools(meta, batt_charge, charge_step, batt_max_charge)
		-- Get tool metadata
		local inv = meta:get_inventory()
		local toolstack, tooldef = get_tool(inv, "dst")
		if not toolstack then
			return batt_charge, false
		end
		-- Do the discharging
		local charge = tooldef.technic_get_charge(toolstack)
		if charge <= 0 then
			return batt_charge, true
		elseif batt_charge >= batt_max_charge then
			return batt_charge, false
		end
		local oldcharge = charge
		charge_step = math.min(charge_step, batt_max_charge - batt_charge, charge)
		charge = charge - charge_step
		if charge ~= oldcharge then
			tooldef.technic_set_charge(toolstack, charge)
			inv:set_stack("dst", 1, toolstack)
		end
		return batt_charge + charge_step, (charge == 0)
	end

	local function run(pos, node, run_state, network)
		local meta  = minetest.get_meta(pos)

		local eu_input       = meta:get_int(tier.."_EU_input")
		local current_charge = meta:get_int("internal_EU_charge")

		local EU_upgrade, tube_upgrade = 0, 0
		if def.upgrade then
			EU_upgrade, tube_upgrade = technic.handle_machine_upgrades(meta)
		end
		local max_charge = def.max_charge * (1 + EU_upgrade / 10)

		-- Charge/discharge the battery with the input EUs
		if eu_input >= 0 then
			current_charge = math.min(current_charge + eu_input, max_charge)
		else
			current_charge = math.max(current_charge + eu_input, 0)
		end

		-- Charging/discharging tools here
		local tool_full, tool_empty
		current_charge, tool_full = charge_tools(meta, current_charge, def.charge_step)
		current_charge, tool_empty = discharge_tools(meta, current_charge, def.discharge_step, max_charge)

		if def.tube and (tool_full or tool_empty) then
			technic.handle_machine_pipeworks(pos, tube_upgrade, function(pos2, x_velocity, z_velocity)
				if tool_full then
					technic.send_items(pos2, x_velocity, z_velocity, "src")
				elseif tool_empty then
					technic.send_items(pos2, x_velocity, z_velocity, "dst")
				end
			end)
		end

		-- We allow batteries to charge on less than the demand
		local supply = math.min(def.discharge_rate, current_charge)
		local demand = math.min(def.charge_rate, max_charge - current_charge)
		network:update_battery(current_charge, max_charge, supply, demand)

		meta:set_int(tier.."_EU_demand", demand)
		meta:set_int(tier.."_EU_supply", supply)
		meta:set_int("internal_EU_charge", current_charge)
		meta:set_int("internal_EU_charge_max", max_charge)

		local timer = minetest.get_node_timer(pos)
		if not timer:is_started() then
			timer:start(2)
		end
	end

	local function on_timer(pos, elapsed)
		if not technic.pos2network(pos) then return end
		update_node(pos)
		return true
	end

	for i = 0, 8 do
		local groups = {snappy=2, choppy=2, oddly_breakable_by_hand=2,
				technic_machine=1, ["technic_"..ltier]=1, axey=2, handy=1}
		if i ~= 0 then
			groups.not_in_creative_inventory = 1
		end

		if def.tube then
			groups.tubedevice = 1
			groups.tubedevice_receiver = 1
		end

		local top_tex = texture_prefix.."_top.png"..tube_entry
		local front_tex = texture_prefix.."_front.png^technic_power_meter"..i..".png"
		local side_tex = texture_prefix.."_side.png"..tube_entry
		local bottom_tex = texture_prefix.."_bottom.png"..cable_entry
		if ltier == "lv" then
			top_tex = texture_prefix.."_top.png"
			front_tex = texture_prefix.."_side.png^technic_power_meter"..i..".png"
			side_tex = texture_prefix.."_side.png^technic_power_meter"..i..".png"
		end

		minetest.register_node(colon..nodename..i, {
			description = S("@1 Battery Box", S(tier)),
			tiles = {
				top_tex,
				bottom_tex,
				side_tex,
				side_tex,
				side_tex,
				front_tex},
			groups = groups,
			_mcl_blast_resistance = 1,
			_mcl_hardness = 0.8,
			connect_sides = {"bottom"},
			tube = def.tube and tube or nil,
			paramtype2 = "facedir",
			sounds = technic.sounds.node_sound_wood_defaults(),
			drop = "technic:"..ltier.."_battery_box0",
			on_construct = function(pos)
				local meta = minetest.get_meta(pos)
				meta:set_string("infotext", S("@1 Battery Box", S(tier)))
				meta:set_int(tier.."_EU_demand", 0)
				meta:set_int(tier.."_EU_supply", 0)
				meta:set_int(tier.."_EU_input",  0)
				meta:set_float("internal_EU_charge", 0)
				local inv = meta:get_inventory()
				inv:set_size("src", 1)
				inv:set_size("dst", 1)
				inv:set_size("upgrade1", 1)
				inv:set_size("upgrade2", 1)
				update_node(pos, true)
			end,
			can_dig = technic.machine_can_dig,
			allow_metadata_inventory_put = technic.machine_inventory_put,
			allow_metadata_inventory_take = technic.machine_inventory_take,
			allow_metadata_inventory_move = technic.machine_inventory_move,
			technic_run = run,
			on_timer = on_timer,
			on_rightclick = function(pos) update_node(pos, true) end,
			on_rotate = function(pos, node, user, mode, new_param2)
				if mode ~= 1 then
					return false
				end
			end,
			after_place_node = def.tube and pipeworks.after_place,
			after_dig_node = technic.machine_after_dig_node,
			on_receive_fields = function(pos, formname, fields, player)
				if fields.quit then
					return
				end
				local playername = player:get_player_name()
				if minetest.is_protected(pos, playername) then
					minetest.record_protection_violation(pos, playername)
					return
				elseif fields.setchannel then
					local meta = minetest.get_meta(pos)
					meta:set_string("channel", fields.channel or "")
					update_node(pos, true)
				end
			end,
			digiline = {
				receptor = {
					rules = technic.digilines.rules,
					action = function() end
				},
				effector = {
					rules = technic.digilines.rules,
					action = function(pos, node, channel, msg)
						if msg ~= "GET" and msg ~= "get" then
							return
						end
						local meta = minetest.get_meta(pos)
						if channel ~= meta:get_string("channel") then
							return
						end
						local inv = meta:get_inventory()
						digilines.receptor_send(pos, technic.digilines.rules, channel, {
							demand = meta:get_int(tier.."_EU_demand"),
							supply = meta:get_int(tier.."_EU_supply"),
							input  = meta:get_int(tier.."_EU_input"),
							charge = meta:get_int("internal_EU_charge"),
							max_charge = def.max_charge * (1 + technic.handle_machine_upgrades(meta) / 10),
							src      = inv:get_stack("src", 1):to_table(),
							dst      = inv:get_stack("dst", 1):to_table(),
							upgrade1 = inv:get_stack("upgrade1", 1):to_table(),
							upgrade2 = inv:get_stack("upgrade2", 1):to_table()
						})
					end
				},
			},
		})
	end

	-- Register as a battery type
	-- Battery type machines function as power reservoirs and can both receive and give back power
	for i = 0, 8 do
		technic.register_machine(tier, nodename..i, technic.battery)
	end

end -- End registration
