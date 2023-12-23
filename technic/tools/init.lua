local path = technic.modpath.."/tools"
local mesecons_materials = minetest.get_modpath("mesecons_materials")

local function enabled(name)
	return technic.config:get_bool("enable_" .. name)
end

if enabled("mining_drill")      then dofile(path.."/mining_drill.lua") end
if enabled("mining_laser")      then dofile(path.."/mining_lasers.lua") end
if enabled("flashlight")        then dofile(path.."/flashlight.lua") end
if enabled("cans")              then dofile(path.."/cans.lua") end
if enabled("chainsaw")          then dofile(path.."/chainsaw.lua") end
if enabled("tree_tap")          then dofile(path.."/tree_tap.lua") end
if enabled("sonic_screwdriver") and mesecons_materials then dofile(path.."/sonic_screwdriver.lua") end
if enabled("prospector")        then dofile(path.."/prospector.lua") end
if enabled("vacuum")            then dofile(path.."/vacuum.lua") end
if enabled("multimeter")        then dofile(path.."/multimeter.lua") end

if minetest.get_modpath("screwdriver") then
	-- compatibility alias
	minetest.register_alias("technic:screwdriver", "screwdriver:screwdriver")
end
