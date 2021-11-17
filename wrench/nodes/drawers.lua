
-- Register wrench support for drawers mod nodes

local INT, STRING = wrench.META_TYPE_INT, wrench.META_TYPE_STRING

-- Assemble definitions for drawer type 1, 2 and 4
for _, drawer_type in ipairs({1, 2, 4}) do

	local def = {
		lists = {"upgrades"},
		metas = {},
		after_place = drawers.spawn_visuals
	}

	for i=1, drawer_type do

		local suffix = ""
		if drawer_type ~= 1 then
			-- Index as suffix
			suffix = i
		end

		def.metas["name" .. suffix] = STRING
		def.metas["count" .. suffix] = INT
		def.metas["max_count" .. suffix] = INT
		def.metas["base_stack_max" .. suffix] = INT
		def.metas["entity_infotext" .. suffix] = STRING
		def.metas["stack_max_factor" .. suffix] = INT
	end

	wrench.register_node("drawers:wood" .. drawer_type, def)
	wrench.register_node("drawers:acacia_wood" .. drawer_type, def)
	wrench.register_node("drawers:aspen_wood" .. drawer_type, def)
	wrench.register_node("drawers:junglewood" .. drawer_type, def)
	wrench.register_node("drawers:pine_wood" .. drawer_type, def)
end
