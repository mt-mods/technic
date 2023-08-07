
local S = minetest.get_translator("technic_worldgen")

minetest.override_item("default:steel_ingot", {
	description = S("Wrought Iron Ingot"),
	-- Make the color of the ingot a bit darker to separate it better from tin
	inventory_image = "technic_wrought_iron_ingot.png^[multiply:#bbbbbbff",
})

-- Override description and textures of "steel" items

local excluded_words = {
	"[Cc]arbon",
	"[Ss]tainless",
	"[Ff]lint",
}

local function is_steel(name, desc)
	name = name:gsub(".+:(.+)", "%1")  -- Ignore mod name
	if name:match("[Ss]teel") or desc:match("[Ss]teel") then
		for _, word in pairs(excluded_words) do
			if name:match(word) or desc:match(word) then
				return false
			end
		end
		return true
	end
end

local function edit_desc(desc, old, new)
	desc = desc:gsub(old, new)
	desc = desc:gsub(old:lower(), new:lower())
	return desc
end

local function replace_texture(tile)
	local new_tile
	if type(tile) == "string" then
		new_tile = tile:gsub("default_steel_block.png", "technic_wrought_iron_block.png")
	else
		new_tile = {}
		for k, v in pairs(tile) do
			if k == "name" then
				new_tile[k] = v:gsub("default_steel_block.png", "technic_wrought_iron_block.png")
			else
				new_tile[k] = v
			end
		end
	end
	return new_tile
end

local function do_override(name, def)
	local desc = def.description
	if not is_steel(name, desc) then
		return
	end
	local override = {}
	if name:find("steelblock") then
		override.description = edit_desc(desc, "Steel", "Wrought Iron")
	else
		override.description = edit_desc(desc, "Steel", "Iron")
	end
	if def.tiles then
		override.tiles = {}
		for _, tile in ipairs(def.tiles) do
			table.insert(override.tiles, replace_texture(tile))
		end
	end
	if def.inventory_image then
		override.inventory_image = replace_texture(def.inventory_image)
	end
	if def.wield_image then
		override.wield_image = replace_texture(def.wield_image)
	end
	minetest.override_item(name, override)
end

minetest.register_on_mods_loaded(function()
	for name, def in pairs(minetest.registered_items) do
		do_override(name, def)
	end
end)
