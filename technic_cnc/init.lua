local technic_modpath = minetest.get_modpath("technic")
local digilines_modpath = minetest.get_modpath("digilines")
local pipeworks_modpath = minetest.get_modpath("pipeworks")

technic_cnc = {}
technic_cnc.modpath = minetest.get_modpath("technic_cnc")
technic_cnc.use_technic = technic_modpath and minetest.settings:get_bool("technic_cnc_use_technic", true)
local use_digilines = digilines_modpath and minetest.settings:get_bool("technic_cnc_use_digilines", true)
local use_pipeworks = pipeworks_modpath and minetest.settings:get_bool("technic_cnc_use_pipeworks", true)

technic_cnc.getter = minetest.get_translator(minetest.get_current_modname())

if use_digilines then technic_cnc.digilines = dofile(technic_cnc.modpath.."/digilines.lua") end
if use_pipeworks then technic_cnc.pipeworks = dofile(technic_cnc.modpath.."/pipeworks.lua") end

technic_cnc.formspec = dofile(technic_cnc.modpath .. "/formspec.lua")
dofile(technic_cnc.modpath .. "/programs.lua")
dofile(technic_cnc.modpath .. "/api.lua")
dofile(technic_cnc.modpath .. "/materials/init.lua")
dofile(technic_cnc.modpath .. "/cnc.lua")
