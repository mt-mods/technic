
fixture("minetest")

local players = {}

_G.minetest.check_player_privs = function(player_or_name, ...)
	local player_privs
	if type(player_or_name) == "table" then
		player_privs = player_or_name._privs
	else
		player_privs = players[player_or_name]._privs
	end
	local missing_privs = {}
	local has_priv = false
	local arg={...}
	for _,priv in ipairs(arg) do
		if player_privs[priv] then
			has_priv = true
		else
			table.insert(missing_privs, priv)
		end
	end
	return has_priv, missing_privs
end

_G.minetest.get_player_by_name = function(name)
	return players[name]
end

_G.Player = function(name, privs)
	local player = {
		_name = name or "SX",
		_privs = privs or { test_priv=1 },
		get_player_control = function(self)
			return {}
		end,
		get_player_name = function(self)
			return self._name
		end
	}
	table.insert(players, player)
	return player
end
