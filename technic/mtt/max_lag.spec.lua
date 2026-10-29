-- simple util function test

mtt.register("technic.max_lag", function(callback)
	local lag = technic.get_max_lag()
	assert(lag ~= nil and lag > 0)
	callback()
end)
