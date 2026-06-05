
local modpath = core.get_modpath("technic_worldgen")

technic = rawget(_G, "technic") or {}

technic.sounds = {}
if core.get_modpath("default") then
	technic.sounds = default
end
if core.get_modpath("mcl_sounds") then
	technic.sounds = mcl_sounds
end

dofile(modpath.."/config.lua")
dofile(modpath.."/nodes.lua")
dofile(modpath.."/oregen.lua")
dofile(modpath.."/crafts.lua")
if core.get_modpath("default") and technic.config:get_bool("enable_steel_override") then
	dofile(modpath.."/overrides.lua")
end

-- Rubber trees, moretrees also supplies these
if not core.get_modpath("moretrees") then
	dofile(modpath.."/rubber.lua")
else
	-- Older versions of technic provided rubber trees regardless
	core.register_alias("technic:rubber_sapling", "moretrees:rubber_tree_sapling")
	core.register_alias("technic:rubber_tree_empty", "moretrees:rubber_tree_trunk_empty")
end

-- mg suppport
if core.get_modpath("mg") then
	dofile(modpath.."/mg.lua")
end

core.register_alias("technic:uranium", "technic:uranium_lump")

if core.get_modpath("default") then
	core.register_alias("technic:wrought_iron_ingot", "default:steel_ingot")
	core.register_alias("technic:wrought_iron_block", "default:steelblock")
	core.register_alias("technic:diamond_block", "default:diamondblock")
	core.register_alias("technic:diamond", "default:diamond")
	core.register_alias("technic:mineral_diamond", "default:stone_with_diamond")
end

if core.get_modpath("mcl_core") then
	core.register_alias("technic:wrought_iron_ingot", "mcl_core:iron_ingot")
	core.register_alias("technic:wrought_iron_block", "mcl_core:ironblock")
	core.register_alias("technic:diamond_block", "mcl_core:diamondblock")
	core.register_alias("technic:diamond", "mcl_core:diamond")
	core.register_alias("technic:mineral_diamond", "mcl_core:stone_with_diamond")
end
