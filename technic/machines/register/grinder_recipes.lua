
local S = technic.getter
local mat = technic.materials

technic.register_recipe_type("grinding", {
	description = S("Grinding"),
	icon = "technic_hv_grinder_front.png",
})

function technic.register_grinder_recipe(data)
	data.time = data.time or 3
	technic.register_recipe("grinding", data)
end

local recipes = {
	-- Dusts
	{mat.coal_lump,          "technic:coal_dust 2"},
	{mat.copper_lump,        "technic:copper_dust 2"},
	{mat.desert_stone,       mat.desert_sand},
	{mat.gold_lump,          "technic:gold_dust 2"},
	{mat.iron_lump,          "technic:wrought_iron_dust 2"},
	{mat.tin_lump,           "technic:tin_dust 2"},
	{"technic:chromium_lump",      "technic:chromium_dust 2"},
	{"technic:uranium_lump",       "technic:uranium_dust 2"},
	{"technic:zinc_lump",          "technic:zinc_dust 2"},
	{"technic:lead_lump",          "technic:lead_dust 2"},
	{"technic:sulfur_lump",        "technic:sulfur_dust 2"},
	{mat.stone,              "technic:stone_dust"},
	{mat.sand,               "technic:stone_dust"},
	{mat.desert_sand,        "technic:stone_dust"},
	{mat.silver_sand,        "technic:stone_dust"},

	-- Other
	{mat.cobble,           mat.gravel},
	{mat.gravel,           mat.sand},
	{mat.sandstone,        mat.sand.." 2"}, -- reverse recipe can be found in the compressor
	{mat.desert_sandstone, mat.desert_sand.." 2"}, -- reverse recipe can be found in the compressor
	{mat.silver_sandstone, mat.silver_sand.." 2"}, -- reverse recipe can be found in the compressor

	{mat.ice,              mat.snowblock},
}

if minetest.get_modpath("ethereal") then
	-- the density of charcoal is ~1/10 of coal, otherwise it's the same graphitic carbon
	table.insert(recipes, {"ethereal:charcoal_lump 5", "technic:coal_dust 1"})
end

-- defuse the sandstone -> 4 sand recipe to avoid infinite sand bugs (also consult the inverse compressor recipe)
minetest.clear_craft({
	recipe = {
		{mat.sandstone}
	},
})
minetest.clear_craft({
	recipe = {
		{mat.desert_sandstone}
	},
})
minetest.clear_craft({
	recipe = {
		{mat.silver_sandstone}
	},
})

if minetest.get_modpath("farming") then
	table.insert(recipes, {mat.seed_wheat,   "farming:flour 1"})
end

if minetest.get_modpath("moreores") then
	table.insert(recipes, {"moreores:mithril_lump",   "technic:mithril_dust 2"})
	table.insert(recipes, {"moreores:silver_lump",    "technic:silver_dust 2"})
end

if minetest.get_modpath("gloopores") or minetest.get_modpath("glooptest") then
	table.insert(recipes, {"gloopores:alatro_lump",   "technic:alatro_dust 2"})
	table.insert(recipes, {"gloopores:kalite_lump",   "technic:kalite_dust 2"})
	table.insert(recipes, {"gloopores:arol_lump",     "technic:arol_dust 2"})
	table.insert(recipes, {"gloopores:talinite_lump", "technic:talinite_dust 2"})
	table.insert(recipes, {"gloopores:akalin_lump",   "technic:akalin_dust 2"})
end

if minetest.get_modpath("homedecor") then
	table.insert(recipes, {"home_decor:brass_ingot", "technic:brass_dust 1"})
end

for _, data in pairs(recipes) do
	technic.register_grinder_recipe({input = {data[1]}, output = data[2]})
end

-- dusts
local function register_dust(name, ingot)
	local lname = string.lower(name)
	lname = string.gsub(lname, ' ', '_')
	minetest.register_craftitem("technic:"..lname.."_dust", {
		description = S("@1 Dust", S(name)),
		inventory_image = "technic_"..lname.."_dust.png",
	})
	if ingot then
		minetest.register_craft({
			type = "cooking",
			recipe = "technic:"..lname.."_dust",
			output = ingot,
		})
		technic.register_grinder_recipe({ input = {ingot}, output = "technic:"..lname.."_dust 1" })
	end
end

-- Sorted alphibeticaly
register_dust("Brass",           "basic_materials:brass_ingot")
register_dust("Bronze",          mat.bronze_ingot)
register_dust("Carbon Steel",    "technic:carbon_steel_ingot")
register_dust("Cast Iron",       "technic:cast_iron_ingot")
register_dust("Chernobylite",    "technic:chernobylite_block")
register_dust("Chromium",        "technic:chromium_ingot")
register_dust("Coal",            nil)
register_dust("Copper",          mat.copper_ingot)
register_dust("Lead",            "technic:lead_ingot")
register_dust("Gold",            mat.gold_ingot)
register_dust("Mithril",         mat.mithril_ingot)
register_dust("Silver",          mat.silver_ingot)
register_dust("Stainless Steel", "technic:stainless_steel_ingot")
register_dust("Stone",           mat.stone)
register_dust("Sulfur",          nil)
register_dust("Tin",             mat.tin_ingot)
register_dust("Wrought Iron",    "technic:wrought_iron_ingot")
register_dust("Zinc",            "technic:zinc_ingot")
if minetest.get_modpath("gloopores") or minetest.get_modpath("glooptest") then
	register_dust("Akalin",          "glooptest:akalin_ingot")
	register_dust("Alatro",          "glooptest:alatro_ingot")
	register_dust("Arol",            "glooptest:arol_ingot")
	register_dust("Kalite",          nil)
	register_dust("Talinite",        "glooptest:talinite_ingot")
end

for p = 0, 35 do
	local nici = (p ~= 0 and p ~= 7 and p ~= 35) and 1 or nil
	local psuffix = p == 7 and "" or p
	local ingot = "technic:uranium"..psuffix.."_ingot"
	local dust = "technic:uranium"..psuffix.."_dust"
	minetest.register_craftitem(dust, {
		description = S("@1%-Fissile Uranium Dust", string.format("%.1f", p/10)),
		inventory_image = "technic_uranium_dust.png",
		on_place_on_ground = minetest.craftitem_place_item,
		groups = {uranium_dust=1, not_in_creative_inventory=nici},
	})
	minetest.register_craft({
		type = "cooking",
		recipe = dust,
		output = ingot,
	})
	technic.register_grinder_recipe({ input = {ingot}, output = dust })
end

local function uranium_dust(p)
	return "technic:uranium"..(p == 7 and "" or p).."_dust"
end
for pa = 0, 34 do
	for pb = pa+1, 35 do
		local pc = (pa+pb)/2
		if pc == math.floor(pc) then
			minetest.register_craft({
				type = "shapeless",
				recipe = { uranium_dust(pa), uranium_dust(pb) },
				output = uranium_dust(pc).." 2",
			})
		end
	end
end

minetest.register_craft({
	type = "fuel",
	recipe = "technic:coal_dust",
	burntime = 50,
})

if minetest.get_modpath("gloopores") or minetest.get_modpath("glooptest") then
	minetest.register_craft({
		type = "fuel",
		recipe = "technic:kalite_dust",
		burntime = 37.5,
	})
end
