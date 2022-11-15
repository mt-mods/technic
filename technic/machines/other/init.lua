local path = technic.modpath.."/machines/other"

-- Mesecons and tubes related
dofile(path.."/injector.lua")
dofile(path.."/constructor.lua")

-- Coal-powered machines
dofile(path.."/coal_alloy_furnace.lua")
dofile(path.."/coal_furnace.lua")

-- Force-loading
dofile(path.."/anchor.lua")
