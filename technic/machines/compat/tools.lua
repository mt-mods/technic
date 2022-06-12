--
-- This allows using old style technic.register_power_tool tool registration function.
--
-- To make tool fully compatible replace `minetest.register_tool` with `technic.register_power_tool`
-- and add `technic_max_charge` field for tool definition.
-- Fields `wear_represents` and `on_refill` can be removed if using defaults.
--
-- Does not offer compatibility for charger mods: mods that charge or discharge registered power tools.
-- Compatibility for those can be achieved by using `<tooldef>.technic_get_charge` / `<tooldef>.technic_set_charge`.
--

local function compat_set_RE_wear(stack, charge)
	local def = stack:get_definition()
	if def.technic_wear_factor then
		local wear = math.floor(charge * def.technic_wear_factor + 0.5)
		stack:set_wear(wear > 0 and 65536 - wear or 0)
	end
end

local function compat_technic_get_charge(stack)
	local def = stack:get_definition()
	if def.technic_max_charge then
		local legacy_fields = minetest.deserialize(stack:get_meta():get_string("")) or {}
		return legacy_fields.charge or 0, def.technic_max_charge
	end
	return 0, 0
end

local function compat_technic_set_charge(stack, charge)
	compat_set_RE_wear(stack, charge)
	local meta = stack:get_meta()
	local legacy_fields = minetest.deserialize(meta:get_string("")) or {}
	legacy_fields.charge = charge
	meta:set_string("", minetest.serialize(legacy_fields))
end

-- This attempts to find out if mod is aware of technic.plus version property and marks mod as `plus_aware` if
-- it tries to read `technic.plus` value. Marked tools wont receive automatic metadata compatibility functions.
local plus_aware = {}
do
	local original_mt = getmetatable(technic)
	local mt = original_mt and table.copy(original_mt) or {}
	local mt_index = mt.__index or rawget
	local plus = technic.plus
	rawset(technic, "plus", nil)

	-- Extend `__index` lookup function for `technic` to collect mod names that are reading `technic.plus` property
	function mt:__index(key)
		if key == "plus" then
			local modname = minetest.get_current_modname()
			if modname then
				plus_aware[modname] = true
			end
			return plus
		end
		return mt_index(self, key)
	end
	setmetatable(technic, mt)

	-- Restore version and metatable, this must happen after handling register_on_mods_loaded callbacks
	minetest.after(0, function()
		rawset(technic, "plus", plus)
		setmetatable(technic, original_mt)
	end)
end

-- Override `technic.register_power_tool` to handle old style registration that was only setting max charge value.
local register_power_tool = technic.register_power_tool
function technic.register_power_tool(itemname, def_or_max_charge)
	if type(def_or_max_charge) == "number" then
		minetest.log("warning", "Deprecated technic.register_power_tool use. Setting max_charge for "..itemname)
		technic.power_tools[itemname] = def_or_max_charge
		minetest.register_on_mods_loaded(function()
			minetest.log("warning", "Deprecated technic.register_power_tool use. Ensuring fields for "..itemname)
			local redef = minetest.registered_items[itemname]
			if redef and redef.wear_represents == "technic_RE_charge" then
				-- Override power tools that called register_power_tool but do not have on_refill function defined
				local overrides = {
					technic_max_charge = def_or_max_charge,
					technic_wear_factor = 65535 / def_or_max_charge,
					technic_get_charge = technic.get_RE_charge,
					technic_set_charge = technic.set_RE_charge,
					on_refill = function(stack)
						local tooldef = stack:get_definition()
						tooldef.technic_set_charge(stack, def_or_max_charge)
						return stack
					end,
				}
				-- Add legacy meta handlers if mod did not attempt to read technic.plus value
				local modname = itemname:match(":?(.+):")
				if plus_aware[modname] then
					minetest.log("warning", "Mod "..modname.." seems to be aware of technic.plus but "..
						itemname.." is still using deprecated registration, skipping meta charge compatibility.")
				elseif not redef.technic_get_charge and not redef.technic_set_charge then
					overrides.technic_get_charge = compat_technic_get_charge
					overrides.technic_set_charge = compat_technic_set_charge
					minetest.log("warning", "Using metadata charge values for "..itemname)
				end
				-- Override tool definition with added / new values
				minetest.override_item(itemname, overrides)
				minetest.log("warning", "Updated legacy Technic power tool definition for "..itemname)
			end
		end)
	else
		return register_power_tool(itemname, def_or_max_charge)
	end
end

-- Same as `technic.set_RE_charge` but without calling through `itemdef.technic_set_charge`.
function technic.set_RE_wear(stack, charge)
	minetest.log("warning", "Use of deprecated function technic.set_RE_wear with stack: "..stack:get_name())
	compat_set_RE_wear(stack, charge)
end
