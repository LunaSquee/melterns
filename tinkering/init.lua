-- Tinkering for Luanti 5.0.0+
-- Copyright (c) 2019 Evert "Diamond" Prants <evert@lunasqu.ee>

tinkering = rawget(_G, "tinkering") or {}

local modpath = core.get_modpath(core.get_current_modname())
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
