--[[ for cheaper digiline cables and plates, add the following lines in worldpath/technic.conf:
# 2 instead of 8 digiline wire for digiline cables
lv_digi_cable_recipe =         , digilines:wire_std_00000000,,, technic:lv_cable        ,,, digilines:wire_std_00000000
lv_digi_cable_plate_1_recipe = , digilines:wire_std_00000000,,, technic:lv_cable_plate_1,,, digilines:wire_std_00000000

mv_digi_cable_recipe =         , digilines:wire_std_00000000,,, technic:mv_cable        ,,, digilines:wire_std_00000000
mv_digi_cable_plate_1_recipe = , digilines:wire_std_00000000,,, technic:mv_cable_plate_1,,, digilines:wire_std_00000000

hv_digi_cable_recipe =         , digilines:wire_std_00000000,,, technic:hv_cable        ,,, digilines:wire_std_00000000
hv_digi_cable_plate_1_recipe = , digilines:wire_std_00000000,,, technic:hv_cable_plate_1,,, digilines:wire_std_00000000
--]]

local function replace_craft(name, value)
	local craft = { output = "technic:" .. name }

	-- comma or space separated list
	-- empty elements must be separeted with commas
        local m = value:gmatch("%s*([^%s,]*)%s*[%s,]?")

	-- if recipe exists then replace it
	if minetest.clear_craft(craft) then
		craft.recipe = {
			{m() or '', m() or '', m() or ''},
			{m() or '', m() or '', m() or ''},
			{m() or '', m() or '', m() or ''}
		}
		minetest.register_craft(craft)
	end
end

local conf_table = technic.config:to_table()
for k, v in pairs(conf_table) do
	local name = k:match('^(.+)_recipe$')
	if name then replace_craft(name, v) end
end
