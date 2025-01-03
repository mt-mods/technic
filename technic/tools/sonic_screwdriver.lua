local sonic_screwdriver_max_charge = 15000

local S = technic.getter
local mat = technic.materials

local screwdriver = screwdriver or nil
if not screwdriver then
	local function nextrange(x, max)
		x = x + 1
		if x > max then
			x = 0
		end
		return x
	end

	-- Simple and hacky rotation script, assumed facedir
	local function simple_rotate(pos, node, mode)
		local rotationPart = node.param2 % 32 -- get first 4 bits
		local preservePart = node.param2 - rotationPart

		local axisdir = math.floor(rotationPart / 4)
		local rotation = rotationPart - axisdir * 4
		if mode == screwdriver.ROTATE_FACE then
			rotationPart = axisdir * 4 + nextrange(rotation, 3)
		elseif mode == screwdriver.ROTATE_AXIS then
			rotationPart = nextrange(axisdir, 5) * 4
		end

		return preservePart + rotationPart
	end

	-- local use only
	screwdriver = {
		ROTATE_FACE = 1,
		ROTATE_AXIS = 2,

		rotate = setmetatable({}, {
			__index = function ()
				return simple_rotate
			end
		})
	}
end

-- Handles rotation
local function screwdriver_handler(itemstack, user, pointed_thing, mode)
	if pointed_thing.type ~= "node" then
		return
	end

	if technic.get_RE_charge(itemstack) < 100 then
		return itemstack
	end

	local pos = pointed_thing.under
	local player_name = user and user:get_player_name() or ""

	if minetest.is_protected(pos, player_name) then
		minetest.record_protection_violation(pos, player_name)
		return
	end

	local node = minetest.get_node(pos)
	local ndef = minetest.registered_nodes[node.name]
	if not ndef then
		return itemstack
	end
	-- can we rotate this paramtype2?
	local fn = screwdriver.rotate[ndef.paramtype2]
	if not fn and not ndef.on_rotate then
		return itemstack
	end

	local should_rotate = true
	local new_param2
	if fn then
		new_param2 = fn(pos, node, mode)
		if not new_param2 then
			-- rotation refused
			return itemstack
		end
	else
		new_param2 = node.param2
	end

	-- Node provides a handler, so let the handler decide instead if the node can be rotated
	-- contrary to the default screwdriver, do not check for can_dig, to allow rotating machines with CLU's in them
	-- this is consistent with the previous sonic screwdriver
	if ndef.on_rotate then
		-- Copy pos and node because callback can modify it
		local result = ndef.on_rotate(vector.new(pos),
				{name = node.name, param1 = node.param1, param2 = node.param2},
				user, mode, new_param2)
		if result == false then -- Disallow rotation
			return itemstack
		elseif result == true then
			should_rotate = false
		end
	elseif ndef.on_rotate == false then
		return itemstack
	end

	if should_rotate and new_param2 ~= node.param2 then
		if not technic.use_RE_charge(itemstack, 100) then
			return itemstack
		end
		node.param2 = new_param2
		minetest.swap_node(pos, node)
		minetest.check_for_falling(pos)
		minetest.sound_play("technic_sonic_screwdriver", {pos = pos, gain = 0.5, max_hear_distance = 10}, true)
	end

	return itemstack
end

technic.register_power_tool("technic:sonic_screwdriver", {
	description = S("Sonic Screwdriver (left-click rotates face, right-click rotates axis)"),
	inventory_image = "technic_sonic_screwdriver.png",
	max_charge = sonic_screwdriver_max_charge,
	on_use = function(itemstack, user, pointed_thing)
		return screwdriver_handler(itemstack, user, pointed_thing, screwdriver.ROTATE_FACE)
	end,
	on_place = function(itemstack, user, pointed_thing)
		return screwdriver_handler(itemstack, user, pointed_thing, screwdriver.ROTATE_AXIS)
	end,
})

minetest.register_craft({
	output = "technic:sonic_screwdriver",
	recipe = {
		{"",                         mat.diamond,        ""},
		{"mesecons_materials:fiber", "technic:battery",        "mesecons_materials:fiber"},
		{"mesecons_materials:fiber", mat.mithril_ingot, "mesecons_materials:fiber"}
	}
})
