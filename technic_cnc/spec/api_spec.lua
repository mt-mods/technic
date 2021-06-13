require("mineunit")

mineunit("core")
mineunit("player")

describe("CNC API", function()

	fixture("default")
	fixture("basic_materials")
	fixture("pipeworks")

	sourcefile("init")

	-- Our player Sam will be helping, he promised to place some nodes
	local Sam = Player("Sam")

	-- Construct test world with CNC machines
	world.clear()
	local pos = {x=1,y=2,z=3}
	world.place_node(pos, {name = "technic:cnc", param2 = 0}, Sam)

	describe("Machine control", function()

		local program = "stick"
		local material = "default:stone"
		local size = 1

		it("returns product item string", function()
			local result = technic_cnc.get_product(program, material, size)
			assert.is_same("default:stone_technic_cnc_stick 8", result)
		end)

		it("configures new program", function()
			local meta = minetest.get_meta(pos)
			assert.is_true(technic_cnc.set_program(meta, program, size))
		end)

		it("fails configuring invalid program", function()
			local meta = minetest.get_meta(pos)
			assert.is_false(technic_cnc.set_program(meta, "program_that_does_not_exist", size))
		end)

		it("machine is enabled by default", function()
			local meta = minetest.get_meta(pos)
			assert.is_true(technic_cnc.is_enabled(meta))
		end)

		it("disables machine", function()
			local meta = minetest.get_meta(pos)
			technic_cnc.disable(meta)
			-- Verify new state
			assert.is_false(technic_cnc.is_enabled(meta))
		end)

		it("enables machine", function()
			local meta = minetest.get_meta(pos)
			technic_cnc.enable(meta)
			-- Verify new state
			assert.is_true(technic_cnc.is_enabled(meta))
		end)

		it("manufactures products", function()
			-- Prepare variables and fill src inventory
			local meta = minetest.get_meta(pos)
			local inventory = meta:get_inventory()
			inventory:set_stack("src", 1, "default:stone 42")
			inventory:set_stack("dst", 1, ItemStack())
			local materialstack = inventory:get_stack("src", 1)

			-- Test CNC cutting process
			local result = technic_cnc.produce(meta, inventory, materialstack)
			assert.is_true(result)

			-- Check output inventory for correct products
			local stack = inventory:get_stack("dst", 1)
			assert.equals("default:stone_technic_cnc_stick", stack:get_name())
			assert.equals(8, stack:get_count())
		end)

		it("fails manufacturing products", function()
			-- Prepare variables and fill src inventory
			local meta = minetest.get_meta(pos)
			local inventory = meta:get_inventory()
			inventory:set_stack("src", 1, "default:badstone 42")
			inventory:set_stack("dst", 1, ItemStack())
			local materialstack = inventory:get_stack("src", 1)

			-- Test CNC cutting process
			local result = technic_cnc.produce(meta, inventory, materialstack)
			assert.is_false(result)

			-- Check output inventory for no products
			assert.is_true(inventory:is_empty("dst"))
		end)

	end)

	describe("Machine registration", function()

		it("registers example machine", function()
			-- Yes, this is copy/paste from README.md. It should work.

			-- Textures for machine
			local tiles = {
				"my_mod_my_cnc_machine_top.png",
				"my_mod_my_cnc_machine_bottom.png",
				"my_mod_my_cnc_machine_right.png",
				"my_mod_my_cnc_machine_left.png",
				"my_mod_my_cnc_machine_back.png",
				"my_mod_my_cnc_machine_front.png"
			}
			local tiles_active = {
				"my_mod_my_cnc_machine_top_active.png",
				"my_mod_my_cnc_machine_bottom_active.png",
				"my_mod_my_cnc_machine_right_active.png",
				"my_mod_my_cnc_machine_left_active.png",
				"my_mod_my_cnc_machine_back_active.png",
				"my_mod_my_cnc_machine_front_active.png"
			}

			--
			-- Add pipeworks tube connection with overlay textures if pipeworks is available for CNC machines
			--
			local tube_def = nil
			if technic_cnc.pipeworks then
				tiles = technic_cnc.pipeworks.tube_entry_overlay(tiles)
				tiles_active = technic_cnc.pipeworks.tube_entry_overlay(tiles_active)
				tube_def = technic_cnc.pipeworks.new_tube()
			end

			--
			-- Default values provided with example machine registration below.
			--
			-- Required definition keys that do not have default value:
			--   description, programs, demand
			-- Optional definition keys that do not have default value:
			--   recipe, upgrade, digilines, tube
			--
			technic_cnc.register_cnc_machine("my_mod_name:my_cnc_machine", {
				description = "My Mod - My CNC Machine",
				input_size = 1,
				output_size = 4,
				digilines = technic_cnc.digilines,
				upgrade = true,
				tube = tube_def,
				programs = { "sphere", "spike", "stick", "slope" },
				demand = 539,
				get_formspec = technic_cnc.formspec.get_formspec,
				on_receive_fields = technic_cnc.formspec.on_receive_fields,
				recipe = {
					{'default:glass',      'default:glass',   'default:glass'},
					{'default:steelblock', 'default:diamond', 'default:steelblock'},
					{'default:steelblock', '',                'default:steelblock'},
				},
				tiles = tiles,
				tiles_active = tiles_active,
			})

			-- Verify node registration
			assert.is_table(minetest.registered_nodes["my_mod_name:my_cnc_machine"])

			-- Try to place it
			world.place_node({x=-99,y=-999,z=-9999}, {name = "my_mod_name:my_cnc_machine", param2 = 0}, Sam)
		end)

	end)

end)
