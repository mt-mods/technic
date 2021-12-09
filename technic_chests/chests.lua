
local S = minetest.get_translator(minetest.get_current_modname())

local function register_chests(data)
	local name = data.description:lower()
	local type_description = {
		S("@1 Chest", S(data.description)),
		S("@1 Locked Chest", S(data.description)),
		S("@1 Protected Chest", S(data.description)),
	}
	for i,t in ipairs({"", "_locked", "_protected"}) do
		local data_copy = table.copy(data)
		data_copy.locked = t == "_locked"
		data_copy.protected = t == "_protected"
		data_copy.texture_prefix = "technic_"..name.."_chest"
		data_copy.description = type_description[i]
		technic.chests.register_chest(":technic:"..name..t.."_chest", data_copy)
	end
end

local function register_crafts(name, material, base_open, base_locked, base_protected)
	name = name:lower()
	if minetest.registered_items[material] then
		if minetest.registered_items[base_open] then
			minetest.register_craft({
				output = "technic:"..name.."_chest",
				recipe = {
					{material, material, material},
					{material, base_open, material},
					{material, material, material},
				}
			})
		end
		if minetest.registered_items[base_locked] then
			minetest.register_craft({
				output = "technic:"..name.."_locked_chest",
				recipe = {
					{material, material, material},
					{material, base_locked, material},
					{material, material, material},
				}
			})
		end
		if minetest.registered_items[base_protected] then
			minetest.register_craft({
				output = "technic:"..name.."_protected_chest",
				recipe = {
					{material, material, material},
					{material, base_protected, material},
					{material, material, material},
				}
			})
		end
	end
	minetest.register_craft({
		output = "technic:"..name.."_locked_chest",
		type = "shapeless",
		recipe = {"basic_materials:padlock","technic:"..name.."_chest"}
	})
	minetest.register_craft({
		output = "technic:"..name.."_protected_chest",
		type = "shapeless",
		recipe = {"default:copper_ingot", "technic:"..name.."_chest"}
	})
	minetest.register_craft({
		output = "technic:"..name.."_chest",
		type = "shapeless",
		recipe = {"technic:"..name.."_locked_chest"}
	})
	minetest.register_craft({
		output = "technic:"..name.."_chest",
		type = "shapeless",
		recipe = {"technic:"..name.."_protected_chest"}
	})
end

-- Iron
register_chests({
	description = "Iron",
	width = 9,
	height = 5,
	sort = true,
	infotext = true,
})
register_crafts(
	"Iron",
	minetest.get_modpath("technic_worldgen") and "technic:cast_iron_ingot" or "default:steel_ingot",
	"default:chest",
	"default:chest_locked",
	"protector:chest"
)

-- Copper
register_chests({
	description = "Copper",
	width = 12,
	height = 5,
	sort = true,
	infotext = true,
	autosort = true,
})
register_crafts(
	"Copper",
	"default:copper_ingot",
	"technic:iron_chest",
	"technic:iron_locked_chest",
	"technic:iron_protected_chest"
)

-- Silver
register_chests({
	description = "Silver",
	width = 12,
	height = 6,
	sort = true,
	infotext = true,
	autosort = true,
	quickmove = true,
})
register_crafts(
	"Silver",
	"moreores:silver_ingot",
	"technic:copper_chest",
	"technic:copper_locked_chest",
	"technic:copper_protected_chest"
)

-- Gold
register_chests({
	description = "Gold",
	width = 15,
	height = 6,
	sort = true,
	infotext = true,
	autosort = true,
	quickmove = true,
	color = true,
})
register_crafts(
	"Gold",
	"default:gold_ingot",
	minetest.get_modpath("moreores") and "technic:silver_chest" or "technic:copper_chest",
	minetest.get_modpath("moreores") and "technic:silver_locked_chest" or "technic:copper_locked_chest",
	minetest.get_modpath("moreores") and "technic:silver_protected_chest" or "technic:copper_protected_chest"
)

-- Mithril
register_chests({
	description = "Mithril",
	width = 15,
	height = 6,
	sort = true,
	infotext = true,
	autosort = true,
	quickmove = true,
	digilines = true,
})
register_crafts(
	"Mithril",
	"moreores:mithril_ingot",
	"technic:gold_chest",
	"technic:gold_locked_chest",
	"technic:gold_protected_chest"
)
