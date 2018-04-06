-- Fluidity for Minetest 0.5.0+
-- Copyright (c) 2018 Evert "Diamond" Prants <evert@lunasqu.ee>

fluidity = rawget(_G, "fluidity") or {}

local mpath = minetest.get_modpath("fluidity")
fluidity.modpath = mpath

-- Functions
dofile(mpath.."/functions.lua")

-- Molten metals
dofile(mpath.."/molten.lua")

-- Tanks
dofile(mpath.."/tanks.lua")

-- Florbs
dofile(mpath.."/florbs.lua")

-- Register everything
dofile(mpath.."/register.lua")
