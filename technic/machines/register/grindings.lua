local S = technic.getter
local moretrees = minetest.get_modpath("moretrees")
local dye = minetest.get_modpath("dye")

-- sawdust, the finest wood/tree grinding
local sawdust = "technic:sawdust"
minetest.register_craftitem(sawdust, {
	description = S("Sawdust"),
	inventory_image = "technic_sawdust.png",
})
minetest.register_craft({ type = "fuel", recipe = sawdust, burntime = 6 })
technic.register_compressor_recipe({ input = {sawdust .. " 4"}, output = "default:wood" })

-- tree/wood grindings
local function register_tree_grinding(name, tree, wood, extract, grinding_color)
	local lname = string.lower(name)
	lname = string.gsub(lname, ' ', '_')
	local grindings_name = "technic:"..lname.."_grindings"
	if not minetest.registered_craftitems[grindings_name] then
		local inventory_image = "technic_"..lname.."_grindings.png"
		if grinding_color then
			inventory_image = inventory_image .. "^[colorize:" .. grinding_color
		end
		minetest.register_craftitem(grindings_name, {
			description = S("@1 Grinding", S(name)),
			inventory_image = inventory_image,
		})
		minetest.register_craft({
			type = "fuel",
			recipe = grindings_name,
			burntime = 8,
		})
	end
	technic.register_grinder_recipe({ input = { tree }, output = grindings_name .. " 4" })
	technic.register_grinder_recipe({ input = { grindings_name }, output = sawdust .. " 4" })
	if wood then
		technic.register_grinder_recipe({ input = { wood }, output = grindings_name })
	end
	if extract then
		technic.register_extractor_recipe({ input = { grindings_name .. " 4" }, output = extract})
		technic.register_separating_recipe({
			input = { grindings_name .. " 4" },
			output = { sawdust .. " 4", extract }
		})
	end
end

local rubber_tree_planks = moretrees and "moretrees:rubber_tree_planks"
local default_extract = dye and "dye:brown 2"

-- https://en.wikipedia.org/wiki/Catechu ancient brown dye from the wood of acacia trees
local acacia_extract = dye and "dye:brown 8"

-- technic recipes don't support groups yet :/
--register_tree_grinding("Common Tree", "group:tree", "group:wood", default_extract)

register_tree_grinding("Acacia", "default:acacia_tree", "default:acacia_wood", acacia_extract)
register_tree_grinding("Common Tree", "default:tree", "default:wood", default_extract)
register_tree_grinding("Common Tree", "default:aspen_tree", "default:aspen_wood", default_extract)
register_tree_grinding("Common Tree", "default:jungletree", "default:junglewood", default_extract)
register_tree_grinding("Common Tree", "default:pine_tree", "default:pine_wood", default_extract)
register_tree_grinding("Rubber Tree", "moretrees:rubber_tree_trunk", rubber_tree_planks, "technic:raw_latex")
register_tree_grinding("Rubber Tree", "moretrees:rubber_tree_trunk_empty", nil, "technic:raw_latex")

if moretrees then
	local trees = {
		"beech", "apple_tree", "oak", "sequoia", "birch", "palm",
		"date_palm", "spruce", "cedar", "poplar", "willow", "fir"
	}
	for _,tree in pairs(trees) do
		register_tree_grinding("Common Tree", "moretrees:"..tree.."_trunk", "moretrees:"..tree.."_planks", default_extract)
	end
end
