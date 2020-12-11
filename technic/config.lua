local config_file = minetest.get_worldpath() .. "/technic.conf"

local defaults = {
	-- Power tools enabled
	enable_cans = "true",
	enable_chainsaw = "true",
	enable_flashlight = "false",
	enable_mining_drill = "true",
	enable_mining_laser = "false",
	enable_multimeter = "true",
	enable_prospector = "true",
	enable_sonic_screwdriver = "true",
	enable_tree_tap = "true",
	enable_vacuum = "true",

	-- Power tool options
	multimeter_remote_start_ttl = "300",

	-- Machine options
	enable_wind_mill = "false",
	enable_frames = "false",
	enable_nuclear_reactor_digiline_selfdestruct = "false",
	quarry_dig_above_nodes = "3",
	quarry_max_depth = "100",
	quarry_time_limit = "5000",

	-- Power network and general options
	switch_off_delay_seconds = "1800",
	network_overload_reset_time = "20",
	admin_priv = "basic_privs",
	enable_corium_griefing = "true",
	enable_radiation_protection = "true",
	enable_radiation_throttling = "false",
	enable_entity_radiation_damage = "true",
	enable_longterm_radiation_damage = "true",
	--constant_digit_count = nil,
}

--
-- Create technic.config settings object and
-- initialize configuration with default values.
--

local config_obj = Settings(config_file)
local Config = {}
Config.__index = Config

function Config:get_int(...)
	local args = {...}
	local value = tonumber(self:get(args[1]))
	if not value then
		if args[2] then
			return args[2]
		end
		error("Invalid configuration value for key " .. args[1] .. " in " .. config_file .. ". Number expected.")
	end
	return value
end

local config_obj_mt = getmetatable(config_obj)
for key,value in pairs(config_obj_mt) do
	if type(value) == "function" then
		Config[key] = function(self, ...) return value(config_obj, ...) end
	else
		config_obj_mt[key] = value
	end
end
setmetatable(Config, config_obj_mt)
technic.config = setmetatable({}, Config)

local conf_table = technic.config:to_table()
for k, v in pairs(defaults) do
	if conf_table[k] == nil then
		technic.config:set(k, v)
	end
end
