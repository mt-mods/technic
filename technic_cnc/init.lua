local technic_modpath = minetest.get_modpath("technic")
local digilines_modpath = minetest.get_modpath("digilines")
local pipeworks_modpath = minetest.get_modpath("pipeworks")

technic_cnc = {}
technic_cnc.modpath = minetest.get_modpath("technic_cnc")
technic_cnc.use_technic = technic_modpath and minetest.settings:get_bool("technic_cnc_use_technic", true)
local use_digilines = digilines_modpath and minetest.settings:get_bool("technic_cnc_use_digilines", true)
local use_pipeworks = pipeworks_modpath and minetest.settings:get_bool("technic_cnc_use_pipeworks", true)

if rawget(_G, "intllib") then
	technic_cnc.getter = intllib.Getter()
else
	technic_cnc.getter = function(s, a, ...)
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

if use_digilines then technic_cnc.digilines = dofile(technic_cnc.modpath.."/digilines.lua") end
if use_pipeworks then technic_cnc.pipeworks = dofile(technic_cnc.modpath.."/pipeworks.lua") end

technic_cnc.formspec = dofile(technic_cnc.modpath .. "/formspec.lua")
dofile(technic_cnc.modpath .. "/programs.lua")
dofile(technic_cnc.modpath .. "/api.lua")
dofile(technic_cnc.modpath .. "/materials/init.lua")
dofile(technic_cnc.modpath .. "/cnc.lua")
