local S = technic.getter

local max_charge = 50000
local power_usage = 100
local texture = "technic_multimeter.png"
local texture_logo = "technic_multimeter_logo.png"
local texture_bg9 = "technic_multimeter_bg.png"
local texture_button = "technic_multimeter_button.png"
local texture_button_pressed = "technic_multimeter_button_pressed.png"
local bgcolor = "#FFC00F"
local bgcolor_lcd = "#4B8E66"
local bghiglight_lcd = "#5CAA77"
--local bgcolor_button = "#626E41"

minetest.register_craft({
	output = 'technic:multimeter',
	recipe = {
		{'basic_materials:copper_wire', 'mesecons_materials:fiber',   'basic_materials:gold_wire'},
		{'technic:rubber',              'technic:control_logic_unit', 'basic_materials:plastic_sheet'},
		{'technic:battery',             'technic:copper_coil',        'basic_materials:plastic_sheet'},
	}
})

-- Base58
--local alpha = {1,2,3,4,5,6,7,8,9,"A","B","C","D","E","F","G","H","J","K",
--               "L","M","N","P","Q","R","S","T","U","V","W","X","Y","Z",
--               "a","b","c","d","e","f","g","h","i","j","k","m","n","o",
--               "p","q","r","s","t","u","v","w","x","y","z"}
-- Base36
local alpha = {0,1,2,3,4,5,6,7,8,9,"A","B","C","D","E","F","G","H","I","J","K",
               "L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z"}
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
-- Microseconds to milliseconds
local function us2ms(val) return type(val) == "number" and (val / 1000) or 0 end
-- Microseconds to seconds
local function us2s(val) return type(val) == "number" and (val / 1000 / 1000) or 0 end

local formspec_escape = minetest.formspec_escape

local function formspec(data)
	local tablerows = ""
	for _,row in ipairs(data.rows) do
		tablerows = tablerows .. ",1" ..
			"," .. formspec_escape(row[1] or "-") ..
			"," .. formspec_escape(row[2] or "-") ..
			"," .. formspec_escape(row[3] or "-")
	end
	return ("formspec_version[3]size[8,10;]bgcolor[%s;both;]"):format(bgcolor) ..
		--("style_type[button,button_exit;font=mono;bgcolor=%s]"):format(bgcolor_button) ..
		"style_type[*;font=mono,bold]" ..
		"style_type[label;font=mono,bold;font_size=*2]" ..
		("background9[0,0;8,10;%s;false;4]"):format(texture_bg9) ..
		("image[0.3,0.3;5.75,1;%s]"):format(texture_logo) ..
		("label[0.6,1.5;Network %s]"):format(base36(data.network_id) or "N/A") ..
		("image_button_exit[0.1,9.1;2.6,0.8;%s;wp;Waypoint;false;false;%s]"):format(texture_button, texture_button_pressed) ..
		("image_button[2.7,9.1;2.6,0.8;%s;up;Update;false;false;%s]"):format(texture_button, texture_button_pressed) ..
		("image_button_exit[5.3,9.1;2.6,0.8;%s;exit;Exit;false;false;%s]"):format(texture_button, texture_button_pressed) ..
		--"button_exit[0.1,9.1;2.6,0.8;wp;Waypoint]" ..
		--"button[2.7,9.1;2.6,0.8;up;Update]" ..
		--"button_exit[5.3,9.1;2.6,0.8;exit;Exit]" ..
		("tableoptions[border=false;background=%s;highlight=%s]"):format(bgcolor_lcd,bghiglight_lcd) ..
		"tablecolumns[indent;text,width=14;text,width=14;text,align=center]" ..
		("table[0.1,3.4;7.8,5.4;items;1,Property,Value 1,Value 2%s]"):format(tablerows)
end

local function multimeter_inspect(player, pos)
	local id = technic.pos2network(pos)
	local rows = {}
	local data = { network_id = id, rows = rows }
	if id then
		table.insert(rows, { "Ref. point", v2s(technic.network2pos(id)), "coord" })
		table.insert(rows, { "Activated", technic.active_networks[id] and "yes" or "no", "active" })
		local net = technic.networks[id]
		if net then
			table.insert(rows, { "Timeout", ("%0.1f"):format(us2s(net.timeout)), "s" })
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
		table.insert(rows, { "Ref. point", "N/A", "coord" })
		table.insert(rows, { "Activated", "no", "active" })
	end
	minetest.show_formspec(player:get_player_name(), "technic:multimeter", formspec(data))
end

local function is_valid_node(pos)
	local name = minetest.get_node(pos).name
	return not not (technic.machine_tiers[name] or technic.get_cable_tier(name))
end

technic.register_power_tool("technic:multimeter", max_charge)

minetest.register_tool("technic:multimeter", {
	description = S("Flute Multimeter"),
	inventory_image = texture,
	wield_image = texture,
	--wield_scale = { x = 0.8, y = 1, z = 0.8 },
	liquids_pointable = false,
	wear_represents = "technic_RE_charge",
	on_refill = technic.refill_RE_charge,
	on_use = function(itemstack, player, pointed_thing)
		local pos = minetest.get_pointed_thing_position(pointed_thing, false)
		if not pos or pointed_thing.type ~= "node" or not is_valid_node(pos) then
			return itemstack
		end
		local meta = minetest.deserialize(itemstack:get_metadata())
		if meta and meta.charge and meta.charge >= power_usage then
			if not technic.creative_mode then
				meta.charge = meta.charge - power_usage
				technic.set_RE_wear(itemstack, meta.charge, max_charge)
				itemstack:set_metadata(minetest.serialize(meta))
			end
			multimeter_inspect(player, pos)
		end
		return itemstack
	end,
})
