
local max_lag = 0

minetest.register_globalstep(function(dtime)
	max_lag = max_lag * 0.9998
	if dtime > max_lag then
		max_lag = dtime
	end
end)

function technic.get_max_lag()
	return max_lag
end
