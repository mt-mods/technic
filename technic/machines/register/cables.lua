
local cable_tier = {}

function technic.is_tier_cable(name, tier)
	return cable_tier[name] == tier
end

function technic.get_cable_tier(name)
	return cable_tier[name]
end

local function match_cable_tier_filter(name, tiers)
	-- Helper to check for set of cable tiers
	if tiers then
		for _, tier in ipairs(tiers) do if cable_tier[name] == tier then return true end end
		return false
	end
	return cable_tier[name] ~= nil
end

local function get_neighbors(pos, tiers)
	-- TODO: Move this to network.lua
	local tier_machines = tiers and technic.machines[tiers[1]]
	local is_cable = match_cable_tier_filter(minetest.get_node(pos).name, tiers)
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
		if tier_machines and tier_machines[name] then
			table.insert(machines, connected_pos)
		elseif match_cable_tier_filter(name, tiers) then
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

local function place_network_node(pos, tiers, name)
	-- Get connections and primary network if there's any
	local network, cables, machines = get_neighbors(pos, tiers)
	if not network then
		-- We're evidently not on a network, nothing to add ourselves to
		return
	end

	-- Attach to primary network, this must be done before building branches from this position
	technic.add_network_node(pos, network)
	if not match_cable_tier_filter(name, tiers) then
		if technic.machines[tiers[1]][name] == technic.producer_receiver then
			-- FIXME: Multi tier machine like supply converter should also attach to other networks around pos.
			--      Preferably also with connection rules defined for machine.
			--      nodedef.connect_sides could be used to generate these rules.
			--		For now, assume that all multi network machines belong to technic.producer_receiver group:
			-- Get cables and networks around PR_RE machine
			local _, machine_cables, _ = get_neighbors(pos)
			for _,connection in ipairs(machine_cables) do
				if connection.network and connection.network.id ~= network.id then
					-- Attach PR_RE machine to secondary networks (last added is primary until above note is resolved)
					technic.add_network_node(pos, connection.network)
				end
			end
		else
			-- Check connected cables for foreign networks, overload if machine was connected to multiple networks
			for _, connection in ipairs(cables) do
				if connection.network and connection.network.id ~= network.id then
					technic.overload_network(connection.network.id)
					technic.overload_network(network.id)
				end
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
				technic.remove_network(network.id)
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

local function remove_network_node(pos, tiers, name)
	-- Get the network and neighbors
	local network, cables, machines = get_neighbors(pos, tiers)
	if not network then return end

	if not match_cable_tier_filter(name, tiers) then
		-- Machine removed, skip cable checks to prevent unnecessary network cleanups
		for _,connection in ipairs(cables) do
			if connection.network then
				-- Remove machine from all networks around it
				technic.remove_network_node(connection.network.id, pos)
			end
		end
		return
	end

	if #cables == 1 then
		-- Dead end cable removed, remove it from the network
		technic.remove_network_node(network.id, pos)
		-- Remove neighbor machines from network if cable was removed
		if match_cable_tier_filter(name, tiers) then
			for _,machine_pos in ipairs(machines) do
				local net, _, _ = get_neighbors(machine_pos, tiers)
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

local function cable_defaults(nodename, data)
	assert(data.tier, "Technic cable registration requires `tier` field")
	assert(data.size, "Technic cable registration requires `size` field")
	assert(data.description, "Technic cable registration requires `description` field")

	local def = table.copy(data)
	local tier = def.tier
	local ltier = string.lower(tier)
	local size = def.size

	def.connects_to = def.connects_to or {
		"group:technic_"..ltier.."_cable",
		"group:technic_"..ltier,
		"group:technic_all_tiers"
	}
	def.groups = def.groups or {
		snappy = 2,
		choppy = 2,
		oddly_breakable_by_hand = 2,
		["technic_"..ltier.."_cable"] = 1
	}
	def.drop = def.drop or nodename
	def.sounds = def.sounds or default.node_sound_wood_defaults()
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
				if (crtl.aux1 or crtl.sneak) and not (crtl.aux1 and crtl.sneak) then
					local fine_pointed = minetest.pointed_thing_to_face_pos(placer, pointed_thing)
					fine_pointed = vector.subtract(fine_pointed, pointed_thing.above)
					fine_pointed[xyz[index < 0 and -index or index]] = nil
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
				return item_place_override_node(itemstack, placer, pointed_thing, {name = nodename.."_"..(num or 1)})
			end
		else
			def.groups.not_in_creative_inventory = 1
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
	minetest.register_node(nodename, def)
	cable_tier[nodename] = def.tier
end

minetest.register_on_mods_loaded(function()
	-- FIXME: Move this to register.lua or somewhere else where register_on_mods_loaded is not required.
	--        Possible better option would be to inject these when machine is registered in register.lua.
	for name, tiers in pairs(technic.machine_tiers) do
		local nodedef = minetest.registered_nodes[name]
		local on_construct = type(nodedef.on_construct) == "function" and nodedef.on_construct
		local on_destruct = type(nodedef.on_destruct) == "function" and nodedef.on_destruct
		minetest.override_item(name,{
			on_construct = on_construct
				and function(pos) on_construct(pos) place_network_node(pos, tiers, name) end
				or  function(pos) place_network_node(pos, tiers, name) end,
			on_destruct = on_destruct
				and function(pos) on_destruct(pos) remove_network_node(pos, tiers, name) end
				or  function(pos) remove_network_node(pos, tiers, name) end,
		})
	end
end)
