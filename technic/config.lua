technic.config = technic.config or Settings(minetest.get_worldpath().."/technic.conf")

local conf_table = technic.config:to_table()

local defaults = {
	enable_mining_drill = "true",
	enable_mining_laser = "false",
	enable_flashlight = "false",
	enable_wind_mill = "false",
	enable_frames = "false",
	enable_corium_griefing = "true",
	enable_radiation_protection = "true",
	enable_entity_radiation_damage = "true",
	enable_longterm_radiation_damage = "true",
	enable_nuclear_reactor_digiline_selfdestruct = "false",
	switch_max_range = "256",
	switch_off_delay_seconds = "1800",
	network_overload_reset_time = "20",
	admin_priv = "basic_privs",
	--constant_digit_count = nil,
}

for k, v in pairs(defaults) do
	if conf_table[k] == nil then
		technic.config:set(k, v)
	end
end
