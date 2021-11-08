-- This file includes the functions and data structures for registering machines and tools for LV, MV, HV types.
-- We use the technic namespace for these functions and data to avoid eventual conflict.

technic.receiver = "RE"
technic.producer = "PR"
technic.producer_receiver = "PR_RE"
technic.battery  = "BA"

technic.machines    = {}
technic.power_tools = setmetatable({}, {
	-- TODO: Should get rid of this table, tool stack / item definition already has all required data and more.
	-- Add __newindex logging after technic itself is cleaned up. Other mods should not be accessing this but still.
	__index = function(self, key)
		minetest.log("warning", "Deprecated access technic.power_tools["..tostring(key).."]")
		return rawget(self, key)
	end,
})
technic.networks = {}
technic.machine_tiers = {}

function technic.register_tier(tier, description)
	technic.machines[tier] = {}
end

function technic.register_machine(tier, nodename, machine_type)
	-- Lookup table to get compatible node names and machine type by tier
	if not technic.machines[tier] then
		return
	end
	technic.machines[tier][nodename] = machine_type
	-- Lookup table to get compatible tiers by node name
	if not technic.machine_tiers[nodename] then
		technic.machine_tiers[nodename] = {}
	end
	table.insert(technic.machine_tiers[nodename], tier)
end

function technic.register_power_tool(itemname, itemdef)
	local max_charge = itemdef.technic_max_charge or itemdef.max_charge or 10000
	itemdef.wear_represents = itemdef.wear_represents or "technic_RE_charge"
	itemdef.technic_max_charge = max_charge
	itemdef.technic_wear_factor = 65535 / max_charge
	itemdef.on_refill = itemdef.on_refill or function(stack)
		-- This is always using originally defined max_charge even if stack somehow changed to another
		technic.set_RE_charge(stack, max_charge)
		return stack
	end
	itemdef.tool_capabilities = itemdef.tool_capabilities or { punch_attack_uses = 0 }
	minetest.register_tool(itemname, itemdef)
	technic.power_tools[itemname] = max_charge
end
