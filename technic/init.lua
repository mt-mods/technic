
technic = rawget(_G, "technic") or {}

technic.plus = true
technic.version = 1.2

technic.creative_mode = minetest.settings:get_bool("creative_mode")

local modpath = minetest.get_modpath("technic")
technic.modpath = modpath

local S = minetest.get_translator("technic")
technic.getter = S

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

-- Aliases for legacy node/item names
dofile(modpath.."/legacy.lua")

-- Visual effects
dofile(modpath.."/effects.lua")

-- Chat commands
dofile(modpath.."/chatcommands.lua")

if minetest.get_modpath("mtt") then
	dofile(modpath.."/integration_test.lua")
end
