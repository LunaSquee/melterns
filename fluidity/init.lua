-- Fluidity for Minetest 5.0.0+
-- Copyright (c) 2018 Evert "Diamond" Prants <evert@lunasqu.ee>

fluidity = rawget(_G, "fluidity") or {}

local mpath = minetest.get_modpath("fluidity")
fluidity.modpath = mpath

function fluidity.fluid_short(str)
	return string.lower(str):gsub("%s", "_")
end

-- Molten metals
dofile(mpath.."/molten.lua")

-- Florbs
dofile(mpath.."/florbs.lua")

-- Register everything
dofile(mpath.."/register.lua")
