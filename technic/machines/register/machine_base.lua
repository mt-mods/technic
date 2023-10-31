
local S = technic.getter

local fs_helpers = pipeworks.fs_helpers
local tube_entry = "^pipeworks_tube_connection_metallic.png"

function technic.default_can_insert(pos, node, stack, direction)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	if meta:get_int("splitstacks") == 1 then
		stack = stack:peek_item(1)
	end
	return inv:room_for_item("src", stack)
end

function technic.new_default_tube()
	return {
		insert_object = function(pos, node, stack, direction)
			local meta = minetest.get_meta(pos)
			local inv = meta:get_inventory()
			return inv:add_item("src", stack)
		end,
		can_insert = technic.default_can_insert,
		connect_sides = {left = 1, right = 1, back = 1, top = 1, bottom = 1},
	}
end

local connect_default = {"bottom", "back", "left", "right"}

local function round(v)
	return math.floor(v + 0.5)
end

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

	local formspec =
		"size[9,10;]"..
		"list[context;src;"..(4-input_size)..",1;"..input_size..",1;]"..
		"list[context;dst;5,1;2,2;]"..
		"label[0,0;"..def.description.."]"..
		"listring[context;dst]"..
		"listring[current_player;main]"..
		"listring[context;src]"..
		"listring[current_player;main]"
	if def.upgrade then
		formspec = formspec..
			"list[context;upgrade1;1,3;1,1;]"..
			"list[context;upgrade2;2,3;1,1;]"..
			"label[1,4;"..S("Upgrade Slots").."]"..
			"listring[context;upgrade1]"..
			"listring[current_player;main]"..
			"listring[context;upgrade2]"..
			"listring[current_player;main]"
	end

	if minetest.get_modpath("mcl_formspec") then
		formspec = formspec..
			mcl_formspec.get_itemslot_bg(4-input_size,1,input_size,1)..
			mcl_formspec.get_itemslot_bg(5,1,2,2)..
			-- player inventory
			"list[current_player;main;0,5.5;9,3;9]"..
			mcl_formspec.get_itemslot_bg(0,5.5,9,3)..
			"list[current_player;main;0,8.74;9,1;]"..
			mcl_formspec.get_itemslot_bg(0,8.74,9,1)..
			"listring[current_player;main]"
		if def.upgrade then
			formspec = formspec..
			mcl_formspec.get_itemslot_bg(1,3,1,1)..
			mcl_formspec.get_itemslot_bg(2,3,1,1)
		end
	else
		formspec = formspec..
			"list[current_player;main;0,5;8,4;]"..
			"listring[current_player;main]"
	end

	local tube = technic.new_default_tube()
	if def.can_insert then
		tube.can_insert = def.can_insert
	end
	if def.insert_object then
		tube.insert_object = def.insert_object
	end

	local run = function(pos, node)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
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

		local powered = eu_input >= machine_demand[EU_upgrade+1]
		if powered then
			meta:set_int("src_time", meta:get_int("src_time") + round(def.speed*10))
		end
		while true do
			local result = inv:get_list("src") and technic.get_recipe(typename, inv:get_list("src"))
			if not result then
				technic.swap_node(pos, nodename)
				meta:set_string("infotext", infotext_idle)
				meta:set_int(tier.."_EU_demand", 0)
				meta:set_int("src_time", 0)
				return
			end
			meta:set_int(tier.."_EU_demand", machine_demand[EU_upgrade+1])
			technic.swap_node(pos, nodename.."_active")
			meta:set_string("infotext", infotext_active .. "\n" ..
			S("Demand: @1", technic.EU_string(machine_demand[EU_upgrade+1])))
			if meta:get_int("src_time") < round(result.time*10) then
				if not powered then
					technic.swap_node(pos, nodename)
					meta:set_string("infotext", infotext_unpowered)
				end
				return
			end
			local output = result.output
			if type(output) ~= "table" then output = { output } end
			local output_stacks = {}
			for _, o in ipairs(output) do
				table.insert(output_stacks, ItemStack(o))
			end
			local room_for_output = true
			inv:set_size("dst_tmp", inv:get_size("dst"))
			inv:set_list("dst_tmp", inv:get_list("dst"))
			for _, o in ipairs(output_stacks) do
				if not inv:room_for_item("dst_tmp", o) then
					room_for_output = false
					break
				end
				inv:add_item("dst_tmp", o)
			end
			if not room_for_output then
				technic.swap_node(pos, nodename)
				meta:set_string("infotext", infotext_idle)
				meta:set_int(tier.."_EU_demand", 0)
				meta:set_int("src_time", round(result.time*10))
				return
			end
			meta:set_int("src_time", meta:get_int("src_time") - round(result.time*10))
			inv:set_list("src", result.new_input)
			inv:set_list("dst", inv:get_list("dst_tmp"))
		end
	end

	local tentry = tube_entry
	if ltier == "lv" then
		tentry = ""
	end

	minetest.register_node(colon..nodename, {
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
		_mcl_blast_resistance = 1,
		_mcl_hardness = 0.8,
		tube = def.tube and tube or nil,
		connect_sides = def.connect_sides or connect_default,
		legacy_facedir_simple = true,
		sounds = technic.sounds.node_sound_wood_defaults(),
		on_construct = function(pos)
			local node = minetest.get_node(pos)
			local meta = minetest.get_meta(pos)

			local form_buttons = ""
			if not string.find(node.name, ":lv_") then
				form_buttons = fs_helpers.cycling_button(
					meta,
					pipeworks.button_base,
					"splitstacks",
					{
						pipeworks.button_off,
						pipeworks.button_on
					}
				)..pipeworks.button_label
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
		technic_run = run,
		after_place_node = def.tube and pipeworks.after_place,
		after_dig_node = technic.machine_after_dig_node,
		on_receive_fields = function(pos, formname, fields, sender)
			if fields.quit then return end
			if not pipeworks.may_configure(pos, sender) then return end
			fs_helpers.on_receive_fields(pos, fields)
			local node = minetest.get_node(pos)
			local meta = minetest.get_meta(pos)
			local form_buttons = ""
			if not string.find(node.name, ":lv_") then
				form_buttons = fs_helpers.cycling_button(
					meta,
					pipeworks.button_base,
					"splitstacks",
					{
						pipeworks.button_off,
						pipeworks.button_on
					}
				)..pipeworks.button_label
			end
			meta:set_string("formspec", formspec..form_buttons)
		end,
	})

	minetest.register_node(colon..nodename.."_active",{
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
		technic_run = run,
		technic_disabled_machine_name = nodename,
		on_receive_fields = function(pos, formname, fields, sender)
			if fields.quit then return end
			if not pipeworks.may_configure(pos, sender) then return end
			fs_helpers.on_receive_fields(pos, fields)
			local node = minetest.get_node(pos)
			local meta = minetest.get_meta(pos)
			local form_buttons = ""
			if not string.find(node.name, ":lv_") then
				form_buttons = fs_helpers.cycling_button(
					meta,
					pipeworks.button_base,
					"splitstacks",
					{
						pipeworks.button_off,
						pipeworks.button_on
					}
				)..pipeworks.button_label
			end
			meta:set_string("formspec", formspec..form_buttons)
		end,
	})

	technic.register_machine(tier, nodename,            technic.receiver)
	technic.register_machine(tier, nodename.."_active", technic.receiver)

end -- End registration

