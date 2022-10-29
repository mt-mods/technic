local constant_digit_count = technic.config:get("constant_digit_count")

-- converts a number to a readable string with SI prefix, e.g. 10000 → "10 k",
-- 15 → "15 ", 0.1501 → "150.1 m"
-- a non-breaking space (U+a0) instead of a usual one is put after number
-- The precision is 4 digits
local prefixes = {[-8] = "y", [-7] = "z", [-6] = "a", [-5] = "f", [-4] = "p",
	[-3] = "n", [-2] = "µ", [-1] = "m", [0] = "",  [1] = "k", [2] = "M",
	[3] = "G", [4] = "T", [5] = "P", [6] = "E", [7] = "Z", [8] = "Y"}
function technic.pretty_num(num)
	-- the small number added is due to floating point inaccuracy
	local b = math.floor(math.log10(math.abs(num)) +0.000001)
	local pref_i
	if b ~= 0 then
		-- b is decremented by 1 to avoid a single digit with many decimals,
		-- e.g. instead of 1.021 MEU, 1021 kEU is shown
		pref_i = math.floor((b - 1) / 3)
	else
		-- as special case, avoid showing e.g. 1100 mEU instead of 1.1 EU
		pref_i = 0
	end
	if not prefixes[pref_i] then
		-- This happens for 0, nan, inf, very big values, etc.
		if num == 0 then
			-- handle 0 explicilty to avoid showing "-0"
			if not constant_digit_count then
				return "0 "
			end
			-- gives 0.000
			return string.format("%.3f ", 0)
		end
		return string.format("%.4g ", num)
	end

	num = num * 10 ^ (-3 * pref_i)
	if constant_digit_count then
		local comma_digits_cnt = 3 - (b - 3 * pref_i)
		return string.format("%." .. comma_digits_cnt .. "f %s",
			num, prefixes[pref_i])
	end
	return string.format("%.4g %s", num, prefixes[pref_i])
end

-- some unittests
assert(technic.pretty_num(-0) == "0 ")
assert(technic.pretty_num(0) == "0 ")
assert(technic.pretty_num(1234) == "1234 ")
assert(technic.pretty_num(123456789) == "123.5 M")

-- used to display power values
function technic.EU_string(num)
	return technic.pretty_num(num) .. "EU"
end

--- Same as minetest.swap_node, but only changes name
-- and doesn't re-set if already set.
function technic.swap_node(pos, name)
	local node = minetest.get_node(pos)
	if node.name ~= name then
		node.name = name
		minetest.swap_node(pos, node)
	end
end

function technic.set_RE_charge(stack, charge)
	local wear_factor = stack:get_definition().technic_wear_factor
	if wear_factor then
		local wear = math.floor(charge * wear_factor + 0.5)
		stack:set_wear(wear > 0 and 65536 - wear or 0)
	else
		minetest.log("error", "technic.set_RE_charge item not registered as power tool: "..stack:get_name())
	end
end

function technic.get_RE_charge(stack)
	local def = stack:get_definition()
	if def.technic_wear_factor then
		local wear = stack:get_wear()
		return (wear > 0 and math.floor((65536 - wear) / def.technic_wear_factor + 0.5) or 0), def.technic_max_charge
	end
	minetest.log("warning", "technic.get_RE_charge item not registered as power tool: "..stack:get_name())
	return 0, 0
end

function technic.use_RE_charge(stack, amount)
	if technic.creative_mode or amount <= 0 then
		-- Do not check charge in creative mode or when trying to use zero amount
		return true
	end
	local charge = technic.get_RE_charge(stack)
	if charge < amount then
		-- Not enough energy available
		return false
	end
	-- Ensure that at least single point is always added to wear when using tool
	local wear_factor = stack:get_definition().technic_wear_factor
	local wear = stack:get_wear()
	wear = math.max(math.floor(wear + 1.5), math.floor(amount * wear_factor + wear + 0.5))
	stack:set_wear(wear > 65535 and 0 or wear)
	-- Charge used successfully
	return true
end

-- If the node is loaded, returns it. If it isn't loaded, load it.
function technic.get_or_load_node(pos)
	local node = minetest.get_node_or_nil(pos)
	if node then return node end
	minetest.load_area(pos)
	return minetest.get_node(pos)
end

technic.tube_inject_item = pipeworks.tube_inject_item or function(pos, start_pos, velocity, item)
	local tubed = pipeworks.tube_item(vector.new(pos), item)
	tubed:get_luaentity().start_pos = vector.new(start_pos)
	tubed:set_velocity(velocity)
	tubed:set_acceleration(vector.new(0, 0, 0))
end

--- Iterates over the node positions along the specified ray.
-- The returned positions will not include the starting position.
function technic.trace_node_ray(pos, dir, range)
	local x_step = dir.x > 0 and 1 or -1
	local y_step = dir.y > 0 and 1 or -1
	local z_step = dir.z > 0 and 1 or -1

	local i = 1
	return function(p)
		-- Approximation of where we should be if we weren't rounding
		-- to nodes.  This moves forward a bit faster then we do.
		-- A correction is done below.
		local real_x = pos.x + (dir.x * i)
		local real_y = pos.y + (dir.y * i)
		local real_z = pos.z + (dir.z * i)

		-- How far off we've gotten from where we should be.
		local dx = math.abs(real_x - p.x)
		local dy = math.abs(real_y - p.y)
		local dz = math.abs(real_z - p.z)

		-- If the real position moves ahead too fast, stop it so we
		-- can catch up.  If it gets too far ahead it will smooth
		-- out our movement too much and we won't turn fast enough.
		if dx + dy + dz < 2 then
			i = i + 1
		end

		-- Step in whichever direction we're most off course in.
		if dx > dy then
			if dx > dz then
				p.x = p.x + x_step
			else
				p.z = p.z + z_step
			end
		elseif dy > dz then
			p.y = p.y + y_step
		else
			p.z = p.z + z_step
		end
		if vector.distance(pos, p) > range then
			return nil
		end
		return p
	end, vector.round(pos)
end

--- Like trace_node_ray, but includes extra positions close to the ray.
function technic.trace_node_ray_fat(pos, dir, range)
	local x_step = dir.x > 0 and 1 or -1
	local y_step = dir.y > 0 and 1 or -1
	local z_step = dir.z > 0 and 1 or -1

	local next_poses = {}

	local i = 1
	return function(p)
		local ni, np = next(next_poses)
		if np then
			next_poses[ni] = nil
			return np
		end

		-- Approximation of where we should be if we weren't rounding
		-- to nodes.  This moves forward a bit faster then we do.
		-- A correction is done below.
		local real_x = pos.x + (dir.x * i)
		local real_y = pos.y + (dir.y * i)
		local real_z = pos.z + (dir.z * i)

		-- How far off we've gotten from where we should be.
		local dx = math.abs(real_x - p.x)
		local dy = math.abs(real_y - p.y)
		local dz = math.abs(real_z - p.z)

		-- If the real position moves ahead too fast, stop it so we
		-- can catch up.  If it gets too far ahead it will smooth
		-- out our movement too much and we won't turn fast enough.
		if dx + dy + dz < 2 then
			i = i + 1
		end

		-- Step in whichever direction we're most off course in.
		local sx, sy, sz  -- Whether we've already stepped along each axis
		if dx > dy then
			if dx > dz then
				sx = true
				p.x = p.x + x_step
			else
				sz = true
				p.z = p.z + z_step
			end
		elseif dy > dz then
			sy = true
			p.y = p.y + y_step
		else
			sz = true
			p.z = p.z + z_step
		end

		if vector.distance(pos, p) > range then
			return nil
		end

		-- Add other positions that we're significantly off on.
		-- We can just use fixed integer keys here because the
		-- table will be completely cleared before we reach this
		-- code block again.
		local dlen = math.sqrt(dx*dx + dy*dy + dz*dz)
		-- Normalized axis deltas
		local dxn, dyn, dzn = dx / dlen, dy / dlen, dz / dlen
		if not sx and dxn > 0.5 then
			next_poses[1] = vector.new(p.x + x_step, p.y, p.z)
		end
		if not sy and dyn > 0.5 then
			next_poses[2] = vector.new(p.x, p.y + y_step, p.z)
		end
		if not sz and dzn > 0.5 then
			next_poses[3] = vector.new(p.x, p.y, p.z + z_step)
		end

		return p
	end, vector.round(pos)
end

function technic.insert_object_unique_stack(pos, node, incoming_stack, direction)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	local incoming_name = incoming_stack:get_name()
	local stack_index = nil
	for inv_index, inv_stack in pairs(inv:get_list("src")) do
		if inv_stack:get_name() == incoming_name then
			stack_index = inv_index
			break
		end
	end
	if stack_index == nil then
		return inv:add_item("src", incoming_stack)
	end
	local present_stack = inv:get_stack("src", stack_index)
	local leftover = present_stack:add_item(incoming_stack)
	inv:set_stack("src", stack_index, present_stack)
	return leftover
end

function technic.can_insert_unique_stack(pos, node, incoming_stack, direction)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	local incoming_name = incoming_stack:get_name()
	if meta:get_int("splitstacks") == 0 then
		-- avoid looping second time with inv:contains_item("src", incoming_stack)
		for _, inv_stack in pairs(inv:get_list("src")) do
			if inv_stack:get_name() == incoming_name then
				return inv_stack:item_fits(incoming_stack)
			end
		end
	end
	return technic.default_can_insert(pos, node, incoming_stack, direction)
end
