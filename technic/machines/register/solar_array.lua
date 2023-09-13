
local S = technic.getter

function technic.register_solar_array(nodename, data)
	local _, modname, name, def = technic.register_compat_v1_to_v2(nodename, data, "solar_array")
	assert(def.tier, "Technic register_solar_array requires `tier` field")

	local tier = def.tier
	local ltier = string.lower(tier)
	local infotext = S("Arrayed Solar @1 Generator", S(tier))

	local run = function(pos, node)
		-- The action here is to make the solar array produce power
		-- Power is dependent on the light level and the height above ground
		-- There are many ways to cheat by using other light sources like lamps.
		-- As there is no way to determine if light is sunlight that is just a shame.
		-- To take care of some of it solar panels do not work outside daylight hours or if
		-- built below 0m
		local pos1 = { y = pos.y + 1, x = pos.x, z = pos.z }

		minetest.load_area(pos1)
		local light = minetest.get_node_light(pos1, nil)
		local time_of_day = minetest.get_timeofday()
		local meta = minetest.get_meta(pos)
		light = light or 0

		-- turn on array only during day time and if sufficient light
		-- I know this is counter intuitive when cheating by using other light sources.
		if light >= 12 and time_of_day >= 0.24 and time_of_day <= 0.76 and pos.y > 0 then
			local charge_to_give = math.floor((light + pos.y) * def.power)
			charge_to_give = math.max(charge_to_give, 0)
			charge_to_give = math.min(charge_to_give, def.power * 50)
			meta:set_string("infotext", S("@1 Active (@2)", infotext, technic.EU_string(charge_to_give)))
			meta:set_int(tier.."_EU_supply", charge_to_give)
		else
			meta:set_string("infotext", S("@1 Idle", infotext))
			meta:set_int(tier.."_EU_supply", 0)
		end
	end

	def.tiles = def.tiles or {
		modname.."_"..name.."_top.png",
		modname.."_"..name.."_bottom.png",
		modname.."_"..name.."_side.png",
		modname.."_"..name.."_side.png",
		modname.."_"..name.."_side.png",
		modname.."_"..name.."_side.png"
	}
	def.groups = def.groups or {
		snappy=2, choppy=2, oddly_breakable_by_hand=2, technic_machine=1, ["technic_"..ltier]=1
	}
	def.connect_sides = def.connect_sides or {"bottom"}
	def.sounds = def.sounds or technic.sounds.node_sound_wood_defaults()
	def.description = def.description or S("Arrayed Solar @1 Generator", S(tier))
	def.active = def.active or false
	def.drawtype = def.drawtype or "nodebox"
	def.paramtype = def.paramtype or "light"
	def.node_box = def.nodebox or {
		type = "fixed",
		fixed = {-0.5, -0.5, -0.5, 0.5, 0, 0.5},
	}
	def.on_construct = def.on_construct or function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_int(tier.."_EU_supply", 0)
	end
	def.technic_run = def.technic_run or run

	minetest.register_node(nodename, def)
	technic.register_machine(tier, nodename, technic.producer)
end
