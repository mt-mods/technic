local S = technic.getter

-- Registration compatibility shim to transform Technic 1.x arguments to 2.x
-- This could be made stricter for new style API by utilizing `assert`

local function shallow_copy(t)
	local result = {}
	for k, v in pairs(t) do
		result[k] = v
	end
	return setmetatable(result, getmetatable(t))
end

function technic.register_compat_v1_to_v2(name, data, default_name)
	local modname = minetest.get_current_modname()
	local colon, def
	if type(name) == "table" then
		-- Log old API usage, swap name to def and set name from def table
		local msg = "Deprecated Technic registration API call: %s (%s)"
		def = shallow_copy(name)
		name = def.machine_name or default_name
		def.machine_name = nil
		def.description = def.machine_desc
		def.machine_desc = nil
		minetest.log("warning", msg:format(tostring(name), tostring(modname)))
	else
		def = shallow_copy(data)
	end
	-- Input name can be "modname:nodename", ":modname:nodename" or "nodename".
	-- If name is presented as "nodename" then check for old def.modname field.
	if name:find(":") then
		colon, modname, name = name:match("(:?)(.+):(.+)")
		-- Make sure that all fields are set, can be empty but pattern matcher must succeed.
		assert(colon and modname and name)
	elseif def.modname then
		minetest.log("warning", ("Definition contains modname for %s"):format(name))
		colon = ":"
		modname = def.modname
	end
	return (colon or ""), modname, name, def
end

-- Registration functions in Technic 1.x version

function technic.register_alloy_furnace(def)
	def.typename = "alloy"
	def.description = S("@1 Alloy Furnace", S(def.tier))
	def.insert_object = technic.insert_object_unique_stack
	def.can_insert = technic.can_insert_unique_stack
	technic.register_base_machine(def)
end

function technic.register_centrifuge(def)
	def.typename = "separating"
	def.description = S("@1 Centrifuge", S(def.tier))
	technic.register_base_machine(def)
end

function technic.register_compressor(def)
	def.typename = "compressing"
	def.description = S("@1 Compressor", S(def.tier))
	technic.register_base_machine(def)
end

function technic.register_extractor(def)
	def.typename = "extracting"
	def.description = S("@1 Extractor", S(def.tier))
	technic.register_base_machine(def)
end

function technic.register_freezer(def)
	def.typename = "freezing"
	def.description = S("@1 Freezer", S(def.tier))
	technic.register_base_machine(def)
end

function technic.register_grinder(def)
	def.typename = "grinding"
	def.description = S("@1 Grinder", S(def.tier))
	technic.register_base_machine(def)
end

function technic.register_electric_furnace(def)
	def.typename = "cooking"
	def.description = S("@1 Furnace", S(def.tier))
	technic.register_base_machine(def)
end
