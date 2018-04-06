
-- Register molten metals
-- Default metals
local metals = {"steel", "copper", "tin", "gold", "mese", "obsidian", "lead", "chromium", "zinc", "silver", "mithril"}

for _,v in pairs(metals) do
	fluidity.register_molten_metal(v)
end

-- Register tanks for all fluids
fluidity.register_fluid_tank({
	tank_name        = "fluid_tank",
	tank_description = "Fluid Tank",
	capacity         = 64,
	tiles            = {"default_glass.png", "default_glass_detail.png"}
})

-- Register florbs for all fluids
fluidity.register_florb({
	florb_name        = "florb",
	florb_description = "Florb",
	capacity          = 1000,
	tiles             = {"fluidity_florb.png", "fluidity_florb_mask.png"}
})
