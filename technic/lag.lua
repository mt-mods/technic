
local samples = {}

local index = 1

minetest.register_globalstep(function(dtime)
	-- Looping index; we don't need to know the order of the samples,
	-- so we can just overwrite previous ones to save a bit of performance
	samples[index] = dtime
	if index < 100 then
		index = index + 1
	else
		index = 1
	end
end)


function technic.get_max_lag()
	if #samples < 1 then
		return 0
	end
	local max_lag = 0
	for _,t in ipairs(samples) do
		if t > max_lag then
			max_lag = t
		end
	end
	return max_lag
end

function technic.get_avg_lag()
	if #samples < 1 then
		return 0
	end
	local avg_lag = 0
	for _,t in ipairs(samples) do
		avg_lag = avg_lag + t
	end
	return avg_lag / #samples
end
