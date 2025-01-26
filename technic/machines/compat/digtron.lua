--
-- Compatibility hacks for digtron to work well with new Technic Plus network and power tools
--
-- More information:
-- https://github.com/mt-mods/technic/issues/100
-- https://github.com/mt-mods/technic/issues/233
--
-- Disable some luacheck warnings to allow having original formatting here
-- luacheck: no max line length
-- luacheck: globals digtron

-- Only relevant sections modified, you can directly compare this with upstream function defined in util.lua
local node_inventory_table = {type="node"}
local function tap_batteries(battery_positions, target, test)
	if (battery_positions == nil) then
		return 0
	end

	local current_burned = 0
	-- 1 coal block is 370 PU
	-- 1 coal lump is 40 PU
	-- An RE battery holds 10000 EU of charge
	-- local power_ratio = 100 -- How much charge equals 1 unit of PU from coal
	-- setting Moved to digtron.config.power_ratio

	for k, location in pairs(battery_positions) do
		if current_burned > target then
			break
		end
		node_inventory_table.pos = location.pos
		local inv = minetest.get_inventory(node_inventory_table)
		local invlist = inv:get_list("batteries")

		if (invlist == nil) then -- This check shouldn't be needed, it's yet another guard against https://github.com/minetest/minetest/issues/8067
			break
		end

		for i, itemstack in pairs(invlist) do
			local charge = technic.get_charge(itemstack)
			local power_available = math.floor(charge / digtron.config.power_ratio)
			if power_available ~= 0 then
				local actual_burned = power_available -- we just take all we have from the battery, since they aren't stackable
				-- don't bother recording the items if we're just testing, nothing is actually being removed.
				if test ~= true then
					-- since we are taking everything, the wear and charge can both be set to 0
					technic.set_charge(itemstack, 0)
				end
				current_burned = current_burned + actual_burned
			end

			if current_burned > target then
				break
			end
		end

		if test ~= true then
			-- only update the list if we're doing this for real.
			inv:set_list("batteries", invlist)
		end
	end
	return current_burned
end

local function power_connector_compat()
	local digtron_technic_run = minetest.registered_nodes["digtron:power_connector"].technic_run
	minetest.override_item("digtron:power_connector",{
		technic_run = function(pos, node)
			local network_id = technic.pos2network(pos)
			local sw_pos = network_id and technic.network2sw_pos(network_id)
			local meta = minetest.get_meta(pos)
			meta:set_string("HV_network", sw_pos and minetest.pos_to_string(sw_pos) or "")
			return digtron_technic_run(pos, node)
		end,
		technic_on_disable = function(pos, node)
			local meta = minetest.get_meta(pos)
			meta:set_string("HV_network", "")
			meta:set_string("HV_EU_input", "")
		end,
	})
end

local function battery_holder_compat()
	-- Override battery holder
	local tube = minetest.registered_nodes["digtron:battery_holder"].tube
	tube.can_insert = function(pos, node, stack, direction)
		if technic.get_charge(stack) > 0 then
			local inv = minetest.get_meta(pos):get_inventory()
			return inv:room_for_item("batteries", stack)
		end
		return false
	end
	minetest.override_item("digtron:battery_holder",{
		allow_metadata_inventory_put = function(pos, listname, index, stack, player)
			return (listname == "batteries" and technic.get_charge(stack) > 0) and stack:get_count() or 0
		end,
		tube = tube,
	})
	-- Override digtron.tap_batteries
	digtron.tap_batteries = tap_batteries
end

minetest.register_on_mods_loaded(function()
	if minetest.registered_nodes["digtron:power_connector"] then
		power_connector_compat()
	end
	if minetest.registered_nodes["digtron:battery_holder"] then
		battery_holder_compat()
	end
end)
