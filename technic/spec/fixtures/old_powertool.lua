
local function doregister(modname, callback)
	mineunit:set_modpath(modname, "spec/fixtures")
	mineunit:set_current_modname(modname)
	callback()
	mineunit:restore_current_modname()
end

local MAX_CHARGE = 65536
local USE_CHARGE = 1000

-- No updates for compatibility
doregister("oldlegacy", function()
	technic.register_power_tool("oldlegacy:powertool", MAX_CHARGE)
	minetest.register_tool("oldlegacy:powertool", {
		description = "Powertool",
		inventory_image = "powertool.png",
		stack_max = 1,
		wear_represents = "technic_RE_charge",
		on_refill = technic.refill_RE_charge,
		on_use = function(itemstack, user, pointed_thing)
			local meta = minetest.deserialize(itemstack:get_meta():get_string(""))
			if not meta or not meta.charge or meta.charge < USE_CHARGE then
				return
			end
			meta.charge = meta.charge - USE_CHARGE
			technic.set_RE_wear(itemstack, meta.charge, MAX_CHARGE)
			itemstack:get_meta():set_string("", minetest.serialize(meta))
			return itemstack
		end,
	})
end)

-- Previously suggested minimal compatibility workaround added
doregister("oldminimal", function()
	technic.register_power_tool("oldminimal:powertool", MAX_CHARGE)
	minetest.register_tool("oldminimal:powertool", {
		description = "Powertool",
		inventory_image = "powertool.png",
		stack_max = 1,
		wear_represents = "technic_RE_charge",
		on_refill = technic.refill_RE_charge,
		on_use = function(itemstack, user, pointed_thing)
			local meta = technic.plus and { charge = technic.get_RE_charge(itemstack) }
				or error("oldminimal:powertool wrong charge handler called")
			if not meta or not meta.charge or meta.charge < USE_CHARGE then
				return
			end
			meta.charge = meta.charge - USE_CHARGE
			technic.set_RE_wear(itemstack, meta.charge, MAX_CHARGE)
			itemstack:get_meta():set_string("", minetest.serialize(meta))
			return itemstack
		end,
	})
end)

-- Halfway there, checking for technic.plus and deciding charge handling based on that
doregister("oldhalfway", function()
	local get_charge = technic.plus and technic.get_RE_charge or function()
		error("Wrong get_charge handler called for oldhalfway:powertool")
	end
	local set_charge = technic.plus and technic.set_RE_charge or function()
		error("Wrong set_charge handler called for oldhalfway:powertool")
	end
	technic.register_power_tool("oldhalfway:powertool", MAX_CHARGE)
	minetest.register_tool("oldhalfway:powertool", {
		description = "Powertool",
		inventory_image = "powertool.png",
		stack_max = 1,
		wear_represents = "technic_RE_charge",
		on_refill = technic.refill_RE_charge,
		on_use = function(itemstack, user, pointed_thing)
			local charge = get_charge(itemstack)
			if not charge or charge < USE_CHARGE then
				return
			end
			set_charge(itemstack, charge - USE_CHARGE)
			return itemstack
		end,
	})
end)
