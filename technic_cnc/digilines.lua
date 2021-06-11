
local rules = technic_cnc.use_technic and technic.digilines.rules or digilines.rules.default
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
	if channel ~= meta:get_string("channel") then
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
		msg.size = nil
	end

	-- Verify program if provided
	if msg.program ~= nil then
		-- If program is set it must be string and available
		if type(msg.program) ~= "string" or not technic_cnc.products[msg.program] then
			msg.program = nil
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
		if msg == "programs" then
			digilines.receptor_send(pos, rules, channel, technic_cnc.products)
		elseif msg == "status" then
			local inv = meta:get_inventory()
			local srcstack = inv:get_stack("src", 1)
			local status = {
				enabled = technic_cnc.is_enabled(meta),
				time = meta:get_int("src_time"),
				size = meta:get_int("size"),
				program = meta:get_string("program"),
				user = meta:get_string("cnc_user"),
				material = {
					name = srcstack:get_name(),
					count = srcstack:get_count(),
				}
			}
			digilines.receptor_send(pos, rules, channel, status)
		elseif msg == "enable" then
			technic_cnc.enable(meta)
		elseif msg == "disable" then
			technic_cnc.disable(meta)
		end
	else
		-- Configure milling programs
		if msg.program then
			technic_cnc.set_program(meta, msg.program, msg.size)
		elseif msg.size then
			meta:set_int("size", msg.size)
		end
		-- Enable / disable CNC machine
		if msg.enabled == true then
			technic_cnc.enable(meta)
		elseif msg.enabled == false then
			technic_cnc.disable(meta)
		end
	end
end

return def
