require("mineunit")

-- Load complete technic mod
fixture("technic")
sourcefile("init")

describe("Nuclear reactor", function()

	-- Execute on mods loaded callbacks to finish loading.
	mineunit:mods_loaded()
	-- Tell mods that 1 minute passed already to execute all weird core.after hacks.
	mineunit:execute_globalstep(60)
	world.set_default_node("air")

	local player = Player("SX")
	local REACTOR_EU_OUTPUT = 100 * 1000

	-- Execute multiple globalsteps: run_network(times = 1, dtime = 1)
	local run_network = spec_utility.run_globalsteps

	-- Place itemstack into inventory slot: place_itemstack(pos, itemstack, listname = "src", index = auto)
	local place_itemstack = spec_utility.place_itemstack

	local function wall(results, pos, k1, k2, w, h, nodename)
		local start1, end1 = pos[k1], pos[k1] + w - 1
		local start2, end2 = pos[k2], pos[k2] + h - 1
		local k3
		repeat k3 = next(pos, k3) until k3 ~= k1 and k3 ~= k2
		local c3 = pos[k3]
		results = results or {}
		for c1 = start1, end1 do
			for c2 = start2, end2 do
				local p = {[k1]=c1,[k2]=c2,[k3]=c3}
				table.insert(results, {p, nodename})
			end
		end
		return results
	end

	local function box(results, p, d, nodename)
		results = results or {}
		wall(results, p, "x", "z", d, d, nodename) -- floor
		wall(results, vector.offset(p, 0, 1, 0), "x", "y", d, d - 1, nodename) -- wall
		wall(results, vector.offset(p, 0, 1, d-1), "x", "y", d, d - 1, nodename) -- wall
		wall(results, vector.offset(p, 0, 1, 1), "z", "y", d - 2, d - 1, nodename) -- wall
		wall(results, vector.offset(p, d-1, 1, 1), "z", "y", d - 2, d - 1, nodename) -- wall
		wall(results, vector.offset(p, 1, d-1, 1), "x", "z", d - 2, d - 2, nodename) -- ceiling
		return results
	end

	-- Base structure for reactor
	local reactor_container = {}
	box(reactor_container, {x=-3,y=-3,z=-3}, 7, "technic:blast_resistant_concrete")
	box(reactor_container, {x=-2,y=-2,z=-2}, 5, "technic:lead_block")
	box(reactor_container, {x=-1,y=-1,z=-1}, 3, "default:water_source")

	-- Add cables and apply reactor layout to world
	table.insert(reactor_container, {{x=0,y=-1,z=0}, "technic:hv_cable"})
	table.insert(reactor_container, {{x=0,y=-2,z=0}, "technic:hv_cable"})
	table.insert(reactor_container, {{x=0,y=-3,z=0}, "technic:hv_cable"})
	table.insert(reactor_container, {{x=1,y=-3,z=0}, "technic:hv_cable"})
	world.layout(reactor_container)

	-- Get reactor node definition
	local def = core.registered_items["technic:hv_nuclear_reactor_core"]

	it("generates energy", function()
		-- Add reactor core and switching station
		world.place_node({x=0,y=0,z=0}, "technic:hv_nuclear_reactor_core", player)
		world.place_node({x=1,y=-2,z=0}, "technic:switching_station", player)
		-- Add fuel
		place_itemstack({x=0,y=0,z=0}, "technic:uranium_fuel", "src", 1)
		place_itemstack({x=0,y=0,z=0}, "technic:uranium_fuel", "src", 2)
		place_itemstack({x=0,y=0,z=0}, "technic:uranium_fuel", "src", 3)
		place_itemstack({x=0,y=0,z=0}, "technic:uranium_fuel", "src", 4)
		place_itemstack({x=0,y=0,z=0}, "technic:uranium_fuel", "src", 5)
		place_itemstack({x=0,y=0,z=0}, "technic:uranium_fuel", "src", 6)
		-- Start reactor
		def.on_receive_fields({x=0,y=0,z=0}, "", {start="Start"}, player)
		-- Run network once
		run_network(1)
		-- Validate 100kEU output
		local id = technic.pos2network({x=0,y=0,z=0})
		assert.not_nil(technic.networks[id])
		assert.equals(REACTOR_EU_OUTPUT, technic.networks[id].supply)
	end)

	it("melts down with bad structure", function()
		local id = technic.pos2network({x=0,y=0,z=0})
		-- Remove single BRC node
		core.remove_node({x=3,y=3,z=3})
		-- ABM interval = 4, min structure_accumulated_badness = 25 for immediate meltdown
		run_network(24, 4)
		-- Validate 100kEU output
		assert.not_nil(technic.networks[id])
		assert.equals(REACTOR_EU_OUTPUT, technic.networks[id].supply)
		-- structure_accumulated_badness is 24, ABM increases structure_accumulated_badness to 25
		run_network(1,4)
		-- Validate zero output and core replacement
		assert.not_nil(technic.networks[id])
		assert.equals(0, technic.networks[id].supply)
		assert.nodename("technic:corium_source", {x=0,y=0,z=0})
	end)

end)
