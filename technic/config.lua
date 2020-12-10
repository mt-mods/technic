technic.config = technic.config or Settings(minetest.get_worldpath().."/technic.conf")
local conf_table = technic.config:to_table()

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

for k, v in pairs(defaults) do
	if conf_table[k] == nil then
		technic.config:set(k, v)
	end
end
