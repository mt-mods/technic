
local S = technic.getter

local cable_tier = {}

function technic.is_tier_cable(name, tier)
	return cable_tier[name] == tier
end

function technic.get_cable_tier(name)
	return cable_tier[name]
end

local function get_neighbors(pos, tier)
	-- TODO: Move this to network.lua
	local tier_machines = technic.machines[tier]
	local is_cable = technic.is_tier_cable(minetest.get_node(pos).name, tier)
	local network = is_cable and technic.networks[technic.pos2network(pos)]
	local cables = {}
	local machines = {}
	local positions = {
		{x=pos.x+1, y=pos.y,   z=pos.z},
		{x=pos.x-1, y=pos.y,   z=pos.z},
		{x=pos.x,   y=pos.y+1, z=pos.z},
		{x=pos.x,   y=pos.y-1, z=pos.z},
		{x=pos.x,   y=pos.y,   z=pos.z+1},
		{x=pos.x,   y=pos.y,   z=pos.z-1},
	}
	for _,connected_pos in ipairs(positions) do
		local name = minetest.get_node(connected_pos).name
		if tier_machines[name] then
			table.insert(machines, connected_pos)
		elseif technic.is_tier_cable(name, tier) then
			local cable_network = technic.networks[technic.pos2network(connected_pos)]
			table.insert(cables,{
				pos = connected_pos,
				network = cable_network,
			})
			if not network then network = cable_network end
		end
	end
	return network, cables, machines
end

local function place_network_node(pos, tier, name)
	-- Get connections and primary network if there's any
	local network, cables, machines = get_neighbors(pos, tier)
	if not network then
		-- We're evidently not on a network, nothing to add ourselves to
		return
	end

	-- Attach to primary network, this must be done before building branches from this position
	technic.add_network_node(pos, network)
	if not technic.is_tier_cable(name, tier) then
		-- Check connected cables for foreign networks
		for _, connection in ipairs(cables) do
			if connection.network and connection.network.id ~= network.id then
				technic.overload_network(connection.network.id)
				technic.overload_network(network.id)
			end
		end
		-- Machine added, skip all network building
		return
	end

	-- Attach neighbor machines if cable was added
	for _,machine_pos in ipairs(machines) do
		technic.add_network_node(machine_pos, network)
	end

	-- Attach neighbor cables
	for _,connection in ipairs(cables) do
		if connection.network then
			if connection.network.id ~= network.id then
				-- Remove network if position belongs to another network
				-- FIXME: Network requires partial rebuild but avoid doing it here if possible.
				-- This might cause problems when merging two active networks into one
				technic.remove_network(connection.network.id)
				connection.network = nil
			end
		else
			-- There's cable that does not belong to any network, attach whole branch
			technic.add_network_node(connection.pos, network)
			technic.add_network_branch({connection.pos}, network)
		end
	end
end
-- NOTE: Exported for tests but should probably be moved to network.lua
technic.network_node_on_placenode = place_network_node

local function remove_network_node(pos, tier, name)
	-- Get the network and neighbors
	local network, cables, machines = get_neighbors(pos, tier)
	if not network then return end

	if #cables == 1 then
		-- Dead end cable removed, remove it from the network
		technic.remove_network_node(network.id, pos)
		-- Remove neighbor machines from network if cable was removed
		if technic.is_tier_cable(name, tier) then
			for _,machine_pos in ipairs(machines) do
				local net, _, _ = get_neighbors(machine_pos, tier)
				if not net then
					-- Remove machine from network if it does not have other connected cables
					technic.remove_network_node(network.id, machine_pos)
				end
			end
		end
	else
		-- TODO: Check branches around and switching stations for branches:
		--   remove branches that do not have switching station. Switching stations not tracked but could be easily tracked.
		--   remove branches not connected to another branch. Individual branches not tracked, requires simple AI heuristics.
		--   move branches that have switching station to new networks without checking or loading actual nodes in world.
		--   To do all this network must be aware of individual branches and switching stations, might not be worth it...
		-- For now remove whole network and let ABM rebuild it
		technic.remove_network(network.id)
	end
end
-- NOTE: Exported for tests but should probably be moved to network.lua
technic.network_node_on_dignode = remove_network_node

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

local function override_table(target, source)
	if target and source then
		for k,v in pairs(source) do
			target[k] = v
		end
	end
	return target
end

function technic.register_cable(tier, size, description, prefix, override_cable, override_cable_plate)
	prefix = prefix or ""
	override_cable_plate = override_cable_plate or override_cable
	local ltier = string.lower(tier)
	local node_name = "technic:"..ltier..prefix.."_cable"
	cable_tier[node_name] = tier

	local groups = {snappy=2, choppy=2, oddly_breakable_by_hand=2,
			["technic_"..ltier.."_cable"] = 1}

	local node_box = {
		type = "connected",
		fixed          = {-size, -size, -size, size,  size, size},
		connect_top    = {-size, -size, -size, size,  0.5,  size}, -- y+
		connect_bottom = {-size, -0.5,  -size, size,  size, size}, -- y-
		connect_front  = {-size, -size, -0.5,  size,  size, size}, -- z-
		connect_back   = {-size, -size,  size, size,  size, 0.5 }, -- z+
		connect_left   = {-0.5,  -size, -size, size,  size, size}, -- x-
		connect_right  = {-size, -size, -size, 0.5,   size, size}, -- x+
	}

	minetest.register_node(node_name, override_table({
		description = S("%s Cable"):format(tier),
		tiles = {"technic_"..ltier..prefix.."_cable.png"},
		inventory_image = "technic_"..ltier..prefix.."_cable_wield.png",
		wield_image = "technic_"..ltier..prefix.."_cable_wield.png",
		groups = groups,
		sounds = default.node_sound_wood_defaults(),
		drop = node_name,
		paramtype = "light",
		sunlight_propagates = true,
		drawtype = "nodebox",
		node_box = node_box,
		connects_to = {"group:technic_"..ltier.."_cable",
			"group:technic_"..ltier, "group:technic_all_tiers"},
		on_construct = function(pos) place_network_node(pos, tier, node_name) end,
		on_destruct = function(pos) remove_network_node(pos, tier, node_name) end,
	}, override_cable))

	local xyz = {
		["-x"] = 1,
		["-y"] = 2,
		["-z"] = 3,
		["x"] = 4,
		["y"] = 5,
		["z"] = 6,
	}
	local notconnects = {
		[1] = "left",
		[2] = "bottom",
		[3] = "front",
		[4] = "right",
		[5] = "top",
		[6] = "back",
	}
	local function s(p)
		if p:find("-") then
			return p:sub(2)
		else
			return "-"..p
		end
	end
	-- TODO: Does this really need 6 different nodes? Use single node for cable plate if possible.
	for p, i in pairs(xyz) do
		local def = {
			description = S("%s Cable Plate"):format(tier),
			tiles = {"technic_"..ltier..prefix.."_cable.png"},
			groups = table.copy(groups),
			sounds = default.node_sound_wood_defaults(),
			drop = node_name .. "_plate_1",
			paramtype = "light",
			sunlight_propagates = true,
			drawtype = "nodebox",
			node_box = table.copy(node_box),
			connects_to = {"group:technic_"..ltier.."_cable",
				"group:technic_"..ltier, "group:technic_all_tiers"},
			on_construct = function(pos) place_network_node(pos, tier, node_name.."_plate_"..i) end,
			on_destruct = function(pos) remove_network_node(pos, tier, node_name.."_plate_"..i) end,
		}
		def.node_box.fixed = {
			{-size, -size, -size, size, size, size},
			{-0.5, -0.5, -0.5, 0.5, 0.5, 0.5}
		}
		def.node_box.fixed[1][xyz[p]] = 7/16 * (i-3.5)/math.abs(i-3.5)
		def.node_box.fixed[2][xyz[s(p)]] = 3/8 * (i-3.5)/math.abs(i-3.5)
		def.node_box["connect_"..notconnects[i]] = nil
		if i == 1 then
			def.on_place = function(itemstack, placer, pointed_thing)
				local pointed_thing_diff = vector.subtract(pointed_thing.above, pointed_thing.under)
				local num = 1
				local changed
				for k, v in pairs(pointed_thing_diff) do
					if v ~= 0 then
						changed = k
						num = xyz[s(tostring(v):sub(-2, -2)..k)]
						break
					end
				end
				local crtl = placer:get_player_control()
				if (crtl.aux1 or crtl.sneak) and not (crtl.aux1 and crtl.sneak) and changed then
					local fine_pointed = minetest.pointed_thing_to_face_pos(placer, pointed_thing)
					fine_pointed = vector.subtract(fine_pointed, pointed_thing.above)
					fine_pointed[changed] = nil
					local ps = {}
					for p, _ in pairs(fine_pointed) do
						ps[#ps+1] = p
					end
					local bigger = (math.abs(fine_pointed[ps[1]]) > math.abs(fine_pointed[ps[2]]) and ps[1]) or ps[2]
					if math.abs(fine_pointed[bigger]) < 0.3 then
						num = num + 3
						num = (num <= 6 and num) or num - 6
					else
						num = xyz[((fine_pointed[bigger] < 0 and "-") or "") .. bigger]
					end
				end
				if num == nil then num = 1 end
				return item_place_override_node(
					itemstack, placer, pointed_thing,
					{name = node_name.."_plate_"..num}
				)
			end
		else
			def.groups.not_in_creative_inventory = 1
		end
		def.on_rotate = function(pos, node, user, mode, new_param2)
			local dir = 0
			if mode == screwdriver.ROTATE_FACE then -- left-click
				dir = 1
			elseif mode == screwdriver.ROTATE_AXIS then -- right-click
				dir = -1
			end
			local num = tonumber(node.name:sub(-1))
			num = num + dir
			num = (num >= 1 and num) or num + 6
			num = (num <= 6 and num) or num - 6
			minetest.swap_node(pos, {name = node_name.."_plate_"..num})
		end
		minetest.register_node(node_name.."_plate_"..i, override_table(def, override_cable_plate))
		cable_tier[node_name.."_plate_"..i] = tier
	end

	minetest.register_craft({
		output = node_name.."_plate_1 5",
		recipe = {
			{""       , ""       , node_name},
			{node_name, node_name, node_name},
			{""       , ""       , node_name},
		}
	})

	minetest.register_craft({
		output = node_name,
		recipe = {
			{node_name.."_plate_1"},
		}
	})
end

-- TODO: Instead of universal callback either require machines to call place_network_node or patch all nodedefs
minetest.register_on_placenode(function(pos, node)
	for tier, machine_list in pairs(technic.machines) do
		if machine_list[node.name] ~= nil then
			return place_network_node(pos, tier, node.name)
		end
	end
end)

-- TODO: Instead of universal callback either require machines to call remove_network_node or patch all nodedefs
minetest.register_on_dignode(function(pos, node)
	for tier, machine_list in pairs(technic.machines) do
		if machine_list[node.name] ~= nil then
			return remove_network_node(pos, tier, node.name)
		end
	end
end)
