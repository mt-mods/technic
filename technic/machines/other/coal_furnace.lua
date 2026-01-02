local S = technic.getter

local default_furnace = core.registered_nodes["default:furnace"]

if default_furnace and default_furnace.description == "Furnace" then
	core.override_item("default:furnace", { description = S("Fuel-Fired Furnace") })
end
