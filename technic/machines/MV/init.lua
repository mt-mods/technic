
technic.register_tier("MV", "Medium Voltage")

local path = technic.modpath.."/machines/MV"

-- Wiring stuff
dofile(path.."/cables.lua")
dofile(path.."/battery_box.lua")

-- Generators
if technic.config:get_bool("enable_wind_mill") then
	dofile(path.."/wind_mill.lua")
end
dofile(path.."/generator.lua")
dofile(path.."/solar_array.lua")
dofile(path.."/hydro_turbine.lua")

-- Machines
dofile(path.."/alloy_furnace.lua")
dofile(path.."/electric_furnace.lua")
dofile(path.."/grinder.lua")
dofile(path.."/extractor.lua")
dofile(path.."/compressor.lua")
dofile(path.."/centrifuge.lua")

dofile(path.."/tool_workshop.lua")

dofile(path.."/freezer.lua")
