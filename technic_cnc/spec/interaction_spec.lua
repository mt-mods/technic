require("mineunit")

mineunit("core")
mineunit("player")
mineunit("protection")

describe("CNC formspec interaction", function()

	fixture("default")
	fixture("basic_materials")
	fixture("pipeworks")
	fixture("digilines")

	sourcefile("init")

	-- Our player Sam will be helping, he promised to place some nodes
	local Sam = Player("Sam")
	local SX = Player("SX")

	-- Construct test world with CNC machines
	world.clear()
	local pos = {x=3,y=2,z=1}
	world.place_node(pos, {name = "technic:cnc_mk2", param2 = 0}, Sam)

	local protectedpos = {x=2,y=2,z=2}
	mineunit:protect(protectedpos, SX)

	local nodedef = minetest.registered_nodes["technic:cnc_mk2"]

	do -- prepare machines for simple upgrade check
		world.place_node({x=98,y=98,z=98}, {name = "technic:cnc", param2 = 0}, Sam)
		local meta = minetest.get_meta({x=98,y=98,z=98})
		meta:set_string("cnc_product", "default:stone_technic_cnc_element_t")
		meta:set_float("cnc_multiplier", 4.2)
	end
	do -- prepare machines for simple upgrade check
		world.place_node({x=99,y=99,z=99}, {name = "technic:cnc_mk2", param2 = 0}, Sam)
		local meta = minetest.get_meta({x=99,y=99,z=99})
		meta:set_string("cnc_product", "default:stone_technic_cnc_element_t_double")
		meta:set_float("cnc_multiplier", 4.2)
	end

	-- Let Sam do some formspec interaction tests with CNC machines

	it("allows placing materials", function()
		Sam:do_metadata_inventory_put(pos, "src", 1, ItemStack("default:stone 42"))

		-- Check metadata values
		local stack = minetest.get_meta(pos):get_inventory():get_stack("src", 1)
		assert.equals("default:stone", stack:get_name())
		assert.equals(42, stack:get_count())
	end)

	it("allows placing materials protected", function()
		world.place_node(protectedpos, {name = "technic:cnc_mk2", param2 = 0}, SX)
		SX:do_metadata_inventory_put(protectedpos, "src", 1, ItemStack("default:stone 42"))

		-- Check metadata values
		local stack = minetest.get_meta(protectedpos):get_inventory():get_stack("src", 1)
		assert.equals("default:stone", stack:get_name())
		assert.equals(42, stack:get_count())
	end)

	it("disallows placing materials protected", function()
		world.place_node(protectedpos, {name = "technic:cnc_mk2", param2 = 0}, SX)
		Sam:do_metadata_inventory_put(protectedpos, "src", 1, ItemStack("default:stone 42"))

		-- Check metadata values
		local stack = minetest.get_meta(protectedpos):get_inventory():get_stack("src", 1)
		assert.equals("", stack:get_name())
		assert.equals(0, stack:get_count())
	end)

	it("does not check protection for noop actions", function()
		-- Check for unnecessary protection messages
		spy.on(minetest, "is_protected")
		-- Submit formspec without any meaningful action
		nodedef.on_receive_fields(pos, "", { quit = true }, Sam)
		-- Check that minetest.is_protected was not called
		assert.spy(minetest.is_protected).was_not.called()
	end)

	it("checks protection for programming", function()
		-- Check for unnecessary protection messages
		spy.on(minetest, "is_protected")
		-- Submit formspec without any meaningful action
		nodedef.on_receive_fields(pos, "", { half = true }, Sam)
		-- Check that minetest.is_protected was not called
		assert.spy(minetest.is_protected).was.called()
	end)

	it("sets metadata on form submit", function()
		-- Submit formspec selecting CNC sizes and digiline channel
		nodedef.on_receive_fields(pos, "", { half = true }, Sam)
		nodedef.on_receive_fields(pos, "", { full = true }, Sam)
		nodedef.on_receive_fields(pos, "", { setchannel = true, channel = "Sam" }, Sam)

		-- Check metadata values
		local meta = minetest.get_meta(pos)
		assert.equals(1, meta:get_int("size"))
		assert.equals("Sam", meta:get("channel"))
	end)

	it("manufactures products", function()
		-- Submit formspec selecting CNC sizes and program, 2 spheres and 16 sticks
		nodedef.on_receive_fields(pos, "", { sphere = true }, Sam)
		nodedef.on_receive_fields(pos, "", { stick = true }, Sam)
		nodedef.on_receive_fields(pos, "", { sphere = true }, Sam)
		nodedef.on_receive_fields(pos, "", { stick = true }, Sam)

		-- Check metadata values
		local meta = minetest.get_meta(pos)
		assert.equals("stick", meta:get("program"))

		-- Check output inventory for correct products
		local stack1 = meta:get_inventory():get_stack("dst", 1)
		assert.equals("default:stone_technic_cnc_sphere", stack1:get_name())
		assert.equals(2, stack1:get_count())

		local stack2 = meta:get_inventory():get_stack("dst", 2)
		assert.equals("default:stone_technic_cnc_stick", stack2:get_name())
		assert.equals(16, stack2:get_count())
	end)

	it("updates old machines", function()
		do -- Verify starting point and set meta value that is used to look for old machine
			local meta = minetest.get_meta({x=98,y=98,z=98})
			assert.equals("default:stone_technic_cnc_element_t", meta:get("cnc_product"))
			meta:set_float("technic_power_machine", 1)
		end
		do -- Verify starting point and set meta value that is used to look for old machine
			local meta = minetest.get_meta({x=99,y=99,z=99})
			assert.equals("default:stone_technic_cnc_element_t_double", meta:get("cnc_product"))
			meta:set_float("technic_power_machine", 1)
		end

		nodedef.on_receive_fields({x=98,y=98,z=98}, "", { quit = true, channel = "Sam" }, Sam)
		nodedef.on_receive_fields({x=99,y=99,z=99}, "", { quit = true, channel = "Sam" }, Sam)

		do -- Check metadata values
			local meta = minetest.get_meta({x=98,y=98,z=98})
			assert.is_nil(meta:get("cnc_product"))
			assert.is_nil(meta:get("cnc_multiplier"))
			assert.equals("element_t", meta:get("program"))
			assert.equals(2, meta:get_int("size"))
		end
		do -- Check metadata values
			local meta = minetest.get_meta({x=99,y=99,z=99})
			assert.is_nil(meta:get("cnc_product"))
			assert.is_nil(meta:get("cnc_multiplier"))
			assert.equals("element_t", meta:get("program"))
			assert.equals(1, meta:get_int("size"))
		end
	end)

end)
