
-- Use this fixture when loading full Technic mod.
-- Loads all required modules and fixtures for technic

-- Load modules required by tests
mineunit("core")
mineunit("player")
mineunit("protection")
mineunit("common/after")
mineunit("server")
mineunit("voxelmanip")

-- Load fixtures required by tests
fixture("default")
fixture("mesecons")
fixture("digilines")
fixture("pipeworks")
fixture("technic_worldgen")
