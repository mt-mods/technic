
local S = rawget(_G, "intllib") and intllib.Getter() or function(s) return s end

minetest.register_tool("wrench:wrench", {
	description = S("Wrench"),
	inventory_image = "technic_wrench.png",
	on_use = function(itemstack, player, pointed_thing)
		if not player or not pointed_thing then
			return
		end
		local name = player:get_player_name()
		local pos = pointed_thing.under
		if minetest.is_protected(pos, name) then
			return
		end
		local can_pickup, msg = wrench.can_pickup_node(pos, player)
		if not can_pickup then
			if msg then
				minetest.chat_send_player(name, msg)
			end
			return
		end
		local new_stack = wrench.pickup_node(pos, player)
		player:get_inventory():add_item("main", new_stack)
		itemstack:add_wear(65535 / 20)
		return itemstack
	end,
})

if minetest.get_modpath("technic") and technic.config:get_bool("enable_wrench_crafting") then
	minetest.register_craft({
		output = "wrench:wrench",
		recipe = {
			{"technic:carbon_steel_ingot", "", "technic:carbon_steel_ingot"},
			{"", "technic:carbon_steel_ingot", ""},
			{"", "technic:carbon_steel_ingot", ""}
		}
	})
end
