
-- Fuel driven alloy furnace. This uses no EUs:

local S = technic.getter
local mat = technic.materials

core.register_craft({
	output = 'technic:coal_alloy_furnace',
	recipe = {
		{mat.brick, mat.brick, mat.brick},
		{mat.brick, '',              mat.brick},
		{mat.brick, mat.brick, mat.brick},
	}
})

local machine_name = S("Fuel-Fired Alloy Furnace")
local size = core.get_modpath("mcl_formspec") and "size[9,9]" or "size[8,9]"
local formspec =
	size..
	"label[0,0;"..machine_name.."]"..
	"image[2,2;1,1;default_furnace_fire_bg.png]"..
	"list[context;fuel;2,3;1,1;]"..
	"list[context;src;2,1;2,1;]"..
	"list[context;dst;5,1;2,2;]"

if core.get_modpath("mcl_formspec") then
	formspec = formspec..
	mcl_formspec.get_itemslot_bg(2,3,1,1)..
	mcl_formspec.get_itemslot_bg(2,1,2,1)..
	mcl_formspec.get_itemslot_bg(5,1,2,2)..
	-- player inventory
	"list[current_player;main;0,4.5;9,3;9]"..
	mcl_formspec.get_itemslot_bg(0,4.5,9,3)..
	"list[current_player;main;0,7.74;9,1;]"..
	mcl_formspec.get_itemslot_bg(0,7.74,9,1)
else
	formspec = formspec..
	"list[current_player;main;0,5;8,4;]"
end

-- listrings
formspec = formspec..
	"listring[context;dst]"..
	"listring[current_player;main]"..
	"listring[context;src]"..
	"listring[current_player;main]"..
	"listring[context;fuel]"..
	"listring[current_player;main]"

core.register_node("technic:coal_alloy_furnace", {
	description = machine_name,
	tiles = {"technic_coal_alloy_furnace_top.png",  "technic_coal_alloy_furnace_bottom.png",
	         "technic_coal_alloy_furnace_side.png", "technic_coal_alloy_furnace_side.png",
	         "technic_coal_alloy_furnace_side.png", "technic_coal_alloy_furnace_front.png"},
	paramtype2 = "facedir",
	groups = {cracky=2, pickaxey=2},
	is_ground_content = false,
	_mcl_blast_resistance = 1,
	_mcl_hardness = 0.8,
	legacy_facedir_simple = true,
	sounds = technic.sounds.node_sound_stone_defaults(),
	on_construct = function(pos)
		local meta = core.get_meta(pos)
		meta:set_string("formspec", formspec)
		meta:set_string("infotext", machine_name)
		local inv = meta:get_inventory()
		inv:set_size("fuel", 1)
		inv:set_size("src", 2)
		inv:set_size("dst", 4)
	end,
	can_dig = technic.machine_can_dig,
	allow_metadata_inventory_put = technic.machine_inventory_put,
	allow_metadata_inventory_take = technic.machine_inventory_take,
	allow_metadata_inventory_move = technic.machine_inventory_move,
	on_metadata_inventory_move = technic.machine_on_inventory_move,
	on_metadata_inventory_put = technic.machine_on_inventory_put,
	on_metadata_inventory_take = technic.machine_on_inventory_take,
})

core.register_node("technic:coal_alloy_furnace_active", {
	description = machine_name,
	tiles = {"technic_coal_alloy_furnace_top.png",  "technic_coal_alloy_furnace_bottom.png",
	         "technic_coal_alloy_furnace_side.png", "technic_coal_alloy_furnace_side.png",
	         "technic_coal_alloy_furnace_side.png", "technic_coal_alloy_furnace_front_active.png"},
	paramtype2 = "facedir",
	light_source = 8,
	drop = "technic:coal_alloy_furnace",
	groups = {cracky=2, not_in_creative_inventory=1, pickaxey=2},
	is_ground_content = false,
	_mcl_blast_resistance = 1,
	_mcl_hardness = 0.8,
	legacy_facedir_simple = true,
	sounds = technic.sounds.node_sound_stone_defaults(),
	can_dig = technic.machine_can_dig,
	allow_metadata_inventory_put = technic.machine_inventory_put,
	allow_metadata_inventory_take = technic.machine_inventory_take,
	allow_metadata_inventory_move = technic.machine_inventory_move,
	on_metadata_inventory_move = technic.machine_on_inventory_move,
	on_metadata_inventory_put = technic.machine_on_inventory_put,
	on_metadata_inventory_take = technic.machine_on_inventory_take,
})

core.register_abm({
	label = "Machines: run coal alloy furnace",
	nodenames = {"technic:coal_alloy_furnace", "technic:coal_alloy_furnace_active"},
	interval = 1,
	chance = 1,
	action = function(pos, node, active_object_count, active_object_count_wider)
		local meta = core.get_meta(pos)
		local inv = meta:get_inventory()
		local src_list = inv:get_list("src")
		if not src_list then
			return
		end

		for i, name in pairs({
				"fuel_totaltime",
				"fuel_time",
				"src_totaltime",
				"src_time"}) do
			if not meta:get_float(name) then
				meta:set_float(name, 0.0)
			end
		end

		-- Get what to cook if anything
		local recipe = technic.get_recipe("alloy", src_list)

		local was_active = false

		if meta:get_float("fuel_time") < meta:get_float("fuel_totaltime") then
			was_active = true
			meta:set_int("fuel_time", meta:get_int("fuel_time") + 1)
			if recipe then
				meta:set_int("src_time", meta:get_int("src_time") + 1)
				if meta:get_int("src_time") >= recipe.time then
					meta:set_int("src_time", 0)
					technic.process_recipe(recipe, inv)
				end
			else
				meta:set_int("src_time", 0)
			end
		end

		if meta:get_float("fuel_time") < meta:get_float("fuel_totaltime") then
			local percent = math.floor(meta:get_float("fuel_time") /
					meta:get_float("fuel_totaltime") * 100)
			meta:set_string("infotext", S("@1 Active", machine_name).." ("..percent.."%)")
			technic.swap_node(pos, "technic:coal_alloy_furnace_active")
			meta:set_string("formspec",
				size..
				"label[0,0;"..machine_name.."]"..
				"image[2,2;1,1;default_furnace_fire_bg.png^[lowpart:"..
				(100 - percent)..":default_furnace_fire_fg.png]"..
				"list[context;fuel;2,3;1,1;]"..
				"list[context;src;2,1;2,1;]"..
				"list[context;dst;5,1;2,2;]"..

				(core.get_modpath("mcl_formspec") and
					mcl_formspec.get_itemslot_bg(2,3,1,1)..
					mcl_formspec.get_itemslot_bg(2,1,2,1)..
					mcl_formspec.get_itemslot_bg(5,1,2,2)..
					-- player inventory
					"list[current_player;main;0,4.5;9,3;9]"..
					mcl_formspec.get_itemslot_bg(0,4.5,9,3)..
					"list[current_player;main;0,7.74;9,1;]"..
					mcl_formspec.get_itemslot_bg(0,7.74,9,1)
				or "list[current_player;main;0,5;8,4;]")..

				-- listrings
				"listring[context;dst]"..
				"listring[current_player;main]"..
				"listring[context;src]"..
				"listring[current_player;main]"..
				"listring[context;fuel]"..
				"listring[current_player;main]")
			return
		end

		if not technic.get_recipe("alloy", inv:get_list("src")) then
			if was_active then
				meta:set_string("infotext", S("@1 is empty", machine_name))
				technic.swap_node(pos, "technic:coal_alloy_furnace")
				meta:set_string("formspec", formspec)
			end
			return
		end

		-- Next take a hard look at the fuel situation
		local fuellist = inv:get_list("fuel")
		local fuel, afterfuel = core.get_craft_result({method = "fuel", width = 1, items = fuellist})

		if fuel.time <= 0 then
			meta:set_string("infotext", S("@1 Out Of Fuel", machine_name))
			technic.swap_node(pos, "technic:coal_alloy_furnace")
			meta:set_string("formspec", formspec)
			return
		end

		meta:set_string("fuel_totaltime", fuel.time)
		meta:set_string("fuel_time", 0)

		inv:set_stack("fuel", 1, afterfuel.items[1])
	end,
})

