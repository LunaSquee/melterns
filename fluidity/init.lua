fluidity = rawget(_G, "fluidity") or {}

local mpath = minetest.get_modpath("fluidity")
fluidity.modpath = mpath

-- Functions
dofile(mpath.."/functions.lua")

-- Register molten metals
dofile(mpath.."/molten.lua")

-- Register tanks for each fluid
dofile(mpath.."/tanks.lua")
