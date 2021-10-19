local config_file = minetest.get_worldpath() .. "/technic.conf"

local defaults = {
	enable_mining_drill = "true",
	enable_mining_laser = "false",
	enable_flashlight = "false",
	enable_wind_mill = "false",
	enable_frames = "false",
	enable_corium_griefing = "true",
	enable_radiation_protection = "true",
	enable_radiation_throttling = "false",
	enable_entity_radiation_damage = "true",
	enable_longterm_radiation_damage = "true",
	enable_nuclear_reactor_digiline_selfdestruct = "false",
	switch_max_range = "256",
	switch_off_delay_seconds = "1800",
	network_overload_reset_time = "20",
	admin_priv = "basic_privs",
	quarry_dig_above_nodes = "3",
	quarry_max_depth = "100",
	quarry_time_limit = "5000",
	max_lag_reduction_multiplier = "0.99",
	--constant_digit_count = nil,
}

--
-- Create technic.config settings object and
-- initialize configuration with default values.
--

local config_obj = Settings(config_file)

technic.config = {}

function technic.config:get_int(key)
	local value = tonumber(self:get(key))
	if not value then
		error("Invalid configuration value for key " .. key .. " in " .. config_file .. ". Number expected.")
	end
	return value
end

function technic.config:get(...) return config_obj:get(...) end
function technic.config:get_bool(...) return config_obj:get_bool(...) end
function technic.config:get_np_group(...) return config_obj:get_np_group(...) end
function technic.config:get_flags(...) return config_obj:get_flags(...) end
function technic.config:set(...) return config_obj:set(...) end
function technic.config:set_bool(...) return config_obj:set_bool(...) end
function technic.config:set_np_group(...) return config_obj:set_np_group(...) end
function technic.config:remove(...) return config_obj:remove(...) end
function technic.config:get_names(...) return config_obj:get_names(...) end
function technic.config:write(...) return config_obj:write(...) end
function technic.config:to_table(...) return config_obj:to_table(...) end

local conf_table = technic.config:to_table()
for k, v in pairs(defaults) do
	if conf_table[k] == nil then
		technic.config:set(k, v)
	end
end
