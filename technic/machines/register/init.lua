local path = technic.modpath.."/machines/register"

dofile(path.."/common.lua")

-- Wiring stuff
dofile(path.."/cables.lua")
dofile(path.."/battery_box.lua")

-- Generators
dofile(path.."/solar_array.lua")
dofile(path.."/generator.lua")

-- API for machines
dofile(path.."/recipes.lua")
dofile(path.."/machine_base.lua")

-- Recipes
dofile(path.."/alloy_recipes.lua")
dofile(path.."/grinder_recipes.lua")
dofile(path.."/extractor_recipes.lua")
dofile(path.."/compressor_recipes.lua")
dofile(path.."/centrifuge_recipes.lua")
dofile(path.."/freezer_recipes.lua")

-- Multi-Machine Recipes
dofile(path.."/grindings.lua")
