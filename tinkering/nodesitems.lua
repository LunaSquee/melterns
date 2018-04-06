
-- Common nodebox
tinkering.bench = {
	type = "fixed",
	fixed = {
		{-0.5000, 0.3125, -0.5000, 0.5000, 0.5000, 0.5000},
		{-0.5000, -0.5000, -0.5000, -0.3125, 0.3125, -0.3125},
		{0.3125, -0.5000, -0.5000, 0.5000, 0.3125, -0.3125},
		{-0.5000, -0.5000, 0.3125, -0.3125, 0.3125, 0.5000},
		{0.3125, -0.5000, 0.3125, 0.5000, 0.3125, 0.5000}
	}
}

-- Tool Station
dofile(tinkering.modpath.."/nodes/tool_station.lua")

-- Part Builder
dofile(tinkering.modpath.."/nodes/part_builder.lua")

-- Pattern Table
dofile(tinkering.modpath.."/nodes/pattern_table.lua")

-- Recipes
minetest.register_craft({
	output = 'tinkering:blank_pattern 16',
	recipe = {
		{'default:stick', 'group:wood'},
		{'group:wood',    'default:stick'},
	},
})

minetest.register_craft({
	output = 'tinkering:tool_station',
	recipe = {
		{'tinkering:blank_pattern', 'tinkering:blank_pattern', 'tinkering:blank_pattern'},
		{'tinkering:blank_pattern', 'group:wood',              'tinkering:blank_pattern'},
		{'tinkering:blank_pattern', 'tinkering:blank_pattern', 'tinkering:blank_pattern'},
	},
})

minetest.register_craft({
	output = 'tinkering:pattern_table',
	recipe = {
		{'tinkering:blank_pattern'},
		{'group:wood'},
	},
})

minetest.register_craft({
	output = 'tinkering:part_builder',
	recipe = {
		{'tinkering:blank_pattern'},
		{'group:tree'},
	},
})

minetest.register_craft({
	output = 'fluidity:florb',
	recipe = {
		{'default:glass'},
		{'bucket:bucket_empty'},
	},
})

minetest.register_craft({
	type="shapeless",
	output = 'fluidity:florb',
	recipe = {'group:florb'},
})
