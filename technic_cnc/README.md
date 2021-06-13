Technic CNC
-----------------

Provides CNC machines that allow cutting nodes to selected shapes.

![luacheck](https://github.com/mt-mods/technic/workflows/luacheck/badge.svg)
![mineunit](https://github.com/mt-mods/technic/workflows/mineunit/badge.svg)
![](https://byob.yarr.is/mt-mods/technic/coverage-cnc)

# Machines

### LV CNC Machine (technic:cnc)

* Manufactures different shapes from provided raw materials.
* Manufactures products over time if technic is enabled.
* Manufactures products immediately when selecting program if technic is not enabled.
* 1 inventory slot for input materials, 4 inventory slots for products.

### LV CNC Machine Mk2 (technic:cnc_mk2)

* All features provided by technic:cnc
* Only available if technic, digilines or pipeworks is available.
* Has digiline API for programming, enabling, disabling, getting status and getting programs.
* Can use technic upgrades for energy saving (RE battery), auto eject (CLU), and public use (chest).
* Has support for pipeworks tubes for receiving raw materials or taking products using filter injectors.

# Configuration (minetest.conf)

| Configuration key           | Default     | Description
|-----------------------------|-------------|--------------------------------------------------------------------------|
| technic_cnc_use_technic     | true        | Use technic power networks and upgrades, machines require LV network     |
| technic_cnc_use_digilines   | true        | Use digilines to allow configuring machines using digiline messages      |
| technic_cnc_use_pipeworks   | true        | Use pipeworks for tube and injector support                              |

# Digilines (technic:cnc_mk2)

### Simple commands, type: string

| Command           | Description
|-------------------|--------------------------------------------------------------------------------------------------|
| enable            | Enables machines, machine will attempt manufacturing products if materials are available         |
| disable           | Disables machines, machine will stop manufacturing and will not consume power                    |
| programs          | Machine will send table containing all possible programs as keys and product count as values     |
| status            | Machine will send table with following keys: enabled, time, size, program, user, material        |

Example reply for `programs` command:
```lua
{
	element_end = 2,
	slope_inner_edge = 1,
	twocurvededge = 1,
	cylinder = 2,
	stick = 8,
	spike = 1,
	element_cross = 1,
	slope_edge_upsdown = 1,
	cylinder_horizontal = 2,
	element_edge = 2,
	oblate_spheroid = 1,
	slope = 2,
	slope_lying = 2,
	slope_inner_edge_upsdown = 1,
	sphere = 1,
	element_straight = 2,
	slope_upsdown = 2,
	pyramid = 2,
	element_t = 1,
	onecurvededge = 1,
	slope_edge = 1
}
```

Example reply for `status` command:
```lua
{
	enabled = true,
	time = 2,
	user = "SX",
	material = {
		count = 98,
		name = "default:desert_sandstone",
	},
	program = "sphere",
	size = 2
}
```

### Complex commands, type: table

Command can contain any combination of keys and will affect only relevant parts of functionality.

Example with all possible keys set:

```lua
{
	program = "sphere",
	size = 2,
	enabled = true
}
```

Value for `program` should be one of keys returned by simple command `programs`, it will change CNC program.

Value for `size` should be number `1` or `2`, other numbers or types are not acceppted. Sets size of programs that can
produce both half and full sized nodes. `2` is for half size and `1` for full size products.

Value for `ènabled` should be `true` or `false`. Functions similar to simple string commands `enable` and `disable`.

Invalid values or value types are simply skipped and not used, check your value types
and keys for typos if it seems that machine accepts commands only partially.

# Technic CNC API for extensions

API is incomplete, feel free to give suggestions for functionality or other feedback about CNC API.

### CNC material, program and product extension API:

*Currently undetermined / to be determined.*

### CNC machine control and manufacturing API:
```lua
-- Get product item string with count for given program, material and size
-- Return value example: default:desert_sandstone_technic_cnc_stick 8
function technic_cnc.get_product(program, material, size)

-- Set program for cnc machine with optional size, size is not changed if size is nil
function technic_cnc.set_program(meta, program, size)

-- Returns true if CNC machine is enabled and false if machine is disabled
function technic_cnc.is_enabled(meta) -- return true|false

-- Enables CNC machine
function technic_cnc.enable(meta)

-- Disables CNC machine
function technic_cnc.disable(meta)

-- Finds first input stack with items
function technic_cnc.get_material(inventory)

-- Manufacture product based on current program.
-- Updates src and dst inventories taking required amount from src inventory and placing products into dst inventory
function technic_cnc.produce(meta, inventory)
```

### Register new CNC machine defined by your mod:
```lua
-- Textures for machine
local tiles = {
	"my_mod_my_cnc_machine_top.png",
	"my_mod_my_cnc_machine_bottom.png",
	"my_mod_my_cnc_machine_right.png",
	"my_mod_my_cnc_machine_left.png",
	"my_mod_my_cnc_machine_back.png",
	"my_mod_my_cnc_machine_front.png"
}
local tiles_active = {
	"my_mod_my_cnc_machine_top_active.png",
	"my_mod_my_cnc_machine_bottom_active.png",
	"my_mod_my_cnc_machine_right_active.png",
	"my_mod_my_cnc_machine_left_active.png",
	"my_mod_my_cnc_machine_back_active.png",
	"my_mod_my_cnc_machine_front_active.png"
}

--
-- Add pipeworks tube connection with overlay textures if pipeworks is available for CNC machines
--
local tube_def = nil
if technic_cnc.pipeworks then
	tiles = technic_cnc.pipeworks.tube_entry_overlay(tiles)
	tiles_active = technic_cnc.pipeworks.tube_entry_overlay(tiles_active)
	tube_def = technic_cnc.pipeworks.new_tube()
end

--
-- Default values provided with example machine registration below.
--
-- Required definition keys that do not have default value:
--   description, programs, demand
-- Optional definition keys that do not have default value:
--   recipe, upgrade, digilines, tube
--
technic_cnc.register_cnc_machine("my_mod_name:my_cnc_machine", {
	description = "My Mod - My CNC Machine",
	input_size = 1,
	output_size = 4,
	digilines = technic_cnc.digilines,
	upgrade = true,
	tube = tube_def,
	programs = { "sphere", "spike", "stick", "slope" },
	demand = 539,
	get_formspec = technic_cnc.formspec.get_formspec,
	on_receive_fields = technic_cnc.formspec.on_receive_fields,
	recipe = {
		{'default:glass',      'default:glass',   'default:glass'},
		{'default:steelblock', 'default:diamond', 'default:steelblock'},
		{'default:steelblock', '',                'default:steelblock'},
	},
	tiles = tiles,
	tiles_active = tiles_active,
})
```
