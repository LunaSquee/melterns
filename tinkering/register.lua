tinkering.tools = {
	pick = {
		description = "Pickaxe",
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
		description = "Axe",
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
		description = "Sword",
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
		description = "Shovel",
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
	pickaxe_head = {description = "%s Pickaxe Head", materials = 1, image = tinkering.tools.pick.textures.main},
	axe_head     = {description = "%s Axe Head",     materials = 1, image = tinkering.tools.axe.textures.main},
	sword_blade  = {description = "%s Sword Blade",  materials = 1, image = tinkering.tools.sword.textures.main},
	shovel_head  = {description = "%s Shovel Head",  materials = 1, image = tinkering.tools.shovel.textures.main},
	tool_rod     = {description = "%s Tool Rod",     materials = 1, image = "tinkering_tool_rod.png"},
	tool_binding = {description = "%s Tool Binding", materials = 1, image = "tinkering_tool_binding.png"}
}

-- Create component for material
local function create_material_component(data)
	local desc = data.description
	local name = data.name
	local mod  = data.mod_name

	minetest.register_craftitem(mod..":"..name, {
		description     = desc,
		groups          = {tinker_component = 1},
		inventory_image = data.image
	})
end

-- Register a new tool component
function tinkering.register_component(name, data)
	local mod = data.mod_name or "tinkering"

	if not tinkering.components[name] then
		tinkering.components[name] = data
	end

	-- Register components for all materials
	for m, s in pairs(tinkering.materials) do
		local component = m.."_"..name

		create_material_component({
			name        = component,
			mod_name    = mod,
			description = data.description:format(s.name),
			image       = tinkering.color_filter(data.image, s.color)
		})

		-- Make all components meltable
		metal_melter.set_spec(name, metal_caster.spec.cast)
		metal_melter.register_melt(mod..":"..component, m, name)
	end
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
	tinkering.tools[name] = data
end

-- Create groups based on materials
local function apply_modifiers(materials, basegroup, dgroup)
	local tags = {}
	local groups = {}

	local incr = 0.00
	local uses = 0
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
	end

	-- Apply damage group modifications
	for g,l in pairs(dgroup) do
		if dmg[g] == nil or dmg[g] < l then
			dmg[g] = l
		end
	end

	return groups, dmg, tags
end

-- Generate a tool texture based on tool type, main material (head) and rod material (handle).
function tinkering.compose_tool_texture(tooltype, main, rod)
	local mat_main = tinkering.materials[main]
	local mat_rod  = tinkering.materials[rod]

	local tool_data = tinkering.tools[tooltype]

	local main_tex = tool_data.textures.main   .."\\^[multiply\\:".. mat_main.color
	local rod_tex  = tool_data.textures.second .."\\^[multiply\\:".. mat_rod.color
	local align    = tool_data.textures.offset

	return "[combine:16x16:"..align.."="..main_tex..":0,0="..rod_tex
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
	local fg, fd, tags = apply_modifiers(materials, groups, dgroups)
	local tool_caps = {
		full_punch_interval = 1.0,
		max_drop_level = 0,
		groupcaps = fg,
		damagegroups = fd,
	}

	-- Construct the name
	name = main.name.." "..name

	return tool_caps, name, tags
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
		groups            = {tinker_tool = 1},
		inventory_image   = tinkering.compose_tool_texture(tool_type, materials.main, materials.rod)
	}

	-- Store materials to use in metadata
	local tink_mats = ""
	for _,m in pairs(materials) do
		tink_mats = tink_mats..","..m
	end

	return tool_tree, tink_mats, tags
end

-- Compare provided components to the required components of this tool
local function compare_components_required(tool_spec, materials)
	local all_match = true
	
	for i, v in pairs(tool_spec) do
		if not materials[i] then
			all_match = false
		end
	end

	return all_match
end

-- Create a new tool based on parameters specified.
function tinkering.create_tool(tool_type, materials, want_tool, custom_name, overrides)
	-- TODO: Apply tags
	-- TODO: Add texture as metadata (https://github.com/minetest/minetest/issues/5686)

	-- Not a valid tool type
	if not tinkering.tools[tool_type] then return false end
	local tool_data = tinkering.tools[tool_type]

	-- Check if the components are correct
	if not compare_components_required(tool_data.components, materials) then return false end

	-- Get tool definition and other metadata
	local tool_def, mat_names, tags = tinkering.tool_definition(tool_type, materials)
	if not tool_def then return false end

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

	-- Create internal name
	local internal_name = mod_name..":"..materials.main.."_"..tool_type

	-- Register base tool if it doesnt exist already
	if not minetest.registered_items[internal_name] then
		minetest.register_tool(internal_name, tool_def)
	end

	if not want_tool then return true end

	-- Create a new tool instance and apply metadata
	local tool = ItemStack(internal_name)
	local meta = tool:get_meta()
	meta:set_string("description", tool_def.description)
	meta:set_string("texture_string", tool_def.inventory_image) -- NOT IMPLEMENTED YET!
	meta:set_tool_capabilities(tool_def.tool_capabilities)
	meta:set_string("materials", mat_names)

	return tool
end

-- Register components and base tools
local start_load = os.clock()
local num_components = 0
local num_tools = 0

-- Create base tools
for m, s in pairs(tinkering.materials) do
	for t,_ in pairs(tinkering.tools) do
		tinkering.create_tool(t, {main=m,binding="wood",rod="wood"}, false, nil, {groups={not_in_creative_inventory=1}})
		num_tools = num_tools + 1
	end
end

-- Register tool components
for i, v in pairs(tinkering.components) do
	tinkering.register_component(i, v)
	num_components = num_components + 1
end

print(("[tinkering] Added %d components and %d base tools in %f seconds."):format(num_components, num_tools, os.clock() - start_load))
