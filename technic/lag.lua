
local samples = {}

local index = 1

local last_step = minetest.get_us_time()

minetest.register_globalstep(function()
	-- Calculate own step time as a workaround to 2 second limit
	local now = minetest.get_us_time()
	samples[index] = now - last_step
	last_step = now
	-- Looping index; we don't need to know the order of the samples,
	-- so we can just overwrite previous ones to save a bit of performance
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
	return max_lag / 1000000
end

function technic.get_avg_lag()
	if #samples < 1 then
		return 0
	end
	local avg_lag = 0
	for _,t in ipairs(samples) do
		avg_lag = avg_lag + t
	end
	return (avg_lag / #samples) / 1000000
end
