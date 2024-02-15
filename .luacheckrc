std = "minetest+max"
unused_args = false

-- Exclude regression tests / unit tests
exclude_files = {
	"**/spec/**",
}

globals = {
	"technic", "technic_cnc"
}

read_globals = {
	-- Mods
	"default", "stairsplus",
	"screwdriver", "bucket",
	"digilines", "pipeworks",
	"mesecon", "moretrees",
	"unified_inventory", "protector",
	"unifieddyes", "digiline_remote",
	"drawers", "mg", "mcl_explosions",
	"craftguide", "i3", "mtt",
	"vizlib", "mcl_sounds", "mcl_vars",
	"mcl_worlds", "mcl_buckets", "mcl_formspec",
	"mcl_craftguide",

	-- Only used in technic/machines/MV/lighting.lua (disabled)
	"isprotect", "homedecor_expect_infinite_stacks",
}
