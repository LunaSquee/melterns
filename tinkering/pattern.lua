local S = core.get_translator("melterns")

tinkering.patterns = {}

-- Register a new pattern
function tinkering.register_pattern(name, data)
    local mod = data.mod_name or minetest.get_current_modname()
    local desc = data.description
    local itemname = mod .. ":" .. name .. "_pattern"

    data.itemname = itemname
    tinkering.patterns[name] = data

    minetest.register_craftitem(itemname, {
        description = desc .. " " .. S("Pattern") .. "\n\n" ..
            S("Material Cost: @1", data.cost),
        inventory_image = mod.."_" .. name .. "_pattern.png",
        _tinker_pattern = name,
        groups = {tinker_pattern = 1, ["tc_" .. name] = 1}
    })
end

-- Create blank pattern
minetest.register_craftitem("tinkering:blank_pattern", {
    description = S("Blank Pattern"),
    inventory_image = "tinkering_blank_pattern.png",
    groups = {tinker_pattern = 1}
})
