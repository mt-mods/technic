
local S = technic.getter

local fs_helpers = pipeworks.fs_helpers

local tube_entry = "^pipeworks_tube_connection_metallic.png"

local mat = technic.materials

local param2_to_under = {
	[0] = {x= 0,y=-1,z= 0}, [1] = {x= 0,y= 0,z=-1},
	[2] = {x= 0,y= 0,z= 1}, [3] = {x=-1,y= 0,z= 0},
	[4] = {x= 1,y= 0,z= 0}, [5] = {x= 0,y= 1,z= 0}
}

local function get_itemslot_bg(x, y, w, h) -- mcl hasn't moved to real co-ordinates yet
	local out = ""
	for i = 0, w - 1, 1 do
		for j = 0, h - 1, 1 do
			out = out .. "image[" .. x + i*1.25 .. "," .. y + j*1.25 .. ";1,1;mcl_formspec_itemslot.png]"
		end
	end
	return out
end
local has_mcl_formspec = core.global_exists("mcl_formspec")

local margin_x, margin_y = 0.5, 0.5
local slot_size, slot_spacing = 1, 0.25
local slot_interval = slot_size + slot_spacing
local separation = 0.5
local machine_section_h = 4.5
local plrinv_w, plrinv_h = 8, 4
if has_mcl_formspec then
	plrinv_w = 9
	plrinv_h = 4.5
end
local body_width = plrinv_w * slot_interval - slot_spacing
local plrinv_y = machine_section_h + separation
local body_height = plrinv_y + plrinv_h * slot_interval - slot_spacing

local subject_w = slot_interval * 8 - slot_spacing
local subject_x, subject_y = (body_width - subject_w)/2, 0.5
local src_x, src_y = subject_x, subject_y + slot_interval

local base_formspec = {}

table.insert(base_formspec, "formspec_version[4]")
table.insert(base_formspec, ("size[%.2f,%.2f]"):format(2 * margin_x + body_width, 2 * margin_y + body_height))
table.insert(base_formspec, ("label[%.2f,%.2f;%s]")
	:format(margin_x, margin_y, S("Self-Contained Injector")))

-- player inventory
if has_mcl_formspec then
	local top_inv_y = margin_y + plrinv_y
	local hotbar_y = top_inv_y + 3 * slot_interval + slot_spacing
	table.insert(base_formspec, get_itemslot_bg(margin_x + src_x, margin_y + src_y, 8,2))
	table.insert(base_formspec, get_itemslot_bg(margin_x, top_inv_y, plrinv_w, 3))
	table.insert(base_formspec, get_itemslot_bg(margin_x, hotbar_y, plrinv_w,1))
	table.insert(base_formspec,("list[current_player;main;%.2f,%.2f;%d,3;9]")
		:format(margin_x, top_inv_y, plrinv_w))
	table.insert(base_formspec,("list[current_player;main;%.2f,%.2f;%d,1;]")
		:format(margin_x, hotbar_y, plrinv_w))
else
	table.insert(base_formspec, ("list[current_player;main;%.2f,%.2f;%d,%d;]")
		:format(margin_x, margin_y + plrinv_y, plrinv_w, plrinv_h))
end

table.insert(base_formspec, ("list[context;main;%.2f,%.2f;8,2;]")
	:format(margin_x + src_x, margin_y + src_y))

-- listrings
table.insert(base_formspec, "listring[context;main]")
table.insert(base_formspec, "listring[current_player;main]")

base_formspec = table.concat(base_formspec)

local form_buttons = function(meta)
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

local function set_injector_formspec(pos)
	local meta = core.get_meta(pos)
	local formspec = {base_formspec, form_buttons(meta)}
	local is_stackwise = meta:get_string("mode") == "whole stacks"
	table.insert(formspec, ("button[%.2f,%.2f;%.2f,%.2f;%s;%s]")
		:format(
			margin_x + subject_x, margin_y + subject_y, slot_size * 4, slot_size,
			is_stackwise and "mode_item" or "mode_stack",
			is_stackwise and S("Stackwise") or S("Itemwise")
		))
	local is_enabled = core.get_node_timer(pos):is_started()
	table.insert(formspec, ("button[%.2f,%.2f;%.2f,%.2f;%s;%s]")
		:format(
			margin_x + subject_x + subject_w - slot_size * 4, margin_y + subject_y, slot_size * 4, slot_size,
			is_enabled and "disable" or "enable",
			is_enabled and S("Enabled") or S("Disabled")
		))
	meta:set_string("formspec", table.concat(formspec))
end

core.register_node("technic:injector", {
	description = S("Self-Contained Injector"),
	tiles = {
		"technic_injector_top.png"..tube_entry,
		"technic_injector_bottom.png",
		"technic_injector_side.png"..tube_entry,
		"technic_injector_side.png"..tube_entry,
		"technic_injector_side.png"..tube_entry,
		"technic_injector_side.png"
	},
	paramtype2 = "facedir",
	groups = {snappy=2, choppy=2, oddly_breakable_by_hand=2, tubedevice=1, tubedevice_receiver=1, axey=2, handy=1},
	is_ground_content = false,
	_mcl_blast_resistance = 1,
	_mcl_hardness = 0.8,
	tube = {
		can_insert = function(pos, node, stack, direction)
			local meta = core.get_meta(pos)
			if meta:get_int("splitstacks") == 1 then
				stack = stack:peek_item(1)
			end
			return meta:get_inventory():room_for_item("main", stack)
		end,
		insert_object = function(pos, node, stack, direction)
			return core.get_meta(pos):get_inventory():add_item("main", stack)
		end,
		connect_sides = {left=1, right=1, back=1, top=1, bottom=1},
	},
	sounds = technic.sounds.node_sound_wood_defaults(),
	on_construct = function(pos)
		local meta = core.get_meta(pos)
		meta:set_string("infotext", S("Self-Contained Injector"))
		meta:set_string("mode", "single items")
		meta:get_inventory():set_size("main", 16)
		core.get_node_timer(pos):start(1)
		set_injector_formspec(pos)
	end,
	can_dig = function(pos, player)
		return core.get_meta(pos):get_inventory():is_empty("main")
	end,
	on_receive_fields = function(pos, formanme, fields, sender)
		if fields.quit or not pipeworks.may_configure(pos, sender) then
			return
		end
		local meta = core.get_meta(pos)
		if fields.mode_item then
			meta:set_string("mode", "single items")
		elseif fields.mode_stack then
			meta:set_string("mode", "whole stacks")
		elseif fields.disable then
			core.get_node_timer(pos):stop()
		elseif fields.enable then
			core.get_node_timer(pos):start(1)
		end
		fs_helpers.on_receive_fields(pos, fields)
		set_injector_formspec(pos)
	end,
	on_timer = function(pos, elapsed)
		local meta = core.get_meta(pos)
		local node = core.get_node(pos)
		local dir = param2_to_under[math.floor(node.param2 / 4)]
		local node_under = core.get_node(vector.add(pos, dir))
		if core.get_item_group(node_under.name, "tubedevice") > 0 then
			local inv = meta:get_inventory()
			local list = inv:get_list("main")
			if not list then
				return true
			end
			local stackwise = meta:get_string("mode") == "whole stacks"
			for i,stack in ipairs(list) do
				if not stack:is_empty() then
					if stackwise then
						technic.tube_inject_item(pos, pos, dir, stack:to_table())
						stack:clear()
					else
						technic.tube_inject_item(pos, pos, dir, stack:take_item(1):to_table())
					end
					inv:set_stack("main", i, stack)
					break
				end
			end
		end
		return true
	end,
	on_rotate = function(pos, node, user, mode, new_param2)
		node.param2 = new_param2
		core.swap_node(pos, node)
		pipeworks.scan_for_tube_objects(pos)
		return true
	end,
	allow_metadata_inventory_put = technic.machine_inventory_put,
	allow_metadata_inventory_take = technic.machine_inventory_take,
	allow_metadata_inventory_move = technic.machine_inventory_move,
	on_metadata_inventory_move = technic.machine_on_inventory_move,
	on_metadata_inventory_put = technic.machine_on_inventory_put,
	on_metadata_inventory_take = technic.machine_on_inventory_take,
	after_place_node = pipeworks.after_place,
	after_dig_node = pipeworks.after_dig
})

core.register_craft({
	output = "technic:injector 1",
	recipe = {
		{"", "technic:control_logic_unit",""},
		{"", mat.chest,""},
		{"", "pipeworks:tube_1",""},
	}
})

core.register_lbm({
	label = "Old injector conversion",
	name = "technic:old_injector_conversion",
	nodenames = {"technic:injector"},
	run_at_every_load = false,
	action = function(pos, node)
		core.get_node_timer(pos):start(1)
		set_injector_formspec(pos)
	end
})
