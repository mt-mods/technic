
local modpath = minetest.get_modpath("technic_worldgen")

technic = rawget(_G, "technic") or {}

technic.sounds = {}
if minetest.get_modpath("default") then
	technic.sounds = default
end
if minetest.get_modpath("mcl_sounds") then
	technic.sounds = mcl_sounds
end

dofile(modpath.."/config.lua")
dofile(modpath.."/nodes.lua")
dofile(modpath.."/oregen.lua")
dofile(modpath.."/crafts.lua")
if minetest.get_modpath("default") then
	dofile(modpath.."/overrides.lua")
elseif minetest.get_modpath("mcl_core") then
	minetest.register_alias("technic:wrought_iron_ingot", "mcl_core:iron_ingot")
end

-- Rubber trees, moretrees also supplies these
if not minetest.get_modpath("moretrees") then
	dofile(modpath.."/rubber.lua")
else
	-- Older versions of technic provided rubber trees regardless
	minetest.register_alias("technic:rubber_sapling", "moretrees:rubber_tree_sapling")
	minetest.register_alias("technic:rubber_tree_empty", "moretrees:rubber_tree_trunk_empty")
end

-- mg suppport
if minetest.get_modpath("mg") then
	dofile(modpath.."/mg.lua")
end

minetest.register_alias("technic:uranium", "technic:uranium_lump")

if minetest.get_modpath("default") then
	minetest.register_alias("technic:wrought_iron_ingot", "default:steel_ingot")
	minetest.register_alias("technic:wrought_iron_block", "default:steelblock")
	minetest.register_alias("technic:diamond_block", "default:diamondblock")
	minetest.register_alias("technic:diamond", "default:diamond")
	minetest.register_alias("technic:mineral_diamond", "default:stone_with_diamond")
end

if minetest.get_modpath("mcl_core") then
	minetest.register_alias("technic:wrought_iron_ingot", "mcl_core:iron_ingot")
	minetest.register_alias("technic:wrought_iron_block", "mcl_core:ironblock")
	minetest.register_alias("technic:diamond_block", "mcl_core:diamondblock")
	minetest.register_alias("technic:diamond", "mcl_core:diamond")
	minetest.register_alias("technic:mineral_diamond", "mcl_core:stone_with_diamond")
end
