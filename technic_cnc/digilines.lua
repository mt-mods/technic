
local rules = technic.digilines.rules
local def = {
	receptor = {
		rules = rules,
	},
	effector = {
		rules = rules,
	},
}

local function check_message(meta, channel, msg)
	-- Digiline channel check
	if channel ~= meta:get_string(channel) then
		return false
	end

	-- Message type check
	if type(msg) == "string" then
		-- String is is always valid, get out skipping all table checks
		return true
	elseif type(msg) ~= "table" then
		return false
	end

	-- Verify that size is either nil or number between 1-2
	if msg.size ~= nil and (type(msg.size) ~= "number" or msg.size < 1 or msg.size > 2) then
		return false
	end

	-- Verify program if provided
	if msg.program ~= nil then
		-- If program is set it must be string and available
		if type(msg.program) ~= "string" or not technic_cnc.products[msg.program] then
			return false
		end
	end

	-- Message is valid (but not necessarily useful)
	return true
end

function def.effector.action(pos, node, channel, msg)
	-- Validate message contents,
	local meta = minetest.get_meta(pos)
	if not check_message(meta, channel, msg) then
		return
	end

	-- Process message and execute required actions
	if type(msg) == "string" then
		msg = msg:lower()
		if msg == "get" then
			digilines.receptor_send(pos, rules, channel, technic_cnc.products)
		end
	else
		-- Configure milling programs
		if msg.program then
			technic_cnc.set_program(meta, msg.program, msg.size)
		elseif msg.size then
			meta:set_int("size", msg.size)
		end
		-- Enable / disable CNC machine
		if msg.enabled == true or msg.enable then
			technic_cnc.enable(meta)
		elseif msg.enabled == false or msg.disable then
			technic_cnc.disable(meta)
		end
	end
end

return def
