-- Metal Melter for Minetest 0.5.0+
-- Copyright (c) 2018 Evert "Diamond" Prants <evert@lunasqu.ee>

local modpath = minetest.get_modpath("metal_melter")
metal_melter = {}

-- Melting database
dofile(modpath.."/meltable.lua")

-- Crafting components
dofile(modpath.."/components.lua")

-- Fluid bar for formspec
function metal_melter.fluid_bar(x, y, fluid_buffer)
	local texture = "default_water.png"
	local metric  = 0

	if fluid_buffer and fluid_buffer.fluid and fluid_buffer.fluid ~= "" and
		minetest.registered_nodes[fluid_buffer.fluid] ~= nil then
		texture = minetest.registered_nodes[fluid_buffer.fluid].tiles[1]
		if type(texture) == "table" then
			texture = texture.name
		end
		metric  = math.floor(100 * fluid_buffer.amount / fluid_buffer.capacity)
	end

	return "image["..x..","..y..";1,2.8;melter_gui_barbg.png"..
		   "\\^[lowpart\\:"..metric.."\\:"..texture.."\\\\^[resize\\\\:64x128]"..
		   "image["..x..","..y..";1,2.8;melter_gui_gauge.png]"
end

-- Melter
dofile(modpath.."/melter.lua")

-- Caster
dofile(modpath.."/caster.lua")
