
local S = technic.getter

function technic.alloy_furnace_insert_object(pos, node, stack, direction)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	local incoming_name = stack:get_name()
	local count_existing_of_incoming_type = 0
	local count_incoming = stack:get_count()
	for _, inv_stack in pairs(inv:get_list("src")) do
		local count = inv_stack:get_count()
		if inv_stack:get_name() == incoming_name then
			count_existing_of_incoming_type = count_existing_of_incoming_type + count
			break
		end
	end
	if 0 == count_existing_of_incoming_type then return inv:add_item("src", stack) end
	local stack_max = stack:get_stack_max()
	local overflow = count_existing_of_incoming_type + count_incoming - stack_max
	if 0 < overflow then
		if meta:get_int("splitstacks") == 0 then return stack end
		local return_stack = stack:peek_item(overflow)
		local add_stack = stack:peek_item(stack_max - count_existing_of_incoming_type)
		inv:add_item("src", add_stack)
		return return_stack
	else
		-- possibly works too: return inv:add_item(......)
		inv:add_item("src", stack)
		return ItemStack(nil)
	end
end

function technic.alloy_furnace_can_insert(pos, node, stack, direction)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	if meta:get_int("splitstacks") == 0 then
		-- reject second stack of item that is already present
		local incoming_name = stack:get_name()
		for _, inv_stack in pairs(inv:get_list("src")) do
			if not inv_stack:is_empty() and inv_stack:get_name() == incoming_name then
				return false
			end
		end
	end

	return technic.default_can_insert(pos, node, stack, direction)
end

function technic.register_alloy_furnace(data)
	data.typename = "alloy"
	data.machine_name = "alloy_furnace"
	data.machine_desc = S("%s Alloy Furnace")

	data.insert_object = technic.alloy_furnace_insert_object
	data.can_insert = technic.alloy_furnace_can_insert

	technic.register_base_machine(data)
end
