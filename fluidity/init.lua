-- Fluidity for Minetest 5.0.0+
-- Copyright (c) 2019 Evert "Diamond" Prants <evert@lunasqu.ee>

fluidity = rawget(_G, "fluidity") or {}

local mpath = minetest.get_modpath("fluidity")
fluidity.modpath = mpath

function fluidity.fluid_short(str)
	return string.lower(str):gsub("%s", "_")
end

-- External mod/game compatibilty
dofile(mpath.."/compatibility.lua")

-- Molten metals
dofile(mpath.."/molten.lua")

-- Meltable metals list
dofile(mpath.."/meltable.lua")

-- Florbs
dofile(mpath.."/florbs.lua")

-- Register everything
dofile(mpath.."/register.lua")
