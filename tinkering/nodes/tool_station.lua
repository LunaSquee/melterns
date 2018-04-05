-- TODO: Repair
tool_station = {}

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

function tool_station.get_formspec()
	local tool_list = tool_station.get_tool_type_list(8, 0, 5)
	return "size[13,8.5]"..
		default.gui_bg..
		default.gui_bg_img..
		default.gui_slots..
		"list[context;input;1,0.25;3,3;]"..
		"list[context;output;5,1.25;1,1;]"..
		"image[4,1.25;1,1;gui_furnace_arrow_bg.png^[transformR270]"..
		"list[current_player;main;0,4.25;8,1;]"..
		"list[current_player;main;0,5.5;8,3;8]"..
		tool_list..
		"listring[context;input]"..
		"listring[current_player;main]"..
		"listring[context;output]"..
		"listring[current_player;main]"..
		default.get_hotbar_bg(0, 4.25)
end

local function get_metalgroup(groups)
	if not groups then return nil end
	for g,i in pairs(groups) do
		if g:find("metal_") == 1 then
			return g:gsub("^metal_", "")
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

	for _,stack in pairs(list) do
		local stack_name = stack:get_name()
		for tt, ty in pairs(tool.components) do
			local in_grp = minetest.get_item_group(stack_name, "tc_"..ty) > 0
			if in_grp then
				local mtg = get_metalgroup(minetest.registered_items[stack_name].groups)
				if mtg ~= nil then
					result[tt] = mtg
					
					if not items_required[stack_name] then
						items_required[stack_name] = 0
					end

					items_required[stack_name] = items_required[stack_name] + 1
				end
			end
		end
	end

	return result, items_required
end

local function handle_take_output(pos, listname)
	local meta = minetest.get_meta(pos)
	local inv  = meta:get_inventory()

	local tooltype = meta:get_string("tool_type")

	if tooltype ~= "" then
		local list = inv:get_list(listname)
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
	end
end

local function on_timer(pos, elapsed)
	local meta    = minetest.get_meta(pos)
	local inv     = meta:get_inventory()
	local refresh = false

	local output = nil

	-- Get selected tool type
	local tool_type = meta:get_string("tool_type")

	if tool_type ~= "" then
		local list    = inv:get_list("input")
		local results = tool_station.get_types(list, tool_type)
		if results then
			-- Attempt to create the tool with the provided materials
			local tool_res = tinkering.create_tool(tool_type, results, true)
			if tool_res then
				output = tool_res
			end
		end
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
