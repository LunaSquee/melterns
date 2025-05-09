fluidity.melts = {}

-- fluidity.molten_metals - metals

function fluidity.register_melt(item, metal, type)
    if not fluidity.melts[metal] then fluidity.melts[metal] = {} end

    if not fluidity.melts[metal][type] then fluidity.melts[metal][type] = {} end

    table.insert(fluidity.melts[metal][type], item)

    core.log("info", "Registered melt for " .. metal .. ", item " .. item ..
                 " (" .. type .. ")")
end

function fluidity.get_metal_for_item(item, type_check)
    for metal, types in pairs(fluidity.melts) do
        for typename, items in pairs(types) do
            if not type_check or typename == type_check then
                for _, itemname in pairs(items) do
                    if itemname == item then
                        return metal
                    end
                end
            end
        end
    end
end

-- Autofind meltable
local autofind = {"ingot", "lump", "crystal", "ore", "block", "raw"}
local modfind = {
    "default", "technic", "moreores", "elepower_dynamics", "mcl_core",
    "mcl_raw_ores", "mcl_copper"
}
local remap = {["raw"] = "lump"}

function fluidity.auto_detect_metal_forms(metal, mod)
    if mod then local modfind = {[0] = mod} end

    for _, v in pairs(modfind) do
        for _, k in pairs(autofind) do
            local configurations = {
                metal .. "_" .. k, k .. "_" .. metal, metal .. k, k .. metal
            }

            local typename = remap[k] or k

            for _, name in pairs(configurations) do
                if name ~= metal and name ~= k then
                    local name_w_mod = v .. ":" .. name
                    if minetest.registered_items[name_w_mod] then
                        fluidity.register_melt(name_w_mod, metal, typename)
                    end
                end
            end
        end
    end
end

-- Manually register default blocks, for now
fluidity.register_melt("default:mese", "mese", "block")
fluidity.register_melt("default:obsidian", "obsidian", "block")
fluidity.register_melt("default:goldblock", "gold", "block")
fluidity.register_melt("default:steelblock", "steel", "block")
fluidity.register_melt("default:copperblock", "copper", "block")
fluidity.register_melt("default:tinblock", "tin", "block")

-- Special snowflake
fluidity.register_melt("default:iron_lump", "steel", "lump")

-- VoxeLibre oddities
fluidity.register_melt("mcl_copper:block", "copper", "block")
fluidity.register_melt("mcl_core:ironblock", "steel", "block")
fluidity.register_melt("mcl_core:iron_ingot", "steel", "ingot")
fluidity.register_melt("mcl_raw_ores:raw_iron", "steel", "lump")
fluidity.register_melt("mcl_core:obsidian", "obsidian", "block")
fluidity.register_melt("mesecons_torch:redstoneblock", "mese", "block")

-- Register melts after all mods have loaded
minetest.register_on_mods_loaded(function()
    for metal, _ in pairs(fluidity.molten_metals) do
        fluidity.auto_detect_metal_forms(metal)
    end
end)
