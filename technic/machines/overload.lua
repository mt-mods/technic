--
-- Network overloading (incomplete cheat mitigation)
--

local overload_reset_time = technic.config:get_int("network_overload_reset_time")
local overloaded_networks = {}
local networks = technic.networks

function technic.overload_network(network_id)
	local network = networks[network_id]
	if network then
		network.supply = 0
		network.battery_charge = 0
	end
	overloaded_networks[network_id] = minetest.get_us_time() + (overload_reset_time * 1000 * 1000)
end

function technic.reset_overloaded(network_id)
	local remaining = math.max(0, overloaded_networks[network_id] - minetest.get_us_time())
	if remaining == 0 then
		-- Clear cache, remove overload and restart network
		technic.remove_network(network_id)
		overloaded_networks[network_id] = nil
	end
	-- Returns 0 when network reset or remaining time if reset timer has not expired yet
	return remaining
end

function technic.is_overloaded(network_id)
	return overloaded_networks[network_id]
end
