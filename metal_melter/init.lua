-- Metal Melter for Minetest 0.5.0+
-- Copyright (c) 2018 Evert "Diamond" Prants <evert@lunasqu.ee>

local modpath = minetest.get_modpath("metal_melter")
metal_melter = {}

-- Melting database
dofile(modpath.."/meltable.lua")

-- Crafting components
dofile(modpath.."/components.lua")

-- Melter
dofile(modpath.."/melter.lua")

-- Caster
dofile(modpath.."/caster.lua")
