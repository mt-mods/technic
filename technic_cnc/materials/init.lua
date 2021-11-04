
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

local function alias(old, new)
	for _,shape in pairs(technic_cnc.programs) do
		minetest.register_alias(old .. "_" .. shape.suffix, new .. "_" .. shape.suffix)
	end
end

alias("technic:brass_block", "basic_materials:brass_block")
