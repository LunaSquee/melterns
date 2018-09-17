part_builder = {}

function part_builder.get_formspec()
	return "size[8,8.5]"..
		default.gui_bg..
		default.gui_bg_img..
		default.gui_slots..
		"label[0,0;Part Builder]"..
		"list[context;pattern;1,1.5;1,1;]"..
		"list[context;input;2,1;1,2;]"..
		"list[context;output;6,1.5;1,1;]"..
		"image[4,1.5;1,1;gui_furnace_arrow_bg.png^[transformR270]"..
		"list[current_player;main;0,4.25;8,1;]"..
		"list[current_player;main;0,5.5;8,3;8]"..
		"listring[current_player;main]"..
		"listring[context;pattern]"..
		"listring[current_player;main]"..
		"listring[context;input]"..
		"listring[current_player;main]"..
		"listring[context;output]"..
		"listring[current_player;main]"..
		default.get_hotbar_bg(0, 4.25)
end

local function get_template_group(groups)
	if not groups then return nil end
	for g,i in pairs(groups) do
		if g:find("tc_") == 1 then
			return g:gsub("^tc_", "")
		end
	end
	return nil
end

local function find_buildable(material_name, pattern_name)
	local types = metal_melter.melts[material_name]

	if not types then return nil end

	local typeres = types[pattern_name]
	if not typeres then return nil end

	if #typeres > 0 then
		return typeres[1]
	end

	return nil
end

local function find_material_match(type, stack)
	local match  = nil

	for mat,iv in pairs(tinkering.materials) do
		if match then break end
		if not iv.cast then
			if iv.base == "group" and minetest.get_item_group(stack, iv.default) > 0 then
				match = mat
			elseif stack == iv.default then
				match = mat
			end
		end
	end

	return match
end

local function get_output(inv)
	local pattern      = inv:get_stack("pattern", 1):get_name()
	local find_pattern = get_template_group(minetest.registered_items[pattern].groups)

	if not find_pattern then return nil end
	local list = inv:get_list("input")

	local material    = nil
	local total_count = 0
	local output      = nil

	for _,stack in pairs(list) do
		if not stack:is_empty() then
			local mat = find_material_match(find_pattern, stack:get_name())

			-- Both input slots need to be of the same material, unless one of them is empty
			if material and mat ~= material then
				material = nil
				break
			end

			material = mat
			total_count = total_count + stack:get_count()
		end
	end

	if not material then return nil end
	local cost = tinkering.patterns[find_pattern].cost

	if total_count < cost then return nil end

	local output_stack = find_buildable(material, find_pattern)

	return output_stack, cost
end

local function handle_take_output(pos, listname)
	local inv = minetest.get_meta(pos):get_inventory()

	local output, cost = get_output(inv)
	local left = cost

	local input = inv:get_list("input")
	for _,stack in pairs(input) do
		if not stack:is_empty() then
			local stack_cnt = stack:get_count()
			if stack_cnt > left then
				stack:set_count(stack_cnt - left)
				break
			else
				if stack_cnt == left then
					stack:clear()
					break
				else
					left = left - stack:get_count()
					stack:clear()
				end
			end
		end
	end

	inv:set_list("input", input)
	minetest.get_node_timer(pos):start(0.05)
end

local function on_timer(pos, elapsed)
	local meta    = minetest.get_meta(pos)
	local inv     = meta:get_inventory()

	local output = get_output(inv)

	if output then
		inv:set_list("output", {output})
	else
		inv:set_list("output", {})
	end

	return false
end

local function allow_metadata_inventory_put (pos, listname, index, stack, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return 0
	end

	if listname == "output" then
		return 0
	end

	if listname == "pattern" then
		if minetest.get_item_group(stack:get_name(), "tinker_pattern") == 0 then
			return 0
		end
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
	meta:set_string("formspec", part_builder.get_formspec())
	
	-- Create inventory
	local inv = meta:get_inventory()
	inv:set_size('pattern', 1)
	inv:set_size('input', 2)
	inv:set_size('output', 1)
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
	return inv:is_empty("input") and inv:is_empty("output") and inv:is_empty("pattern")
end

local function on_receive_fields(pos, formname, fields, sender)
	if sender and minetest.is_protected(pos, sender:get_player_name()) then
		return 0
	end

	minetest.get_node_timer(pos):start(0.02)
end

minetest.register_node("tinkering:part_builder", {
	description = "Part Builder",
	tiles = {
		"tinkering_blank_pattern.png",  "tinkering_bench_bottom.png",
		"tinkering_bench_side.png",     "tinkering_bench_side.png",
		"tinkering_bench_side.png",     "tinkering_bench_side.png"
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
