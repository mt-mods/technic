
-- This wont give full compatibility but allows using old style technic.register_power_tool tool registration function.
-- Tools still have to read charge value using technic.get_RE_charge, allows easier compatibility with official Technic
-- mod for some tools: a lot less changes required for compatibility but tool will keep some unnecessary meatadata.
--
-- To make tool fully compatible replace minetest.register_tool with technic.register_power_tool and add `max_charge`
-- field for tool definition. Fields `wear_represents` and `on_refill` can also be removed if using defaults.
--
local register_power_tool = technic.register_power_tool
function technic.register_power_tool(itemname, itemdef)
	if type(itemdef) == "number" then
		minetest.log("warning", "Deprecated technic.register_power_tool use. Setting max_charge for "..itemname)
		technic.power_tools[itemname] = itemdef
		minetest.register_on_mods_loaded(function()
			minetest.log("warning", "Deprecated technic.register_power_tool use. Ensuring fields for "..itemname)
			local redef = minetest.registered_items[itemname]
			if redef and redef.wear_represents == "technic_RE_charge" and not redef.on_refill then
				-- Override power tools that called register_power_tool but do not have on_refill function defined
				local max_charge = itemdef
				minetest.override_item(itemname, {
					on_refill = function(stack)
						technic.set_RE_charge(stack, max_charge)
						return stack
					end,
					max_charge = max_charge,
					technic_wear_factor = 65535 / max_charge,
				})
				minetest.log("warning", "Updated on_refill and max_charge for "..itemname)
			end
		end)
	else
		return register_power_tool(itemname, itemdef)
	end
end

-- Alias set set_RE_wear, many tools calls this to set wear value which is also handled by set_RE_charge
function technic.set_RE_wear(stack, charge)
	minetest.log("warning", "Use of deprecated function technic.set_RE_wear with stack: "..stack:get_name())
	technic.set_RE_charge(stack, charge)
end
