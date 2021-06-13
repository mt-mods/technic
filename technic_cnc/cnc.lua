-- Technic CNC v2.0 by SX
-- Based on Technic CNC v1.0 by kpoppel
-- Based on the NonCubic Blocks MOD v1.4 by yves_de_beck

local S = technic_cnc.getter

-- This should handle both onesize_products and twosize_products, currently
-- twosize_products are hardcoded for formspec definitions.
local programs = {}
for key,_ in pairs(technic_cnc.onesize_products) do table.insert(programs, key) end
table.sort(programs)

--
-- Register technic:cnc machine
--
do
	technic_cnc.register_cnc_machine("technic:cnc", {
		description = technic_cnc.use_technic and S("LV CNC Machine") or S("CNC Machine"),
		output_size = 4,
		programs = programs,
		demand = 450,
		recipe = technic_cnc.use_technic and ({
			{'default:glass',              'technic:diamond_drill_head', 'default:glass'},
			{'technic:control_logic_unit', 'technic:machine_casing',     'basic_materials:motor'},
			{'technic:carbon_steel_ingot', 'technic:lv_cable',           'technic:carbon_steel_ingot'},
		}) or ({
			{'default:glass',       'default:diamond',    'default:glass'},
			{'basic_materials:ic',  'default:steelblock', 'basic_materials:motor'},
			{'default:steel_ingot', 'default:mese',       'default:steel_ingot'},
		}),
		tiles = {
			"technic_cnc_top.png", "technic_cnc_bottom.png", "technic_cnc_side.png",
			"technic_cnc_side.png", "technic_cnc_side.png", "technic_cnc_front.png"
		},
		tiles_active = {
			"technic_cnc_top_active.png", "technic_cnc_bottom.png", "technic_cnc_side.png",
			"technic_cnc_side.png", "technic_cnc_side.png", "technic_cnc_front_active.png"
		},
	})
end

--
-- Register technic:cnc_mk2 machine
--
if technic_cnc.use_technic or technic_cnc.pipeworks or technic_cnc.digilines then
	local tiles = {
		"technic_cnc_mk2_top.png", "technic_cnc_bottom.png", "technic_cnc_mk2_side.png",
		"technic_cnc_mk2_side.png", "technic_cnc_mk2_side.png", "technic_cnc_mk2_front.png"
	}
	local tiles_active = {
		"technic_cnc_mk2_top_active.png", "technic_cnc_bottom.png", "technic_cnc_mk2_side.png",
		"technic_cnc_mk2_side.png", "technic_cnc_mk2_side.png", "technic_cnc_mk2_front_active.png"
	}
	if technic_cnc.pipeworks then
		tiles = technic_cnc.pipeworks.tube_entry_overlay(tiles)
		tiles_active = technic_cnc.pipeworks.tube_entry_overlay(tiles_active)
	end
	technic_cnc.register_cnc_machine("technic:cnc_mk2", {
		description = S("LV CNC Machine") .. " Mk2",
		output_size = 4,
		digilines = technic_cnc.digilines,
		upgrade = true,
		tube = technic_cnc.pipeworks and technic_cnc.pipeworks.new_tube() or nil,
		programs = programs,
		demand = 900,
		recipe = {
			{'basic_materials:ic', 'technic:cnc',                 'basic_materials:ic'},
			{'pipeworks:tube_1',   'technic:machine_casing',      'pipeworks:tube_1'},
			{'technic:cnc',        'digilines:wire_std_00000000', 'technic:cnc'},
		},
		tiles = tiles,
		tiles_active = tiles_active,
	})
end
