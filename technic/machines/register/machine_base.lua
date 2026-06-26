
local S = technic.getter

local fs_helpers = pipeworks.fs_helpers
local tube_entry = "^pipeworks_tube_connection_metallic.png"

local function get_itemslot_bg(x, y, w, h) -- mcl hasn't moved to real co-ordinates yet
	local out = ""
	for i = 0, w - 1, 1 do
		for j = 0, h - 1, 1 do
			out = out .. "image[" .. x + i*1.25 .. "," .. y + j*1.25 .. ";1,1;mcl_formspec_itemslot.png]"
		end
	end
	return out
end

function technic.default_can_insert(pos, node, stack, direction)
	local meta = core.get_meta(pos)
	local inv = meta:get_inventory()
	if meta:get_int("splitstacks") == 1 then
		stack = stack:peek_item(1)
	end
	return inv:room_for_item("src", stack)
end

function technic.new_default_tube()
	return {
		insert_object = function(pos, node, stack, direction)
			local meta = core.get_meta(pos)
			local inv = meta:get_inventory()
			return inv:add_item("src", stack)
		end,
		can_insert = technic.default_can_insert,
		connect_sides = {left = 1, right = 1, back = 1, top = 1, bottom = 1},
	}
end

local connect_default = {"bottom", "back", "left", "right"}

function technic.register_base_machine(nodename, data)
	local colon, modname, name, def = technic.register_compat_v1_to_v2(nodename, data)
	local texture_prefix = modname.."_"..name
	nodename = modname..":"..name

	local typename = def.typename
	local input_size = technic.recipes[typename].input_size
	local tier = def.tier
	local ltier = string.lower(tier)
	local infotext_idle = S("@1 Idle", def.description)
	local infotext_active = S("@1 Active", def.description)
	local infotext_unpowered = S("@1 Unpowered", def.description)

	local groups = {cracky = 2, technic_machine = 1, ["technic_"..ltier] = 1, pickaxey=2}
	if def.tube then
		groups.tubedevice = 1
		groups.tubedevice_receiver = 1
	end
	local active_groups = table.copy(groups)
	active_groups.not_in_creative_inventory = 1

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

	local arrow_length = 1
	local arrow_margin = 0.25
	local arrowhead_length = 0.25
	local upgrades_x, upgrades_y = body_width - (slot_size + slot_spacing + slot_size), machine_section_h - slot_size
	local dst_w = (slot_size + slot_spacing + slot_size)
	local subject_w = slot_size + arrow_margin * 2 + arrow_length + dst_w
	local src_x, src_y = (body_width - subject_w)/2, 1
	local label_offset = 0.2

	local formspec_base = {}
	table.insert(formspec_base, "formspec_version[4]")
	table.insert(formspec_base, ("size[%.2f,%.2f]"):format(2 * margin_x + body_width, 2 * margin_y + body_height))
	table.insert(formspec_base, ("label[%.2f,%.2f;%s]")
		:format(margin_x, margin_y, def.description))
	local _arrow_begin = margin_x + src_x + slot_size + arrow_margin
	local _dst_x = margin_x + src_x + subject_w - dst_w
	local _begin_y = margin_y + src_y
	local _arrow_thickness = arrowhead_length
	-- player inventory
	if has_mcl_formspec then
		local top_inv_y = margin_y + plrinv_y
		local hotbar_y = top_inv_y + 3 * slot_interval + slot_spacing
		table.insert(formspec_base, get_itemslot_bg(margin_x + src_x, _begin_y, 1,1))
		table.insert(formspec_base, get_itemslot_bg(_dst_x, _begin_y, 2,2))
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
		:format(margin_x + src_x, _begin_y))
	table.insert(formspec_base, ("list[context;dst;%.2f,%.2f;2,2;]")
		:format(_dst_x, _begin_y))
	table.insert(formspec_base, ("image[%.2f,%.2f;%.2f,%.2f;%s]")
		:format(
			_arrow_begin, _begin_y + (slot_size - _arrow_thickness)/2,
			arrow_length - arrowhead_length, _arrow_thickness,
			"blank.png^[invert:rgba"
		))
	table.insert(formspec_base, ("image[%.2f,%.2f;%.2f,%.2f;%s]")
		:format(
			_arrow_begin + arrow_length - arrowhead_length,
			_begin_y + slot_size/2 - arrowhead_length,
			arrowhead_length, arrowhead_length * 2,
			"technic_arrowhead.png"
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

	local formspec = table.concat(formspec_base)

	local tube = technic.new_default_tube()
	if def.can_insert then
		tube.can_insert = def.can_insert
	end
	if def.insert_object then
		tube.insert_object = def.insert_object
	end

	local update_node = function(pos, meta, newnode, infotext, demand, src_time)
		technic.swap_node(pos, newnode)
		meta:set_string("infotext", infotext)
		meta:set_int(tier.."_EU_demand", demand)
		meta:set_int("src_time", src_time)
	end

	local run = function(pos, node)
		local meta = core.get_meta(pos)
		local eu_input = meta:get_int(tier.."_EU_input")
		local machine_demand = def.demand

		-- Setup meta def if it does not exist.
		if not eu_input then
			meta:set_int(tier.."_EU_demand", machine_demand[1])
			meta:set_int(tier.."_EU_input", 0)
			return
		end

		local EU_upgrade, tube_upgrade = 0, 0
		if def.upgrade then
			EU_upgrade, tube_upgrade = technic.handle_machine_upgrades(meta)
		end
		if def.tube then
			technic.handle_machine_pipeworks(pos, tube_upgrade)
		end

		local inv = meta:get_inventory()
		local demand = machine_demand[EU_upgrade+1]
		local powered = eu_input >= demand
		local src_time = meta:get_int("src_time")
		if powered then
			src_time = src_time + math.floor(def.speed * 10 + 0.5)
		end
		while true do
			local recipe = inv:get_list("src") and technic.get_recipe(typename, inv:get_list("src"))
			if not recipe then
				update_node(pos, meta, nodename, infotext_idle, 0, 0)
				return
			end
			local recipe_time = math.floor(recipe.time * 10 + 0.5)
			if src_time < recipe_time then
				if powered then
					local infotext = infotext_active .. "\n" .. S("Demand: @1", technic.EU_string(demand))
					update_node(pos, meta, nodename.."_active", infotext, demand, src_time)
				else
					update_node(pos, meta, nodename, infotext_unpowered, demand, src_time)
				end
				return
			elseif not technic.process_recipe(recipe, inv) then
				update_node(pos, meta, nodename, infotext_idle, 0, recipe_time)
				return
			end
			src_time = src_time - recipe_time
		end
	end

	local tentry = tube_entry
	if ltier == "lv" then
		tentry = ""
	end

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

	core.register_node(colon..nodename, {
		description = def.description,
		tiles = {
			texture_prefix.."_top.png"..tentry,
			texture_prefix.."_bottom.png"..tentry,
			texture_prefix.."_side.png"..tentry,
			texture_prefix.."_side.png"..tentry,
			texture_prefix.."_side.png"..tentry,
			texture_prefix.."_front.png"
		},
		paramtype2 = "facedir",
		groups = groups,
		is_ground_content = false,
		_mcl_blast_resistance = 1,
		_mcl_hardness = 0.8,
		tube = def.tube and tube or nil,
		connect_sides = def.connect_sides or connect_default,
		legacy_facedir_simple = true,
		sounds = technic.sounds.node_sound_wood_defaults(),
		on_construct = function(pos)
			local node = core.get_node(pos)
			local meta = core.get_meta(pos)

			local form_buttons = ""
			if not string.find(node.name, ":lv_") then
				form_buttons = presumed_form_buttons(meta)
			end

			meta:set_string("infotext", def.description)
			meta:set_int("tube_time",  0)
			meta:set_string("formspec", formspec..form_buttons)
			local inv = meta:get_inventory()
			inv:set_size("src", input_size)
			inv:set_size("dst", 4)
			inv:set_size("upgrade1", 1)
			inv:set_size("upgrade2", 1)
		end,
		can_dig = technic.machine_can_dig,
		allow_metadata_inventory_put = technic.machine_inventory_put,
		allow_metadata_inventory_take = technic.machine_inventory_take,
		allow_metadata_inventory_move = technic.machine_inventory_move,
		on_metadata_inventory_move = technic.machine_on_inventory_move,
		on_metadata_inventory_put = technic.machine_on_inventory_put,
		on_metadata_inventory_take = technic.machine_on_inventory_take,
		technic_run = run,
		after_place_node = def.tube and pipeworks.after_place,
		after_dig_node = technic.machine_after_dig_node,
		on_receive_fields = function(pos, formname, fields, sender)
			if fields.quit then return end
			if not pipeworks.may_configure(pos, sender) then return end
			fs_helpers.on_receive_fields(pos, fields)
			local node = core.get_node(pos)
			local meta = core.get_meta(pos)
			local form_buttons = ""
			if not string.find(node.name, ":lv_") then
				form_buttons = presumed_form_buttons(meta)
			end
			meta:set_string("formspec", formspec..form_buttons)
		end,
	})

	core.register_node(colon..nodename.."_active",{
		description = def.description,
		tiles = {
			texture_prefix.."_top.png"..tentry,
			texture_prefix.."_bottom.png"..tentry,
			texture_prefix.."_side.png"..tentry,
			texture_prefix.."_side.png"..tentry,
			texture_prefix.."_side.png"..tentry,
			texture_prefix.."_front_active.png"
		},
		paramtype2 = "facedir",
		drop = nodename,
		groups = active_groups,
		is_ground_content = false,
		_mcl_blast_resistance = 1,
		_mcl_hardness = 0.8,
		connect_sides = def.connect_sides or connect_default,
		legacy_facedir_simple = true,
		sounds = technic.sounds.node_sound_wood_defaults(),
		tube = def.tube and tube or nil,
		can_dig = technic.machine_can_dig,
		allow_metadata_inventory_put = technic.machine_inventory_put,
		allow_metadata_inventory_take = technic.machine_inventory_take,
		allow_metadata_inventory_move = technic.machine_inventory_move,
		on_metadata_inventory_move = technic.machine_on_inventory_move,
		on_metadata_inventory_put = technic.machine_on_inventory_put,
		on_metadata_inventory_take = technic.machine_on_inventory_take,
		technic_run = run,
		technic_disabled_machine_name = nodename,
		on_receive_fields = function(pos, formname, fields, sender)
			if fields.quit then return end
			if not pipeworks.may_configure(pos, sender) then return end
			fs_helpers.on_receive_fields(pos, fields)
			local node = core.get_node(pos)
			local meta = core.get_meta(pos)
			local form_buttons = ""
			if not string.find(node.name, ":lv_") then
				form_buttons = presumed_form_buttons(meta)
			end
			meta:set_string("formspec", formspec..form_buttons)
		end,
	})

	technic.register_machine(tier, nodename,            technic.receiver)
	technic.register_machine(tier, nodename.."_active", technic.receiver)

end -- End registration

