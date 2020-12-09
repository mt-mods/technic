-- Minetest 0.4.7 mod: technic
-- namespace: technic
-- (c) 2012-2013 by RealBadAngel <mk@realbadangel.pl>

local load_start = os.clock()

technic = rawget(_G, "technic") or {}
technic.creative_mode = minetest.settings:get_bool("creative_mode")

local modpath = minetest.get_modpath("technic")
technic.modpath = modpath


-- Boilerplate to support intllib
if rawget(_G, "intllib") then
	technic.getter = intllib.Getter()
else
	technic.getter = function(s, a, ...)
		if a == nil then
			return s
		end
		a = {a, ...}
		return s:gsub(
			"(@?)@(%(?)(%d+)(%)?)",
			function(e, o, n, c)
				if e == "" then
					return a[tonumber(n)] .. (o == "" and c or "")
				else
					return "@" .. o .. n .. c
				end
			end
		)
	end
end
local S = technic.getter

-- max_lag
dofile(modpath.."/max_lag.lua")

-- Read configuration file
dofile(modpath.."/config.lua")

-- Helper functions
dofile(modpath.."/helpers.lua")

-- Items
dofile(modpath.."/items.lua")

-- Craft recipes for items
dofile(modpath.."/crafts.lua")

-- Register functions
dofile(modpath.."/register.lua")

-- Radiation
dofile(modpath.."/radiation.lua")

-- Machines
dofile(modpath.."/machines/init.lua")

-- Tools
dofile(modpath.."/tools/init.lua")

-- Aliases for legacy node/item names
dofile(modpath.."/legacy.lua")

-- visual effects
dofile(modpath.."/effects.lua")

if minetest.settings:get_bool("log_mods") then
	print(S("[Technic] Loaded in %f seconds"):format(os.clock() - load_start))
end

if minetest.settings:get_bool("enable_technic_integration_test") then
	dofile(modpath.."/integration_test.lua")
end
