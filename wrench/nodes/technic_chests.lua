
-- Register wrench support for technic_chests

local function with_owner_field(metas)
	local result = table.copy(metas)
	result.owner = wrench.META_TYPE_STRING
	return result
end

local chests_meta = {
	iron = {
		infotext = wrench.META_TYPE_STRING,
	},
	copper = {
		infotext = wrench.META_TYPE_STRING,
	},
	silver = {
		infotext = wrench.META_TYPE_STRING,
		formspec = wrench.META_TYPE_STRING,
	},
	gold = {
		infotext = wrench.META_TYPE_STRING,
		formspec = wrench.META_TYPE_STRING,
	},
	mithril = {
		infotext = wrench.META_TYPE_STRING,
		formspec = wrench.META_TYPE_STRING,
	},
}

for name, metas in pairs(chests_meta) do
	wrench:register_node("technic:"..name.."_chest", {
		lists = {"main"},
		metas = metas,
	})
	wrench:register_node("technic:"..name.."_protected_chest", {
		lists = {"main"},
		metas = metas,
	})
	wrench:register_node("technic:"..name.."_locked_chest", {
		lists = {"main"},
		metas = with_owner_field(metas),
		owned = true,
	})
end

-- Register extra nodes with color marking for gold chest

local chest_mark_colors = {
	'_black',
	'_blue',
	'_brown',
	'_cyan',
	'_dark_green',
	'_dark_grey',
	'_green',
	'_grey',
	'_magenta',
	'_orange',
	'_pink',
	'_red',
	'_violet',
	'_white',
	'_yellow',
}

for i = 1, 15 do
	wrench:register_node("technic:gold_chest"..chest_mark_colors[i], {
		lists = {"main"},
		metas = chests_meta.gold,
	})
	wrench:register_node("technic:gold_protected_chest"..chest_mark_colors[i], {
		lists = {"main"},
		metas = chests_meta.gold,
	})
	wrench:register_node("technic:gold_locked_chest"..chest_mark_colors[i], {
		lists = {"main"},
		metas = with_owner_field(chests_meta.gold),
		owned = true,
	})
end
