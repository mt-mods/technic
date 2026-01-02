local S = technic.getter

local desc = S("Administrative World Anchor")

local function floor_to_nearest(n, precision)
	return math.floor(n / precision) * precision
end

local function compute_forceload_positions(pos, meta)
	local radius = meta:get_int("radius")
	local minpos = vector.offset(pos, -radius, -radius, -radius)
	local maxpos = vector.offset(pos, radius, radius, radius)
	local minbpos = vector.apply(minpos, floor_to_nearest, 16)
	local maxbpos = vector.apply(maxpos, floor_to_nearest, 16)
	local flposes = {}
	for x = minbpos.x, maxbpos.x, 16 do
		for y = minbpos.y, maxbpos.y, 16 do
			for z = minbpos.z, maxbpos.z, 16 do
				table.insert(flposes, vector.new(x, y, z))
			end
		end
	end
	return flposes
end

local function currently_forceloaded_positions(meta)
	local ser = meta:get_string("forceloaded")
	return ser == "" and {} or core.deserialize(ser)
end

local function forceload_off(meta)
	local flposes = currently_forceloaded_positions(meta)
	meta:set_string("forceloaded", "")
	for _, p in ipairs(flposes) do
		core.forceload_free_block(p)
	end
end

local function forceload_on(pos, meta)
	local want_flposes = compute_forceload_positions(pos, meta)
	local have_flposes = {}
	for _, p in ipairs(want_flposes) do
		if core.forceload_block(p) then
			table.insert(have_flposes, p)
		end
	end
	meta:set_string("forceloaded", #have_flposes == 0 and "" or core.serialize(have_flposes))
end

local function set_display(pos, meta)
	meta:set_string("infotext", S(meta:get_int("enabled") ~= 0 and "@1 Enabled" or "@1 Disabled", desc))
	meta:set_string("formspec",
		"size[5,3.5]"..
		"item_image[0,0;1,1;technic:admin_anchor]"..
		"label[1,0;"..desc.."]"..
		"label[0,1;"..S("Owner: @1", meta:get_string("owner")).."]"..
		(meta:get_int("locked") == 0 and
			"button[3,1;2,1;lock;"..S("Unlocked").."]" or
			"button[3,1;2,1;unlock;"..S("Locked").."]")..
		"field[0.25,2.3;1,1;radius;"..S("Radius")..";${radius}]"..
		(meta:get_int("enabled") == 0 and
			"button[3,2;2,1;enable;"..S("Disabled").."]" or
			"button[3,2;2,1;disable;"..S("Enabled").."]")..
		"label[0,3;"..S("Keeping @1/@2 map blocks loaded",
				#currently_forceloaded_positions(meta), #compute_forceload_positions(pos, meta)).."]")
end

core.register_node("technic:admin_anchor", {
	description = desc,
	drawtype = "normal",
	tiles = {"technic_admin_anchor.png"},
	is_ground_content = false,
	groups = {cracky=3, not_in_creative_inventory=1, pickaxey=1},
	_mcl_blast_resistance = 1,
	_mcl_hardness = 0.8,
	sounds = technic.sounds.node_sound_stone_defaults(),
	after_place_node = function (pos, placer)
		local meta = core.get_meta(pos)
		if placer and placer:is_player() then
			meta:set_string("owner", placer:get_player_name())
		end
		set_display(pos, meta)
	end,
	can_dig = function (pos, player)
		local meta = core.get_meta(pos)
		return meta:get_int("locked") == 0 or (player and player:is_player()
				and player:get_player_name() == meta:get_string("owner"))
	end,
	on_destruct = function (pos)
		local meta = core.get_meta(pos)
		forceload_off(meta)
	end,
	on_receive_fields = function (pos, formname, fields, sender)
		local meta = core.get_meta(pos)
		if (meta:get_int("locked") ~= 0 or fields.lock) and
				not (sender and sender:is_player() and
					sender:get_player_name() == meta:get_string("owner")) then
			return
		end
		if fields.unlock then meta:set_int("locked", 0) end
		if fields.lock then meta:set_int("locked", 1) end
		if fields.disable or fields.enable or fields.radius then
			forceload_off(meta)
			if fields.disable then meta:set_int("enabled", 0) end
			if fields.enable then meta:set_int("enabled", 1) end
			if fields.radius and string.find(fields.radius, "^[0-9]+$") and tonumber(fields.radius) < 256 then
				meta:set_int("radius", fields.radius)
			end
			if meta:get_int("enabled") ~= 0 then
				forceload_on(pos, meta)
			end
		end
		set_display(pos, meta)
	end,
	mesecons = {
		effector = {
			action_on = function(pos)
				local meta = core.get_meta(pos)
				meta:set_int("enabled", 1)
				forceload_on(pos, meta)
				set_display(pos, meta)
			end,
			action_off = function(pos)
				local meta = core.get_meta(pos)
				meta:set_int("enabled", 0)
				forceload_off(meta)
				set_display(pos, meta)
			end
		}
	}
})
