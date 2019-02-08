metal_melter.melts  = {}

-- fluidity.molten_metals - metals

function metal_melter.register_melt(item, metal, type)
	if not metal_melter.melts[metal] then
		metal_melter.melts[metal] = {}
	end

	if not metal_melter.melts[metal][type] then
		metal_melter.melts[metal][type] = {}
	end

	table.insert(metal_melter.melts[metal][type], item)
end

-- Autofind meltable
local autofind = {"ingot", "lump", "crystal", "ore", "block"}
local modfind = {"default", "technic", "moreores", "elepower_dynamics"}

function metal_melter.auto_detect_metal_forms(metal, mod)
	if mod then
		local modfind = { [0] = mod }
	end

	for i, v in pairs(modfind) do
		for j, k in pairs(autofind) do
			local name = v .. ":" .. metal .. "_" .. k

			if minetest.registered_items[name] then
				metal_melter.register_melt(name, metal, k)
			end
		end
	end
end

-- Manually register default blocks, for now
metal_melter.register_melt("default:mese", "mese", "block")
metal_melter.register_melt("default:obsidian", "obsidian", "block")
metal_melter.register_melt("default:goldblock", "gold", "block")
metal_melter.register_melt("default:steelblock", "steel", "block")
metal_melter.register_melt("default:copperblock", "copper", "block")
metal_melter.register_melt("default:tinblock", "tin", "block")

-- Special snowflake
metal_melter.register_melt("default:iron_lump", "steel", "lump")

-- Register melts after all mods have loaded
minetest.register_on_mods_loaded(function ()
	for metal,_ in pairs(fluidity.molten_metals) do
		metal_melter.auto_detect_metal_forms(metal)
	end
end)
