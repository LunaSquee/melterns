
local mei = fluidity.external.items

-- Crafting components

-- Items

minetest.register_craftitem("metal_melter:heated_brick", {
	description = "Heatbrick",
	inventory_image = "metal_melter_heated_brick.png",
	groups = {brick=1}
})

-- Nodes

minetest.register_node("metal_melter:heated_bricks", {
	description = "Heatbricks",
	tiles = {"metal_melter_heatbrick.png"},
	groups = {cracky = 3},
	paramtype2 = "facedir",
	place_param2 = 0,
	is_ground_content = false,
	sounds = fluidity.external.sounds.node_sound_stone,
})

minetest.register_node("metal_melter:heat_gravel", {
	description = "Heat Gravel",
	tiles = {"metal_melter_heat_gravel.png"},
	groups = {crumbly = 2, falling_node = 1},
	sounds = fluidity.external.sounds.node_sound_gravel
})

minetest.register_node("metal_melter:heat_exchanger", {
	description = "Heat Exchanger Plate",
	tiles = {"metal_melter_heat_exchanger.png"},
	groups = {cracky = 3},
	place_param2 = 0,
	is_ground_content = false,
	sounds = fluidity.external.sounds.node_sound_stone,
	drawtype = "nodebox",
	paramtype = "light",
	paramtype2 = "facedir",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.5000, -0.5000, -0.5000, 0.5000, -0.4375, 0.5000}
		}
	}
})

minetest.register_node('metal_melter:casting_table', {
	description = "Casting Table",
	paramtype = "light",
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.5000, 0.3750, -0.5000, 0.5000, 0.5000, 0.5000},
			{-0.4375, -0.5000, -0.4375, -0.3125, 0.3750, -0.3125},
			{0.3125, -0.5000, -0.4375, 0.4375, 0.3750, -0.3125},
			{-0.4375, -0.5000, 0.3125, -0.3125, 0.3750, 0.4375},
			{0.3125, -0.5000, 0.3125, 0.4375, 0.3750, 0.4375}
		}
	},
	tiles = {"metal_melter_heat_exchanger.png"},
	groups = {cracky = 3},
	sunlight_propagates = true,
	is_ground_content = false,
})

fluid_tanks.register_tank("metal_melter:heated_tank",{
	description = "Heated Tank",
	capacity    = 8000,
	tiles       = {"melter_heated_tank.png"},
	accepts     = {mei.lava}
})

-- Crafting

minetest.register_craft({
    output = 'metal_melter:heat_gravel 4',
    recipe = {
        {mei.gravel, mei.sand, mei.gravel},
        {mei.sand,   mei.clay, mei.sand},
        {mei.gravel, mei.sand, mei.gravel},
    },
})

minetest.register_craft({
    output = 'metal_melter:heat_gravel 4',
    recipe = {
        {mei.sand,   mei.gravel, mei.sand},
        {mei.gravel, mei.clay,   mei.gravel},
        {mei.sand,   mei.gravel, mei.sand},
    },
})

minetest.register_craft({
	output = 'metal_melter:heated_bricks 4',
	recipe = {
		{'metal_melter:heated_brick', 'metal_melter:heated_brick'},
		{'metal_melter:heated_brick', 'metal_melter:heated_brick'},
	}
})

minetest.register_craft({
	output = 'metal_melter:heated_tank',
	recipe = {
		{'metal_melter:heated_brick', mei.glass, 'metal_melter:heated_brick'},
		{'metal_melter:heated_brick', mei.glass, 'metal_melter:heated_brick'},
		{'metal_melter:heated_brick', mei.glass, 'metal_melter:heated_brick'},
	}
})

minetest.register_craft({
	output = 'metal_melter:heat_exchanger',
	recipe = {
		{mei.steel_ingot,       mei.steel_ingot,       mei.steel_ingot},
		{'metal_melter:heated_brick', 'metal_melter:heated_brick', 'metal_melter:heated_brick'},
	}
})

minetest.register_craft({
	output = 'metal_melter:casting_table',
	recipe = {
		{'metal_melter:heated_brick', 'metal_melter:heated_brick', 'metal_melter:heated_brick'},
		{'metal_melter:heated_brick', '',                          'metal_melter:heated_brick'},
		{'metal_melter:heated_brick', '',                          'metal_melter:heated_brick'},
	}
})

minetest.register_craft({
	output = 'metal_melter:metal_melter',
	recipe = {
		{'metal_melter:heated_bricks', 'metal_melter:heated_tank',    'metal_melter:heated_bricks'},
		{'metal_melter:heated_bricks', 'metal_melter:heat_exchanger', 'metal_melter:heated_bricks'},
		{'metal_melter:heated_bricks', 'metal_melter:heated_tank',    'metal_melter:heated_bricks'},
	}
})

minetest.register_craft({
	output = 'metal_melter:metal_caster',
	recipe = {
		{'metal_melter:heated_bricks', 'metal_melter:heated_tank',    'metal_melter:heated_bricks'},
		{'metal_melter:heated_bricks', 'metal_melter:heat_exchanger', 'metal_melter:casting_table'},
		{'metal_melter:heated_bricks', 'metal_melter:heated_tank',    'metal_melter:heated_bricks'},
	}
})

-- Smelting

minetest.register_craft({
    type = "cooking",
    output = "metal_melter:heated_brick",
    recipe = "metal_melter:heat_gravel",
    cooktime = 3,
})

-- Pipeworks
