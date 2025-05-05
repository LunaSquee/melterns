local S = core.get_translator("melterns")

tinkering.tools = {
	pick = {
		description = S("Pickaxe"),
		groups = {"cracky"},
		fleshy_decrement = 1,
		components = {
			main    = "pickaxe_head",
			binding = "tool_binding",
			rod     = "tool_rod"
		},
		textures = {
			main   = "tinkering_pickaxe_head.png",
			second = "tinkering_overlay_handle_pickaxe.png",
			offset = "1,-1"
		}
	},
	axe = {
		description = S("Axe"),
		groups = {"choppy"},
		fleshy_increment = 1,
		components = {
			main    = "axe_head",
			binding = "tool_binding",
			rod     = "tool_rod"
		},
		textures = {
			main   = "tinkering_axe_head.png",
			second = "tinkering_overlay_handle_axe.png",
			offset = "1,-3"
		}
	},
	sword = {
		description = S("Sword"),
		groups = {"snappy"},
		fleshy_decrement = 0,
		components = {
			main    = "sword_blade",
			binding = "tool_binding",
			rod     = "tool_rod"
		},
		textures = {
			main   = "tinkering_sword_blade.png",
			second = "tinkering_overlay_handle_sword.png",
			offset = "0,0"
		}
	},
	shovel = {
		description = S("Shovel"),
		groups = {"crumbly"},
		fleshy_decrement = 1,
		components = {
			main    = "shovel_head",
			binding = "tool_binding",
			rod     = "tool_rod"
		},
		textures = {
			main   = "tinkering_shovel_head.png",
			second = "tinkering_overlay_handle_shovel.png",
			offset = "3,-3"
		}
	},
}

tinkering.components = {
	pickaxe_head = {
		description = S("Pickaxe Head"),
		compose_description = function(u) return S("@1 Pickaxe Head", u) end,
		material_cost = 2,
		image = tinkering.tools.pick.textures.main
	},
	axe_head = {
		description = S("Axe Head"),
		compose_description = function(u) return S("@1 Axe Head", u) end,
		material_cost = 2,
		image = tinkering.tools.axe.textures.main
	},
	sword_blade = {
		description = S("Sword Blade"),
		compose_description = function(u) return S("@1 Sword Blade", u) end,
		material_cost = 2,
		image = tinkering.tools.sword.textures.main
	},
	shovel_head = {
		description = S("Shovel Head"),
		compose_description = function(u) return S("@1 Shovel Head", u) end,
		material_cost = 2,
		image = tinkering.tools.shovel.textures.main
	},
	tool_rod = {
		description = S("Tool Rod"),
		compose_description = function(u) return S("@1 Tool Rod", u) end,
		material_cost = 1,
		image = "tinkering_tool_rod.png"
	},
	tool_binding = {
		description = S("Tool Binding"),
		compose_description = function(u) return S("@1 Tool Binding", u) end,
		material_cost = 2,
		image = "tinkering_tool_binding.png"
	}
}

local mcl_group_translations = {
	crumbly = "shovely",
	cracky = "pickaxey",
	snappy = "swordy",
	choppy = "axey"
}

-- Create component for material
function tinkering.create_material_component(data)
	local desc = data.description
	local name = data.name
	local mod  = data.mod_name or minetest.get_current_modname()

	local groups = {tinker_component = 1}
	groups["tc_"..data.component] = 1
	groups["material_"..data.metal] = 1

	minetest.register_craftitem(mod..":"..name, {
		description       = desc,
		groups            = groups,
		_tinker_component = data.component,
		_tinker_material  = data.metal,
		inventory_image   = data.image
	})
end

-- Create groups based on materials
local function apply_modifiers(materials, basegroup, dgroup)
	local tags = {}
	local groups = {}

	local incr = 0.00
	local uses = 0
	local maxlevel = 0
	local dmg = {}

	-- Apply material modifiers
	for m, v in pairs(materials) do
		local material = tinkering.materials[v]
		local mod = material.modifier

		if m ~= "main" then
			if mod[m] then
				local mp = mod[m]
				if mp.increase then
					incr = incr + mp.increase
				end

				if mp.uses then
					uses = uses + mp.uses
				end

				if mp.maxlevel and maxlevel < mp.maxlevel then
					maxlevel = mp.maxlevel
				end

				if mp.damage then
					for g,mod in pairs(mp.damage) do
						if dmg[g] == nil or dmg[g] < mod then
							dmg[g] = mod
						end
					end
				end
			end
		end

		-- Apply tags
		if mod.tags then
			for _,t in pairs(mod.tags) do
				if tags[t.name] == nil then
					tags[t.name] = t.description
				end
			end
		end
	end

	-- Apply modified to base groups
	for grp, d in pairs(basegroup) do
		groups[grp] = d

		for id,val in pairs(d.times) do
			groups[grp].times[id] = val + (incr / id)
		end

		groups[grp].uses = d.uses + uses

		if groups[grp].maxlevel and maxlevel < groups[grp].maxlevel then
			maxlevel = groups[grp].maxlevel
		end
	end

	-- Apply damage group modifications
	for g,l in pairs(dgroup) do
		if dmg[g] == nil or dmg[g] < l then
			dmg[g] = l
		end
	end

	return groups, dmg, tags, maxlevel
end

-- Generate a tool texture based on tool type, main material (head) and rod material (handle).
function tinkering.compose_tool_texture(tooltype, main, rod)
	local mat_main = tinkering.materials[main]
	local mat_rod  = tinkering.materials[rod]
	local tool_data = tinkering.tools[tooltype].textures

	return tinkering.combine_textures(tool_data.main, tool_data.second, mat_main.color, mat_rod.color, tool_data.offset)
end

local function quickcopy(t)
	local res = {}
	for i, v in pairs(t) do
		res[i] = v
	end
	return res
end

-- Generate tool capabilities based on tool type and materials
function tinkering.get_tool_capabilities(tool_type, materials)
	if not materials["main"] or not materials["rod"] then
		return nil
	end

	-- Get main material
	local main = tinkering.materials[materials.main]
	if not main then return nil end

	-- Tool data
	local tool_data = tinkering.tools[tool_type]

	-- Name of the tool
	local name = tool_data.description or "Tool"

	-- Group copies
	local groups = {}
	local dgroups = {}

	-- Copy the damage groups
	for g,v in pairs(main.modifier.damagegroups) do
		-- Decrement/increment damage group if tool wants it
		if tool_data[g.."_decrement"] then
			dgroups[g] = v - tool_data[g.."_decrement"]
		elseif tool_data[g.."_increment"] then
			dgroups[g] = v + tool_data[g.."_increment"]
		else
			dgroups[g] = v
		end
	end

	-- Type specific groups and modifiers
	for _,v in pairs(tool_data.groups) do
		if main.modifier[v] then
			groups[v] = quickcopy(main.modifier[v])
		end
	end

	-- Apply all modifiers
	local fg, fd, tags, maxlevel = apply_modifiers(materials, groups, dgroups)

	-- Use MCL tool capabilities
	if core.get_modpath("mcl_core") ~= nil then
		for grp, val in pairs(mcl_group_translations) do
			if fg[grp] then
				local temp = {}
				for i = #fg[grp].times, 1, -1 do
					table.insert(temp, fg[grp].times[i])
				end
				fg[val] = fg[grp]
				fg[val].uses = fg[grp].uses * 10
				fg[val].times = temp
				fg[val].maxlevel = 0
				fg[grp] = nil
			end
		end
	end

	local tool_caps = {
		full_punch_interval = 1.0,
		max_drop_level = maxlevel,
		groupcaps = fg,
		damage_groups = fd,
	}

	core.debug(dump(tool_caps))

	-- Construct the name
	name = main.name.." "..name

	return tool_caps, name, tags
end

-- Replace the itemstack with a broken tool instead of destroying it
local function after_use_handler(itemstack, user, node, digparams)
	local wear_add = digparams.wear
	local wear_before = itemstack:get_wear()
	if wear_before + wear_add < 65536 then
		itemstack:add_wear(wear_add)
		return itemstack
	end
	-- TODO: Consider creating an itemdef field for the broken counterpart name
	local tool_broken = ItemStack(itemstack:get_name().."_broken")
	local tool_broken_meta = tool_broken:get_meta()
	local meta = itemstack:get_meta()
	tool_broken_meta:from_table(meta:to_table())
	local description = meta:get_string("description")
	tool_broken_meta:set_string("description_non_broken", description)
	tool_broken_meta:set_string("description", description .. "\n" .. minetest.colorize("#BB1111", S("Broken")))
	tool_broken_meta:set_string("capabilities_non_broken", minetest.serialize(itemstack:get_tool_capabilities()))
	itemstack:replace(tool_broken)
	meta:set_tool_capabilities({})
	return itemstack
end

-- Return tool definition
function tinkering.tool_definition(tool_type, materials)
	if not materials["main"] or not materials["rod"] then
		return nil
	end

	local capabilities, name, tags = tinkering.get_tool_capabilities(tool_type, materials)
	if not capabilities then return nil end

	local tool_tree = {
		description       = name,
		tool_capabilities = capabilities,
		groups            = {tinker_tool = 1, ["mainly_"..materials.main] = 1, ["tinker_"..tool_type] = 1, not_in_creative_inventory = 1},
		after_use         = after_use_handler,
		_is_broken        = false,
		inventory_image   = tinkering.compose_tool_texture(tool_type, materials.main, materials.rod)
	}

	return tool_tree, tags
end

-- Compare provided components to the required components of this tool
local function compare_components_required(tool_spec, materials)
	local all_match = true

	for i, v in pairs(tool_spec) do
		if not materials[i] then
			all_match = false
		end
	end

	for i, v in pairs(materials) do
		if not tool_spec[i] then
			all_match = false
		end
	end

	return all_match
end

-- Create a new tool based on parameters specified.
function tinkering.create_tool(tool_type, materials, want_tool, custom_name, overrides)
	-- Not a valid tool type
	if not tinkering.tools[tool_type] then return nil end
	local tool_data = tinkering.tools[tool_type]

	-- Check if the components are correct
	if not compare_components_required(tool_data.components, materials) then return nil end

	-- Get tool definition and other metadata
	local tool_def, tags = tinkering.tool_definition(tool_type, materials)
	if not tool_def then return nil end

	local mod_name = tool_data.mod or "tinkering"

	-- Apply overrides
	if overrides then
		for i, v in pairs(overrides) do
			tool_def[i] = v
		end
	end

	-- Use custom name
	if custom_name ~= nil and custom_name ~= "" then
		tool_def.description = custom_name
	end

	tool_def._mcl_toollike_wield = true

	-- Create internal name
	local internal_name = mod_name..":"..materials.main.."_"..tool_type

	-- Register base tool if it doesnt exist already
	if not minetest.registered_items[internal_name] and minetest.get_current_modname() then
		minetest.register_tool(internal_name, tool_def)
		local tool_def_broken = table.copy(tool_def)
		tool_def_broken.tool_capabilities = nil
		tool_def_broken.description = tool_def_broken.description.." (" .. S("Broken") .. ")"
		tool_def_broken.after_use = nil
		tool_def_broken._is_broken = true
		tool_def_broken._unbroken_name = internal_name
		minetest.register_tool(internal_name.."_broken", tool_def_broken)
	end

	if not want_tool then return nil end

	-- Store materials to use in metadata
	local mat_names = ""
	local i = 1
	for name, mat in pairs(materials) do
		if i == 1 then
			mat_names = name.."="..mat
		else
			mat_names = mat_names..","..name.."="..mat
		end
		i = i + 1
	end

	-- Add components to description
	local description = tool_def.description
	description = description.."\n"

	for cmp, mat in pairs(materials) do
		local info = tinkering.materials[mat]
		local comp = tool_data.components[cmp]
		local desc = tinkering.components[comp].compose_description(info.name)

		description = description .. "\n" .. minetest.colorize(info.color, desc)
	end

	-- Add tags to description
	description = description.."\n"

	for _,tag in pairs(tags) do
		description = description .. "\n" .. tag
	end

	-- Create a new tool instance and apply metadata
	local tool = ItemStack(internal_name)
	local meta = tool:get_meta()

	if tool_def["initial_metadata"] then
		-- For the mods that add additional fields to tool metadata, e. g. toolranks
		meta:from_table(tool_def.initial_metadata)
	end

	meta:set_string("description", description)
	meta:set_string("inventory_image", tool_def.inventory_image)
	meta:set_tool_capabilities(tool_def.tool_capabilities)
	meta:set_string("materials", mat_names)

	if tool_def["wear"] then
		tool:set_wear(tool_def.wear)
	end

	return tool
end

-- Register new tool material
function tinkering.register_material_tool(material)
	for t,_ in pairs(tinkering.tools) do
		tinkering.create_tool(t, {main=material,binding="wood",rod="wood"}, false, nil)
	end
end

-- Register a new tool component
function tinkering.register_component(name, data)
	local mod = data.mod_name or minetest.get_current_modname()

	if not tinkering.components[name] then
		tinkering.components[name] = data
	end

	local comp_desc = data.description

	-- Register cast
	metal_melter.register_melt_value(name, metal_caster.spec.cast)
	metal_caster.register_cast(name, {
		description = comp_desc,
		mod_name    = mod,
		result      = name,
		cost        = data.material_cost,
		typenames   = {name}
	})

	-- Register pattern
	tinkering.register_pattern(name, {
		description = comp_desc,
		cost        = data.material_cost,
		mod_name    = mod
	})

	-- Register components for all materials
	for m, s in pairs(tinkering.materials) do
		local component = m.."_"..name

		tinkering.create_material_component({
			name        = component,
			component   = name,
			metal       = m,
			mod_name    = mod,
			description = data.compose_description(s.name),
			image       = tinkering.color_filter(data.image, s.color)
		})

		-- Make all components meltable
		fluidity.register_melt(mod..":"..component, m, name)
	end
end

-- Register a new material type and register base components and tools for material
function tinkering.register_material(name, data)
	local mod = data.mod_name or minetest.get_current_modname()

	assert(data.name ~= nil)
	assert(data.base ~= nil)
	assert(data.modifier ~= nil)
	assert(data.color ~= nil)
	assert(data.default ~= nil or data.cast == true)

	data.mod = mod
	tinkering.materials[name] = data

	-- Register all components for material
	for comp, comp_def in pairs(tinkering.components) do
		local component = name.."_"..comp

		tinkering.create_material_component({
			name        = component,
			component   = comp,
			metal       = name,
			mod_name    = mod,
			description = comp_def.compose_description(name),
			image       = tinkering.color_filter(comp_def.image, data.color)
		})

		-- Make all components meltable
		fluidity.register_melt(mod..":"..component, name, comp)
	end

	tinkering.register_material_tool(name)
end

-- Register a modifier we can apply to a tool
function tinkering.register_modifier(name, data)
	assert(data.name ~= nil)
	assert(data.default ~= nil)
	assert(data.modifier ~= nil)

	tinkering.modifiers[name] = data
end

-- Register a tool type
--
--data = {
--	description = "Pickaxe",     -- Name (description) of the tool
--	groups = {"cracky"},  -- Group caps that apply
--  mod = "tinkering",    -- The mod you're registering this tool from
--	fleshy_decrement = 1, -- Amount removed from base damage group "fleshy". Negative value adds.
--	components = {
--		main    = "pickaxe_head", -- Name of the primary component
--		binding = "tool_binding", -- Second component
--		rod     = "tool_rod"      -- Mandatory rod component
--	},
--	textures = {
--		main   = "tinkering_pickaxe_head.png",           -- Head (main) Texture
--		second = "tinkering_overlay_handle_pickaxe.png", -- Overlay (typically a handle)
--		offset = "1,-1"                                  -- Head's offset on the texture
--	}
--}
--
function tinkering.register_tool_type(name, data)
	assert(data.components ~= nil)
	assert(data.description ~= nil)
	assert(data.textures ~= nil)

	if not data.mod then
		data.mod = minetest.get_current_modname()
	end

	tinkering.tools[name] = data
end

-- Register a new tool type and register base tool for all materials
function tinkering.register_tool(name, data)
	tinkering.register_tool_type(name, data)

	for material in pairs(tinkering.materials) do
		local components_table = { main = material }
		for comp in pairs(data.components) do
			components_table[comp] = "wood"
		end

		tinkering.create_tool(name, components_table, false, nil)
	end
end

-- TODO: this is a workaround to enable digging using tinkering tools
-- VoxeLibre will only work if you use _mcl_diggroups and that is not compatible with
-- metadata tool capabilities at all. Not exactly sure why they did it like this.
-- Currently, we just allow any tinker tool to break anything.
-- This should be addressed properly in the future.
if core.get_modpath("_mcl_autogroup") then
	core.register_on_mods_loaded(function()
		local original_can_harvest = mcl_autogroup.can_harvest
		mcl_autogroup.can_harvest = function (nodename, toolname, player)
			local can_dig = original_can_harvest(nodename, toolname, player)
			if not can_dig and core.get_item_group(toolname, "tinker_tool") > 0 then
				return true
			end
			return can_dig
		end
	end)
end
