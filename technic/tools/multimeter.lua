local S = technic.getter

local remote_start_ttl = technic.config:get_int("multimeter_remote_start_ttl")

local max_charge = 50000
local power_usage = 100 -- Normal network reading uses this much energy
local rs_charge_multiplier = 100 -- Remote start energy requirement multiplier
local texture = "technic_multimeter.png"
local texture_logo = "technic_multimeter_logo.png"
local texture_bg9 = "technic_multimeter_bg.png"
local texture_button = "technic_multimeter_button.png"
local texture_button_pressed = "technic_multimeter_button_pressed.png"
local bgcolor = "#FFC00F"
local bgcolor_lcd = "#4B8E66"
local bghiglight_lcd = "#5CAA77"
local textcolor = "#101010"
--local bgcolor_button = "#626E41"

local form_width = 8
local form_height = 11.5
local btn_count = 3
local btn_spacing = 0.1
local btn_width = (form_width - ((btn_count + 1) * btn_spacing)) / btn_count

local open_formspecs = {}

local formspec_escape = minetest.formspec_escape
local function fmtf(n) return type(n) == "number" and ("%0.3f"):format(n) or n end
local function fs_x_pos(i) return (btn_spacing * i) + (btn_width * (i - 1)) end
local function create_button(index, y, h, name, label, exit, modifier)
	local x = fs_x_pos(index)
	local t1 = texture_button .. (modifier and formspec_escape(modifier) or "")
	local t2 = texture_button_pressed .. (modifier and formspec_escape(modifier) or "")
	local dimensions = ("%s,%s;%s,%s"):format(fmtf(x),fmtf(y),fmtf(btn_width),h)
	local properties = ("%s;%s;%s;false;false;%s"):format(t1, name, label, t2)
	return ("image_button%s[%s;%s]"):format(exit and "_exit" or "", dimensions, properties)
end

local formspec_format_string = "formspec_version[3]" ..
	("size[%s,%s;]bgcolor[%s;both;]"):format(fmtf(form_width), fmtf(form_height), bgcolor) ..
	("style_type[*;textcolor=%s;font_size=*1]"):format(textcolor) ..
	("style_type[table;textcolor=%s;font_size=*1;font=mono]"):format(textcolor) ..
	("style_type[label;textcolor=%s;font_size=*2]"):format(textcolor) ..
	("background9[0,0;%s,%s;%s;false;3]"):format(fmtf(form_width), fmtf(form_height), texture_bg9) ..
	("image[0.3,0.3;5.75,1;%s]"):format(texture_logo) ..
	"label[0.6,1.5;Network %s]" ..
	("field[%s,2.5;%s,0.8;net;Network ID:;%%s]"):format(fmtf(fs_x_pos(2)),fmtf(btn_width)) ..
	create_button(3, "2.5", "0.8", "rs", "Remote start", false, "^[colorize:#10E010:125") ..
	create_button(1, form_height - 0.9, "0.8", "wp", "Waypoint", true) ..
	create_button(2, form_height - 0.9, "0.8", "up", "Update", false) ..
	create_button(3, form_height - 0.9, "0.8", "exit", "Exit", true) ..
	("tableoptions[border=false;background=%s;highlight=%s;color=%s]"):format(bgcolor_lcd,bghiglight_lcd,textcolor) ..
	"tablecolumns[indent,width=0.2;text,width=13;text,width=13;text,align=center]" ..
	("table[0.1,3.4;%s,%s;items;1,Property,Value,Unit%%s]"):format(fmtf(form_width - 0.2), fmtf(form_height - 4.4))

minetest.register_craft({
	output = 'technic:multimeter',
	recipe = {
		{'basic_materials:copper_strip',  'technic:rubber',     'basic_materials:copper_strip'},
		{'basic_materials:plastic_sheet', 'basic_materials:ic', 'basic_materials:plastic_sheet'},
		{'technic:battery',               'basic_materials:ic', 'technic:copper_coil'},
	}
})

local function use_charge(itemstack, multiplier)
	return technic.use_charge(itemstack, power_usage * (multiplier or 1))
end

local function async_itemstack_get(player, refstack)
	local inv = player:get_inventory()
	local invindex, invstack
	if inv and refstack then
		local invsize = inv:get_size('main')
		local name = refstack:get_name()
		local count = refstack:get_count()
		local meta = refstack:get_meta()
		for i=1,invsize do
			local stack = inv:get_stack('main', i)
			if stack:get_count() == count and stack:get_name() == name and stack:get_meta():equals(meta) then
				-- This item stack seems very similar to one that were used originally, use this
				invindex = i
				invstack = stack
				break
			end
		end
	end
	return inv, invindex, invstack
end

--[[ Base58
local alpha = {
	"1","2","3","4","5","6","7","8","9","A","B","C","D","E","F","G","H",
	"J","K","L","M","N","P","Q","R","S","T","U","V","W","X","Y","Z",
	"a","b","c","d","e","f","g","h","i","j","k","m","n","o",
	"p","q","r","s","t","u","v","w","x","y","z"
} --]]
-- Base36
local alpha = {
	"0","1","2","3","4","5","6","7","8","9","A","B","C","D","E","F","G","H",
	"I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z"
}
local function base36(num)
	if type(num) ~= "number" then return end
	if num < 36 then return alpha[num + 1] end
	local result = ""
	while num ~= 0 do
		result = alpha[(num % 36) + 1] .. result
		num = math.floor(num / 36)
	end
	return result
end

-- Clean version of minetest.pos_to_string
local function v2s(v) return ("%s,%s,%s"):format(v.x,v.y,v.z) end
-- Size of hash table
local function count(t)
	if type(t) ~= "table" then return 0 end
	local c=0 for _ in pairs(t) do c=c+1 end return c
end
-- Percentage value as string
local function percent(val, max)
	if type(val) ~= "number" or type(max) ~= "number" then return "" end
    local p = (val / max) * 100
    return p > 99.99 and "100" or ("%0.2f"):format(p)
end
-- Get network TTL
local function net_ttl(net) return type(net.timeout) == "number" and (net.timeout - minetest.get_us_time()) end
-- Microseconds to milliseconds
local function us2ms(val) return type(val) == "number" and (val / 1000) or 0 end
-- Microseconds to seconds
local function us2s(val) return type(val) == "number" and (val / 1000 / 1000) or 0 end

local function formspec(data)
	local tablerows = ""
	for _,row in ipairs(data.rows) do
		tablerows = tablerows .. ",1" ..
			"," .. formspec_escape(row[1] or "-") ..
			"," .. formspec_escape(row[2] or "-") ..
			"," .. formspec_escape(row[3] or "-")
	end
	local base36_net = base36(data.network_id) or "N/A"
	return formspec_format_string:format(base36_net, base36_net, tablerows)
end

local function multimeter_inspect(itemstack, player, pos, fault)
	local id = pos and technic.pos2network(pos)
	local rows = {}
	local data = { network_id = id, rows = rows }
	local name = player:get_player_name()
	if id and itemstack and not fault then
		table.insert(rows, { "Ref. point", v2s(technic.network2pos(id)), "coord" })
		table.insert(rows, { "Activated", technic.active_networks[id] and "yes" or "no", "active" })
		local net = technic.networks[id]
		if net then
			table.insert(rows, { "Timeout", ("%0.1f"):format(us2s(net_ttl(net))), "s" })
			table.insert(rows, { "Lag", ("%0.2f"):format(us2ms(net.lag)), "ms" })
			table.insert(rows, { "Skip", net.skip, "cycles" })
			table.insert(rows, {})
			local PR = net.PR_nodes
			local RE = net.RE_nodes
			local BA = net.BA_nodes
			local C = count(net.all_nodes)
			table.insert(rows, { "Supply", net.supply, "EU" })
			table.insert(rows, { "Demand", net.demand, "EU" })
			table.insert(rows, { "Battery charge", net.battery_charge, "EU" })
			table.insert(rows, { "Battery charge", percent(net.battery_charge, net.battery_charge_max), "%" })
			table.insert(rows, { "Battery capacity", net.battery_charge_max, "EU" })
			table.insert(rows, {})
			table.insert(rows, { "Nodes", C, "count" })
			table.insert(rows, { "Cables", C - #PR - #RE - #BA, "count" }) -- FIXME: Do not count PR+RE duplicates
			table.insert(rows, { "Generators", #PR, "count" })
			table.insert(rows, { "Consumers", #RE, "count" })
			table.insert(rows, { "Batteries", #BA, "count" })
		end
	else
		table.insert(rows, { "Operation failed", "", "" })
		if not id then
			table.insert(rows, {})
			table.insert(rows, { "Bad contact", "No network", "Fault" })
		end
		if fault then table.insert(rows, {}) end
		if fault == "battery" then
			table.insert(rows, { "Recharge", "Insufficient charge", "Fault" })
		elseif fault == "decode" then
			table.insert(rows, { "Decoder error", "Net ID decode", "Fault" })
		elseif fault == "switchload" then
			table.insert(rows, { "Remote load error", "Load switching station", "Fault" })
		elseif fault == "cableload" then
			table.insert(rows, { "Remote load error", "Load ref. cable", "Fault" })
		elseif fault == "protected" then
			table.insert(rows, { "Protection error", "Area is protected", "Access" })
		end
		if not itemstack then
			table.insert(rows, {})
			table.insert(rows, { "Missing FLUTE", "FLUTE not found", "Fault" })
		end
	end
	open_formspecs[name] = { pos = pos, itemstack = itemstack }
	minetest.show_formspec(name, "technic:multimeter", formspec(data))
end

local function remote_start_net(player, pos)
	local sw_pos = {x=pos.x,y=pos.y+1,z=pos.z}
	-- Try to load switch network node
	local sw_node = technic.get_or_load_node(sw_pos)
	if sw_node.name ~= "technic:switching_station" then return "switchload" end
	-- Try to load network node
	local tier = technic.sw_pos2tier(sw_pos, true)
	if not tier then return "cableload" end
	-- Check protections
	if minetest.is_protected(pos, player:get_player_name()) then return "protected" end
	-- All checks passed, start network
	local network_id = technic.sw_pos2network(sw_pos) or technic.create_network(sw_pos)
	technic.activate_network(network_id, remote_start_ttl)
end

local function async_itemstack_use_charge(itemstack, player, multiplier)
	local fault = nil
	local inv, invindex, invstack = async_itemstack_get(player, itemstack)
	if not inv or not invindex or not use_charge(invstack, multiplier) then
		-- Multimeter battery empty
		fault = "battery"
	elseif invstack then
		inv:set_stack('main', invindex, invstack)
	end
	return invstack, fault
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname ~= "technic:multimeter" then
		-- Not our formspec, tell engine to continue with other registered handlers
		return
	end
	local name = player:get_player_name()
	local flute = open_formspecs[name]
	if fields and name then
		local pos = flute and flute.pos
		if fields.up then
			local itemstack = flute and flute.itemstack
			local invstack, fault = async_itemstack_use_charge(itemstack, player)
			multimeter_inspect(invstack, player, pos, fault)
			return true
		elseif fields.wp and pos then
			local network_id = technic.pos2network(pos)
			local encoded_net_id = base36(network_id)
			if encoded_net_id then
				local net_pos = technic.network2pos(network_id)
				local id = player:hud_add({
					hud_elem_type = "waypoint",
					name = ("Network %s"):format(encoded_net_id),
					text = "m",
					number = 0xE0B020,
					world_pos = net_pos
				})
				minetest.after(90, function() if player then player:hud_remove(id) end end)
			end
		elseif fields.rs and fields.net and fields.net ~= "" then
			-- Use charge first before even attempting remote start
			local itemstack = flute and flute.itemstack
			local invstack, fault = async_itemstack_use_charge(itemstack, player, rs_charge_multiplier)
			if not fault then
				local net_id = tonumber(fields.net, 36)
				local net_pos = net_id and technic.network2pos(net_id)
				if net_pos then
					fault = remote_start_net(player, net_pos)
				else
					fault = "decode"
				end
			end
			multimeter_inspect(invstack, player, pos, fault)
			return true
		elseif fields.quit then
			open_formspecs[name] = nil
		end
	end
	-- Tell engine to skip rest of formspec handlers
	return true
end)

local function check_node(pos)
	local name = minetest.get_node(pos).name
	if technic.machine_tiers[name] or technic.get_cable_tier(name) or name == "technic:switching_station" then
		return name
	end
end

technic.register_power_tool("technic:multimeter", {
	description = S("Multimeter"),
	inventory_image = texture,
	wield_image = texture,
	liquids_pointable = false,
	max_charge = max_charge,
	on_use = function(itemstack, player, pointed_thing)
		local pos = minetest.get_pointed_thing_position(pointed_thing, false)
		if pos and pointed_thing.type == "node" then
			local name = check_node(pos)
			if name then
				if name == "technic:switching_station" then
					-- Switching station compatibility shim
					pos.y = pos.y - 1
				end
				open_formspecs[player:get_player_name()] = nil
				multimeter_inspect(itemstack, player, pos, not use_charge(itemstack) and "battery")
			end
		end
		return itemstack
	end,
})
