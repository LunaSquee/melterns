
local mer = fluidity.external.ref

pattern_table = {}

function pattern_table.get_tool_type_list(ix, iy, mx)
	local formspec = ""
	local x        = 0
	local y        = 0

	for t, pattern in pairs(tinkering.patterns) do
		local mod = pattern.mod_name or "tinkering"
		formspec = formspec.. ("item_image_button[%f,%f;1,1;%s;%s;]"):format(x + ix, y + iy, mod..":"..t.."_pattern", t)
		x = x + 1.25
		if x >= mx then
			y = y + 1.25
			x = 0
		end
	end

	return formspec
end

function pattern_table.get_formspec()
	local pattern_list = pattern_table.get_tool_type_list(11.75, 0.375, 6.25)
	return "formspec_version[4]size[18,10.45]"..
		"label[0.375,0.375;Pattern Table]"..
		mer.get_itemslot_bg(4.125, 2, 1, 1) ..
		"list[context;input;4.125,2;1,1;]"..
		mer.get_itemslot_bg(6.625, 2, 1, 1) ..
		"list[context;output;6.625,2;1,1;]"..
		"image[5.375,2;1,1;"..mer.gui_furnace_arrow.."^[transformR270]"..
		mer.gui_player_inv()..
		pattern_list..
		"listring[current_player;main]"..
		"listring[context;input]"..
		"listring[current_player;main]"..
		"listring[context;output]"..
		"listring[current_player;main]"
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

	if listname == "input" and minetest.get_item_group(stack:get_name(), "tinker_pattern") == 0 then 
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
	meta:set_string("formspec", pattern_table.get_formspec())
	
	-- Create inventory
	local inv = meta:get_inventory()
	inv:set_size('input', 1)
	inv:set_size('output', 1)
end

local function on_take(pos, listname, index, stack, player)
	local inv = minetest.get_meta(pos):get_inventory()
end

local function can_dig(pos, player)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	return inv:is_empty("input") and inv:is_empty("output")
end

local function convert_blank(pos, btn)
	local inv     = minetest.get_meta(pos):get_inventory()
	local pattern = tinkering.patterns[btn]

	if not pattern then return nil end

	local itemname = ItemStack(pattern.mod_name..":"..btn.."_pattern")

	local input = inv:get_stack("input", 1)
	if minetest.get_item_group(input:get_name(), "tinker_pattern") == 0 then return end

	if inv:room_for_item("output", itemname) then
		inv:add_item("output", itemname)
		input:set_count(input:get_count() - 1)
		inv:set_stack("input", 1, input)
	end
end

local function on_receive_fields(pos, formname, fields, sender)
	if sender and minetest.is_protected(pos, sender:get_player_name()) then
		return 0
	end

	if not fields["quit"] then
		for field in pairs(fields) do
			convert_blank(pos, field)
			break
		end
	end

	minetest.get_node_timer(pos):start(0.02)
end

minetest.register_node("tinkering:pattern_table", {
	description = "Pattern Table",
	tiles = {
		"tinkering_pattern_bench.png", "tinkering_bench_bottom.png",
		"tinkering_bench_side.png",    "tinkering_bench_side.png",
		"tinkering_bench_side.png",    "tinkering_bench_side.png"
	},
	drawtype = "nodebox",
	paramtype = "light",
	node_box = tinkering.bench,

	on_construct = on_construct,
	legacy_facedir_simple = true,
	is_ground_content = false,
	sounds = fluidity.external.sounds.node_sound_wood,

	can_dig = can_dig,
	on_construct = on_construct,
	on_receive_fields = on_receive_fields,

	allow_metadata_inventory_put  = allow_metadata_inventory_put,
	allow_metadata_inventory_take = allow_metadata_inventory_take,
	allow_metadata_inventory_move = allow_metadata_inventory_move,

	groups = {choppy = 3, axey = 1, oddly_breakable_by_hand = 1},

	_mcl_hardness = 1,
	_mcl_blast_resistance = 1,
})
