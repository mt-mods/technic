require("mineunit")

-- Load complete technic mod
fixture("technic")
sourcefile("init")

describe("Chat command", function()

	-- Execute on mods loaded callbacks to finish loading.
	mineunit:mods_loaded()
	-- Tell mods that 1 minute passed already to execute all weird core.after hacks.
	mineunit:execute_globalstep(60)

	world.set_default_node("air")
	world.layout({
		-- Simple test network to grab stats from
		{{x=0,y=51,z=2}, "technic:hv_generator"},
		{{{x=0,y=50,z=2},{x=1,y=50,z=2}}, "technic:hv_cable"},
	})
	-- Use place_node for switching station to fire node initialization
	world.place_node({x=1,y=51,z=2}, "technic:switching_station")

	local M = function(s) return require("luassert.match").matches(s) end
	local ANY = require("luassert.match")._

	local technic_admin_priv = technic.config:get("admin_priv")
	-- Players, one with admin privs and another without
	local SX = Player("SX", { shout = 1,  interact = 1, [technic_admin_priv] = 1 })
	local Sam = Player("Sam", { shout = 1,  interact = 1 })
	-- Matching multiple missing privileges is vague here, important thing is that access gets denied
	local MISSING_ADMIN_PRIV_MATCHER = M("missing privileges: "..technic_admin_priv)

	setup(function()
		mineunit:execute_on_joinplayer(SX)
		mineunit:execute_on_joinplayer(Sam)
	end)

	teardown(function()
		mineunit:execute_on_leaveplayer(Sam)
		mineunit:execute_on_leaveplayer(SX)
	end)

	local function it_allows_chat_command(chatcommand, callback)
		return it("allows "..chatcommand, function()
			spy.on(core, "chat_send_player")
			SX:send_chat_message(chatcommand)
			assert.spy(core.chat_send_player).not_called_with("SX", MISSING_ADMIN_PRIV_MATCHER)
			return callback()
		end)
	end

	local function it_denies_chat_command(chatcommand, callback)
		return it("denies "..chatcommand, function()
			spy.on(core, "chat_send_player")
			Sam:send_chat_message(chatcommand)
			assert.spy(core.chat_send_player).called_with("Sam", MISSING_ADMIN_PRIV_MATCHER)
			return callback()
		end)
	end

	-- Commands denied without admin privilege

	it_denies_chat_command("/powerctrl off", function()
		assert.spy(core.chat_send_player).not_called_with("Sam", M("globalstep disabled"))
		assert.is_true(technic.powerctrl_state)
	end)

	it_denies_chat_command("/powerctrl on", function()
		assert.spy(core.chat_send_player).not_called_with("Sam", M("globalstep enabled"))
		assert.is_true(technic.powerctrl_state)
	end)

	it_denies_chat_command("/technic_get_active_networks", function()
		assert.spy(core.chat_send_player).not_called_with("Sam", M("%d+ %D*active"))
	end)

	it_denies_chat_command("/technic_flush_switch_cache", function() end)

	it_denies_chat_command("/technic_clear_network_data", function() end)

	-- Commands allowed with admin privilege

	it_allows_chat_command("/powerctrl", function()
		assert.spy(core.chat_send_player).called_with("SX", M("globalstep enabled"))
		assert.is_true(technic.powerctrl_state)
	end)

	it_allows_chat_command("/powerctrl off", function()
		assert.spy(core.chat_send_player).called_with("SX", M("globalstep disabled"))
		assert.is_false(technic.powerctrl_state)
	end)

	it_allows_chat_command("/powerctrl on", function()
		assert.spy(core.chat_send_player).called_with("SX", M("globalstep enabled"))
		assert.is_true(technic.powerctrl_state)
	end)

	it_allows_chat_command("/technic_get_active_networks", function()
		assert.spy(core.chat_send_player).called_with("SX", M("%d+ %D*active"))
		assert.spy(core.chat_send_player).called_with("SX", M("%d+ %D*total"))
		assert.spy(core.chat_send_player).called_with("SX", M("%d+ %D*nodes"))
		assert.spy(core.chat_send_player).called_with("SX", M("%d+%.?%d* %D*lag"))
	end)

	it_allows_chat_command("/technic_flush_switch_cache", function()
		assert.spy(core.chat_send_player).not_called_with("SX", MISSING_ADMIN_PRIV_MATCHER)
	end)

	it_allows_chat_command("/technic_clear_network_data", function()
		assert.spy(core.chat_send_player).not_called_with("SX", MISSING_ADMIN_PRIV_MATCHER)
	end)

end)
