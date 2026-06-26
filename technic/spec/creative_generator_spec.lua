require("mineunit")
--[[
	Technic network unit tests.
	Execute mineunit at technic source directory.
--]]

-- Load complete technic mod
fixture("technic")
sourcefile("init")

describe("Creative Generator using", function()

	-- Execute on mods loaded callbacks to finish loading.
	mineunit:mods_loaded()
	-- Tell mods that 1 minute passed already to execute all weird core.after hacks.
	mineunit:execute_globalstep(60)
	world.set_default_node("air")

	-- Execute multiple globalsteps: run_network(times = 1, dtime = 1)
	local run_network = spec_utility.run_globalsteps

	describe("network building", function()

        local player = Player("SX")
        local gen_pos = {x=101,y=951,z=100}
        local def = core.registered_items["technic:creative_generator"]
        local on_receive_fields = def.on_receive_fields

		world.layout({
			{{x=100,y=950,z=100}, "technic:hv_cable"},
			{{x=101,y=950,z=100}, "technic:hv_cable"},
			{{x=100,y=951,z=100}, "technic:switching_station"},
			{gen_pos,             "technic:creative_generator"},
		})

		-- Build network
		local id = technic.pos2network(gen_pos)
        local net = technic.networks[id]

		it("generates energy", function()
			-- Build the network so it includes the creative generator and
			-- execute one globalstep to collect supply values from machines.
			run_network(1)
			assert.equals(100000, net.supply)
		end)

        it("generates more energy on request", function()
            local meta = core.get_meta(gen_pos)
            meta:set_int("power", 20260617)
			run_network(1)
			assert.equals(20260617, net.supply)
        end)

        it("pauses on formspec request", function()
            on_receive_fields(gen_pos, "", { disable = true }, player)
			run_network(1)
			assert.equals(0, net.supply) -- no power sources
        end)

        it("resumes on formspec request", function()
            on_receive_fields(gen_pos, "", { enable = true }, player)
			run_network(1)
			assert.equals(20260617, net.supply) -- back to normal
        end)

        it("maintains a minimum power", function()
            on_receive_fields(gen_pos, "", { power = "-1" }, player)
			run_network(1)
            assert.equals(0, net.supply) -- math.max(power, 0)
        end)

        it("maintains a maximum power", function()
            on_receive_fields(gen_pos, "", { power = tostring(2147483647 + 10) }, player)
			run_network(1)
            assert.equals(2147483647, net.supply) -- math.min(power, 2147483647), s32 limit
        end)

	end)
end)