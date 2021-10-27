mineunit:set_modpath("pipeworks", "spec/fixtures")

_G.pipeworks = {}
_G.pipeworks.button_label = ""
_G.pipeworks.fs_helpers = {}
_G.pipeworks.fs_helpers.cycling_button = function(...) return "" end

_G.pipeworks = setmetatable(_G.pipeworks, {
	__call = function(self,...) return self end,
	__index = function(...) return function(...)end end,
})
