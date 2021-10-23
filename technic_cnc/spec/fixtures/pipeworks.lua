
mineunit:set_modpath("pipeworks", "spec/fixtures")

_G.pipeworks = {
	fs_helpers = {
		cycling_button = function(...) return "" end,
	},
	-- Direct calls to may_configure causes unnecessary protection messages with public machines
	string_startswith = function(s, a) return s:sub(1,#a) == a end,
	may_configure = function() error("Incorrectly wrapped call to pipeworks.may_configure") end,
}
