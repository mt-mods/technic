
local has_mcl = minetest.get_modpath("mcl_core")
local stones = {"default:stone", "mcl_core:stone", "mcl_deepslate:deepslate"}

local uranium_params = {
	offset = 0,
	scale = 1,
	spread = {x = 100, y = 100, z = 100},
	seed = 420,
	octaves = 3,
	persist = 0.7
}
local uranium_threshold = 0.55

local chromium_params = {
	offset = 0,
	scale = 1,
	spread = {x = 100, y = 100, z = 100},
	seed = 421,
	octaves = 3,
	persist = 0.7
}
local chromium_threshold = 0.55

local zinc_params = {
	offset = 0,
	scale = 1,
	spread = {x = 100, y = 100, z = 100},
	seed = 422,
	octaves = 3,
	persist = 0.7
}
local zinc_threshold = 0.5

local lead_params = {
	offset = 0,
	scale = 1,
	spread = {x = 100, y = 100, z = 100},
	seed = 423,
	octaves = 3,
	persist = 0.7
}
local lead_threshold = 0.3

minetest.register_ore({
	ore_type = "scatter",
	ore = "technic:mineral_uranium",
	wherein = stones,
	clust_scarcity = 8*8*8,
	clust_num_ores = 4,
	clust_size = 3,
	y_min = has_mcl and mcl_vars.mg_overworld_min or -300,
	y_max = has_mcl and mcl_worlds.layer_to_y(80) or -80,
	noise_params = uranium_params,
	noise_threshold = uranium_threshold,
})

minetest.register_ore({
	ore_type = "scatter",
	ore = "technic:mineral_chromium",
	wherein = stones,
	clust_scarcity = 8*8*8,
	clust_num_ores = 2,
	clust_size = 3,
	y_min = has_mcl and mcl_vars.mg_overworld_min or -200,
	y_max = has_mcl and mcl_worlds.layer_to_y(80) or -100,
	noise_params = chromium_params,
	noise_threshold = chromium_threshold,
})

minetest.register_ore({
	ore_type = "scatter",
	ore = "technic:mineral_chromium",
	wherein = stones,
	clust_scarcity = 6*6*6,
	clust_num_ores = 2,
	clust_size = 3,
	y_min = has_mcl and mcl_vars.mg_overworld_min or -31000,
	y_max = has_mcl and mcl_worlds.layer_to_y(80) or -200,
	flags = "absheight",
	noise_params = chromium_params,
	noise_threshold = chromium_threshold,
})

minetest.register_ore({
	ore_type = "scatter",
	ore = "technic:mineral_zinc",
	wherein = stones,
	clust_scarcity = 8*8*8,
	clust_num_ores = 5,
	clust_size = 7,
	y_min = -32,
	y_max = 2,
	noise_params = zinc_params,
	noise_threshold = zinc_threshold,
})

minetest.register_ore({
	ore_type = "scatter",
	ore = "technic:mineral_zinc",
	wherein = stones,
	clust_scarcity = 6*6*6,
	clust_num_ores = 4,
	clust_size = 3,
	y_min = has_mcl and mcl_vars.mg_overworld_min or -31000,
	y_max = -32,
	flags = "absheight",
	noise_params = zinc_params,
	noise_threshold = zinc_threshold,
})

minetest.register_ore({
	ore_type = "scatter",
	ore = "technic:mineral_lead",
	wherein = stones,
	clust_scarcity = 9*9*9,
	clust_num_ores = 5,
	clust_size = 3,
	y_min = -16,
	y_max = 16,
	noise_params = lead_params,
	noise_threshold = lead_threshold,
})

minetest.register_ore({
	ore_type = "scatter",
	ore = "technic:mineral_lead",
	wherein = stones,
	clust_scarcity = 8*8*8,
	clust_num_ores = 5,
	clust_size = 3,
	y_min = has_mcl and mcl_vars.mg_overworld_min or -128,
	y_max = -16,
	noise_params = lead_params,
	noise_threshold = lead_threshold,
})

minetest.register_ore({
	ore_type = "scatter",
	ore = "technic:mineral_lead",
	wherein = stones,
	clust_scarcity = 6*6*6,
	clust_num_ores = 5,
	clust_size = 3,
	y_min = has_mcl and mcl_vars.mg_overworld_min or -31000,
	y_max = has_mcl and mcl_worlds.layer_to_y(80) or -128,
	flags = "absheight",
	noise_params = lead_params,
	noise_threshold = lead_threshold,
})

-- Sulfur
local sulfur_buf = {}
local sulfur_noise

minetest.register_on_generated(function(minp, maxp)
	local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
	local a = VoxelArea:new({MinEdge=emin, MaxEdge=emax})
	vm:get_data(sulfur_buf)
	local pr = PseudoRandom(17 * minp.x + 42 * minp.y + 101 * minp.z)
	sulfur_noise = sulfur_noise or minetest.get_perlin(9876, 3, 0.5, 100)

	local lava = has_mcl and "mcl_core:lava_source" or "default:lava_source"
	local lava_flowing = has_mcl and "mcl_core:lava_flowing" or "default:lava_flowing"
	local stone = has_mcl and "mcl_core:stone" or "default:stone"
	local c_lava = minetest.get_content_id(lava)
	local c_lava_flowing = minetest.get_content_id(lava_flowing)
	local c_stone = minetest.get_content_id(stone)
	local c_sulfur = minetest.get_content_id("technic:mineral_sulfur")

	local grid_size = 5
	for x = minp.x + math.floor(grid_size / 2), maxp.x, grid_size do
	for y = minp.y + math.floor(grid_size / 2), maxp.y, grid_size do
	for z = minp.z + math.floor(grid_size / 2), maxp.z, grid_size do
		local c = sulfur_buf[a:index(x, y, z)]
		if (c == c_lava or c == c_lava_flowing)
		and sulfur_noise:get3d({x = x, y = z, z = z}) >= 0.4 then
			for i in a:iter(
				math.max(minp.x, x - grid_size),
				math.max(minp.y, y - grid_size),
				math.max(minp.z, z - grid_size),
				math.min(maxp.x, x + grid_size),
				math.min(maxp.y, y + grid_size),
				math.min(maxp.z, z + grid_size)
			) do
				if sulfur_buf[i] == c_stone and pr:next(1, 10) <= 7 then
					sulfur_buf[i] = c_sulfur
				end
			end
		end
	end
	end
	end

	vm:set_data(sulfur_buf)
	vm:write_to_map(sulfur_buf)
end)

-- in MCL sulfur is generated in the nether
if has_mcl then
	minetest.register_ore({
		ore_type = "scatter",
		ore = "technic:mineral_sulfur",
		wherein = {"mcl_nether:netherrack", "mcl_blackstone:blackstone"},
		clust_scarcity = 830,
		clust_num_ores = 5,
		clust_size = 3,
		y_min = mcl_vars.mg_nether_min,
		y_max = mcl_vars.mg_nether_max,
	})
end

if technic.config:get_bool("enable_marble_generation")
	and not minetest.get_modpath("underch") then
	minetest.register_ore({
		ore_type = "sheet",
		ore = "technic:marble",
		wherein = stones,
		clust_scarcity = 1,
		clust_num_ores = 1,
		clust_size = 3,
		y_min = has_mcl and mcl_vars.mg_overworld_min or -31000,
		y_max = has_mcl and mcl_worlds.layer_to_y(80) or -50,
		noise_threshold = 0.4,
		noise_params = {
			offset = 0, scale = 15, spread = {x = 150, y = 150, z = 150},
			seed = 23, octaves = 3, persist = 0.70
		}
	})
end

if technic.config:get_bool("enable_granite_generation") and not has_mcl then
	minetest.register_ore({
		ore_type = "sheet",
		ore = "technic:granite",
		wherein = stones,
		clust_scarcity = 1,
		clust_num_ores = 1,
		clust_size = 4,
		y_min = -31000,
		y_max = -150,
		noise_threshold = 0.4,
		noise_params = {
			offset = 0, scale = 15, spread = {x = 130, y = 130, z = 130},
			seed = 24, octaves = 3, persist = 0.70
		}
	})
end
