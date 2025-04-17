-- Multifurnace for Minetest 5.0.0+
-- Copyright (c) 2019 Evert "Diamond" Prants <evert@lunasqu.ee>

multifurnace = rawget(_G, "multifurnace") or {}

local modpath = minetest.get_modpath(minetest.get_current_modname())
multifurnace.modpath = modpath

dofile(modpath .. "/multi.lua")

dofile(modpath .. "/faucet.lua")
dofile(modpath .. "/casting_table.lua")
dofile(modpath .. "/furnace.lua")
dofile(modpath .. "/crafting.lua")
