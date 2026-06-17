
local has_digilines = core.global_exists("digilines")

local S = technic.getter
local tube_entry = "^pipeworks_tube_connection_metallic.png"
local cable_entry = "^technic_cable_connection_overlay.png"
local mat = technic.materials

local function get_itemslot_bg(x, y, w, h)
	local out = ""
	for i = 0, w - 1, 1 do
		for j = 0, h - 1, 1 do
			out = out .. "image[" .. x + i*1.25 .. "," .. y + j*1.25 .. ";1,1;mcl_formspec_itemslot.png]"
		end
	end
	return out
end


-- Battery recipes:
-- Tin-copper recipe:
core.register_craft({
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
core.register_craft({
	output = "technic:battery",
	recipe = {
		{"group:wood",         "technic:sulfur_lump", "group:wood"},
		{"technic:lead_ingot", mat.bucket_water, "technic:lead_ingot"},
		{"group:wood",         "technic:sulfur_lump", "group:wood"},
	},
	replacements = {
		{mat.bucket_water, mat.bucket_empty}
	}
})
-- With oil extract:
core.register_craft({
	output = "technic:battery",
	recipe = {
		{"group:wood",         "technic:sulfur_lump",   "group:wood"},
		{"technic:lead_ingot", "homedecor:oil_extract", "technic:lead_ingot"},
		{"group:wood",         "technic:sulfur_lump",   "group:wood"},
	}
})
-- With sulfur dust:
-- With water:
core.register_craft({
	output = "technic:battery",
	recipe = {
		{"group:wood",         "technic:sulfur_dust", "group:wood"},
		{"technic:lead_ingot", mat.bucket_water, "technic:lead_ingot"},
		{"group:wood",         "technic:sulfur_dust", "group:wood"},
	},
	replacements = {
		{mat.bucket_water, mat.bucket_empty}
	}
})
-- With oil extract:
core.register_craft({
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
		local meta = core.get_meta(pos)
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
		local meta = core.get_meta(pos)
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

	local has_mcl_formspec = core.global_exists("mcl_formspec")
	local has_upgrades = def.upgrade

	local slot_size, slot_spacing = 1, 0.25
	local slot_interval = slot_size + slot_spacing
	local margin_x, margin_y = 0.5, 0.5
	local separation = 0.5
	local machine_section_h = 5
	local plrinv_w, plrinv_h = 8, 4
	if has_mcl_formspec then
		plrinv_w = 9
		plrinv_h = 4.25
	end
	local body_width = plrinv_w * slot_interval - slot_spacing
	local plrinv_y = machine_section_h + separation
	local body_height = plrinv_y + plrinv_h * slot_interval - slot_spacing

	local charge_arrow_length = 2
	local charge_arrow_margin = 0.25
	local charge_arrowhead_length = 0.25
	local upgrades_x, upgrades_y = body_width - (slot_size + slot_spacing + slot_size), machine_section_h - slot_size
	local energy_bar_w, energy_bar_h = 1, 2.5
	local subject_w = energy_bar_w + charge_arrow_margin * 2 + charge_arrow_length + slot_size
	local subject_h = energy_bar_h
	local energy_bar_x, energy_bar_y = (body_width - subject_w)/2, 0.75
	local label_offset = 0.2

	local formspec_base = {}
	table.insert(formspec_base, "formspec_version[4]")
	table.insert(formspec_base, ("size[%.2f,%.2f]"):format(2 * margin_x + body_width, 2 * margin_y + body_height))
	local _charge_arrow_begin = margin_x + energy_bar_x + energy_bar_w + charge_arrow_margin
	local _charge_slot_x = margin_x + energy_bar_x + subject_w - slot_size
	local _charge_begin_y = margin_y + energy_bar_y
	local _arrow_thickness = charge_arrowhead_length
	-- player inventory
	if has_mcl_formspec then
		local top_inv_y = margin_y + plrinv_y
		local hotbar_y = top_inv_y + 3 * slot_interval + slot_spacing
		table.insert(formspec_base, get_itemslot_bg(_charge_slot_x, _charge_begin_y,1,1))
		table.insert(formspec_base, get_itemslot_bg(_charge_slot_x, _charge_begin_y + subject_h - slot_size, 1,1))
		table.insert(formspec_base, get_itemslot_bg(margin_x, top_inv_y, plrinv_w, 3))
		table.insert(formspec_base, get_itemslot_bg(margin_x, hotbar_y, plrinv_w,1))
		table.insert(formspec_base,("list[current_player;main;%.2f,%.2f;%d,3;9]")
				:format(margin_x, top_inv_y, plrinv_w))
		table.insert(formspec_base,("list[current_player;main;%.2f,%.2f;%d,1;]")
				:format(margin_x, hotbar_y, plrinv_w))
	else
		table.insert(formspec_base, ("list[current_player;main;%.2f,%.2f;%d,%d;]")
				:format(margin_x, margin_y + plrinv_y, plrinv_w, plrinv_h))
	end
	table.insert(formspec_base, ("list[context;src;%.2f,%.2f;1,1;]")
		:format(_charge_slot_x, _charge_begin_y))
	table.insert(formspec_base, ("list[context;dst;%.2f,%.2f;1,1;]")
		:format(_charge_slot_x, _charge_begin_y + subject_h - slot_size))
	table.insert(formspec_base, ("label[%.2f,%.2f;%s]")
		:format(_charge_slot_x, _charge_begin_y + slot_size + label_offset, S("Charge")))
	table.insert(formspec_base, ("label[%.2f,%.2f;%s]")
		:format(_charge_slot_x, _charge_begin_y + subject_h + label_offset, S("Discharge")))
	table.insert(formspec_base, ("image[%.2f,%.2f;%.2f,%.2f;%s]")
		:format(
			_charge_arrow_begin, _charge_begin_y + (slot_size - _arrow_thickness)/2,
			charge_arrow_length - charge_arrowhead_length, _arrow_thickness,
			"blank.png^[invert:ga"
		))
	table.insert(formspec_base, ("image[%.2f,%.2f;%.2f,%.2f;%s]")
		:format(
			_charge_arrow_begin + charge_arrow_length - charge_arrowhead_length,
			_charge_begin_y + slot_size/2 - charge_arrowhead_length,
			charge_arrowhead_length, charge_arrowhead_length * 2,
			"technic_arrowhead.png^[invert:rb"
		))
	table.insert(formspec_base, ("image[%.2f,%.2f;%.2f,%.2f;%s]")
		:format(
			_charge_arrow_begin + charge_arrowhead_length,
			_charge_begin_y + subject_h - (slot_size + _arrow_thickness)/2,
			charge_arrow_length - charge_arrowhead_length, _arrow_thickness,
			"blank.png^[invert:ra"
		))
	table.insert(formspec_base, ("image[%.2f,%.2f;%.2f,%.2f;%s]")
		:format(
			_charge_arrow_begin,
			_charge_begin_y + subject_h - slot_size/2 - charge_arrowhead_length,
			charge_arrowhead_length, charge_arrowhead_length * 2,
			"technic_arrowhead.png^[transformFX^[invert:gb"
		))
	-- upgrades
	if has_upgrades then
		if has_mcl_formspec then
			table.insert(formspec_base, get_itemslot_bg(margin_x + upgrades_x, margin_y + upgrades_y,1,1))
			table.insert(formspec_base, get_itemslot_bg(margin_x + upgrades_x + slot_interval, margin_y + upgrades_y,1,1))
		end
		table.insert(formspec_base, ("list[context;upgrade1;%.2f,%.2f;1,1;]")
			:format(margin_x + upgrades_x, margin_y + upgrades_y))
		table.insert(formspec_base, ("list[context;upgrade2;%.2f,%.2f;1,1;]")
			:format(margin_x + upgrades_x + slot_interval, margin_y + upgrades_y))
		table.insert(formspec_base, ("label[%.2f,%.2f;%s]")
			:format(margin_x + upgrades_x, margin_y + upgrades_y + slot_size + label_offset, S("Upgrade Slots")))
	end
	-- listrings
	table.insert(formspec_base, "listring[context;dst]")
	table.insert(formspec_base, "listring[current_player;main]")
	table.insert(formspec_base, "listring[context;src]")
	table.insert(formspec_base, "listring[current_player;main]")
	if has_upgrades then
		table.insert(formspec_base, "listring[context;upgrade1]")
		table.insert(formspec_base, "listring[current_player;main]")
		table.insert(formspec_base, "listring[context;upgrade2]")
		table.insert(formspec_base, "listring[current_player;main]")
	end
	table.insert(formspec_base, ("image[%.2f,%.2f;%.2f,%.2f;technic_power_meter_bg.png]")
		:format(margin_x + energy_bar_x, margin_y + energy_bar_y, energy_bar_w, energy_bar_h))
	table.insert(formspec_base, ("label[%.2f,%.2f;%s]")
		:format(margin_x, margin_y, S("@1 Battery Box", S(tier))))
	table.insert(formspec_base, ("label[%.2f,%.2f;%s]")
		:format(margin_x + energy_bar_x, margin_y + energy_bar_y + energy_bar_h + label_offset,	S("Power level")))

	formspec_base = table.concat(formspec_base)

	--
	-- Generate formspec with power meter
	--
	local function get_formspec(charge_ratio, current_charge, max_charge)
		local formspec = {formspec_base}
		table.insert(formspec,
			("image[%.2f,%.2f;%.2f,%.2f;technic_power_meter_bg.png^[lowpart:%d:technic_power_meter_fg.png]"):
			format(margin_x + energy_bar_x, margin_y + energy_bar_y, energy_bar_w, energy_bar_h, charge_ratio * 100)
		)
		table.insert(formspec, ("tooltip[%.2f,%.2f;%.2f,%.2f;%s]"):format(
			margin_x + energy_bar_x, margin_y + energy_bar_y, energy_bar_w, energy_bar_h,
			("%s / %s"):format(technic.EU_string(current_charge), technic.EU_string(max_charge))
		))
		if has_digilines then
			local channel_w, channel_h = 2.5, 0.8
			local button_w, button_h = 1, channel_h
			local channel_x, channel_y = 0, machine_section_h - channel_h
			table.insert(formspec, ("field[%.2f,%.2f;%.2f,%.2f;channel;%s;${channel}]")
				:format(margin_x + channel_x, margin_y + channel_y, channel_w, channel_h, S("Digiline Channel")))
			table.insert(formspec, ("button[%.2f,%.2f;%.2f,%.2f;setchannel;%s]")
				:format(margin_x + channel_x + channel_w, margin_y + channel_y, button_w, button_h, S("Save")))
		end
		return table.concat(formspec)

	end

	--
	-- Update fields not affecting internal network calculations and behavior in any way
	--
	local function update_node(pos, update_formspec)
		-- Read metadata and calculate actual values based on upgrades
		local meta = core.get_meta(pos)
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
			meta:set_string("formspec", get_formspec(charge_ratio, current_charge, max_charge))
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
		local meta  = core.get_meta(pos)

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

		local timer = core.get_node_timer(pos)
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

		core.register_node(colon..nodename..i, {
			description = S("@1 Battery Box", S(tier)),
			tiles = {
				top_tex,
				bottom_tex,
				side_tex,
				side_tex,
				side_tex,
				front_tex},
			groups = groups,
			is_ground_content = false,
			_mcl_blast_resistance = 1,
			_mcl_hardness = 0.8,
			connect_sides = {"bottom"},
			tube = def.tube and tube or nil,
			paramtype2 = "facedir",
			sounds = technic.sounds.node_sound_wood_defaults(),
			drop = "technic:"..ltier.."_battery_box0",
			on_construct = function(pos)
				local meta = core.get_meta(pos)
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
			on_metadata_inventory_move = technic.machine_on_inventory_move,
			on_metadata_inventory_put = technic.machine_on_inventory_put,
			on_metadata_inventory_take = technic.machine_on_inventory_take,
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
				if core.is_protected(pos, playername) then
					core.record_protection_violation(pos, playername)
					return
				elseif fields.setchannel then
					local meta = core.get_meta(pos)
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
						local meta = core.get_meta(pos)
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
