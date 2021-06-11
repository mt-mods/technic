require("mineunit")

mineunit("core")
mineunit("player")
mineunit("protection")

fixture("default")
fixture("basic_materials")
fixture("pipeworks")

describe("CNC formspec interaction", function()

	sourcefile("init")

	-- Our player Sam will be helping, he promised to place some nodes
	local Sam = Player()

	-- Construct test world with CNC machines
	world.clear()
	local pos = {x=3,y=2,z=1}
	world.place_node(pos, {name = "technic:cnc", param2 = 0}, Sam)

	-- TODO: Let Sam do some formspec interaction tests with CNC machines

end)
