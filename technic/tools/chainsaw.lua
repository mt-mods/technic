-- Configuration

local chainsaw_max_charge = 30000 -- Maximum charge of the saw
-- Gives 2500 nodes on a single charge (about 50 complete normal trees)
local chainsaw_charge_per_node = 12
  
local chainsaw_leaves = true -- Cut down tree leaves.
-- Leaf decay may cause slowness on large trees if this is disabled.

local chainsaw_vines = true -- Cut down vines

local timber_nodenames = {} -- Cuttable nodes


-- Support for nodes not in any supported node groups (tree, leaves, leafdecay, leafdecay_drop)

timber_nodenames["default:papyrus"] = true
timber_nodenames["default:cactus"] = true
timber_nodenames["default:bush_stem"] = true
timber_nodenames["default:acacia_bush_stem"] = true
timber_nodenames["default:pine_bush_stem"] = true

if minetest.get_modpath("growing_trees") then
	timber_nodenames["growing_trees:branch_sprout"] = true
	if chainsaw_leaves then
		timber_nodenames["growing_trees:leaves"] = true
	end
end

if minetest.get_modpath("snow") then
	if chainsaw_leaves then
		timber_nodenames["snow:needles"] = true
		timber_nodenames["snow:needles_decorated"] = true
		timber_nodenames["snow:star"] = true
	end
end

if minetest.get_modpath("trunks") then
	if chainsaw_leaves then
		timber_nodenames["trunks:moss"] = true
		timber_nodenames["trunks:moss_fungus"] = true
		timber_nodenames["trunks:treeroot"] = true
	end
end


local S = technic.getter

technic.register_power_tool("technic:chainsaw", chainsaw_max_charge)

-- Table for saving what was sawed down
local produced = {}

-- Save the items sawed down so that we can drop them in a nice single stack
local function handle_drops(drops)
	for _, item in ipairs(drops) do
		local stack = ItemStack(item)
		local name = stack:get_name()
		local p = produced[name]
		if not p then
			produced[name] = stack
		else
			p:set_count(p:get_count() + stack:get_count())
		end
	end
end

--- Iterator over positions to try to saw around a sawed node.
-- This returns positions in a 3x1x3 area around the position, plus the
-- position above it.  This does not return the bottom position to prevent
-- the chainsaw from cutting down nodes below the cutting position.
-- @param pos Sawing position.
local function iterSawTries(pos)
	-- Copy position to prevent mangling it
	local pos = vector.new(pos)
	local i = 0

	return function()
		i = i + 1
		-- Given a (top view) area like so (where 5 is the starting position):
		-- X -->
		-- Z 123
		-- | 456
		-- V 789
		-- This will return positions 1, 4, 7, 2, 8 (skip 5), 3, 6, 9,
		-- and the position above 5.
		if i == 1 then
			-- Move to starting position
			pos.x = pos.x - 1
			pos.z = pos.z - 1
		elseif i == 4 or i == 7 then
			-- Move to next X and back to start of Z when we reach
			-- the end of a Z line.
			pos.x = pos.x + 1
			pos.z = pos.z - 2
		elseif i == 5 then
			-- Skip the middle position (we've already run on it)
			-- and double-increment the counter.
			pos.z = pos.z + 2
			i = i + 1
		elseif i <= 9 then
			-- Go to next Z.
			pos.z = pos.z + 1
		elseif i == 10 then
			-- Move back to center and up.
			-- The Y+ position must be last so that we don't dig
			-- straight upward and not come down (since the Y-
			-- position isn't checked).
			pos.x = pos.x - 1
			pos.z = pos.z - 1
			pos.y = pos.y + 1
		else
			return nil
		end
		return pos
	end
end

-- This function does all the hard work. Recursively we dig the node at hand
-- if it is in the table and then search the surroundings for more stuff to dig.
local function recursive_dig(pos, remaining_charge)
	if remaining_charge < chainsaw_charge_per_node then
		return remaining_charge
	end
	local node = minetest.get_node(pos)

	if not timber_nodenames[node.name] then
		return remaining_charge
	end

	-- Wood found - cut it
	handle_drops(minetest.get_node_drops(node.name, ""))
	minetest.remove_node(pos)
	remaining_charge = remaining_charge - chainsaw_charge_per_node
	
	-- Check for snow on pine trees, etc
	minetest.check_for_falling(pos)

	-- Check surroundings and run recursively if any charge left
	for npos in iterSawTries(pos) do
		if remaining_charge < chainsaw_charge_per_node then
			break
		end
		if timber_nodenames[minetest.get_node(npos).name] then
			remaining_charge = recursive_dig(npos, remaining_charge)
		end
	end
	return remaining_charge
end

-- Function to randomize positions for new node drops
local function get_drop_pos(pos)
	local drop_pos = {}

	for i = 0, 8 do
		-- Randomize position for a new drop
		drop_pos.x = pos.x + math.random(-3, 3)
		drop_pos.y = pos.y - 1
		drop_pos.z = pos.z + math.random(-3, 3)

		-- Move the randomized position upwards until
		-- the node is air or unloaded.
		for y = drop_pos.y, drop_pos.y + 5 do
			drop_pos.y = y
			local node = minetest.get_node_or_nil(drop_pos)

			if not node then
				-- If the node is not loaded yet simply drop
				-- the item at the original digging position.
				return pos
			elseif node.name == "air" then
				-- Add variation to the entity drop position,
				-- but don't let drops get too close to the edge
				drop_pos.x = drop_pos.x + (math.random() * 0.8) - 0.5
				drop_pos.z = drop_pos.z + (math.random() * 0.8) - 0.5
				return drop_pos
			end
		end
	end

	-- Return the original position if this takes too long
	return pos
end

-- Chainsaw entry point
local function chainsaw_dig(pos, current_charge)
	-- Start sawing things down
	local remaining_charge = recursive_dig(pos, current_charge)
	minetest.sound_play("chainsaw", {pos = pos, gain = 1.0,
			max_hear_distance = 10})

	-- Now drop items for the player
	for name, stack in pairs(produced) do
		-- Drop stacks of stack max or less
		local count, max = stack:get_count(), stack:get_stack_max()
		stack:set_count(max)
		while count > max do
			minetest.add_item(get_drop_pos(pos), stack)
			count = count - max
		end
		stack:set_count(count)
		minetest.add_item(get_drop_pos(pos), stack)
	end

	-- Clean up
	produced = {}

	return remaining_charge
end


minetest.register_tool("technic:chainsaw", {
	description = S("Chainsaw"),
	inventory_image = "technic_chainsaw.png",
	stack_max = 1,
	wear_represents = "technic_RE_charge",
	on_refill = technic.refill_RE_charge,
	on_use = function(itemstack, user, pointed_thing)
		if pointed_thing.type ~= "node" then
			return itemstack
		end

		local meta = minetest.deserialize(itemstack:get_metadata())
		if not meta or not meta.charge or
				meta.charge < chainsaw_charge_per_node then
			return
		end

		local name = user:get_player_name()
		if minetest.is_protected(pointed_thing.under, name) then
			minetest.record_protection_violation(pointed_thing.under, name)
			return
		end

		-- Send current charge to digging function so that the
		-- chainsaw will stop after digging a number of nodes
		meta.charge = chainsaw_dig(pointed_thing.under, meta.charge)
		if not technic.creative_mode then
			technic.set_RE_wear(itemstack, meta.charge, chainsaw_max_charge)
			itemstack:set_metadata(minetest.serialize(meta))
		end
		return itemstack
	end,
})

local mesecons_button = minetest.get_modpath("mesecons_button")
local trigger = mesecons_button and "mesecons_button:button_off" or "default:mese_crystal_fragment"

minetest.register_craft({
	output = "technic:chainsaw",
	recipe = {
		{"technic:stainless_steel_ingot", trigger,                      "technic:battery"},
		{"basic_materials:copper_wire",      "basic_materials:motor",              "technic:battery"},
		{"",                              "",                           "technic:stainless_steel_ingot"},
	},
	replacements = { {"basic_materials:copper_wire", "basic_materials:empty_spool"}, },

})

-- Add cuttable nodes after all mods loaded
minetest.after(0, function ()
	for k, v in pairs(minetest.registered_nodes) do
		if v.groups.tree then
			timber_nodenames[k] = true
		elseif chainsaw_leaves and (v.groups.leaves or v.groups.leafdecay or v.groups.leafdecay_drop) then
			timber_nodenames[k] = true
		elseif chainsaw_vines and v.groups.vines then
			timber_nodenames[k] = true
		end
	end
end)

