
local S = minetest.get_translator("pipeworks")
local tube_entry = "^pipeworks_tube_connection_metallic.png"
local button_base = "image_button[%0.1f,%0.1f;1,0.6"
local button_label = "label[%0.1f,%0.1f;" .. S("Allow splitting incoming stacks from tubes") .. "]"
local cycling_buttons = { pipeworks.button_off, pipeworks.button_on }
local fs_helpers = pipeworks.fs_helpers
local pipeworks_on_receive_fields = pipeworks.fs_helpers.on_receive_fields

local function new_tube()
	return {
		insert_object = function(pos, node, stack, direction)
			local meta = minetest.get_meta(pos)
			local inv = meta:get_inventory()
			return inv:add_item("src", stack)
		end,
		can_insert = technic_cnc.use_technic and technic.default_can_insert or function(pos, node, stack, direction)
			local meta = minetest.get_meta(pos)
			local inv = meta:get_inventory()
			return inv:room_for_item("src", stack)
		end,
		connect_sides = {left=1, right=1, back=1, bottom=1},
		input_inventory = {"dst"},
	}
end

local function tube_entry_overlay(tiles)
	assert(type(tiles) == "table" and #tiles == 6, "tube_entry_overlay requires table with 6 elements")
	return {
		tiles[1], tiles[2] .. tube_entry, tiles[3] .. tube_entry,
		tiles[4] .. tube_entry, tiles[5] .. tube_entry, tiles[6],
	}
end

local function cycling_button(meta, name, x, y)
	local form_buttons = fs_helpers.cycling_button(meta, button_base:format(x, y), name, cycling_buttons)
	return form_buttons .. button_label:format(x + 1.2, y + 0.31)
end

-- Pipeworks does not provide API to selectively silence protection messages.
-- This wrapper handles pipeworks cycling buttons without sending unnecessary protection messages.
local function on_receive_fields(pos, meta, fields, sender, update_formspec)
	-- https://github.com/mt-mods/pipeworks/-/blob/master/common.lua#L115
	for field,_ in pairs(fields) do
		if field:match("^fs_helpers_cycling:") then
			if pipeworks.may_configure(pos, sender) then
				pipeworks_on_receive_fields(pos, fields)
				update_formspec(meta)
			end
			-- Handled and protection message sent if necessary
			return true
		end
	end
	-- Not handled, caller may continue processing
	return false
end

return {
	new_tube = new_tube,
	cycling_button = cycling_button,
	on_receive_fields = on_receive_fields,
	tube_entry_overlay = tube_entry_overlay,
}
