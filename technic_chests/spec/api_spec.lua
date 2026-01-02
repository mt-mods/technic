require("mineunit")

mineunit("core")
mineunit("player")
mineunit("server")

describe("Chests API", function()

	fixture("default")
	fixture("digilines")
	--fixture("pipeworks")

	sourcefile("init")

	-- Our player Sam will be helping, he promised to place some nodes
	local Sam = Player("Sam")

	-- Construct test world with CNC machines
	setup(function()
		world.clear()
		mineunit:set_current_modname("my_mod_name")
		mineunit:execute_on_joinplayer(Sam)
	end)

	teardown(function()
		mineunit:restore_current_modname()
	end)

	it("registered builtin chests", function()
		local materials = {"iron", "copper", "silver", "gold", "mithril"}
		local types = {"", "_locked", "_protected"}
		local failed = {}
		for _,m in ipairs(materials) do
			for _,t in ipairs(types) do
				local name = "technic:"..m..t.."_chest"
				if type(core.registered_nodes[name]) ~= "table" then
					table.insert(failed, name)
				end
			end
		end
		if #failed > 0 then
			error("Builtin chest(s) not registered: "..table.concat(failed,", "))
		end
	end)

	it("default builtin descriptions", function()
		local materials = {"iron", "copper", "silver", "gold", "mithril"}
		local types = {"", "_locked", "_protected"}
		local failed = {}
		local S = core.get_translator("technic_chests")
		for _,m in ipairs(materials) do
			for _,t in ipairs(types) do
				local name = "technic:"..m..t.."_chest"
				local description
				if t == "_locked" then
					description = S("@1 Locked Chest", S(m:sub(1,1):upper() .. m:sub(2)))
				elseif t == "_protected" then
					description = S("@1 Protected Chest", S(m:sub(1,1):upper() .. m:sub(2)))
				else
					description = S("@1 Chest", S(m:sub(1,1):upper() .. m:sub(2)))
				end
				assert.equals(description, core.registered_nodes[name].description)
			end
		end
	end)

	it("registers chest", function()
		technic.chests.register_chest("my_mod_name:my_special", {
			description = "My Special",
			texture_prefix = "my_mod_name_my_special",
			width = 15,
			height = 6,
			sort = true,
			infotext = true,
			autosort = true,
			quickmove = true,
			digilines = true,
		})
		-- Verify node registration
		assert.is_table(core.registered_nodes["my_mod_name:my_special"])
		-- Try to place it
		world.place_node({x=-99,y=-999,z=-9999}, {name = "my_mod_name:my_special", param2 = 0}, Sam)
	end)

	it("registers locked chest", function()
		technic.chests.register_chest("my_mod_name:my_locked_special", {
			description = "My Special",
			texture_prefix = "my_mod_name_my_special",
			width = 15,
			height = 6,
			sort = true,
			infotext = true,
			autosort = true,
			quickmove = true,
			digilines = true,
			locked = true
		})
		-- Verify node registration
		assert.is_table(core.registered_nodes["my_mod_name:my_locked_special"])
		-- Try to place it
		world.place_node({x=-99,y=-999,z=-9998}, {name = "my_mod_name:my_locked_special", param2 = 0}, Sam)
	end)

	it("registers protected chest", function()
		technic.chests.register_chest("my_mod_name:my_protected_special", {
			description = "My Special",
			texture_prefix = "my_mod_name_my_special",
			width = 15,
			height = 6,
			sort = true,
			infotext = true,
			autosort = true,
			quickmove = true,
			digilines = true,
			protected = true
		})
		-- Verify node registration
		assert.is_table(core.registered_nodes["my_mod_name:my_protected_special"])
		-- Try to place it
		world.place_node({x=-99,y=-999,z=-9997}, {name = "my_mod_name:my_protected_special", param2 = 0}, Sam)
	end)

end)
