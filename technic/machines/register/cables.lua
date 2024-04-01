
local cable_tier = {}

function technic.is_tier_cable(nodename, tier)
	return cable_tier[nodename] == tier
end

function technic.get_cable_tier(nodename)
	return cable_tier[nodename]
end

function technic.register_cable_tier(name, tier)
	assert(technic.machines[tier], "Tier does not exist")
	assert(type(name) == "string", "Invalid node name")

	cable_tier[name] = tier
end

local function item_place_override_node(itemstack, placer, pointed, node)
	-- Call the default on_place function with a fake itemstack
	local temp_itemstack = ItemStack(itemstack)
	temp_itemstack:set_name(node.name)
	local original_count = temp_itemstack:get_count()
	temp_itemstack =
		minetest.item_place(temp_itemstack, placer, pointed, node.param2) or
		temp_itemstack
	-- Remove the same number of items from the real itemstack
	itemstack:take_item(original_count - temp_itemstack:get_count())
	return itemstack
end

local function cable_defaults(nodename, data)
	assert(data.tier, "Technic cable registration requires `tier` field")
	assert(data.size, "Technic cable registration requires `size` field")
	assert(data.description, "Technic cable registration requires `description` field")

	local def = table.copy(data)
	local tier = def.tier
	local ltier = string.lower(tier)
	local size = def.size

	local place_network_node = technic.place_network_node
	local remove_network_node = technic.remove_network_node

	def.connects_to = def.connects_to or {
		"group:technic_"..ltier.."_cable",
		"group:technic_"..ltier,
		"group:technic_all_tiers"
	}
	def.groups = def.groups or {
		snappy = 2,
		choppy = 2,
		oddly_breakable_by_hand = 2,
		swordy = 1,
		axey = 1,
		handy = 1,
		["technic_"..ltier.."_cable"] = 1
	}
	def.is_ground_content = false
	def.drop = def.drop or nodename
	def.sounds = def.sounds or technic.sounds.node_sound_wood_defaults()
	def.on_construct = def.on_construct or function(pos) place_network_node(pos, {tier}, nodename) end
	def.on_destruct = def.on_destruct or function(pos) remove_network_node(pos, {tier}, nodename) end
	def.paramtype = def.paramtype or "light"
	def.sunlight_propagates = not (def.sunlight_propagates == false and true)
	def.drawtype = def.drawtype or "nodebox"
	def.node_box = def.node_box or {
		type = "connected",
		fixed          = {-size, -size, -size, size,  size, size},
		connect_top    = {-size, -size, -size, size,  0.5,  size}, -- y+
		connect_bottom = {-size, -0.5,  -size, size,  size, size}, -- y-
		connect_front  = {-size, -size, -0.5,  size,  size, size}, -- z-
		connect_back   = {-size, -size,  size, size,  size, 0.5 }, -- z+
		connect_left   = {-0.5,  -size, -size, size,  size, size}, -- x-
		connect_right  = {-size, -size, -size, 0.5,   size, size}, -- x+
	}
	return def
end

function technic.register_cable_plate(nodename, data)
	local xyz = {"x","y","z"}
	local notconnects = {"left", "bottom", "front", "right", "top", "back"}
	local texture_basename = nodename:gsub(":", "_")
	for i = 1, 6 do
		-- Merge defaults and register cable plate
		local def = cable_defaults(nodename.."_"..i, data)
		local size = def.size
		def.tiles = def.tiles or {texture_basename..".png"}
		def.drop = nodename.."_1"
		def.node_box.fixed = {
			{-size, -size, -size, size, size, size},
			{-0.5, -0.5, -0.5, 0.5, 0.5, 0.5}
		}
		def.node_box.fixed[1][i] = 7/16 * (i-3.5)/math.abs(i-3.5)
		def.node_box.fixed[2][(i + 2) % 6 + 1] = 3/8 * (i-3.5)/math.abs(i-3.5)
		def.node_box["connect_"..notconnects[i]] = nil
		if i == 1 then
			def.on_place = function(itemstack, placer, pointed_thing)
				local pointed_thing_diff = vector.subtract(pointed_thing.above, pointed_thing.under)
				local index = pointed_thing_diff.x + (pointed_thing_diff.y*2) + (pointed_thing_diff.z*3)
				local num = index < 0 and -index + 3 or index
				local crtl = placer:get_player_control()
				if (crtl.aux1 or crtl.sneak) and not (crtl.aux1 and crtl.sneak) and index ~= 0 then
					local fine_pointed = minetest.pointed_thing_to_face_pos(placer, pointed_thing)
					fine_pointed = vector.subtract(fine_pointed, pointed_thing.above)
					index = index < 0 and -index or index
					index = (index-1)%3+1
					fine_pointed[xyz[index]] = nil
					local key_a, a = next(fine_pointed)
					local key_b, b = next(fine_pointed, key_a)
					local far_key = math.abs(a) > math.abs(b) and key_a or key_b
					local far = fine_pointed[far_key]
					-- Plate facing
					-- X pair floor +X 4 -X 1 -> Z pair, Y pair
					-- Y pair floor +Y 5 -Y 2 -> X pair, Z pair
					-- Z pair floor +Z 6 -Z 3 -> X pair, Y pair
					if math.abs(far) < 0.3 then
						num = num < 4 and num + 3 or num - 3
					elseif far_key == "x" then
						num = far < 0 and 1 or 4
					elseif far_key == "y" then
						num = far < 0 and 2 or 5
					else
						num = far < 0 and 3 or 6
					end
				end
				local node = {name = nodename.."_"..(num ~= 0 and num or 1)}
				return item_place_override_node(itemstack, placer, pointed_thing, node)
			end
		else
			def.groups.not_in_creative_inventory = 1
			def._mcl_blast_resistance = 1
			def._mcl_hardness = 0.8
		end
		def.on_rotate = function(pos, node, user, mode, new_param2)
			-- mode 1 is left-click, mode 2 is right-click
			local dir = mode == 1 and 1 or (mode == 2 and -1 or 0)
			local num = tonumber(node.name:sub(-1)) + dir - 1
			minetest.swap_node(pos, {name = nodename.."_"..(num % 6 + 1)})
		end
		minetest.register_node(nodename.."_"..i, def)
		cable_tier[nodename.."_"..i] = def.tier
	end
end

function technic.register_cable(nodename, data)
	-- Merge defaults and register cable
	local def = cable_defaults(nodename, data)
	local texture_basename = nodename:gsub(":", "_")
	def.tiles = def.tiles or {texture_basename..".png"}
	def.inventory_image = def.inventory_image or def.inventory_image ~= false and texture_basename.."_wield.png" or nil
	def.wield_image = def.wield_image or def.wield_image ~= false and texture_basename.."_wield.png" or nil
	def._mcl_blast_resistance = 1
	def._mcl_hardness = 0.8
	minetest.register_node(nodename, def)
	cable_tier[nodename] = def.tier
end
