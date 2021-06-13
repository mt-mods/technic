local S = technic_cnc.getter

-- Define slope boxes for the various nodes
-------------------------------------------
technic_cnc.programs = {
	{ suffix  = "technic_cnc_stick",
		model = {-0.15, -0.5, -0.15, 0.15, 0.5, 0.15},
		desc  = S("Stick")
	},

	{ suffix  = "technic_cnc_element_end_double",
		model = {-0.3, -0.5, -0.3, 0.3, 0.5, 0.5},
		desc  = S("Element End Double")
	},

	{ suffix  = "technic_cnc_element_cross_double",
		model = {
			{0.3, -0.5, -0.3, 0.5, 0.5, 0.3},
			{-0.3, -0.5, -0.5, 0.3, 0.5, 0.5},
			{-0.5, -0.5, -0.3, -0.3, 0.5, 0.3}},
		desc  = S("Element Cross Double")
	},

	{ suffix  = "technic_cnc_element_t_double",
		model = {
			{-0.3, -0.5, -0.5, 0.3, 0.5, 0.3},
			{-0.5, -0.5, -0.3, -0.3, 0.5, 0.3},
			{0.3, -0.5, -0.3, 0.5, 0.5, 0.3}},
		desc  = S("Element T Double")
	},

	{ suffix  = "technic_cnc_element_edge_double",
		model = {
			{-0.3, -0.5, -0.5, 0.3, 0.5, 0.3},
			{-0.5, -0.5, -0.3, -0.3, 0.5, 0.3}},
		desc  = S("Element Edge Double")
	},

	{ suffix  = "technic_cnc_element_straight_double",
		model = {-0.3, -0.5, -0.5, 0.3, 0.5, 0.5},
		desc  = S("Element Straight Double")
	},

	{ suffix  = "technic_cnc_element_end",
		model = {-0.3, -0.5, -0.3, 0.3, 0, 0.5},
		desc  = S("Element End")
	},

	{ suffix  = "technic_cnc_element_cross",
		model = {
			{0.3, -0.5, -0.3, 0.5, 0, 0.3},
			{-0.3, -0.5, -0.5, 0.3, 0, 0.5},
			{-0.5, -0.5, -0.3, -0.3, 0, 0.3}},
		desc  = S("Element Cross")
	},

	{ suffix  = "technic_cnc_element_t",
		model = {
			{-0.3, -0.5, -0.5, 0.3, 0, 0.3},
			{-0.5, -0.5, -0.3, -0.3, 0, 0.3},
			{0.3, -0.5, -0.3, 0.5, 0, 0.3}},
		desc  = S("Element T")
	},

	{ suffix  = "technic_cnc_element_edge",
		model = {
			{-0.3, -0.5, -0.5, 0.3, 0, 0.3},
			{-0.5, -0.5, -0.3, -0.3, 0, 0.3}},
		desc  = S("Element Edge")
	},

	{ suffix  = "technic_cnc_element_straight",
		model = {-0.3, -0.5, -0.5, 0.3, 0, 0.5},
		desc  = S("Element Straight")
	},

	{ suffix  = "technic_cnc_oblate_spheroid",
		model = "technic_cnc_oblate_spheroid.obj",
		desc  = S("Oblate spheroid"),
		cbox  = {
			type = "fixed",
			fixed = {
				{ -6/16,  4/16, -6/16, 6/16,  8/16, 6/16 },
				{ -8/16, -4/16, -8/16, 8/16,  4/16, 8/16 },
				{ -6/16, -8/16, -6/16, 6/16, -4/16, 6/16 }
			}
		}
	},

	{ suffix  = "technic_cnc_sphere",
		model = "technic_cnc_sphere.obj",
		desc  = S("Sphere")
	},

	{ suffix  = "technic_cnc_cylinder_horizontal",
		model = "technic_cnc_cylinder_horizontal.obj",
		desc  = S("Horizontal Cylinder")
	},

	{ suffix  = "technic_cnc_cylinder",
		model = "technic_cnc_cylinder.obj",
		desc  = S("Cylinder")
	},

	{ suffix  = "technic_cnc_twocurvededge",
		model = "technic_cnc_two_curved_edge.obj",
		desc  = S("Two Curved Edge/Corner Block")
	},

	{ suffix  = "technic_cnc_onecurvededge",
		model = "technic_cnc_one_curved_edge.obj",
		desc  = S("One Curved Edge Block")
	},

	{ suffix  = "technic_cnc_spike",
		model = "technic_cnc_pyramid_spike.obj",
		desc  = S("Spike"),
		cbox    = {
			type = "fixed",
			fixed = {
				{ -2/16,  4/16, -2/16, 2/16,  8/16, 2/16 },
				{ -4/16,     0, -4/16, 4/16,  4/16, 4/16 },
				{ -6/16, -4/16, -6/16, 6/16,     0, 6/16 },
				{ -8/16, -8/16, -8/16, 8/16, -4/16, 8/16 }
			}
		}
	},

	{ suffix  = "technic_cnc_pyramid",
		model = "technic_cnc_pyramid.obj",
		desc  = S("Pyramid"),
		cbox  = {
			type = "fixed",
			fixed = {
				{ -2/16, -2/16, -2/16, 2/16,     0, 2/16 },
				{ -4/16, -4/16, -4/16, 4/16, -2/16, 4/16 },
				{ -6/16, -6/16, -6/16, 6/16, -4/16, 6/16 },
				{ -8/16, -8/16, -8/16, 8/16, -6/16, 8/16 }
			}
		}
	},

	{ suffix  = "technic_cnc_slope_inner_edge_upsdown",
		model = "technic_cnc_innercorner_upsdown.obj",
		desc  = S("Slope Upside Down Inner Edge/Corner"),
		sbox  = {
			type = "fixed",
			fixed = { -0.5, -0.5, -0.5, 0.5, 0.5, 0.5 }
		},
		cbox  = {
			type = "fixed",
			fixed = {
				{  0.25, -0.25, -0.5,  0.5, -0.5,   0.5  },
				{ -0.5,  -0.25,  0.25, 0.5, -0.5,   0.5  },
				{  0,     0,    -0.5,  0.5, -0.25,  0.5  },
				{ -0.5,   0,     0,    0.5, -0.25,  0.5  },
				{ -0.25,  0.25, -0.5,  0.5,  0,    -0.25 },
				{ -0.5,   0.25, -0.25, 0.5,  0,     0.5  },
				{ -0.5,   0.5,  -0.5,  0.5,  0.25,  0.5  }
			}
		}
	},

	{ suffix  = "technic_cnc_slope_edge_upsdown",
		model = "technic_cnc_outercorner_upsdown.obj",
		desc  = S("Slope Upside Down Outer Edge/Corner"),
		cbox  = {
			type = "fixed",
			fixed = {
				{ -8/16,  8/16, -8/16, 8/16,  4/16, 8/16 },
				{ -4/16,  4/16, -4/16, 8/16,     0, 8/16 },
				{     0,     0,     0, 8/16, -4/16, 8/16 },
				{  4/16, -4/16,  4/16, 8/16, -8/16, 8/16 }
			}
		}
	},

	{ suffix  = "technic_cnc_slope_inner_edge",
		model = "technic_cnc_innercorner.obj",
		desc  = S("Slope Inner Edge/Corner"),
		sbox  = {
			type = "fixed",
			fixed = { -0.5, -0.5, -0.5, 0.5, 0.5, 0.5 }
		},
		cbox  = {
			type = "fixed",
			fixed = {
				{ -0.5,  -0.5,  -0.5,  0.5, -0.25,  0.5  },
				{ -0.5,  -0.25, -0.25, 0.5,  0,     0.5  },
				{ -0.25, -0.25, -0.5,  0.5,  0,    -0.25 },
				{ -0.5,   0,     0,    0.5,  0.25,  0.5  },
				{  0,     0,    -0.5,  0.5,  0.25,  0.5  },
				{ -0.5,   0.25,  0.25, 0.5,  0.5,   0.5  },
				{  0.25,  0.25, -0.5,  0.5,  0.5,   0.5  }
			}
		}
	},

	{ suffix  = "technic_cnc_slope_edge",
		model = "technic_cnc_outercorner.obj",
		desc  = S("Slope Outer Edge/Corner"),
		cbox  = {
			type = "fixed",
			fixed = {
				{  4/16,  4/16,  4/16, 8/16,  8/16, 8/16 },
				{     0,     0,     0, 8/16,  4/16, 8/16 },
				{ -4/16, -4/16, -4/16, 8/16,     0, 8/16 },
				{ -8/16, -8/16, -8/16, 8/16, -4/16, 8/16 }
			}
		}
	},

	{ suffix  = "technic_cnc_slope_upsdown",
		model = "technic_cnc_slope_upsdown.obj",
		desc  = S("Slope Upside Down"),
		cbox  = {
			type = "fixed",
			fixed = {
				{ -8/16,  8/16, -8/16, 8/16,  4/16, 8/16 },
				{ -8/16,  4/16, -4/16, 8/16,     0, 8/16 },
				{ -8/16,     0,     0, 8/16, -4/16, 8/16 },
				{ -8/16, -4/16,  4/16, 8/16, -8/16, 8/16 }
			}
		}
	},

	{ suffix  = "technic_cnc_slope_lying",
		model = "technic_cnc_slope_horizontal.obj",
		desc  = S("Slope Lying"),
		cbox  = {
			type = "fixed",
			fixed = {
				{  4/16, -8/16,  4/16,  8/16, 8/16, 8/16 },
				{     0, -8/16,     0,  4/16, 8/16, 8/16 },
				{ -4/16, -8/16, -4/16,     0, 8/16, 8/16 },
				{ -8/16, -8/16, -8/16, -4/16, 8/16, 8/16 }
			}
		}
	},

	{ suffix  = "technic_cnc_slope",
		model = "technic_cnc_slope.obj",
		desc  = S("Slope"),
		cbox  = {
			type = "fixed",
			fixed = {
				{ -8/16,  4/16,  4/16, 8/16,  8/16, 8/16 },
				{ -8/16,     0,     0, 8/16,  4/16, 8/16 },
				{ -8/16, -4/16, -4/16, 8/16,     0, 8/16 },
				{ -8/16, -8/16, -8/16, 8/16, -4/16, 8/16 }
			}
		}
	},

}

-- Allow disabling certain programs for some node. Default is allowing all types for all nodes
technic_cnc.programs_disable = {
	-- ["default:brick"] = {"technic_cnc_stick"}, -- Example: Disallow the stick for brick
	["default:dirt"] = {
		"technic_cnc_oblate_spheroid",
		"technic_cnc_slope_upsdown",
		"technic_cnc_edge", "technic_cnc_inner_edge",
		"technic_cnc_slope_edge_upsdown",
		"technic_cnc_slope_inner_edge_upsdown",
		"technic_cnc_stick",
		"technic_cnc_cylinder_horizontal"
	}
}

-- TODO: These should be collected automatically through program registration function
-- Also technic_cnc.programs could be parsed and product lists created based on programs.
technic_cnc.onesize_products = {
	cylinder                 = 2,
	cylinder_horizontal      = 2,
	oblate_spheroid          = 1,
	onecurvededge            = 1,
	pyramid                  = 2,
	slope                    = 2,
	slope_edge               = 1,
	slope_edge_upsdown       = 1,
	slope_inner_edge         = 1,
	slope_inner_edge_upsdown = 1,
	slope_lying              = 2,
	slope_upsdown            = 2,
	sphere                   = 1,
	spike                    = 1,
	stick                    = 8,
	twocurvededge            = 1,
}

technic_cnc.twosize_products = {
	element_straight         = 2,
	element_end              = 2,
	element_cross            = 1,
	element_t                = 1,
	element_edge             = 2,
}

-- Lookup tables for all available programs, main use is to verify that requested product is available
technic_cnc.products = {}
for key, size in pairs(technic_cnc.onesize_products) do technic_cnc.products[key] = size end
for key, size in pairs(technic_cnc.twosize_products) do technic_cnc.products[key] = size end
