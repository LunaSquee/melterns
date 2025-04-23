local S = core.get_translator("melterns")

-- Register molten metals
-- Default metals
local metals = {
    steel = S("Steel"),
    copper = S("Copper"),
    tin = S("Tin"),
    bronze = S("Bronze"),
    gold = S("Gold"),
    mese = S("Mese"),
    obsidian = S("Obsidian"),
    lead = S("Lead"),
    chromium = S("Chromium"),
    zinc = S("Zinc"),
    silver = S("Silver"),
    mithril = S("Mithril")
}

for k, v in pairs(metals) do fluidity.register_molten_metal(k, v) end

-- Register florbs for all fluids
fluidity.florbs.register_florb({
    florb_name = "florb",
    florb_description = S("Florb"),
    capacity = 1000,
    tiles = {"fluidity_florb.png", "fluidity_florb_mask.png"}
})
