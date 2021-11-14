
-- Register wrench support for technic mod machines and other containers

local machine_invlist = {"src", "dst"}
local machine_invlist_upgrades = {"src", "dst", "upgrade1", "upgrade2"}

local function register_machine_node(nodename, tier, extra_fields, lists)
	if not lists then
		lists = tier ~= "LV" and machine_invlist_upgrades or machine_invlist
	end
	local metas = {
		infotext = wrench.META_TYPE_STRING,
		formspec = wrench.META_TYPE_STRING,
		[tier.."_EU_demand"] = wrench.META_TYPE_INT,
		[tier.."_EU_input"] = wrench.META_TYPE_INT,
		tube_time = tier ~= "LV" and wrench.META_TYPE_INT or nil,
		src_time = wrench.META_TYPE_INT,
	}
	for key, value in pairs(extra_fields or {}) do
		metas[key] = value
	end
	wrench:register_node(nodename, {lists = lists, metas = metas})
end

-- base_machines table row format: name = { extra meta fields }
local defaults = { tiers = {"LV", "MV", "HV"} }
local base_machines = {
	electric_furnace = defaults,
	grinder = defaults,
	compressor = defaults,
	alloy_furnace = {tiers = {"LV", "MV"}},
	extractor = {tiers = {"LV", "MV"}},
	centrifuge = {tiers = {"MV"}},
}

for name, data in pairs(base_machines) do
	for _,tier in ipairs(data.tiers) do
		local nodename = "technic:"..tier:lower().."_"..name
		register_machine_node(nodename, tier, data.extra_fields, data.lists)
		if minetest.registered_nodes[nodename.."_active"] then
			register_machine_node(nodename.."_active", tier, data.extra_fields, data.lists)
		end
	end
end

---------------------------------------------------------------------
---------------------------------------------------------------------
-- SPECIAL NODES
---------------------------------------------------------------------
---------------------------------------------------------------------

wrench:register_node("technic:coal_alloy_furnace", {
	lists = {"fuel", "src", "dst"},
	metas = {
		infotext = wrench.META_TYPE_STRING,
		fuel_totaltime = wrench.META_TYPE_FLOAT,
		fuel_time = wrench.META_TYPE_FLOAT,
		src_totaltime = wrench.META_TYPE_FLOAT,
		src_time = wrench.META_TYPE_FLOAT
	},
})

wrench:register_node("technic:coal_alloy_furnace_active", {
	lists = {"fuel", "src", "dst"},
	metas = {
		infotext = wrench.META_TYPE_STRING,
		fuel_totaltime = wrench.META_TYPE_FLOAT,
		fuel_time = wrench.META_TYPE_FLOAT,
		src_totaltime = wrench.META_TYPE_FLOAT,
		src_time = wrench.META_TYPE_FLOAT
	},
})

wrench:register_node("technic:tool_workshop", {
	lists = {"src", "upgrade1", "upgrade2"},
	metas = {
		infotext = wrench.META_TYPE_STRING,
		formspec = wrench.META_TYPE_STRING,
		MV_EU_demand = wrench.META_TYPE_INT,
		MV_EU_input = wrench.META_TYPE_INT,
		tube_time = wrench.META_TYPE_INT
	},
})

wrench:register_node("technic:cnc", {
	lists = {"src", "dst"},
	metas = {
		infotext = wrench.META_TYPE_STRING,
		formspec = wrench.META_TYPE_STRING,
		LV_EU_demand = wrench.META_TYPE_INT,
		LV_EU_input = wrench.META_TYPE_INT,
		src_time = wrench.META_TYPE_INT,
		cnc_product = wrench.META_TYPE_STRING
	},
})

wrench:register_node("technic:cnc_active", {
	lists = {"src", "dst"},
	metas = {
		infotext = wrench.META_TYPE_STRING,
		formspec = wrench.META_TYPE_STRING,
		LV_EU_demand = wrench.META_TYPE_INT,
		LV_EU_input = wrench.META_TYPE_INT,
		src_time = wrench.META_TYPE_INT,
		cnc_product = wrench.META_TYPE_STRING
	},
})

for tier, _ in pairs(technic.machines) do
	for i = 0, 8 do
		wrench:register_node("technic:"..tier:lower().."_battery_box"..i, {
			lists = tier ~= "LV" and machine_invlist_upgrades or machine_invlist,
			metas = {
				infotext = wrench.META_TYPE_STRING,
				formspec = wrench.META_TYPE_STRING,
				[tier.."_EU_demand"] = wrench.META_TYPE_INT,
				[tier.."_EU_supply"] = wrench.META_TYPE_INT,
				[tier.."_EU_input"] = wrench.META_TYPE_INT,
				internal_EU_charge = wrench.META_TYPE_INT,
				last_side_shown = wrench.META_TYPE_INT
			},
		})
	end
end
