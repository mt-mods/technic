
-- Use this fixture when loading full Technic mod.
-- Loads all required modules and fixtures for technic

-- Load modules required by tests
mineunit("core")
mineunit("player")
mineunit("protection")
mineunit("common/after")
mineunit("server")
mineunit("voxelmanip")
if mineunit:config("engine_version") ~= "mineunit" then
	mineunit("game/voxelarea")
end

-- Load fixtures required by tests
fixture("default")
fixture("mesecons")
fixture("digilines")
fixture("pipeworks")
fixture("technic_worldgen")

spec_utility = {}

-- Calculate expected amount of items produced by base machines within completed network cycles
function spec_utility.base_machine_output_calculator(RUN_CYCLES)
	return function (machine_speed, recipe_time, output_amount)
		-- Total amount not necessarily divisible by per cycle output
		local partial = math.floor(RUN_CYCLES * (output_amount * machine_speed / recipe_time))
		-- Maximum amount divisible by per cycle output (amount clamped to full cycles)
		return math.floor(partial / output_amount) * output_amount
	end
end

-- Helper function to execute multiple globalsteps
function spec_utility.run_globalsteps(times, dtime)
	-- By default, run once with dtime = 1 second instead of every 0.1 seconds
	for i=1, times or 1 do
		mineunit:execute_globalstep(dtime or 1)
	end
end

-- Helper function to place itemstack into machine inventory, default listname = src
function spec_utility.place_itemstack(pos, itemstack, listname, index)
	local meta = core.get_meta(pos)
	local inv = meta:get_inventory()
	if not inv:room_for_item(listname or "src", itemstack) then
		inv:set_stack(listname or "src", index or 1, itemstack)
	elseif index then
		inv:set_stack(listname or "src", index, itemstack)
	else
		inv:add_item(listname or "src", itemstack)
	end
end

-- Get itemstack in inventory for inspection without removing it, default listname = dst
function spec_utility.get_itemstack(pos, listname, index)
	local meta = core.get_meta(pos)
	local inv = meta:get_inventory()
	return inv:get_stack(listname or "dst", index or 1)
end