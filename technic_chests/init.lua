
local S = core.get_translator(core.get_current_modname())

local modpath = core.get_modpath("technic_chests")

technic = rawget(_G, "technic") or {}
technic.chests = {}

technic.chests.colors = {
	{"black", S("Black")},
	{"blue", S("Blue")},
	{"brown", S("Brown")},
	{"cyan", S("Cyan")},
	{"dark_green", S("Dark Green")},
	{"dark_grey", S("Dark Grey")},
	{"green", S("Green")},
	{"grey", S("Grey")},
	{"magenta", S("Magenta")},
	{"orange", S("Orange")},
	{"pink", S("Pink")},
	{"red", S("Red")},
	{"violet", S("Violet")},
	{"white", S("White")},
	{"yellow", S("Yellow")},
}

function technic.chests.change_allowed(pos, player, owned, protected)
	if owned then
		if core.is_player(player) and not default.can_interact_with_node(player, pos) then
			return false
		end
	elseif protected then
		if core.is_protected(pos, player:get_player_name()) then
			return false
		end
	end
	return true
end

if core.get_modpath("digilines") then
	dofile(modpath.."/digilines.lua")
end

dofile(modpath.."/formspec.lua")
dofile(modpath.."/inventory.lua")
dofile(modpath.."/register.lua")
dofile(modpath.."/chests.lua")

-- Undo all of the locked wooden chest recipes, and just make them use a padlock.
core.register_on_mods_loaded(function()
	core.clear_craft({output = "default:chest_locked"})
	core.register_craft({
		output = "default:chest_locked",
		recipe = {
			{ "group:wood", "group:wood", "group:wood" },
			{ "group:wood", "basic_materials:padlock", "group:wood" },
			{ "group:wood", "group:wood", "group:wood" }
		}
	})
	core.register_craft({
		output = "default:chest_locked",
		type = "shapeless",
		recipe = {
			"default:chest",
			"basic_materials:padlock"
		}
	})
end)

-- Conversion for old chests
core.register_lbm({
	name = "technic_chests:old_chest_conversion",
	nodenames = {"group:technic_chest"},
	run_at_every_load = false,
	action = function(pos, node)
		-- Use `on_construct` function because that has data from register function
		local def = core.registered_nodes[node.name]
		if def and def.on_construct then
			def.on_construct(pos)
		end
	end,
})
