local function noop(...) end
local function dummy_coords(...) return { x = 123, y = 123, z = 123 } end

_G.world = { nodes = {} }
local world = _G.world
_G.world.set_node = function(pos, node)
	local hash = minetest.hash_node_position(pos)
	world.nodes[hash] = node
end
_G.world.clear = function() _G.world.nodes = {} end
_G.world.layout = function(layout, offset)
	_G.world.clear()
	_G.world.add_layout(layout, offset)
end
_G.world.add_layout = function(layout, offset)
	for _, node in ipairs(layout) do
		local pos = node[1]
		if offset then
			pos.x = pos.x + offset.x
			pos.y = pos.y + offset.y
			pos.z = pos.z + offset.z
		end
		_G.world.set_node(pos, {name=node[2], param2=0})
	end
end

_G.core = {}
_G.minetest = _G.core

local configuration_file = fixture_path("minetest.cfg")
_G.Settings = function(fname)
	local settings = {
		_data = {},
		get = function(self, key)
			return self._data[key]
		end,
		get_bool = function(self, key, default)
			return
		end,
		set = function(...)end,
		set_bool = function(...)end,
		write = function(...)end,
		remove = function(self, key)
			self._data[key] = nil
			return true
		end,
		get_names = function(self)
			local result = {}
			for k,_ in pairs(t) do
				table.insert(result, k)
			end
			return result
		end,
		to_table = function(self)
			local result = {}
			for k,v in pairs(self._data) do
				result[k] = v
			end
			return result
		end,
	}
	-- Not even nearly perfect config parser but should be good enough for now
	file = assert(io.open(fname, "r"))
	for line in file:lines() do
		for key, value in string.gmatch(line, "([^= ]+) *= *(.-)$") do
			settings._data[key] = value
		end
	end
	return settings
end
_G.core.settings = _G.Settings(configuration_file)

_G.core.register_on_joinplayer = noop
_G.core.register_on_leaveplayer = noop

fixture("minetest/game/misc")
fixture("minetest/common/misc_helpers")
fixture("minetest/common/vector")

_G.minetest.registered_nodes = {
	testnode1 = {},
	testnode2 = {},
}

_G.minetest.registered_chatcommands = {}

_G.minetest.register_lbm = noop
_G.minetest.register_abm = noop
_G.minetest.register_chatcommand = noop
_G.minetest.chat_send_player = noop
_G.minetest.register_alias = noop
_G.minetest.register_craftitem = noop
_G.minetest.register_craft = noop
_G.minetest.register_node = noop
_G.minetest.register_on_placenode = noop
_G.minetest.register_on_dignode = noop
_G.minetest.register_on_mods_loaded = noop
_G.minetest.item_drop = noop

_G.minetest.get_us_time = function()
	local socket = require 'socket'
	-- FIXME: Returns the time in seconds, relative to the origin of the universe.
	return socket.gettime() * 1000 * 1000
end

_G.minetest.get_node = function(pos)
	local hash = minetest.hash_node_position(pos)
	return world.nodes[hash] or {name="IGNORE",param2=0}
end

_G.minetest.get_modpath = function(...) return "./unit_test_modpath" end

_G.minetest.get_pointed_thing_position = dummy_coords

--
-- Minetest default noop table
--
local default = { __index = function(...) return function(...)end end }
_G.default = {}
setmetatable(_G.default, default)
