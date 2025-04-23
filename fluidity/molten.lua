local S = core.get_translator("melterns")

-- Register molten metals

fluidity.molten_metals = {}

local function firstToUpper(str)
    return (str:gsub("^%l", string.upper))
end

function fluidity.get_metal_for_fluid(fluid)
	for i,v in pairs(fluidity.molten_metals) do
		if v == fluid then
			return i
		end
	end
end

function fluidity.register_molten_metal(metal, metal_name)
	local description = metal_name or firstToUpper(metal)
	local mod_name    = minetest.get_current_modname()
	local fluid_name  = S("Molten @1", metal_name)
	fluidity.molten_metals[metal] = mod_name..":"..metal.."_source"

	minetest.register_node(mod_name..":"..metal.."_source", {
		description = S("Molten @1 Source", description),
		drawtype = "liquid",
		tiles = {
			{
				name = "fluidity_"..metal.."_source_animated.png",
				animation = {
					type = "vertical_frames",
					aspect_w = 16,
					aspect_h = 16,
					length = 3.0,
				},
			},
		},
		special_tiles = {
			{
				name = "fluidity_"..metal.."_source_animated.png",
				animation = {
					type = "vertical_frames",
					aspect_w = 16,
					aspect_h = 16,
					length = 3.0,
				},
				backface_culling = false,
			},
		},
		paramtype = "light",
		light_source = core.LIGHT_MAX - 1,
		walkable = false,
		pointable = false,
		diggable = false,
		buildable_to = true,
		is_ground_content = false,
		drop = "",
		drowning = 1,
		liquidtype = "source",
		liquid_alternative_flowing = mod_name..":"..metal.."_flowing",
		liquid_alternative_source = mod_name..":"..metal.."_source",
		liquid_viscosity = 7,
		liquid_renewable = false,
		_fluid_name = fluid_name,
		_doc_items_entry_name = fluid_name,
		damage_per_second = 4 * 2,
		post_effect_color = {a = 191, r = 255, g = 64, b = 0},
		groups = {molten_metal = 1, lava = 1, liquid = 2, igniter = 1},
	})

	minetest.register_node(mod_name..":"..metal.."_flowing", {
		description = S("Flowing Molten @1", description),
		drawtype = "flowingliquid",
		tiles = {"fluidity_"..metal..".png"},
		special_tiles = {
			{
				name = "fluidity_"..metal.."_flowing_animated.png",
				backface_culling = false,
				animation = {
					type = "vertical_frames",
					aspect_w = 16,
					aspect_h = 16,
					length = 3.3,
				},
			},
			{
				name = "fluidity_"..metal.."_flowing_animated.png",
				backface_culling = true,
				animation = {
					type = "vertical_frames",
					aspect_w = 16,
					aspect_h = 16,
					length = 3.3,
				},
			},
		},
		paramtype = "light",
		paramtype2 = "flowingliquid",
		light_source = core.LIGHT_MAX - 1,
		walkable = false,
		pointable = false,
		diggable = false,
		buildable_to = true,
		is_ground_content = false,
		drop = "",
		drowning = 1,
		liquidtype = "flowing",
		liquid_alternative_flowing = mod_name..":"..metal.."_flowing",
		liquid_alternative_source = mod_name..":"..metal.."_source",
		liquid_viscosity = 7,
		liquid_renewable = false,
		_fluid_name = fluid_name,
		_doc_items_entry_name = fluid_name,
		damage_per_second = 4 * 2,
		post_effect_color = {a = 191, r = 255, g = 64, b = 0},
		groups = {molten_metal = 1, lava = 1, liquid = 2, igniter = 1,
			not_in_creative_inventory = 1},
	})

	fluid_lib.register_liquid(
		mod_name..":"..metal.."_source",
		mod_name..":"..metal.."_flowing",
		mod_name..":bucket_"..metal,
		mod_name.."_bucket_"..metal..".png",
		S("Molten @1 Bucket", description)
	)
end
