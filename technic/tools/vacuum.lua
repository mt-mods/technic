-- Configuration
local vacuum_max_charge        = 10000 -- 10000 - Maximum charge of the vacuum cleaner
local vacuum_charge_per_object = 100   -- 100   - Capable of picking up 50 objects
local vacuum_range             = 8     -- 8     - Area in which to pick up objects

local S = technic.getter

technic.register_power_tool("technic:vacuum", {
	description = S("Vacuum Cleaner"),
	inventory_image = "technic_vacuum.png",
	max_charge = vacuum_max_charge,
	on_use = function(itemstack, user, pointed_thing)
		local original_charge = technic.get_RE_charge(itemstack)
		if original_charge < vacuum_charge_per_object then
			return
		end
		minetest.sound_play("vacuumcleaner", {to_player = user:get_player_name(), gain = 0.4})
		local pos = user:get_pos()
		local inv = user:get_inventory()
		local charge = original_charge
		for _, object in ipairs(minetest.get_objects_inside_radius(pos, vacuum_range)) do
			local entity = object:get_luaentity()
			if not object:is_player() and entity and entity.name == "__builtin:item" and entity.itemstring ~= "" then
				if inv and inv:room_for_item("main", ItemStack(entity.itemstring)) then
					charge = charge - vacuum_charge_per_object
					inv:add_item("main", ItemStack(entity.itemstring))
					minetest.sound_play("item_drop_pickup", {to_player = user:get_player_name(), gain = 0.4,})
					entity.itemstring = ""
					object:remove()
					if charge < vacuum_charge_per_object then
						break
					end
				end
			end
		end
		if not technic.creative_mode and charge ~= original_charge then
			technic.set_RE_charge(itemstack, charge)
			return itemstack
		end
	end,
})

minetest.register_craft({
	output = 'technic:vacuum',
	recipe = {
		{'pipeworks:tube_1',              'pipeworks:filter', 'technic:battery'},
		{'pipeworks:tube_1',              'basic_materials:motor',    'technic:battery'},
		{'technic:stainless_steel_ingot', '',                 ''},
	}
})
