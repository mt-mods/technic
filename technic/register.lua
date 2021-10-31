-- This file includes the functions and data structures for registering machines and tools for LV, MV, HV types.
-- We use the technic namespace for these functions and data to avoid eventual conflict.

technic.receiver = "RE"
technic.producer = "PR"
technic.producer_receiver = "PR_RE"
technic.battery  = "BA"

technic.machines    = {}
technic.power_tools = {} -- TODO: Should get rid of this table, tool stack already has all required data and more
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
	itemdef.wear_represents = itemdef.wear_represents or "technic_RE_charge"
	itemdef.max_charge = itemdef.max_charge or 10000
	itemdef.on_refill = itemdef.on_refill or function(stack)
		technic.set_RE_charge(stack, stack:get_definition().max_charge or 10000)
		return stack
	end
	itemdef.tool_capabilities = itemdef.tool_capabilities or { punch_attack_uses = 0 }
	minetest.register_tool(itemname, itemdef)
	technic.power_tools[itemname] = itemdef.max_charge
end
