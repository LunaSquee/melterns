-- Tinkering for Minetest 0.5.0+
-- Copyright (c) 2018 Evert "Diamond" Prants <evert@lunasqu.ee>

-- This mod is currently stuck behind https://github.com/minetest/minetest/issues/5686
-- Once this gets implemented, the full abilities of this mod will be available.

tinkering = rawget(_G, "tinkering") or {}

local modpath = minetest.get_modpath(minetest.get_current_modname())
tinkering.modpath = modpath

-- Utilities
dofile(modpath.."/util.lua")

-- Material Database
dofile(modpath.."/materials.lua")

-- Pattern Library
dofile(modpath.."/pattern.lua")

-- Tool Library
dofile(modpath.."/tool.lua")

-- Registration
dofile(modpath.."/register.lua")

-- Nodes and items
dofile(modpath.."/nodesitems.lua")
