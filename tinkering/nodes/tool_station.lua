tool_station = {}

local tool_list_cache = nil
function tool_station.get_tool_type_list(ix, iy, mx)
	local formspec = ""
	local x        = 0
	local y        = 0

	formspec = formspec..("button[%d,%d;1,1;anvil;Anvil]"):format(x + ix, y + iy)
	x = x + 1

	for t, tool in pairs(tinkering.tools) do
		local toolmod = tool.mod_name or "tinkering"
		formspec = formspec.. ("item_image_button[%d,%d;1,1;%s;%s;]"):format(x + ix, y + iy, toolmod..":steel_"..t, t)
		formspec = formspec.. ("tooltip[%s;%s]"):format(t, tool.description)
		x = x + 1
		if x >= mx then
			y = y + 1
			x = 0
		end
	end

	return formspec
end

function tool_station.get_formspec(comp_list)
	if not tool_list_cache then
		tool_list_cache = tool_station.get_tool_type_list(8, 0, 5)
	end

	local w = 1
	local h = 0

	local x = 1
	local y = 0

	local til = ""

	if comp_list then
		for _,comp in pairs(comp_list) do
			local img = tinkering.components[comp].image .. "^[colorize:#1e1e1e:255"
			til = til .. "image[" .. (x * 1) .. "," .. (y + 0.8) .. ";1,1;".. img .. "]"
			y = y + 1
			h = h + 1

			if y > 2 then
				y = 0
				x = x + 1
			end

			if h > 3 then
				h = 3
				w = w + 1
			end
		end
	else
		h = 3
		w = 3
	end

	return "size[13,8.5]"..
		default.gui_bg..
		default.gui_bg_img..
		default.gui_slots..
		"label[0,0;Tool Station]"..
		til..
		"list[context;input;1,0.8;" .. w .. "," .. h .. ";]"..
		"list[context;output;5,1.8;1,1;]"..
		"image[4,1.8;1,1;gui_furnace_arrow_bg.png^[transformR270]"..
		"list[current_player;main;0,4.25;8,1;]"..
		"list[current_player;main;0,5.5;8,3;8]"..
		tool_list_cache..
		"listring[current_player;main]"..
		"listring[context;input]"..
		"listring[current_player;main]"..
		"listring[context;output]"..
		"listring[current_player;main]"..
		default.get_hotbar_bg(0, 4.25)
end

local function get_metalgroup(groups)
	if not groups then return nil end
	for g,i in pairs(groups) do
		if g:find("material_") == 1 then
			return g:gsub("^material_", "")
		end
	end
	return nil
end

-- Get tool components from specified stacks
function tool_station.get_types(list, tool_type)
	local tool = tinkering.tools[tool_type]
	if not tool then return nil end

	local result = {}
	local items_required = {}
	local components = {}

	for _,stack in pairs(list) do
		if not result then break end
		local stack_name = stack:get_name()
		for tt, ty in pairs(tool.components) do
			if not result then break end
			local in_grp = minetest.get_item_group(stack_name, "tc_"..ty) > 0
			if in_grp then
				if components[tt] == nil then
					local mtg = get_metalgroup(minetest.registered_items[stack_name].groups)
					if mtg ~= nil then
						result[tt] = mtg
						
						if not items_required[stack_name] then
							items_required[stack_name] = 0
						end

						items_required[stack_name] = items_required[stack_name] + 1
						components[tt] = true
					end
				else
					-- Don't allow multiple components of the same type to avoid confusion
					result = nil
					items_required = nil
					components = {}
					break
				end
			end
		end
	end

	return result, items_required
end

function tool_station.get_tool(list)
	local tool_fnd  = nil
	local tool_type = nil
	for _,stack in pairs(list) do
		local stack_name = stack:get_name()
		if minetest.get_item_group(stack_name, "tinker_tool") > 0 then
			if tool_fnd == nil then
				for t in pairs(tinkering.tools) do
					if minetest.get_item_group(stack_name, "tinker_"..t) > 0 then
						tool_type = t
						break
					end
				end
				tool_fnd = stack
			else
				-- Don't allow multiple tools in the repair grid at the same time to avoid confusion
				tool_fnd = nil
				break
			end
		end
	end
	return tool_fnd, tool_type
end

local function decode_meta(s)
	local t = {}
	for k, v in string.gmatch(s, "(%w+)=(%w+)") do
		t[k] = v
	end
	return t
end

local function find_material(stack)
	-- Meltables
	for metal,list in pairs(metal_melter.melts) do
		for type,stacks in pairs(list) do
			for _,st in pairs(stacks) do
				if st == stack then
					return metal, type
				end 
			end
		end
	end

	-- Grouped
	for mat,iv in pairs(tinkering.materials) do
		if iv.base == "group" and minetest.get_item_group(stack, iv.default) > 0 then
			return mat, "block"
		elseif stack == iv.default then
			return mat, "ingot"
		end
	end

	return nil
end

local function get_materials_in_list(list, skip)
	local result = {}
	for _,stack in pairs(list) do
		local stack_name = stack:get_name()
		if stack_name ~= "" and stack_name ~= skip then
			local material, type = find_material(stack_name)
			if material then
				if result[material] then
					result[material].count = result[material].count + stack:get_count()
				else
					result[material] = {stack = stack_name, type = type, count = stack:get_count()}
				end
			end
		end
	end

	return result
end

local function match_materials(list1, materials)
	local matches = {}
	for name,type in pairs(materials) do
		if list1[type] then
			matches[type] = list1[type]
		end
	end

	-- Return nothing if there are materials not suitable
	for name in pairs(list1) do
		if not matches[name] then
			matches = {}
			break
		end
	end
	return matches
end

local function take_from_list(list, item, list2)
	for _,stack in pairs(list) do
		local stack_name = stack:get_name()
		if stack_name == item then
			stack:clear()
		elseif list2[stack_name] then
			if list2[stack_name] > stack:get_count() then
				list2[stack_name] = list2[stack_name] - stack:get_count()
				stack:clear()
			else
				stack:set_count(stack:get_count() - list2[stack_name])
				list2[stack_name] = 0
			end
		end
	end
	return list
end

local function handle_take_output(pos, listname)
	local meta = minetest.get_meta(pos)
	local inv  = meta:get_inventory()

	local tooltype = meta:get_string("tool_type")
	local list     = inv:get_list(listname)

	if tooltype ~= "" then
		local types, items = tool_station.get_types(list, tooltype)
		if not types then return end
		local res = {}

		for _,stack in pairs(list) do
			local stack_name = stack:get_name()
			if items[stack_name] then
				if not res[stack_name] then
					res[stack_name] = items[stack_name]
				end

				if res[stack_name] > 0 then
					if stack:get_count() > res[stack_name] then
						stack:set_count(stack:get_count() - res[stack_name])
						res[stack_name] = 0
					else
						res[stack_name] = res[stack_name] - stack:get_count()
						stack:clear()
					end
				end
			end
		end

		inv:set_list(listname, list)
	else
		local tool, tool_type_ = tool_station.get_tool(list)
		if tool then
			local comp_mats = tool:get_meta():get_string("materials")
			if comp_mats and comp_mats ~= "" then
				local materials = decode_meta(comp_mats)
				-- Material list found, now we can start doing repair work or replacing a component
				local mat_grid = get_materials_in_list(list, tool:get_name())
				
				-- Find components to remove
				local for_removal = {}
				local removed_types = {}
				local repair = true
				local tool_comps = tinkering.tools[tool_type_].components
				for mat, stat in pairs(mat_grid) do
					for name, comp in pairs(tool_comps) do
						if stat.type == comp and not removed_types[comp] then
							for_removal[stat.stack] = 1
							removed_types[comp] = true
							repair = false
						end
					end
				end

				if not repair then
					inv:set_list(listname, take_from_list(list, tool:get_name(), for_removal))
				end

				if tool:get_wear() ~= 0 and repair then
					local matches = match_materials(mat_grid, materials)
					local repair_cap = 0
					for mat, stat in pairs(matches) do
						repair_cap = repair_cap + math.min(stat.count, 3)
					end

					if repair_cap > 0 then
						local _take = 1
						for i = 1, repair_cap do
							local tool_wear = 65535 - tool:get_wear()
							local repair_cnt = (0.33 * 65535) * i
							local new_wear = 65535 - (tool_wear + repair_cnt)
							if new_wear > 0 then
								_take = _take + 1
							end
						end

						local to_take = {}
						local exch = _take

						for type, c in pairs(matches) do
							if not to_take[c.stack] then to_take[c.stack] = 0 end
							if c.count < exch then
								to_take[c.stack] = to_take[c.stack] + c.count
								exch = exch - 1
							else
								to_take[c.stack] = to_take[c.stack] + exch
								break
							end
						end

						inv:set_list(listname, take_from_list(list, tool:get_name(), to_take))
					end
				end
			end
		end
	end
end

local function on_timer(pos, elapsed)
	local meta    = minetest.get_meta(pos)
	local inv     = meta:get_inventory()
	local refresh = false

	local output = nil

	-- Get selected tool type
	local tool_type = meta:get_string("tool_type")
	local list      = inv:get_list("input")

	if tool_type ~= "" then
		local results = tool_station.get_types(list, tool_type)
		if results then
			-- Attempt to create the tool with the provided materials
			local tool_res = tinkering.create_tool(tool_type, results, true)
			if tool_res then
				output = tool_res
			end
		end
		meta:set_string("formspec", tool_station.get_formspec(tinkering.tools[tool_type].components))
	else
		local tool, tool_type_ = tool_station.get_tool(list)
		if tool then
			local comp_mats = tool:get_meta():get_string("materials")
			if comp_mats and comp_mats ~= "" then
				local materials = decode_meta(comp_mats)
				-- Material list found, now we can start doing repair work or replacing a component
				local mat_grid = get_materials_in_list(list, tool:get_name())
				
				-- Find components to replace
				local comp_repl = {}
				local repair = true
				local tool_comps = tinkering.tools[tool_type_].components
				for mat, stat in pairs(mat_grid) do
					if comp_repl == nil then break end
					for name, comp in pairs(tool_comps) do
						if stat.type == comp then
							if comp_repl[name] then
								-- Dont allow multiple of the same component to avoid confusion
								comp_repl = nil
								break
							else
								comp_repl[name] = mat
							end
							repair = false
						end
					end
				end

				if not repair and comp_repl then
					-- Add non-replacement materials back
					for i,v in pairs(materials) do
						if not comp_repl[i] then
							comp_repl[i] = v
						end
					end

					local tool_res = tinkering.create_tool(tool_type_, comp_repl, true, nil, {wear = tool:get_wear()})
					if tool_res then
						output = tool_res
					end
				end

				-- Attempt to repair tool with provided items
				if tool:get_wear() ~= 0 and repair then
					local matches = match_materials(mat_grid, materials)
					local repair_cap = 0
					for mat, stat in pairs(matches) do
						repair_cap = repair_cap + math.min(stat.count, 3)
					end

					if repair_cap > 0 then
						local tool_wear = 65535 - tool:get_wear()
						local repair_cnt = (0.33 * 65535) * repair_cap
						local new_wear = 65535 - (tool_wear + repair_cnt)
						
						if new_wear < 0 then
							new_wear = 0
						end

						local tool_res = tinkering.create_tool(tool_type_, materials, true, nil, {wear = new_wear})
						if tool_res then
							output = tool_res
						end
					end
				end
			end
		end
		meta:set_string("formspec", tool_station.get_formspec())
	end

	if output then
		inv:set_list("output", {output})
	else
		inv:set_list("output", {})
	end

	return refresh
end

local function allow_metadata_inventory_put (pos, listname, index, stack, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return 0
	end

	if listname == "output" then
		return 0
	end

	return stack:get_count()
end

local function allow_metadata_inventory_move (pos, from_list, from_index, to_list, to_index, count, player)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	local stack = inv:get_stack(from_list, from_index)
	return allow_metadata_inventory_put(pos, to_list, to_index, stack, player)
end

local function allow_metadata_inventory_take (pos, listname, index, stack, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return 0
	end

	return stack:get_count()
end

local function on_construct(pos)
	local meta = minetest.get_meta(pos)
	meta:set_string("formspec", tool_station.get_formspec())
	
	-- Create inventory
	local inv = meta:get_inventory()
	inv:set_size('input', 9)
	inv:set_size('output', 1)

	-- Set tool type meta
	meta:set_string("tool_type", "")
end

local function on_take(pos, listname, index, stack, player)
	local inv = minetest.get_meta(pos):get_inventory()

	if listname == "output" then
		handle_take_output(pos, "input")
	end

	minetest.get_node_timer(pos):start(0.02)
end

local function can_dig(pos, player)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	return inv:is_empty("input") and inv:is_empty("output")
end

local function on_receive_fields(pos, formname, fields, sender)
	if sender and minetest.is_protected(pos, sender:get_player_name()) then
		return 0
	end

	local meta = minetest.get_meta(pos)
	if fields["anvil"] then
		meta:set_string("tool_type", "")
	else
		for name,_ in pairs(fields) do
			if tinkering.tools[name] then
				meta:set_string("tool_type", name)
				break
			end
		end
	end

	minetest.get_node_timer(pos):start(0.02)
end

minetest.register_node("tinkering:tool_station", {
	description = "Tool Station",
	tiles = {
		"tinkering_workbench_top.png", "tinkering_bench_bottom.png",
		"tinkering_bench_side.png",    "tinkering_bench_side.png",
		"tinkering_bench_side.png",    "tinkering_bench_side.png"
	},
	drawtype = "nodebox",
	paramtype = "light",
	node_box = tinkering.bench,

	on_construct = on_construct,
	legacy_facedir_simple = true,
	is_ground_content = false,
	sounds = default.node_sound_wood_defaults(),

	can_dig = can_dig,
	on_timer = on_timer,
	on_construct = on_construct,
	on_receive_fields = on_receive_fields,

	on_metadata_inventory_move = function(pos)
		minetest.get_node_timer(pos):start(0.05)
	end,
	on_metadata_inventory_put = function(pos)
		minetest.get_node_timer(pos):start(0.05)
	end,
	on_metadata_inventory_take = on_take,

	allow_metadata_inventory_put  = allow_metadata_inventory_put,
	allow_metadata_inventory_take = allow_metadata_inventory_take,
	allow_metadata_inventory_move = allow_metadata_inventory_move,

	groups = {choppy = 2, oddly_breakable_by_hand = 2}
})
