This file is fairly incomplete. Read the code if this is not enough. Help is welcome.

Tiers
-----
The tier is a string, currently `"LV"`, `"MV"` and `"HV"` are included with technic.

Network
-------
The network is the cable with the connected machine nodes. The switching station activates network.

Helper functions
----------------
* `technic.EU_string(num)`
	* Converts num to a human-readable string (see pretty_num)
	  and adds the `EU` unit
	* Use this function when showing players energy values
* `technic.pretty_num(num)`
	* Converts the number `num` to a human-readable string with SI prefixes
* `technic.swap_node(pos, nodename)`
	* Same as `mintest.swap_node` but it only changes the nodename.
	* It uses `minetest.get_node` before swapping to ensure the new nodename
	  is not the same as the current one.
* `technic.get_or_load_node(pos)`
	* If the mapblock is loaded, it returns the node at pos,
	  else it loads the chunk and returns `nil`.
* `technic.is_tier_cable(nodename, tier)`
	* Tells whether the node `nodename` is the cable of the tier `tier`.
* `technic.get_cable_tier(nodename)`
	* Returns the tier of the cable `nodename` or `nil`.
* `technic.trace_node_ray(pos, dir, range)`
	* Returns an iteration function (usable in the for loop) to iterate over the
	  node positions along the specified ray.
	* The returned positions will not include the starting position `pos`.
* `technic.trace_node_ray_fat(pos, dir, range)`
	* Like `technic.trace_node_ray` but includes extra positions near the ray.
	* The node ray functions are used for mining lasers.
* `technic.tube_inject_item(pos, start_pos, velocity, item)`
	* Same as `pipeworks.tube_inject_item`

Configuration API
----------------------
* `technic.config` Settings object that contains Technic configuration.
	* Provides all methods that are provided by Minetest Settings object.
	* Uses `<world-path>/technic.conf` as configuration file.
	* If key is not present in configuration then returns default value for that key.
	* `:get_int(key)` Return number value for configuration key.

Power tool API
----------------------

* `technic.register_power_tool(itemname, definition)`
	* Registers power tool adding required fields, otherwise same as `minetest.register_tool(itemname, definition)`.
	* For regular power tools you only want to change `max_charge` and leave other fields unset (defaults).
	* Special fields for `definition`:
		* `technic_max_charge` Number, maximum charge for tool. Defaults to `10000` which is same as RE battery.
		* `on_refill` Function to refill charge completely. Default is to set maximum charge for tool.
		* `wear_represents` Customize wear indicator instead of using charge level. Default is `"technic_RE_charge"`.
		* `tool_capabilities` See Minetest documentation. Default is `{ punch_attack_uses = 0 }`.
		* `technic_get_charge = function(itemstack) ...`
			* This optional callback will be used to get itemstack charge and max\_charge
			* Have to return values `charge, max_charge`
			* Etc. `local charge, maxcharge = itemdef.technic_get_charge(itemstack)`
		* `technic_set_charge = function(itemstack, charge) ...`
			* This optional callback will be used to set itemstack charge
* `technic.get_RE_charge(itemstack)`
	* Returns current charge level of tool
* `technic.set_RE_charge(itemstack, charge)`
	* Sets tool charge level.
* `technic.use_RE_charge(itemstack, charge)`
	* Attempt to use charge and return `true`/`false` indicating success.
	* Always succeeds without checking charge level if creative is enabled.

Machine registration API
----------------------
* `technic.register_machine(tier, nodename, machine_type)`
	* Custom machine registration. Not needed when using builtin machine registration functions.
	* See also `Machine types`
* `technic.register_tier(tier)`
	* Registers network tier.
	* See also `tiers`
* `technic.register_base_machine(nodename, def)`
	* Register various types of basic factory processing machines.
	* `typename = "compressing"`
	* `description = S("%s Compressor")`
	* `tier = "HV"`
	* `demand = {1500, 1000, 750}`
	* `speed = 5`
	* `upgrade = 1`
	* `tube = 1`
	* TODO / TBD
* `technic.register_solar_array(nodename, def)`
	* Registers solar array generator.
	* `tier = "HV"`
	* `power = 100`
	* TODO / TBD
* `technic.register_battery_box(nodename, def)`
	* Registers battery box node used as energy storage.
	* TODO / TBD
* `technic.register_cable(nodename, data)`
	* Registers technic network cables.
	* `tier = "HV"`
	* `size = 3/16`
	* `description = S("%s Digiline Cable"):format("HV")`
	* `digiline = { wire = { rules = technic.digilines.rules_allfaces } }`
* `technic.register_cable_plate(nodename, data)`
	* Registers technic network cable plates. Results in multiple nodes registered with `_1` to `_6` appended to name.
	* See `technic.register_cable(nodename, data)`

Network control API
----------------------
* TBD, functions exported through technic namespace are currently considered to be internal use only.

### Specific machines
* `technic.can_insert_unique_stack(pos, node, stack, direction)`
* `technic.insert_object_unique_stack(pos, node, stack, direction)`
	* Functions for the parameters `can_insert` and `insert_object` to avoid
		filling multiple inventory slots with same type of item.

Used itemdef fields
----------------------
* groups:
	* `technic_<ltier> = 1` ltier is a tier in small letters; this group makes
	  the node connect to the cable(s) of the right tier.
	* `technic_machine = 1` Currently used for
* `connect_sides`
	* In addition to the default use (see lua_api.txt), this tells where the
	  machine can be connected.
* `technic_run(pos, node)`
	* This function is currently used to update the node.
* `wear_represents = "string"`
	* Specifies how the tool wear level is handled. Available modes:
		* `"mechanical_wear"`: represents physical damage
		* `"technic_RE_charge"`: represents electrical charge
* `<itemdef>.technic_run = function(pos, node) ...`
	* This callback is used to update the node.
* `<itemdef>.technic_disabled_machine_name = "string"`
	* Specifies the machine's node name to use when it's not connected connected to a network
* `<itemdef>.technic_on_disable = function(pos, node) ...`
	* This callback is run when the machine is no longer connected to a technic-powered network.

Machine types
-------------
There are currently following types:
* `technic.receiver = "RE"` e.g. grinder
* `technic.producer = "PR"` e.g. solar panel
* `technic.producer_receiver = "PR_RE"` supply converter
* `technic.battery  = "BA"` e.g. LV batbox

Switching Station
-----------------
The switching station is required to start electric network and keep it running.
Unlike in original mod this node does not handle power distribution logic but instead just resets network timeout.

Network logic
-----------------

The network logic collects power from sources (PR), distributes it to sinks (RE),
and uses the excess/shortfall to charge and discharge batteries (BA).

For now, all supply and demand values are expressed in kW.

All the RE nodes are queried for their current EU demand. Those which are off would
require no or a small standby EU demand, while those which are on would require more.
If total demand is less than the available power they are all updated with the demand number.
If any surplus exists from the PR nodes the batteries will be charged evenly with excess power.
If total demand exceeds generator supply then draw difference from batteries.
If total demand is more than available power all RE nodes will be shut down.

### Node meta usage
Nodes connected to the network will have one or more of these parameters as meta data:
* `<LV|MV|HV>_EU_supply` : Exists for PR and BA node types. This is the EU value supplied by the node. Output
* `<LV|MV|HV>_EU_demand` : Exists for RE and BA node types. This is the EU value the node requires to run. Output
* `<LV|MV|HV>_EU_input`  : Exists for RE and BA node types. This is the actual EU value the network can give the node. Input

The reason the LV|MV|HV type is prepended to meta data is because some machine
could require several supplies to work.
This way the supplies are separated per network.
