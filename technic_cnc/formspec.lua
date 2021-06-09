local S = technic_cnc.getter

-- Margin is hardcoded for some elements...
local margin = 0.5
local padding = 0.2
local grid_size = 1 + padding

local fs_prefix = "formspec_version[4]size[%d,%d;]style_type[list;size=1,1;spacing=0.2,0.2]label[0.5,0.5;%s]"

local fs_slimhalf = "label[0.5,3.6;"..S("Slim Elements half / normal height:").."]"..
	"image_button[0.5,4;1,0.5;technic_cnc_full.png;full; ]"..
	"image_button[0.5,4.5;1,0.5;technic_cnc_half.png;half; ]"

local slimhalf_buttons = {
	"element_straight",
	"element_end",
	"element_cross",
	"element_t",
	"element_edge"
}

-- Create button grid that returns paging information (leftover button count).
-- WIP: Starting index could be easily added if needed to provide full paging.
local function image_button_grid(x, y, width, height, items)
	local result = ""
	local count = 0
	local x_start = x
	local y_start = y
	local x_max = x_start + width - grid_size
	local y_max = height and y_start + height - grid_size
	for _,name in ipairs(items) do
		result = result .. ("image_button[%0.1f,%0.1f;1,1;technic_cnc_%s.png;%s;]"):format(x,y,name,name)
		count = count + 1
		if x >= x_max then
			x = x_start
			y = y + grid_size
		else
			x = x + grid_size
		end
		if y_max and y >= y_max then
			return result, #items - count
		end
	end
	return result, #items - count
end

local function label(x, y, text)
	return ("label[%0.1f,%0.1f;%s]"):format(x, y, text)
end

local function list(name, x, y, w, h, text)
	return (text and label(x, y - 0.5, text) or "") ..
		("list[context;%s;%0.1f,%0.1f;%d,%d;]"):format(name, x, y, w, h) ..
		("listring[context;%s]listring[current_player;main]"):format(name)
end

local function get_formspec(nodename, def, meta)
	local width = def.width or 14
	local height = def.height or 13
	local fs = fs_prefix:format(width, height, S("Choose Milling Program:"))

	-- Programming buttons
	local x = margin
	local y = 1
	fs = fs .. image_button_grid(x, y, width - 2, nil, def.programs)

	-- Slim / half / normal
	x = margin + grid_size
	y = 4
	fs = fs .. fs_slimhalf .. image_button_grid(x, y, width - 4, nil, slimhalf_buttons)

	-- Input / output inventories
	x = grid_size * 2 + x
	y = 6
	fs = fs .. list("src", margin, y, 1, 1, S("In:")) .. list("dst", x, y, def.output_size, 1, S("Out:"))

	-- Upgrades
	if def.upgrade then
		x = x + (grid_size * def.output_size) + grid_size
		fs = fs .. list("upgrade1", x, y, 1, 1, S("Upgrade Slots"))
		x = x + grid_size
		fs = fs .. list("upgrade2", x, y, 1, 1)
	end

	-- Stack splitting toggle
	if meta and def.tube and technic_cnc.pipeworks then
		y = height - (grid_size * 4.5) - margin
		fs = fs .. technic_cnc.pipeworks.cycling_button(meta, "splitstacks", margin, y)
	end

	-- Digilines channel field
	x = (grid_size * 8) + margin
	if def.digilines then
		y = height - grid_size - margin + padding + 0.3
		local w = width - x - margin
		fs = fs .. ("field[%0.1f,%0.1f;%0.1f,%0.1f;channel;%s;${channel}]"):format(x, y, w, 0.7, "Channel")
	end

	-- Some filler for empty unused space
	y = height - (grid_size * 4) - margin + padding
	--fs = fs .. ("model[10,%0.1f;3,3;;node.obj;%s;0.1,0.1;true;false]"):format(y, table.concat(def.tiles, ","))
	--fs = fs .. ("image[10,%0.1f;3,3;%s]"):format(y, def.tiles[6])
	fs = fs .. ("item_image[%0.1f,%0.1f;3.6,3.6;%s]"):format(x, y, nodename)

	-- Player inventory / return formspec
	return fs .. ("list[current_player;main;%0.1f,%0.1f;8,4;]"):format(margin, y)
end

local function on_receive_fields(pos, formname, fields, sender)
	local meta = minetest.get_meta(pos)
	local name = sender:get_player_name()

	if meta:get_int("public") ~= 1 and minetest.is_protected(pos, name) then
		return true
	end

	-- Program for half/full size
	if fields.full then
		meta:set_int("size", 1)
		return true
	elseif fields.half then
		meta:set_int("size", 2)
		return true
	end

	-- Resolve the node name and the number of items to make
	local program_selected
	local products = technic_cnc.products
	local inv = meta:get_inventory()
	for program, _ in pairs(fields) do
		if products[program] then
			technic_cnc.set_program(meta, program, meta:get_int("size"))
			technic_cnc.enable(meta)
			meta:set_string("cnc_user", name)
			program_selected = true
			break
		end
	end

	if program_selected and not technic_cnc.use_technic then
		local inputstack = inv:get_stack("src", 1)
		if not inputstack:is_empty() then
			technic_cnc.produce(meta, inv, inputstack)
		end
		return true
	elseif fields.key_enter and fields.key_enter_field == "channel" and not minetest.is_protected(pos, name) then
		meta:set_string("channel", fields.channel)
		return true
	end

	return program_selected
end

return {
	get_formspec = get_formspec,
	on_receive_fields = on_receive_fields,
}
