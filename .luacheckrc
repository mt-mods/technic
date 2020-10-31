unused_args = false

-- Exclude regression tests / unit tests
exclude_files = {
	"**/spec/**",
}

globals = {
    "technic", "technic_cnc", "minetest", "wrench"
}

read_globals = {
    string = {fields = {"split", "trim"}},
    table = {fields = {"copy", "getn"}},

    "intllib", "VoxelArea",
    "default", "stairsplus",

    "PseudoRandom", "ItemStack",
    "mg", "tubelib", "vector",

    "moretrees", "bucket",
    "unified_inventory", "digilines",

    "pipeworks", "screwdriver",
    "VoxelManip", "unifieddyes",

    "Settings", "mesecon",
    "digiline_remote",

    "protector", "isprotect",
    "homedecor_expect_infinite_stacks",
    "monitoring", "drawers"
}

-- Remove after chests update
files["technic_chests/register.lua"].ignore = { "fs_helpers", "name", "locked_after_place" }
files["technic_chests/register.lua"].max_line_length = false
