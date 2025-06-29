
local mei = fluidity.external.items
local S = core.get_translator("melterns")

-- Set the tool times keeping in mind that in Minetest Game-style groups, the lower level breaks slower.
-- AKA weaker blocks are a higher level (cracky = 3 is just like basic stone)
-- BUT in MCL, cracky = 3 would be pickaxey = 1 - the "times" array will be reversed!!
local modifiers = {
	flint = {
		cracky = {times={[1]=3.60, [2]=2.50, [3]=1.00}, uses=5, maxlevel=1},
		crumbly = {times={[1]=4.00, [2]=2.30, [3]=1.20}, uses=5, maxlevel=1},
		snappy = {times={[1]=3.80, [2]=1.30, [3]=1.00}, uses=5, maxlevel=1},
		choppy = {times={[1]=3.70, [2]=2.40, [3]=1.00}, uses=5, maxlevel=1},
		damagegroups = {fleshy = 1},
		explody = nil,

		binding = {increase = 0.00, uses = 0},
		rod = {increase = 0.00, uses = 0},
		tags = {
			{name = "cheap", description = S("Cheap")}
		}
	},
	wood = {
		cracky = {times={[1]=4.50, [2]=2.20, [3]=1.00}, uses=10, maxlevel=1},
		crumbly = {times={[1]=4.80, [2]=2.40, [3]=1.00}, uses=10, maxlevel=1},
		snappy = {times={[1]=4.60, [2]=2.40, [3]=0.80}, uses=10, maxlevel=1},
		choppy = {times={[1]=4.80, [2]=2.40, [3]=1.20}, uses=10, maxlevel=1},
		damagegroups = {fleshy = 2},
		explody = nil,

		binding = {increase = 0.00, uses = 0},
		rod = {increase = 0.00, uses = 0},
		tags = {
			{name = "cheap", description = S("Cheap")},
			{name = "wooden", description = S("Wooden")}
		}
	},
	stone = {
		cracky = {times={[1]=4.10, [2]=2.00, [3]=1.00}, uses=20, maxlevel=1},
		crumbly = {times={[1]=4.10, [2]=1.60, [3]=0.50}, uses=20, maxlevel=1},
		snappy = {times={[1]=3.80, [2]=1.40, [3]=0.40}, uses=20, maxlevel=1},
		choppy = {times={[1]=3.80, [2]=2.00, [3]=1.30}, uses=20, maxlevel=1},
		damagegroups = {fleshy = 4},
		explody = nil,

		binding = {increase = 0.02, uses = -1},
		rod = {increase = 0.02, uses = -1},
		tags = {
			{name = "economic", description = S("Economic")},
			{name = "stonebound", description = S("Stonebound")}
		}
	},
	steel = {
		cracky = {times={[1]=4.00, [2]=1.60, [3]=0.80, [4]=0.70}, uses=20, maxlevel=2},
		crumbly = {times={[1]=1.50, [2]=0.90, [3]=0.40, [4]=0.30}, uses=30, maxlevel=2},
		snappy = {times={[1]=2.50, [2]=1.20, [3]=0.35, [4]=0.30}, uses=30, maxlevel=2},
		choppy = {times={[1]=2.50, [2]=1.40, [3]=1.00, [4]=0.90}, uses=20, maxlevel=2},
		damagegroups = {fleshy = 6},
		explody = nil,

		binding = {increase = -0.02, uses = 3},
		rod = {increase = -0.02, uses = 5},
		tags = {
			{name = "economic", description = S("Economic")},
			{name = "metal", description = S("Metallic")}
		}
	},
	copper = {
		cracky = {times={[1]=3.80, [2]=1.50, [3]=0.85, [4]=0.75}, uses=20, maxlevel=2},
		crumbly = {times={[1]=1.30, [2]=0.80, [3]=0.45, [4]=0.35}, uses=30, maxlevel=2},
		snappy = {times={[1]=2.30, [2]=1.10, [3]=0.35, [4]=0.35}, uses=30, maxlevel=2},
		choppy = {times={[1]=2.30, [2]=1.30, [3]=0.95, [4]=0.95}, uses=20, maxlevel=2},
		damagegroups = {fleshy = 5},
		explody = nil,

		binding = {increase = 0.02, uses = 3},
		rod = {increase = 0.03, uses = 5},
		tags = {
			{name = "cold", description = S("Cold")}
		}
	},
	tin = {
		cracky = {times={[1]=3.00, [2]=1.50, [3]=0.80}, uses=20, maxlevel=2},
		crumbly = {times={[1]=2.80, [2]=1.40, [3]=0.80}, uses=30, maxlevel=2},
		snappy = {times={[1]=2.50, [2]=1.00, [3]=0.80}, uses=30, maxlevel=2},
		choppy = {times={[1]=2.60, [2]=1.20, [3]=1.00}, uses=20, maxlevel=2},
		damagegroups = {fleshy = 5},
		explody = nil,

		binding = {increase = 0.05, uses = -2},
		rod = {increase = 0.05, uses = -3},
		tags = {
			{name = "cheap", description = S("Cheap")}
		}
	},
	bronze = {
		cracky = {times={[1]=3.00, [2]=1.60, [3]=0.80}, uses=30, maxlevel=2},
		crumbly = {times={[1]=2.50, [2]=0.90, [3]=0.40}, uses=40, maxlevel=2},
		snappy = {times={[1]=2.50, [2]=1.20, [3]=0.80}, uses=40, maxlevel=2},
		choppy = {times={[1]=2.50, [2]=1.40, [3]=1.00}, uses=30, maxlevel=2},
		damagegroups = {fleshy = 6},
		explody = nil,

		binding = {increase = -0.01, uses = 2},
		rod = {increase = -0.01, uses = 10},
		tags = {}
	},
	mese = {
		cracky = {times={[1]=2.40, [2]=1.20, [3]=0.60}, uses=20, maxlevel=3},
		crumbly = {times={[1]=2.00, [2]=0.60, [3]=0.30}, uses=20, maxlevel=3},
		snappy = {times={[1]=2.00, [2]=1.00, [3]=0.35}, uses=30, maxlevel=3},
		choppy = {times={[1]=2.20, [2]=1.00, [3]=0.60}, uses=20, maxlevel=3},
		damagegroups = {fleshy = 7},
		explody = nil,

		binding = {increase = -0.05, uses = 10},
		rod = {increase = 0.00, uses = 10},
		tags = {
			{name = "gem", description = S("Precious")},
			{name = "expensive", description = S("Expensive")}
		}
	},
	gold = {
		cracky = {times={[1]=2.40, [2]=1.50, [3]=0.30}, uses=18, maxlevel=3},
		crumbly = {times={[1]=2.20, [2]=1.80, [3]=0.20}, uses=18, maxlevel=3},
		snappy = {times={[1]=2.00, [2]=1.60, [3]=0.25}, uses=18, maxlevel=3},
		choppy = {times={[1]=2.00, [2]=1.40, [3]=0.30}, uses=18, maxlevel=3},
		damagegroups = {fleshy = 6},
		explody = nil,

		binding = {increase = -0.07, uses = -10},
		rod = {increase = -0.01, uses = -5},
		tags = {
			{name = "shiny", description = S("Shiny")},
			{name = "soft", description = S("Soft")}
		}
	},
	obsidian = {
		cracky = {times={[1]=2.30, [2]=1.00, [3]=0.80, [4]=0.60, [5]=0.40}, uses=30, maxlevel=3},
		crumbly = {times={[1]=1.80, [2]=0.80, [3]=0.60, [4]=0.50, [5]=0.35}, uses=30, maxlevel=3},
		snappy = {times={[1]=1.85, [2]=0.85, [3]=0.60, [4]=0.50, [5]=0.35}, uses=40, maxlevel=3},
		choppy = {times={[1]=2.00, [2]=0.85, [3]=0.70, [4]=0.55, [5]=0.40}, uses=30, maxlevel=3},
		damagegroups = {fleshy = 6},
		explody = nil,

		binding = {increase = 0.02, uses = 15},
		rod = {increase = -0.02, uses = 5},
		tags = {
			{name = "reinforced", description = S("Reinforced")}
		}
	},
	lead = {
		cracky = {times={[1]=3.70, [2]=1.30, [3]=0.60, [4]=0.50}, uses=20, maxlevel=3},
		crumbly = {times={[1]=2.40, [2]=0.60, [3]=0.60, [4]=0.50}, uses=30, maxlevel=3},
		snappy = {times={[1]=2.20, [2]=1.00, [3]=0.60, [4]=0.50}, uses=30, maxlevel=3},
		choppy = {times={[1]=2.20, [2]=1.20, [3]=0.60, [4]=0.50}, uses=20, maxlevel=3},
		damagegroups = {fleshy = 7},
		explody = nil,

		binding = {increase = 0.10, uses = 1},
		rod = {increase = 0.05, uses = -5},
		tags = {
			{name = "toxic", description = S("Toxic")}
		}
	},
	chromium = {
		-- TODO: tweak
		cracky = {times={[1]=3.70, [2]=1.30, [3]=0.60, [4]=0.50}, uses=20, maxlevel=3},
		crumbly = {times={[1]=2.40, [2]=1.20, [3]=0.60, [4]=0.40}, uses=30, maxlevel=3},
		snappy = {times={[1]=2.20, [2]=1.20, [3]=0.60, [4]=0.50}, uses=30, maxlevel=3},
		choppy = {times={[1]=2.20, [2]=1.20, [3]=0.60, [4]=0.50}, uses=20, maxlevel=3},
		damagegroups = {fleshy = 5},
		explody = nil,

		binding = {increase = 0.15, uses = 1},
		rod = {increase = -0.05, uses = 2},
		tags = {
			{name = "shiny", description = S("Shiny")}
		}
	},
	zinc = {
		-- TODO: tweak
		cracky = {times={[1]=3.70, [2]=1.30, [3]=0.60}, uses=20, maxlevel = 2},
		crumbly = {times={[1]=1.20, [2]=0.60, [3]=0.40}, uses=30, maxlevel = 2},
		snappy = {times={[1]=2.20, [2]=1.00, [3]=0.40}, uses=30, maxlevel = 2},
		choppy = {times={[1]=2.20, [2]=1.20, [3]=0.60}, uses=20, maxlevel = 2},
		damagegroups = {fleshy = 5},
		explody = nil,

		binding = {increase = -0.05, uses = 1},
		rod = {increase = -0.05, uses = 2},
		tags = {
			{name = "metal", description = S("Metallic")}
		}
	},
	silver = {
		cracky = {times = {[1] = 2.60, [2] = 1.00, [3] = 0.60, [4] = 0.30}, uses = 30, maxlevel = 2},
		crumbly = {times = {[1] = 2.00, [2] = 1.00, [3] = 0.40, [4] = 0.30}, uses = 30, maxlevel = 2},
		snappy = {times = {[1] = 2.00, [2] = 0.80, [3] = 0.60, [4] = 0.40}, uses = 30, maxlevel = 2},
		choppy = {times = {[1] = 2.50, [2] = 0.80, [3] = 0.50, [4] = 0.30}, uses = 30, maxlevel = 2},
		damagegroups = {fleshy = 6},
		explody = nil,

		binding = {increase = -0.05, uses = 10},
		rod = {increase = -0.05, uses = 10},
		tags = {
			{name = "durable", description = S("Durable")},
			{name = "shiny", description = S("Shiny")}
		}
	},
	mithril = {
		cracky = {times = {[1] = 3.00, [2] = 1.60, [3] = 0.60, [4] = 0.50}, uses = 40, maxlevel = 3},
		crumbly = {times = {[1] = 2.80, [2] = 1.50, [3] = 1.00, [4] = 0.60}, uses = 40, maxlevel = 3},
		snappy = {times = {[1] = 3.00, [2] = 2.60, [3] = 1.25, [4] = 0.60}, uses = 40, maxlevel = 3},
		choppy = {times = {[1] = 2.00, [2] = 1.45, [3] = 0.60, [4] = 0.45}, uses = 40, maxlevel = 3},
		damagegroups = {fleshy = 9},
		explody = nil,

		binding = {increase = 0.05, uses = 15},
		rod = {increase = -0.05, uses = 15, damage = {fleshy = 8}},
		tags = {
			{name = "durable", description = S("Durable")},
			{name = "lethal", description = S("Lethal")}
		}
	},
	-- Modifier items
	diamond = {
		uses = 20,
		increase = -0.20,
		count = 1,
		maxlevel = 3,
		damagegroups = {fleshy = 8},
		tags = {
			{name = "diamond", description = S("Diamond")}
		}
	},
	-- Templates
	default_item = {
		cracky = {}, -- Pickaxe
		crumbly = {}, -- Shovel
		snappy = {}, -- Sword
		choppy = {}, -- Axe
		damagegroups = {fleshy = 0}, -- Sword damage
		explody = nil, -- Explody group

		-- Binding specifications
		binding = {
			increase = 0.00, -- Increase in `times`. Divided by group number.
			uses = 0, -- Base uses increase
			damage = {fleshy = 8} -- Sets the damagegroups to this value.
		},
		
		-- Rod specifications, same format as binding
		rod = {},

		-- Tags added to this tool
		tags = {}
	},
	default_modifier = {
		uses = 0, -- Base uses increase
		increase = 0.00, -- Times increase. Divided by group number.
		count = 1, -- How many times this modifier can be applied
		damage = {fleshy = 8}, -- Sets the damagegroups to this value.
		
		-- Tags added to this tool
		tags = {}
	}
}

tinkering.materials = {
	-- Materials
	flint    = {name = S("Flint"),    default = mei.flint,       color = "#514E49", base = "item",               modifier = modifiers.flint},
	wood     = {name = S("Wood"),     default = mei.group_wood,  color = "#634623", base = "group",              modifier = modifiers.wood},
	stone    = {name = S("Stone"),    default = mei.group_stone, color = "#8D8988", base = "group",              modifier = modifiers.stone},
	obsidian = {name = S("Obsidian"),                            color = "#2C384E", base = "node",  cast = true, modifier = modifiers.obsidian},

	-- Metals
	steel  = {name = S("Steel"),  color = "#FFF",    base = "ingot", cast = true, modifier = modifiers.steel},
	copper = {name = S("Copper"), color = "#E87945", base = "ingot", cast = true, modifier = modifiers.copper},
	tin    = {name = S("Tin"),    color = "#C1C1C1", base = "ingot", cast = true, modifier = modifiers.tin},
	bronze = {name = S("Bronze"), color = "#C14E19", base = "ingot", cast = true, modifier = modifiers.bronze},
	gold   = {name = S("Gold"),   color = "#FFFF54", base = "ingot", cast = true, modifier = modifiers.gold},
	mese   = {name = S("Mese"),   color = "#FFFF02", base = "gem",   cast = true, modifier = modifiers.mese},

	-- From moreores
	silver  = {name = S("Silver"),  color = "#D7E2E8", base = "ingot", cast = true, modifier = modifiers.silver},
	mithril = {name = S("Mithril"), color = "#6868D7", base = "ingot", cast = true, modifier = modifiers.mithril},

	-- From technic / elepower
	lead     = {name = S("Lead"),     color = "#C6C6C6", base = "ingot", cast = true, modifier = modifiers.lead},
	chromium = {name = S("Chromium"), color = "#DFE8E8", base = "ingot", cast = true, modifier = modifiers.chromium},
	zinc     = {name = S("Zinc"),     color = "#CEE8EF", base = "ingot", cast = true, modifier = modifiers.zinc},
}

tinkering.modifiers = {
	diamond = {name = S("Diamond"), default = mei.diamond, modifier = modifiers.diamond}
}

if core.get_modpath("mcl_core") then
	tinkering.materials.mese.name = S("Redstone")
	tinkering.modifiers.netherite = {
		name = "netherite", default = "mcl_nether:netherite_ingot",
		modifier = {
			uses = 30,
			increase = -0.25,
			count = 1,
			maxlevel = 3,
			damagegroups = {fleshy = 9},
			tags = {
				{name = "netherite", description = S("Netherite")}
			}
		}
	}
end
