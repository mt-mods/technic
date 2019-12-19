
local S = technic.getter

technic.alloy_furnace_insert_object = function(pos, node, stack, direction)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	local incomming_name = stack:get_name()
	local count_total = 0
	local count_existing_of_incomming_type = 0
	local count_incomming = stack:get_count()
	for _, inv_stack in pairs(inv:get_list("src")) do
		local count = inv_stack:get_count()
		count_total = count_total + count
		if inv_stack:get_name() == incomming_name then
			count_existing_of_incomming_type = count_existing_of_incomming_type + count
		end
	end
	if 0 == count_existing_of_incomming_type then return inv:add_item("src", stack) end
	local stack_max = stack:get_stack_max()
	local overflow = count_existing_of_incomming_type + count_incomming - stack_max
	if 0 < overflow then
		local return_stack = stack:peek_item(overflow)
		local add_stack = stack:peek_item(stack_max - count_existing_of_incomming_type)
		inv:add_item("src", add_stack)
		return return_stack
	else
		-- possibly works too: return inv:add_item(......)
		inv:add_item("src", stack)
		return ItemStack(nil)
	end
end

technic.alloy_furnace_can_insert = function(pos, node, stack, direction)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	if meta:get_int("splitstacks") == 1 then
		stack = stack:peek_item(1)
	end

	-- reject second stack of item that is already present
	local incomming_name = stack:get_name()
	for _,inv_stack in pairs(inv:get_list("src")) do
		if not inv_stack:is_empty() and inv_stack:get_name() == incomming_name then
			return inv_stack:item_fits(stack)
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
