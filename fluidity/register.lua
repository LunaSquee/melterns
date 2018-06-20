
-- Register molten metals
-- Default metals
local metals = {"steel", "copper", "tin", "bronze", "gold", "mese", "obsidian", "lead", "chromium", "zinc", "silver", "mithril"}

for _,v in pairs(metals) do
	fluidity.register_molten_metal(v)
end

-- Register florbs for all fluids
fluidity.florbs.register_florb({
	florb_name        = "florb",
	florb_description = "Florb",
	capacity          = 1000,
	tiles             = {"fluidity_florb.png", "fluidity_florb_mask.png"}
})
