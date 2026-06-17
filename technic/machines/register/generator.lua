local S = technic.getter

local fs_helpers = pipeworks.fs_helpers
local tube_entry = "^pipeworks_tube_connection_metallic.png"

local tube = {
	insert_object = function(pos, node, stack, direction)
		local meta = core.get_meta(pos)
		local inv = meta:get_inventory()
		return inv:add_item("src", stack)
	end,
	can_insert = function(pos, node, stack, direction)
		local meta = core.get_meta(pos)
		local inv = meta:get_inventory()
		if meta:get_int("splitstacks") == 1 then
			stack = stack:peek_item(1)
		end
		return inv:room_for_item("src", stack)
	end,
	connect_sides = {left=1, right=1, back=1, top=1, bottom=1},
}

local has_mcl_formspec = core.global_exists("mcl_formspec")

local generator_formspec_base = {}
local margin_x, margin_y = 0.5, 0.5
local slot_size, slot_spacing = 1, 0.25
local slot_interval = slot_size + slot_spacing
local separation = 0.5
local machine_section_h = 5
local plrinv_w, plrinv_h = 8, 4
if has_mcl_formspec then
	plrinv_w = 9
end
local body_width = plrinv_w * slot_interval - slot_spacing
local plrinv_y = machine_section_h + separation
local body_height = plrinv_y + plrinv_h * slot_interval - slot_spacing

local subject_w = slot_size
local src_x, src_y = (body_width - subject_w)/2, 2

table.insert(generator_formspec_base, "formspec_version[4]")
table.insert(generator_formspec_base, ("size[%.2f,%.2f]"):format(2 * margin_x + body_width, 2 * margin_y + body_height))
table.insert(generator_formspec_base, ("list[context;src;%.2f,%.2f;1,1;]")
	:format(margin_x + src_x, margin_y + src_y))
-- listrings
table.insert(generator_formspec_base, "listring[context;src]")
table.insert(generator_formspec_base, "listring[current_player;main]")
-- player inventory
if has_mcl_formspec then
	table.insert(generator_formspec_base, mcl_formspec.get_itemslot_bg(3,1,1,1))
	table.insert(generator_formspec_base, mcl_formspec.get_itemslot_bg(5,1,1,1))
	table.insert(generator_formspec_base,"list[current_player;main;0,4.5;9,3;9]")
	table.insert(generator_formspec_base, mcl_formspec.get_itemslot_bg(0,4.5,9,3))
	table.insert(generator_formspec_base,"list[current_player;main;0,7.74;9,1;]")
	table.insert(generator_formspec_base, mcl_formspec.get_itemslot_bg(0,7.74,9,1))
else
	table.insert(generator_formspec_base, ("list[current_player;main;%.2f,%.2f;%d,%d;]")
		:format(margin_x, margin_y + plrinv_y, plrinv_w, plrinv_h))
end

generator_formspec_base = table.concat(generator_formspec_base)

local presumed_form_buttons = function(meta)
	return fs_helpers.cycling_button(
		meta,
		pipeworks.button_base:gsub("%[0%,4%.3%;1%,0%.6", ("[%.2f,%.2f;%.2f,%.2f")
			:format(margin_x, margin_y + machine_section_h - 0.5 + 0.1, 1, 0.5)),
		"splitstacks",
		{
			pipeworks.button_off,
			pipeworks.button_on
		}
	)..pipeworks.button_label:gsub("%[0%.9%,4%.31", ("[%.2f,%.2f")
		:format(margin_x + 1, margin_y + machine_section_h - 0.25 + 0.1))
end

local function update_generator_formspec(meta, desc, percent, form_buttons)
	local generator_formspec = {generator_formspec_base, form_buttons}
	table.insert(generator_formspec, ("label[%.2f,%.2f;%s]")
		:format(margin_x, margin_y, desc))
	table.insert(generator_formspec, ("image[%.2f,%.2f;1,1;%s]")
		:format(margin_x + src_x, margin_y + src_y - slot_interval,
			("default_furnace_fire_bg.png^[lowpart:%d:default_furnace_fire_fg.png]"):format(percent)
		))
	return meta:set_string("formspec", table.concat(generator_formspec))
end

function technic.register_generator(data)

	local tier = data.tier
	local ltier = string.lower(tier)

	local groups = {snappy=2, choppy=2, oddly_breakable_by_hand=2,
		technic_machine=1, ["technic_"..ltier]=1, axey=2, handy=1}
	if data.tube then
		groups.tubedevice = 1
		groups.tubedevice_receiver = 1
	end
	local active_groups = {not_in_creative_inventory = 1}
	for k, v in pairs(groups) do active_groups[k] = v end

	local desc = S("Fuel-Fired @1 Generator", S(tier))

	local run = function(pos, node)
		local meta = core.get_meta(pos)
		local burn_time = meta:get_int("burn_time")
		local burn_totaltime = meta:get_int("burn_totaltime")
		-- If more to burn and the energy produced was used: produce some more
		if burn_time > 0 then
			meta:set_int(tier.."_EU_supply", data.supply)
			burn_time = burn_time - 1
			meta:set_int("burn_time", burn_time)
		end
		-- Burn another piece of fuel
		if burn_time == 0 then
			local inv = meta:get_inventory()
			if not inv:is_empty("src") then
				local fuellist = inv:get_list("src")
				local fuel
				local afterfuel
				fuel, afterfuel = core.get_craft_result(
						{method = "fuel", width = 1,
						items = fuellist})
				if not fuel or fuel.time == 0 then
					meta:set_string("infotext", S("@1 Out Of Fuel", desc))
					technic.swap_node(pos, "technic:"..ltier.."_generator")
					meta:set_int(tier.."_EU_supply", 0)
					return
				end
				meta:set_int("burn_time", fuel.time)
				meta:set_int("burn_totaltime", fuel.time)
				inv:set_stack("src", 1, afterfuel.items[1])
				technic.swap_node(pos, "technic:"..ltier.."_generator_active")
				meta:set_int(tier.."_EU_supply", data.supply)
			else
				technic.swap_node(pos, "technic:"..ltier.."_generator")
				meta:set_int(tier.."_EU_supply", 0)
			end
		end
		if burn_totaltime == 0 then burn_totaltime = 1 end
		local percent = math.floor((burn_time / burn_totaltime) * 100)
		meta:set_string("infotext", desc.." ("..percent.."%)")

		local form_buttons = ""
		if ltier ~= "lv" then
			form_buttons = presumed_form_buttons(meta)
		end
		update_generator_formspec(meta, desc, percent, form_buttons)
	end

	local tentry = tube_entry
	if ltier == "lv" then tentry = "" end

	core.register_node("technic:"..ltier.."_generator", {
		description = desc,
		tiles = {
				"technic_"..ltier.."_generator_top.png"..tentry,
				"technic_machine_bottom.png"..tentry,
				"technic_"..ltier.."_generator_side.png"..tentry,
				"technic_"..ltier.."_generator_side.png"..tentry,
				"technic_"..ltier.."_generator_side.png"..tentry,
				"technic_"..ltier.."_generator_front.png"
		},
		paramtype2 = "facedir",
		groups = groups,
		is_ground_content = false,
		_mcl_blast_resistance = 1,
		_mcl_hardness = 0.8,
		connect_sides = {"bottom", "back", "left", "right"},
		legacy_facedir_simple = true,
		sounds = technic.sounds.node_sound_wood_defaults(),
		tube = data.tube and tube or nil,
		on_construct = function(pos)
			local meta = core.get_meta(pos)
			local node = core.get_node(pos)
			meta:set_string("infotext", desc)
			meta:set_int(data.tier.."_EU_supply", 0)
			meta:set_int("burn_time", 0)
			meta:set_int("tube_time",  0)
			local form_buttons = ""
			if not string.find(node.name, ":lv_") then
				form_buttons = presumed_form_buttons(meta)
			end
			update_generator_formspec(meta, desc, 0, form_buttons)
			local inv = meta:get_inventory()
			inv:set_size("src", 1)
		end,
		can_dig = technic.machine_can_dig,
		allow_metadata_inventory_put = technic.machine_inventory_put,
		allow_metadata_inventory_take = technic.machine_inventory_take,
		allow_metadata_inventory_move = technic.machine_inventory_move,
		technic_run = run,
		after_place_node = data.tube and pipeworks.after_place,
		after_dig_node = technic.machine_after_dig_node,
		on_receive_fields = function(pos, formname, fields, sender)
			if not pipeworks.may_configure(pos, sender) then return end
			fs_helpers.on_receive_fields(pos, fields)
			local meta = core.get_meta(pos)
			local node = core.get_node(pos)
			local form_buttons = ""
			if not string.find(node.name, ":lv_") then
				form_buttons = presumed_form_buttons(meta)
			end
			local burn_totaltime = meta:get_int("burn_totaltime") or 0
			local burn_time = meta:get_int("burn_time")
			local percent = math.floor(burn_time / burn_totaltime * 100)
			update_generator_formspec(meta, desc, percent, form_buttons)
		end,
	})

	core.register_node("technic:"..ltier.."_generator_active", {
		description = desc,
		tiles = {
			"technic_"..ltier.."_generator_top.png"..tube_entry,
			"technic_machine_bottom.png"..tube_entry,
			"technic_"..ltier.."_generator_side.png"..tube_entry,
			"technic_"..ltier.."_generator_side.png"..tube_entry,
			"technic_"..ltier.."_generator_side.png"..tube_entry,
			"technic_"..ltier.."_generator_front_active.png"
		},
		paramtype2 = "facedir",
		groups = active_groups,
		is_ground_content = false,
		_mcl_blast_resistance = 1,
		_mcl_hardness = 0.8,
		connect_sides = {"bottom"},
		legacy_facedir_simple = true,
		sounds = technic.sounds.node_sound_wood_defaults(),
		tube = data.tube and tube or nil,
		drop = "technic:"..ltier.."_generator",
		can_dig = technic.machine_can_dig,
		after_dig_node = technic.machine_after_dig_node,
		allow_metadata_inventory_put = technic.machine_inventory_put,
		allow_metadata_inventory_take = technic.machine_inventory_take,
		allow_metadata_inventory_move = technic.machine_inventory_move,
		technic_run = run,
		technic_on_disable = function(pos, node)
			local timer = core.get_node_timer(pos)
			timer:start(1)
		end,
		on_timer = function(pos)
			-- Connected back?
			if technic.get_timeout(tier, pos) > 0 then return false end

			local meta = core.get_meta(pos)
			local node = core.get_node(pos)

			local burn_time = meta:get_int("burn_time") or 0

			if burn_time <= 0 then
				meta:set_int(tier.."_EU_supply", 0)
				meta:set_int("burn_time", 0)
				technic.swap_node(pos, "technic:"..ltier.."_generator")
				return false
			end

			local burn_totaltime = meta:get_int("burn_totaltime") or 0
			if burn_totaltime == 0 then burn_totaltime = 1 end
			burn_time = burn_time - 1
			meta:set_int("burn_time", burn_time)
			local percent = math.floor(burn_time / burn_totaltime * 100)

			local form_buttons = ""
			if not string.find(node.name, ":lv_") then
				form_buttons = presumed_form_buttons(meta)
			end
			update_generator_formspec(meta, desc, percent, form_buttons)
			return true
		end,
		on_receive_fields = function(pos, formname, fields, sender)
			if not pipeworks.may_configure(pos, sender) then return end
			fs_helpers.on_receive_fields(pos, fields)
			local meta = core.get_meta(pos)
			local node = core.get_node(pos)
			local form_buttons = ""
			if not string.find(node.name, ":lv_") then
				form_buttons = presumed_form_buttons(meta)
			end

			local burn_totaltime = meta:get_int("burn_totaltime") or 0
			local burn_time = meta:get_int("burn_time")
			local percent = math.floor(burn_time / burn_totaltime * 100)

			update_generator_formspec(meta, desc, percent, form_buttons)
		end,
	})

	technic.register_machine(tier, "technic:"..ltier.."_generator",        technic.producer)
	technic.register_machine(tier, "technic:"..ltier.."_generator_active", technic.producer)
end

