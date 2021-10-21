require("mineunit")
--[[
	Technic network unit tests.
	Execute busted at technic source directory.
--]]

-- Load fixtures required by tests
mineunit("core")
mineunit("player")
mineunit("protection")
mineunit("common/after")
mineunit("server")
mineunit("voxelmanip")

fixture("pipeworks")
fixture("network")
fixture("default")
fixture("technic_worldgen")
fixture("mesecons")

sourcefile("init")

describe("Technic node placement", function()

	local function placement_test(player, name, xpos)
		return function()
			player:get_inventory():set_stack("main", 1, name)
			player:do_place({x=xpos, y=1, z=0})
		end
	end

	local player = Player("SX")

	-- Execute on mods loaded callbacks to finish loading.
	mineunit:mods_loaded()
	-- Tell mods that 1 minute passed already to execute all weird minetest.after hacks.
	mineunit:execute_globalstep(60)

	local nodes = {}
	for nodename, def in pairs(minetest.registered_nodes) do
		if not (def.groups and def.groups.not_in_creative_inventory) and nodename:find("^technic:") then
			table.insert(nodes, nodename)
		end
	end

	setup(function()
		world.clear()
		mineunit:execute_on_joinplayer(player)
	end)

	teardown(function()
		mineunit:execute_on_leaveplayer(player)
	end)

	for x, nodename in ipairs(nodes) do
		it("player can place "..nodename, placement_test(player, nodename, x))
	end

	it("gloabalstep works", function()
		for _=1,60 do
			mineunit:execute_globalstep(1)
		end
	end)

end)
