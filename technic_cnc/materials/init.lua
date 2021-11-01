
local path = technic_cnc.modpath .. "/materials/"

dofile(path .. "default.lua")
dofile(path .. "basic_materials.lua")

local optional_mods = {
	"bakedclay",
	"ethereal",
	"moreblocks",
	"technic_worldgen",
}

for _, mod in pairs(optional_mods) do
	if minetest.get_modpath(mod) then
		dofile(path .. mod .. ".lua")
	end
end
