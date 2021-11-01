
local S = technic_cnc.getter

technic_cnc.register_all(
	"basic_materials:concrete_block",
	{cracky = 2, level = 2, not_in_creative_inventory = 1},
	{"basic_materials_concrete_block.png"},
	S("Concrete")
)

technic_cnc.register_all(
	"basic_materials:cement_block",
	{cracky = 2, level = 2, not_in_creative_inventory = 1},
	{"basic_materials_cement_block.png"},
	S("Cement")
)

technic_cnc.register_all(
	"basic_materials:brass_block",
	{cracky = 1, level = 2, not_in_creative_inventory = 1},
	{"basic_materials_brass_block.png"},
	S("Brass block")
)
