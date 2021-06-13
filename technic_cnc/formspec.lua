local S = technic_cnc.getter

-- Margin is hardcoded for some elements...
local margin = 0.5
local padding = 0.2
local grid_size = 1 + padding

local fs_prefix = "formspec_version[4]size[%d,%d]style_type[list;size=1,1;spacing=0.2,0.2]label[0.5,0.5;%s]"

local fs_slimhalf = "label[0.5,3.6;"..S("Slim Elements half / normal height:").."]"..
	"image_button[0.5,4;1,0.49;technic_cnc_full%s.png;full; ]"..
	"image_button[0.5,4.51;1,0.49;technic_cnc_half%s.png;half; ]"

-- TODO: These should be defined in programs.lua and provide API to register more
local slimhalf_buttons = {
	"element_straight",
	"element_end",
	"element_cross",
	"element_t",
	"element_edge"
}

-- Create button grid that returns paging information (leftover button count).
-- WIP: Starting index could be easily added if needed to provide full paging.
local function image_button_grid(x_start, y_start, width, height, items, selected)
	local result = ""
	local count = 0
	local row = 0
	local column = 0
	local max_row = math.floor(height / grid_size + 0.1)
	local max_column = math.floor(math.min(#items, math.floor(width / grid_size) * max_row) / max_row + 0.1)
	for _,name in ipairs(items) do
		local x = x_start + column * grid_size
		local y = y_start + row * grid_size
		local modifier = selected == name and "^[invert:b" or ""
		result = result .. ("image_button[%0.1f,%0.1f;1,1;technic_cnc_%s.png%s;%s;]"):format(x, y, name, modifier, name)
		count = count + 1
		if column + 1 < max_column then
			column = column + 1
		else
			column = 0
			row = row + 1
			if row >= max_row then
				return result, #items - count
			end
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
		("listring[current_player;main]listring[context;%s]"):format(name)
end

local function get_formspec(nodename, def, meta)
	local width = grid_size * 11 + margin * 2
	local height = 13
	local fs = fs_prefix:format(width, height, S("Choose Milling Program:"))
	local p = meta:get("program")

	-- Programming buttons
	local x = margin
	local y = 1
	local buttons1, leftover1 = image_button_grid(x, y, width - margin * 2, grid_size * 2, def.programs, p)

	-- Slim / half / normal
	x = margin + grid_size
	y = 4
	local buttons2, leftover2 = image_button_grid(x, y, width - grid_size - margin * 2, grid_size, slimhalf_buttons, p)
	local half = meta:get("size") == "2"
	fs = fs .. buttons1 .. fs_slimhalf:format(half and "" or "_active", half and "_active" or "") .. buttons2

	-- Program paging controls
	if leftover1 > 0 or leftover2 > 0 then
		x = width - margin - grid_size * 2
		fs = fs .. ("button[%0.1f,%0.1f;%0.1f,%0.1f;paging_prev;Previous]"):format(x, padding, grid_size, 0.6)
			.. ("button[%0.1f,%0.1f;%0.1f,%0.1f;paging_next;Next]"):format(x + grid_size, padding, grid_size, 0.6)
	end

	-- Some filler for empty unused space
	y = height - (grid_size * 4) - margin + padding
	--fs = fs .. ("model[10,%0.1f;3,3;;node.obj;%s;0.1,0.1;true;false]"):format(y, table.concat(def.tiles, ","))
	--fs = fs .. ("image[10,%0.1f;3,3;%s]"):format(y, def.tiles[6])
	local size = grid_size * 3
	fs = fs .. ("item_image[%0.1f,%0.1f;%0.1f,%0.1f;%s]"):format(grid_size * 8 + margin, y, size, size, nodename)

	-- Player inventory
	fs = fs .. ("list[current_player;main;%0.1f,%0.1f;8,4;]"):format(margin, y)

	-- Input / output inventories
	x = grid_size * def.input_size + grid_size + margin
	y = 6
	fs = fs .. list("src", margin, y, def.input_size, 1, S("In:")) .. list("dst", x, y, def.output_size, 1, S("Out:"))

	x = grid_size * 8 + margin

	-- Upgrades
	if def.upgrade then
		fs = fs .. list("upgrade1", x, y, 1, 1, S("Upgrade Slots")) .. list("upgrade2", x + grid_size, y, 1, 1)
	end

	-- Stack splitting toggle
	if meta and def.tube and technic_cnc.pipeworks then
		y = height - margin - grid_size * 4.5
		fs = fs .. technic_cnc.pipeworks.cycling_button(meta, "splitstacks", margin, y)
	end

	-- Digilines channel field
	if def.digilines then
		y = height - grid_size - margin + padding + 0.3
		local w = width - x - margin - grid_size
		fs = fs .. ("field[%0.1f,%0.1f;%0.1f,%0.1f;channel;Channel;${channel}]"):format(x + padding, y, w, 0.7)
		fs = fs .. ("button[%0.1f,%0.1f;%0.1f,%0.1f;setchannel;Set]"):format(x + w + padding, y, 1, 0.7)
	end

	return fs
end

local function on_receive_fields(pos, meta, fields, sender, update_formspec)
	local name = sender:get_player_name()

	if fields.quit or (meta:get_int("public") == 0 and minetest.is_protected(pos, name)) then
		return true
	end

	-- Program for half/full size
	if fields.full then
		meta:set_int("size", 1)
		update_formspec(meta)
		return true
	elseif fields.half then
		meta:set_int("size", 2)
		update_formspec(meta)
		return true
	elseif fields.paging_next or fields.paging_prev then
		-- TODO: Page index should be capped between 0 and max based on button count
		local page = meta:get_int("page")
		meta:set_int("page", page + (fields.paging_next and 1 or -1))
		return
	end

	-- Resolve the node name and the number of items to make
	local program_selected
	local products = technic_cnc.products
	for program, _ in pairs(fields) do
		if products[program] then
			local update = meta:get("program") ~= program
			technic_cnc.set_program(meta, program, meta:get_int("size"))
			technic_cnc.enable(meta)
			meta:set_string("cnc_user", name)
			program_selected = true
			if update then
				update_formspec(meta)
			end
			break
		end
	end

	if program_selected and not technic_cnc.use_technic then
		local inv = meta:get_inventory()
		technic_cnc.produce(meta, inv)
		return true
	end

	local setchannel = fields.setchannel or (fields.key_enter and fields.key_enter_field == "channel")
	if setchannel and not minetest.is_protected(pos, name) then
		meta:set_string("channel", fields.channel)
		return true
	end

	return program_selected
end

return {
	get_formspec = get_formspec,
	on_receive_fields = on_receive_fields,
}
