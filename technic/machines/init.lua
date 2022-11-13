local path = technic.modpath.."/machines"

technic.digilines = {
	rules = {
		-- digilines.rules.default
		{x= 1,y= 0,z= 0},{x=-1,y= 0,z= 0}, -- along x beside
		{x= 0,y= 0,z= 1},{x= 0,y= 0,z=-1}, -- along z beside
		{x= 1,y= 1,z= 0},{x=-1,y= 1,z= 0}, -- 1 node above along x diagonal
		{x= 0,y= 1,z= 1},{x= 0,y= 1,z=-1}, -- 1 node above along z diagonal
		{x= 1,y=-1,z= 0},{x=-1,y=-1,z= 0}, -- 1 node below along x diagonal
		{x= 0,y=-1,z= 1},{x= 0,y=-1,z=-1}, -- 1 node below along z diagonal
		-- added rules for digi cable
		{x =  0, y = -1, z = 0}, -- along y below
	},
	rules_allfaces = {
		{x= 1, y= 0, z= 0}, {x=-1, y= 0, z= 0}, -- along x beside
		{x= 0, y= 1, z= 0}, {x= 0, y=-1, z= 0}, -- along y above and below
		{x= 0, y= 0, z= 1}, {x= 0, y= 0, z=-1}, -- along z beside
	}
}

-- Compatibility shim to allow old API usage
dofile(path.."/compat/api.lua")

-- https://github.com/mt-mods/technic/issues/100
dofile(path.."/compat/digtron.lua")

dofile(path.."/network.lua")

dofile(path.."/overload.lua")

dofile(path.."/register/init.lua")

-- Tiers
dofile(path.."/LV/init.lua")
dofile(path.."/MV/init.lua")
dofile(path.."/HV/init.lua")

dofile(path.."/switching_station.lua")
dofile(path.."/switching_station_globalstep.lua")

dofile(path.."/power_monitor.lua")
dofile(path.."/supply_converter.lua")

dofile(path.."/other/init.lua")


-- Metadata cleanup LBM, removes old metadata values from nodes
minetest.register_lbm({
	name = "technic:metadata_cleanup",
	nodenames = {
		"group:technic_machine",
		"group:technic_all_tiers",
		"technic:switching_station",
		"technic:power_monitor",
	},
	action = function(pos, node)
		-- Delete all listed metadata key/value pairs from technic machines
		local keys = {
			"LV_EU_timeout", "MV_EU_timeout", "HV_EU_timeout",
			"LV_network", "MV_network", "HV_network",
			"active_pos", "supply", "demand",
			"battery_count", "battery_charge", "battery_charge_max",
		}
		local meta = minetest.get_meta(pos)
		for _,key in ipairs(keys) do
			-- Value of `""` will delete the key.
			meta:set_string(key, "")
		end
		if node.name == "technic:switching_station" then
			meta:set_string("active", "")

			-- start nodetimer if not already started
			local timer = minetest.get_node_timer(pos)
			if not timer:is_started() then
				timer:start(1.0)
			end
		end
	end,
})
