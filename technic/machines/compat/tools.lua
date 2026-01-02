--
-- This allows using old style technic.register_power_tool tool registration function.
--
-- To make tool fully compatible replace `core.register_tool` with `technic.register_power_tool`
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
		local legacy_fields = core.deserialize(stack:get_meta():get_string("")) or {}
		return legacy_fields.charge or 0, def.technic_max_charge
	end
	return 0, 0
end

local function compat_technic_set_charge(stack, charge)
	compat_set_RE_wear(stack, charge)
	local meta = stack:get_meta()
	local legacy_fields = core.deserialize(meta:get_string("")) or {}
	legacy_fields.charge = charge
	meta:set_string("", core.serialize(legacy_fields))
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
			local modname = core.get_current_modname()
			if modname then
				plus_aware[modname] = true
			end
			return plus
		end
		return mt_index(self, key)
	end
	setmetatable(technic, mt)

	-- Restore version and metatable, this must happen after handling register_on_mods_loaded callbacks
	core.after(0, function()
		rawset(technic, "plus", plus)
		setmetatable(technic, original_mt)
	end)
end

-- Override `technic.register_power_tool` to handle old style registration that was only setting max charge value.
local register_power_tool = technic.register_power_tool
function technic.register_power_tool(itemname, def_or_max_charge)
	if type(def_or_max_charge) == "number" then
		core.log("warning", "Deprecated technic.register_power_tool use. Setting max_charge for "..itemname)
		technic.power_tools[itemname] = def_or_max_charge
		core.register_on_mods_loaded(function()
			core.log("warning", "Deprecated technic.register_power_tool use. Ensuring fields for "..itemname)
			local redef = core.registered_items[itemname]
			if redef and redef.wear_represents == "technic_RE_charge" then
				-- Override power tools that called register_power_tool but do not have on_refill function defined
				local overrides = {
					technic_max_charge = def_or_max_charge,
					technic_wear_factor = 65535 / def_or_max_charge,
					on_refill = function(stack)
						local tooldef = stack:get_definition()
						tooldef.technic_set_charge(stack, def_or_max_charge)
						return stack
					end,
				}
				-- Add legacy meta handlers if mod did not attempt to read technic.plus value
				local modname = itemname:match(":?(.+):")
				if plus_aware[modname] then
					overrides.technic_get_charge = redef.technic_get_charge or technic.get_charge
					overrides.technic_set_charge = redef.technic_set_charge or technic.set_charge
					core.log("warning", "Mod "..modname.." seems to be aware of technic.plus but "..
						itemname.." is still using deprecated registration, skipping meta charge compatibility.")
				elseif not redef.technic_get_charge and not redef.technic_set_charge then
					overrides.technic_get_charge = compat_technic_get_charge
					overrides.technic_set_charge = compat_technic_set_charge
					core.log("warning", "Using metadata charge values for "..itemname)
				end
				-- Override tool definition with added / new values
				core.override_item(itemname, overrides)
				core.log("warning", "Updated legacy Technic power tool definition for "..itemname)
			else
				core.log("error", "Technic compatibility overrides skipped for "..itemname..", charging might "..
					'cause crash. Upgrading to technic.register_power_tool("'..itemname..'", {itemdef}) recommended.')
			end
		end)
	else
		return register_power_tool(itemname, def_or_max_charge)
	end
end

technic.set_RE_charge = assert(technic.set_charge)
technic.get_RE_charge = assert(technic.get_charge)
technic.use_RE_charge = assert(technic.use_charge)

-- Same as `technic.set_charge` but without calling through `itemdef.technic_set_charge`.
function technic.set_RE_wear(stack, charge)
	core.log("warning", "Use of deprecated function technic.set_RE_wear with stack: "..stack:get_name())
	compat_set_RE_wear(stack, charge)
end

-- Old utility function to recharge tools
local function charge_tools(meta, batt_charge, charge_step)
	local src_stack = meta:get_inventory():get_stack("src", 1)
	local def = src_stack:get_definition()
	if not def or not def.technic_max_charge or src_stack:is_empty() then
		return batt_charge, false
	end
	local new_charge = math.min(def.technic_max_charge, def.technic_get_charge(src_stack) + charge_step)
	def.technic_set_charge(src_stack, new_charge)
	meta:get_inventory():set_stack("src", 1, src_stack)
	return batt_charge, (def.technic_max_charge == new_charge)
end

function technic.charge_tools(...)
	core.log("warning", "Use of deprecated function technic.charge_tools")
	technic.charge_tools = charge_tools
	return charge_tools(...)
end
