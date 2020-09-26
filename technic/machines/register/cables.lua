
local S = technic.getter

local cable_tier = {}

function technic.is_tier_cable(name, tier)
	return cable_tier[name] == tier
end

function technic.get_cable_tier(name)
	return cable_tier[name]
end

local function check_connections(pos)
	-- Build a table of all machines
	-- TODO: Move this to network.lua
	-- TODO: Build table for current tier only, we do not want to test other tiers.
	-- Make sure that multi tier machines work (currently supply converter).
	local machines = {}
	for tier,list in pairs(technic.machines) do
		for k,v in pairs(list) do
			machines[k] = v
		end
	end
	local connections = {}
	local positions = {
		{x=pos.x+1, y=pos.y,   z=pos.z},
		{x=pos.x-1, y=pos.y,   z=pos.z},
		{x=pos.x,   y=pos.y+1, z=pos.z},
		{x=pos.x,   y=pos.y-1, z=pos.z},
		{x=pos.x,   y=pos.y,   z=pos.z+1},
		{x=pos.x,   y=pos.y,   z=pos.z-1}}
	for _,connected_pos in pairs(positions) do
		local name = minetest.get_node(connected_pos).name
		if machines[name] or technic.get_cable_tier(name) then
			table.insert(connections,connected_pos)
		end
	end
	return connections
end

local function connect_networks(pos, positions)
	-- TODO: Allow connecting networks:
	-- If neighbor branch does not belong to any network attach it to this network
	-- If neighbor branch belongs to another network check which one has least #all_nodes and rebuild that
	for _,connected_pos in pairs(positions) do
		local net = technic.pos2network(connected_pos)
		if net and technic.networks[net] then
			-- Not a dead end, so the whole network needs to be recalculated
			technic.remove_network(net)
		end
	end
end

local function place_network_node(pos, node)
	local positions = check_connections(pos)
	if #positions < 1 then return end
	local dead_end = #positions == 1

	-- Dead end placed, add it to the network
	-- Get the network
	local network_id = technic.pos2network(positions[1])
	if not network_id then
		-- We're evidently not on a network, nothing to add ourselves to
		return
	end
	local network = technic.networks[network_id]
	local tier = network.tier

	if not dead_end then
		return connect_networks(pos, positions)
	end

	-- Actually add it to the (cached) network
	-- This is similar to check_node_subp
	local pos_hash = minetest.hash_node_position(pos)
	technic.cables[pos_hash] = network_id
	pos.visited = 1
	if technic.is_tier_cable(name, tier) then
		network.all_nodes[pos_hash] = pos
	elseif technic.machines[tier][node.name] then
		if     technic.machines[tier][node.name] == technic.producer then
			table.insert(network.PR_nodes,pos)
		elseif technic.machines[tier][node.name] == technic.receiver then
			table.insert(network.RE_nodes,pos)
		elseif technic.machines[tier][node.name] == technic.producer_receiver then
			table.insert(network.PR_nodes,pos)
			table.insert(network.RE_nodes,pos)
		elseif technic.machines[tier][node.name] == technic.battery then
			table.insert(network.BA_nodes,pos)
		end
	end
end

local function remove_network_node(pos)
	-- Get the network
	local network_id = technic.pos2network(pos)
	if not network_id then
		-- We're evidently not on a network, nothing to add ourselves to
		return
	end

	local positions = check_connections(pos)
	if #positions < 1 then return end
	local dead_end = #positions == 1

	if not dead_end then
		-- TODO: Check branches around and switching stations for branches:
		--   remove branches that do not have switching station.
		--   remove branches not connected to another branch.
		--   do not rebuild networks here, leave that for ABM to reduce unnecessary cache building.
		-- For now remove network like how it was done before:
		technic.remove_network(network_id)
		return
	end

	-- Dead end removed, remove it from the network
	local network = technic.networks[network_id]
	technic.cables[minetest.hash_node_position(pos)] = nil
	-- TODO: Looping over all keys in network is not right way to do this, should fix to use known machine types.
	-- Better to add network function that knows what to remove, something like technic.remove_node(network_id, pos)
	for tblname,table in pairs(network) do
		if type(table) == "table" then
			for machinenum,machine in pairs(table) do
				if machine.x == pos.x
				and machine.y == pos.y
				and machine.z == pos.z then
					table[machinenum] = nil
				end
			end
		end
	end
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
		on_construct = function(pos) place_network_node(pos, node_name) end,
		on_destruct = remove_network_node,
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
			on_construct = function(pos) place_network_node(pos, node_name.."_plate_"..i) end,
			on_destruct = remove_network_node,
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

minetest.register_on_placenode(function(pos, node)
	for tier, machine_list in pairs(technic.machines) do
		if machine_list[node.name] ~= nil then
			return place_network_node(pos, node)
		end
	end
end)

minetest.register_on_dignode(function(pos, node)
	for tier, machine_list in pairs(technic.machines) do
		if machine_list[node.name] ~= nil then
			return remove_network_node(pos)
		end
	end
end)
