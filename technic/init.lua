
technic = rawget(_G, "technic") or {}

technic.plus = true
technic.version = 1.2

if core.get_modpath("mcl_sounds") then
	technic.sounds = mcl_sounds
else
	technic.sounds = assert(default, "No suitable mod found for sounds")
end

technic.creative_mode = core.settings:get_bool("creative_mode")

local modpath = core.get_modpath("technic")
technic.modpath = modpath

local S = core.get_translator("technic")
technic.getter = S

-- Read materials file
dofile(modpath.."/materials.lua")

-- Read configuration file
dofile(modpath.."/config.lua")

-- Lag monitoring
dofile(modpath.."/max_lag.lua")

-- Helper functions
dofile(modpath.."/helpers.lua")

-- Register functions
dofile(modpath.."/register.lua")

-- Compatibility shims for tools
dofile(modpath.."/machines/compat/tools.lua")

-- Items
dofile(modpath.."/items.lua")

-- Craft recipes for items
dofile(modpath.."/crafts.lua")

-- Radiation
dofile(modpath.."/radiation.lua")

-- Machines
dofile(modpath.."/machines/init.lua")

-- Tools
dofile(modpath.."/tools/init.lua")

-- Visual effects
dofile(modpath.."/effects.lua")

-- Chat commands
dofile(modpath.."/chatcommands.lua")

if core.get_modpath("mtt") and mtt.enabled then
	dofile(modpath.."/mtt.lua")
end
