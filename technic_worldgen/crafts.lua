
local S = core.get_translator("technic_worldgen")

local has_mcl = core.get_modpath("mcl_core")

core.register_craftitem(":technic:uranium_lump", {
	description = S("Uranium Lump"),
	inventory_image = "technic_uranium_lump.png",
})

core.register_craftitem(":technic:uranium_ingot", {
	description = S("Uranium Ingot"),
	inventory_image = "technic_uranium_ingot.png",
	groups = {uranium_ingot = 1},
})

core.register_craftitem(":technic:chromium_lump", {
	description = S("Chromium Lump"),
	inventory_image = "technic_chromium_lump.png",
})

core.register_craftitem(":technic:chromium_ingot", {
	description = S("Chromium Ingot"),
	inventory_image = "technic_chromium_ingot.png",
})

core.register_craftitem(":technic:zinc_lump", {
	description = S("Zinc Lump"),
	inventory_image = "technic_zinc_lump.png",
})

core.register_craftitem(":technic:zinc_ingot", {
	description = S("Zinc Ingot"),
	inventory_image = "technic_zinc_ingot.png",
})

core.register_craftitem(":technic:lead_lump", {
	description = S("Lead Lump"),
	inventory_image = "technic_lead_lump.png",
})

core.register_craftitem(":technic:lead_ingot", {
	description = S("Lead Ingot"),
	inventory_image = "technic_lead_ingot.png",
})

core.register_craftitem(":technic:sulfur_lump", {
	description = S("Sulfur Lump"),
	inventory_image = "technic_sulfur_lump.png",
})

core.register_craftitem(":technic:cast_iron_ingot", {
	description = S("Cast Iron Ingot"),
	inventory_image = "technic_cast_iron_ingot.png",
})

core.register_craftitem(":technic:carbon_steel_ingot", {
	description = S("Carbon Steel Ingot"),
	inventory_image = "technic_carbon_steel_ingot.png",
})

core.register_craftitem(":technic:stainless_steel_ingot", {
	description = S("Stainless Steel Ingot"),
	inventory_image = "technic_stainless_steel_ingot.png",
})

local blocks = {
	["uranium"] = "ingot",
	["chromium"] = "ingot",
	["zinc"] = "ingot",
	["lead"] = "ingot",
	["cast_iron"] = "ingot",
	["carbon_steel"] = "ingot",
	["stainless_steel"] = "ingot",
	["sulfur"] = "lump",
}

for material, form in pairs(blocks) do
	local block = "technic:"..material.."_block"
	local item = "technic:"..material.."_"..form

	core.register_craft({
		output = block,
		recipe = {
			{item, item, item},
			{item, item, item},
			{item, item, item},
		}
	})

	core.register_craft({
		output = item.." 9",
		recipe = {{block}}
	})
end

core.register_craft({
	type = "cooking",
	recipe = "technic:zinc_lump",
	output = "technic:zinc_ingot",
})

core.register_craft({
	type = "cooking",
	recipe = "technic:chromium_lump",
	output = "technic:chromium_ingot",
})

core.register_craft({
	type = "cooking",
	recipe = "technic:uranium_lump",
	output = "technic:uranium_ingot",
})

core.register_craft({
	type = "cooking",
	recipe = "technic:lead_lump",
	output = "technic:lead_ingot",
})

core.register_craft({
	type = "cooking",
	recipe = has_mcl and "mcl_core:iron_ingot" or "default:steel_ingot",
	output = "technic:cast_iron_ingot",
})

core.register_craft({
	type = "cooking",
	recipe = "technic:cast_iron_ingot",
	cooktime = 2,
	output = "technic:wrought_iron_ingot",
})

core.register_craft({
	type = "cooking",
	recipe = "technic:carbon_steel_ingot",
	cooktime = 2,
	output = "technic:wrought_iron_ingot",
})

if not core.get_modpath("underch") then
	core.register_craft({
		output = "technic:marble_bricks 4",
		recipe = {
			{"technic:marble","technic:marble"},
			{"technic:marble","technic:marble"}
		}
	})
end

core.register_craft({
	output = "technic:granite_bricks 4",
	recipe = {
		{"technic:granite","technic:granite"},
		{"technic:granite","technic:granite"}
	}
})

core.register_craft({
	output = "technic:blast_resistant_concrete 5",
	recipe = {
		{"basic_materials:concrete_block", "technic:composite_plate", "basic_materials:concrete_block"},
		{"technic:composite_plate", "basic_materials:concrete_block", "technic:composite_plate"},
		{"basic_materials:concrete_block", "technic:composite_plate", "basic_materials:concrete_block"},
	}
})
