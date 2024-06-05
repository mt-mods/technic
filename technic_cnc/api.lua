-- API for the technic CNC machine
-- Again code is adapted from the NonCubic Blocks MOD v1.4 by yves_de_beck

local S = technic_cnc.getter
local ALPHA_CLIP = minetest.features.use_texture_alpha_string_modes and "clip" or true

-- Generic function for registering all the different node types
function technic_cnc.register_program(recipeitem, suffix, model, groups, images, description, cbox, sbox)

	local dtype
	local nodeboxdef
	local meshdef

	if type(model) ~= "string" then -- assume a nodebox if it's a table or function call
		dtype = "nodebox"
		nodeboxdef = {
			type  = "fixed",
			fixed = model
		}
	else
		dtype = "mesh"
		meshdef = model
	end

	if cbox and not sbox then sbox = cbox end

	minetest.register_node(":"..recipeitem.."_"..suffix, {
		description   = description,
		drawtype      = dtype,
		node_box      = nodeboxdef,
		mesh          = meshdef,
		tiles         = images,
		paramtype     = "light",
		paramtype2    = "facedir",
		use_texture_alpha = ALPHA_CLIP,
		walkable      = true,
		groups        = groups,
		is_ground_content = false,
		selection_box = sbox,
		collision_box = cbox
	})
end

-- function to iterate over all the programs the CNC machine knows
function technic_cnc.register_all(recipeitem, groups, images, description)
	for _, data in ipairs(technic_cnc.programs) do
		-- Disable node creation for disabled node types for some material
		local do_register = true
		if technic_cnc.programs_disable[recipeitem] ~= nil then
			for __, disable in ipairs(technic_cnc.programs_disable[recipeitem]) do
				if disable == data.suffix then
					do_register = false
				end
			end
		end
		-- Create the node if it passes the test
		if do_register then
			technic_cnc.register_program(recipeitem, data.suffix, data.model,
				groups, images, description.." "..data.desc, data.cbox, data.sbox)
		end
	end
end

-- REGISTER NEW TECHNIC_CNC_API's PART 2:
-- technic_cnc..register_element_end(subname, recipeitem, groups, images, desc_element_xyz)
------------------------------------------------------------------------------------------------------------
function technic_cnc.register_slope_edge_etc(recipeitem, groups, images, desc_slope, desc_slope_lying,
			desc_slope_upsdown, desc_slope_edge, desc_slope_inner_edge, desc_slope_upsdwn_edge,
			desc_slope_upsdwn_inner_edge, desc_pyramid, desc_spike, desc_onecurvededge, desc_twocurvededge,
			desc_cylinder, desc_cylinder_horizontal, desc_spheroid, desc_element_straight, desc_element_edge,
			desc_element_t, desc_element_cross, desc_element_end)
	technic_cnc.register_slope(recipeitem, groups, images, desc_slope)
	technic_cnc.register_slope_lying(recipeitem, groups, images, desc_slope_lying)
	technic_cnc.register_slope_upsdown(recipeitem, groups, images, desc_slope_upsdown)
	technic_cnc.register_slope_edge(recipeitem, groups, images, desc_slope_edge)
	technic_cnc.register_slope_inner_edge(recipeitem, groups, images, desc_slope_inner_edge)
	technic_cnc.register_slope_edge_upsdown(recipeitem, groups, images, desc_slope_upsdwn_edge)
	technic_cnc.register_slope_inner_edge_upsdown(recipeitem, groups, images, desc_slope_upsdwn_inner_edge)
	technic_cnc.register_pyramid(recipeitem, groups, images, desc_pyramid)
	technic_cnc.register_spike(recipeitem, groups, images, desc_spike)
	technic_cnc.register_onecurvededge(recipeitem, groups, images, desc_onecurvededge)
	technic_cnc.register_twocurvededge(recipeitem, groups, images, desc_twocurvededge)
	technic_cnc.register_cylinder(recipeitem, groups, images, desc_cylinder)
	technic_cnc.register_cylinder_horizontal(recipeitem, groups, images, desc_cylinder_horizontal)
	technic_cnc.register_spheroid(recipeitem, groups, images, desc_spheroid)
	technic_cnc.register_element_straight(recipeitem, groups, images, desc_element_straight)
	technic_cnc.register_element_edge(recipeitem, groups, images, desc_element_edge)
	technic_cnc.register_element_t(recipeitem, groups, images, desc_element_t)
	technic_cnc.register_element_cross(recipeitem, groups, images, desc_element_cross)
	technic_cnc.register_element_end(recipeitem, groups, images, desc_element_end)
end

-- REGISTER STICKS: noncubic.register_xyz(recipeitem, groups, images, desc_element_xyz)
------------------------------------------------------------------------------------------------------------
function technic_cnc.register_stick_etc(recipeitem, groups, images, desc_stick)
	technic_cnc.register_stick(recipeitem, groups, images, desc_stick)
end

function technic_cnc.register_elements(recipeitem, groups, images, desc_element_straight_double,
			desc_element_edge_double, desc_element_t_double, desc_element_cross_double, desc_element_end_double)
	technic_cnc.register_element_straight_double(recipeitem, groups, images, desc_element_straight_double)
	technic_cnc.register_element_edge_double(recipeitem, groups, images, desc_element_edge_double)
	technic_cnc.register_element_t_double(recipeitem, groups, images, desc_element_t_double)
	technic_cnc.register_element_cross_double(recipeitem, groups, images, desc_element_cross_double)
	technic_cnc.register_element_end_double(recipeitem, groups, images, desc_element_end_double)
end

-- CNC MACHINE API
------------------------------------------------------------------------------------------------------------

function technic_cnc.get_product(program, material, size)
	-- Get and return product item string with stack size or nil if product not available
	local multiplier = technic_cnc.products[program]
	if multiplier then
		size = math.max(1, math.min(2, size))
		local twosize = technic_cnc.twosize_products[program]
		local double = size == 1 and twosize and "_double" or ""
		local product = ("%s_technic_cnc_%s%s"):format(material, program, double)
		if minetest.registered_nodes[product] then
			return ("%s %d"):format(product, multiplier * (twosize and size or 1))
		end
	end
end

function technic_cnc.set_program(meta, program, size)
	if technic_cnc.products[program] then
		if size then
			meta:set_int("size", math.max(1, math.min(2, size)))
		end
		meta:set_string("program", program)
		return true
	end
	return false
end

function technic_cnc.is_enabled(meta)
	return meta:get("disable") == nil
end

function technic_cnc.enable(meta)
	meta:set_string("disable", "")
end

function technic_cnc.disable(meta)
	meta:set_string("disable", "1")
	meta:set_string("LV_EU_demand", "")
end

function technic_cnc.get_material(inventory)
	local srclist = inventory:get_list("src")
	for index, stack in ipairs(srclist) do
		if not stack:is_empty() then
			return index, stack
		end
	end
end

function technic_cnc.produce(meta, inventory)
	-- Get and check program
	local program = meta:get("program")
	if program then
		-- Get material stack
		local index, materialstack = technic_cnc.get_material(inventory)
		if index and materialstack then
			-- Get product and produce items if output has enough space
			local size = meta:get_int("size")
			local product = technic_cnc.get_product(program, materialstack:get_name(), size)
			if product and inventory:room_for_item("dst", product) then
				-- Remove materials from input inventory
				materialstack:take_item()
				inventory:set_stack("src", index, materialstack)

				-- Add results to output inventory of machine
				inventory:add_item("dst", product)

				return true
			end
		end
	end
	return false
end

-- REGISTER MACHINES
------------------------------------------------------------------------------------------------------------

function technic_cnc.register_cnc_machine(nodename, def)
	-- Basic sanity check for registration, prefer failing early
	assert(type(nodename) == "string" and #nodename > 0, "nodename should be non empty string")
	assert(type(def.description) == "string", "description field should be string")
	assert(({["nil"]=1,number=1})[type(def.input_size)], "input_size field should be number if set")
	assert(({["nil"]=1,number=1})[type(def.output_size)], "output_size field should be number if set")
	assert(({["nil"]=1,["function"]=1})[type(def.get_formspec)], "get_formspec should be function if set")
	assert(({["nil"]=1,["function"]=1})[type(def.on_receive_fields)], "on_receive_fields should be function if set")
	assert(({["nil"]=1,["function"]=1})[type(def.technic_run)], "technic_run should be function if set")
	assert(({["nil"]=1,table=1})[type(def.tube)], "tube field should be table if set")

	-- Register recipe if recipe given
	if def.recipe then
		minetest.register_craft({
			output = nodename,
			recipe = def.recipe,
		})
	end

	-- Collect / generate basic variables for CNC machine
	local nodename_active = nodename .. "_active"
	local idle_infotext = S("@1 Idle", def.description)
	local active_infotext = S("@1 Active", def.description)
	local unpowered_infotext = S("@1 Unpowered", def.description)
	local groups = { cracky = 2, technic_machine = 1, technic_lv = 1 }
	-- It is possible to override these using def fields
	local on_receive_fields = def.on_receive_fields or technic_cnc.formspec.on_receive_fields
	local get_formspec = def.get_formspec or technic_cnc.formspec.get_formspec
	local input_size = def.input_size or 1
	local output_size = def.output_size or 4
	local technic_run
	local after_dig_node
	local allow_metadata_inventory_put
	local allow_metadata_inventory_take
	local allow_metadata_inventory_move
	local can_dig

	-- Update few variables in definition table to make some things easier
	def.get_formspec = get_formspec
	def.input_size = input_size
	def.output_size = output_size

	-- UPGRADE OLD CNC MACHINES
	local function upgrade_machine(meta)
		local oldmeta = meta:get("technic_power_machine")
		if oldmeta then
			local product = meta:get("cnc_product")
			-- Remove old metadata fields
			meta:set_string("cnc_product", "")
			meta:set_string("cnc_multiplier", "")
			meta:set_string("technic_power_machine", "")
			if product then
				-- Only executed for active machines, old inactive machines do not have cnc_product set
				local program_raw = product:match("[%w_]+:[%w_]+_technic_cnc_([%w_]+)")
				if program_raw then
					local double = "_double"
					local size = program_raw:sub(-#double) == double and 1 or 2
					local program = size == 1 and program_raw:sub(1, #program_raw - #double) or program_raw
					meta:set_string("program", program)
					meta:set_int("size", size)
				end
				meta:set_string("formspec", get_formspec(nodename, def, meta))
			end
		end
	end

	if technic_cnc.use_technic and not def.technic_run then
		-- Check and get EU demand for Technic CNC machine
		assert(type(def.demand) == "number", "demand field must be set for Technic CNC")

		-- Update machine state if needed
		local function update_machine(pos, meta, oldname, newname, infotext, demand)
			if demand then
				meta:set_int("LV_EU_demand", demand)
			end
			meta:set_string("infotext", infotext)
			technic.swap_node(pos, newname)
		end

		-- Technic action code performing the transformation, use form handler for when not using technic
		technic_run = function(pos, node)
			local meta = minetest.get_meta(pos)
			upgrade_machine(meta)

			local demand = def.demand
			if def.upgrade then
				local EU_upgrade, tube_upgrade = technic.handle_machine_upgrades(meta)
				if EU_upgrade and EU_upgrade > 0 then
					demand = math.max(0, demand - EU_upgrade * demand * 0.2)
				end
				technic.handle_machine_pipeworks(pos, tube_upgrade)
			end

			if not technic_cnc.is_enabled(meta) or not meta:get("program") then
				update_machine(pos, meta, node.name, nodename, idle_infotext, 0)
				return
			end

			-- Get and check material stack
			local inv = meta:get_inventory()
			if inv:is_empty("src") then
				update_machine(pos, meta, node.name, nodename, idle_infotext, 0)
				return
			end

			local eu_input = meta:get_int("LV_EU_input")
			if eu_input < demand then
				update_machine(pos, meta, node.name, nodename, unpowered_infotext, demand)
				return
			end

			local src_time = meta:get_int("src_time")
			if src_time >= 3 then
				-- Cycle counter expired, reset counter and attempt to produce items
				if technic_cnc.produce(meta, inv) then
					-- Production succeed, reset cycle counter
					meta:set_int("src_time", 0)
				else
					-- Production failed, set machine status to unpowered and try again after one cycle
					meta:set_int("src_time", 2)
					update_machine(pos, meta, node.name, nodename, unpowered_infotext, 0)
					return
				end
			else
				-- Increment cycle counter
				meta:set_int("src_time", src_time + 1)
			end
			update_machine(pos, meta, node.name, nodename_active, active_infotext, demand)
		end
	end

	if technic_cnc.use_technic then
		allow_metadata_inventory_put = technic.machine_inventory_put
		allow_metadata_inventory_take = technic.machine_inventory_take
		allow_metadata_inventory_move = technic.machine_inventory_move
		can_dig = technic.machine_can_dig
		after_dig_node = def.upgrade and technic.machine_after_dig_node or nil
	else
		allow_metadata_inventory_put = function(pos, listname, index, stack, player)
			if minetest.is_protected(pos, player:get_player_name()) then
				return 0
			end
			return stack:get_count()
		end

		allow_metadata_inventory_take = function(pos, listname, index, stack, player)
			if minetest.is_protected(pos, player:get_player_name()) then
				return 0
			end
			return stack:get_count()
		end

		allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
			if minetest.is_protected(pos, player:get_player_name()) then
				return 0
			end
			return count
		end

		can_dig = function(pos, player)
			if player and minetest.is_protected(pos, player:get_player_name()) then
				return false
			end
			local meta = minetest.get_meta(pos)
			local inv = meta:get_inventory()
			return inv:is_empty("dst") and inv:is_empty("src") and default.can_interact_with_node(player, pos)
		end
	end

	-- Formspec handlers with / without pipeworks
	do
		local wrapped_on_receive_fields = on_receive_fields
		local function update_formspec(meta)
			meta:set_string("formspec", get_formspec(nodename, def, meta))
		end
		if technic_cnc.pipeworks and def.tube then
			local pipeworks_on_receive_fields = technic_cnc.pipeworks.on_receive_fields
			on_receive_fields = function(pos, formname, fields, sender)
				local meta = minetest.get_meta(pos)
				if not wrapped_on_receive_fields(pos, meta, fields, sender, update_formspec) and not fields.quit then
					-- Custom pipeworks form handler to skip unnecessary protection messages
					pipeworks_on_receive_fields(pos, meta, fields, sender, update_formspec)
				end
				upgrade_machine(meta)
			end
		else
			on_receive_fields = function(pos, formname, fields, sender)
				local meta = minetest.get_meta(pos)
				wrapped_on_receive_fields(pos, meta, fields, sender, update_formspec)
				upgrade_machine(meta)
			end
		end
	end

	-- Groups for pipeworks
	if technic_cnc.pipeworks and def.tube then
		groups.tubedevice = 1
		groups.tubedevice_receiver = 1
	end

	-- Only do logging when technic is enabled to avoid duplicating code
	local on_metadata_inventory_move = technic_cnc.use_technic and technic.machine_on_inventory_move or nil
	local on_metadata_inventory_put  = technic_cnc.use_technic and technic.machine_on_inventory_put or nil
	local on_metadata_inventory_take = technic_cnc.use_technic and technic.machine_on_inventory_take or nil

	-- Inactive state CNC machine
	minetest.register_node(":" .. nodename, {
		description = def.description,
		tiles = def.tiles,
		groups = groups,
		connect_sides = {"bottom", "back", "left", "right"},
		paramtype2  = "facedir",
		legacy_facedir_simple = true,
		is_ground_content = false,
		on_construct = function(pos)
			local meta = minetest.get_meta(pos)
			meta:set_string("infotext", def.description)
			meta:set_string("formspec", get_formspec(nodename, def, meta))
			local inv = meta:get_inventory()
			inv:set_size("src", def.input_size)
			inv:set_size("dst", def.output_size)
			if def.upgrade then
				inv:set_size("upgrade1", 1)
				inv:set_size("upgrade2", 1)
			end
		end,
		after_place = def.tube and pipeworks.after_place,
		after_dig_node = def.after_dig_node or after_dig_node,
		tube = def.tube,
		digilines = def.digilines,
		can_dig = def.can_dig or can_dig,
		allow_metadata_inventory_put = def.allow_metadata_inventory_put or allow_metadata_inventory_put,
		allow_metadata_inventory_take = def.allow_metadata_inventory_take or allow_metadata_inventory_take,
		allow_metadata_inventory_move = def.allow_metadata_inventory_move or allow_metadata_inventory_move,
		on_metadata_inventory_move = on_metadata_inventory_move,
		on_metadata_inventory_put = on_metadata_inventory_put,
		on_metadata_inventory_take = on_metadata_inventory_take,
		on_receive_fields = on_receive_fields,
		technic_run = def.technic_run or technic_run,
	})

	-- Active state CNC machine
	if technic_cnc.use_technic then
		local groups_active = table.copy(groups)
		groups_active.not_in_creative_inventory = 1
		minetest.register_node(":" .. nodename_active, {
			description = def.description,
			tiles = def.tiles_active,
			groups = groups_active,
			connect_sides = {"bottom", "back", "left", "right"},
			paramtype2 = "facedir",
			drop = nodename,
			legacy_facedir_simple = true,
			is_ground_content = false,
			after_dig_node = def.after_dig_node or after_dig_node,
			tube = def.tube,
			digilines = def.digilines,
			can_dig = def.can_dig or can_dig,
			allow_metadata_inventory_put = def.allow_metadata_inventory_put or allow_metadata_inventory_put,
			allow_metadata_inventory_take = def.allow_metadata_inventory_take or allow_metadata_inventory_take,
			allow_metadata_inventory_move = def.allow_metadata_inventory_move or allow_metadata_inventory_move,
			on_metadata_inventory_move = on_metadata_inventory_move,
			on_metadata_inventory_put = on_metadata_inventory_put,
			on_metadata_inventory_take = on_metadata_inventory_take,
			on_receive_fields = on_receive_fields,
			technic_run = def.technic_run or technic_run,
			technic_disabled_machine_name = nodename,
		})
		technic.register_machine("LV", nodename, technic.receiver)
		technic.register_machine("LV", nodename_active, technic.receiver)
	else
		minetest.register_alias(nodename_active, nodename)
	end
end
