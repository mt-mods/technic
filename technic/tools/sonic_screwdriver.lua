local sonic_screwdriver_max_charge = 15000

local S = technic.getter

-- screwdriver handler code reused from minetest/minetest_game screwdriver @a9ac480
local ROTATE_FACE = 1
local ROTATE_AXIS = 2

local function nextrange(x, max)
	x = x + 1
	if x > max then
		x = 0
	end
	return x
end

-- Handles rotation
local function screwdriver_handler(itemstack, user, pointed_thing, mode)
	if pointed_thing.type ~= "node" then
		return
	end

	local pos = pointed_thing.under

	if minetest.is_protected(pos, user:get_player_name()) then
		minetest.record_protection_violation(pos, user:get_player_name())
		return
	end

	local node = minetest.get_node(pos)
	local ndef = minetest.registered_nodes[node.name]
	if not ndef or ndef.paramtype2 ~= "facedir" or
			(ndef.drawtype == "nodebox" and
			ndef.node_box.type ~= "fixed") or
			node.param2 == nil then
		return
	end

	-- contrary to the default screwdriver, do not check for can_dig, to allow rotating machines with CLU's in them
	-- this is consistent with the previous sonic screwdriver

	if not technic.use_RE_charge(itemstack, 100) then
		return
	end

	minetest.sound_play("technic_sonic_screwdriver", {pos = pos, gain = 0.3, max_hear_distance = 10}, true)

	-- Set param2
	local rotationPart = node.param2 % 32 -- get first 4 bits
	local preservePart = node.param2 - rotationPart

	local axisdir = math.floor(rotationPart / 4)
	local rotation = rotationPart - axisdir * 4
	if mode == ROTATE_FACE then
		rotationPart = axisdir * 4 + nextrange(rotation, 3)
	elseif mode == ROTATE_AXIS then
		rotationPart = nextrange(axisdir, 5) * 4
	end

	node.param2 = preservePart + rotationPart
	minetest.swap_node(pos, node)

	return itemstack
end

technic.register_power_tool("technic:sonic_screwdriver", {
	description = S("Sonic Screwdriver (left-click rotates face, right-click rotates axis)"),
	inventory_image = "technic_sonic_screwdriver.png",
	max_charge = sonic_screwdriver_max_charge,
	on_use = function(itemstack, user, pointed_thing)
		return screwdriver_handler(itemstack, user, pointed_thing, ROTATE_FACE)
	end,
	on_place = function(itemstack, user, pointed_thing)
		return screwdriver_handler(itemstack, user, pointed_thing, ROTATE_AXIS)
	end,
})

minetest.register_craft({
	output = "technic:sonic_screwdriver",
	recipe = {
		{"",                         "default:diamond",        ""},
		{"mesecons_materials:fiber", "technic:battery",        "mesecons_materials:fiber"},
		{"mesecons_materials:fiber", "moreores:mithril_ingot", "mesecons_materials:fiber"}
	}
})
