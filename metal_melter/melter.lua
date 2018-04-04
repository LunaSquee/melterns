-- Melts metals using lava as a heat source

-- Max lava that can be held by the melter
metal_melter.max_fuel = 8000

-- Max metal that can be held by the melter
metal_melter.max_metal = 16000

-- How much metal is given for melting a typename (in millibuckets)
metal_melter.spec = {
	ingot = 144,
	crystal = 144,
	block = 1296,
	lump = 288,
	cast = 288,
	ore = 288
}

local function in_table(t, n)
	local found = nil
	
	for _, v in pairs(t) do
		if v == n then
			found = v
		end
	end

	return found
end

function metal_melter.get_metal_from_stack(stack)
	local metal = nil
	local metal_type = nil
	
	for mt, types in pairs(metal_melter.melts) do
		if metal then break end
		for tp,items in pairs(types) do
			if in_table(items, stack) then
				metal = mt
				metal_type = tp
				break
			end
		end
	end

	return metal, metal_type
end

function metal_melter.get_metal_melter_formspec_default()
	return "size[8,8.5]"..
		default.gui_bg..
		default.gui_bg_img..
		default.gui_slots..
		"list[context;input;2.25,0.2;1,1;]"..
		"list[context;heat;2.25,1.4;1,1;]"..
		"image[1.3,1.4;1,1;gui_furnace_arrow_bg.png^[transformR90]"..
		"image[0.08,0;1.4,2.8;melter_gui_barbg.png]"..
		"image[0.08,0;1.4,2.8;melter_gui_gauge.png]"..
		"label[0.08,3.4;Lava: 0/"..metal_melter.max_fuel.." mB]"..
		"image[6.68,0;1.4,2.8;melter_gui_barbg.png]"..
		"image[6.68,0;1.4,2.8;melter_gui_gauge.png]"..
		"label[0.08,3.75;No Molten Metal]"..
		"list[context;bucket_in;4.75,0.2;2,2;]"..
		"list[context;bucket_out;4.75,1.4;2,2;]"..
		"image[5.75,0.2;1,1;gui_furnace_arrow_bg.png^[transformR270]"..
		"image[5.75,1.4;1,1;gui_furnace_arrow_bg.png^[transformR90]"..
		"list[current_player;main;0,4.25;8,1;]"..
		"list[current_player;main;0,5.5;8,3;8]"..
		"listring[context;heat]"..
		"listring[current_player;main]"..
		"listring[context;input]"..
		"listring[current_player;main]"..
		"listring[context;bucket_in]"..
		"listring[current_player;main]"..
		"listring[context;bucket_out]"..
		"listring[current_player;main]"..
		default.get_hotbar_bg(0, 4.25)
end

function metal_melter.get_metal_melter_formspec(data)
	local lava_percent = data.lava_level / metal_melter.max_fuel
	local metal_percent = data.metal_level / metal_melter.max_metal

	local metal_formspec = "label[0.08,3.75;No Molten Metal]"

	if data.metal ~= "" then
		metal_formspec = "label[0.08,3.75;"..data.metal..": "..data.metal_level.."/"..metal_melter.max_metal.." mB]"
	end

	return "size[8,8.5]"..
		default.gui_bg..
		default.gui_bg_img..
		default.gui_slots..
		"list[context;input;2.25,0.2;1,1;]"..
		"list[context;heat;2.25,1.4;1,1;]"..
		"image[1.3,1.4;1,1;gui_furnace_arrow_bg.png^[transformR90]"..
		"image[0.08,0;1.4,2.8;melter_gui_barbg.png]"..
		"image[0.08,"..(2.44 - lava_percent * 2.44)..";1.4,"..(lava_percent * 2.8)..";default_lava.png]"..
		"image[0.08,0;1.4,2.8;melter_gui_gauge.png]"..
		"label[0.08,3.4;Lava: "..data.lava_level.."/"..metal_melter.max_fuel.." mB]"..
		"image[6.68,0;1.4,2.8;melter_gui_barbg.png]"..
		"image[6.68,"..(2.44 - metal_percent * 2.44)..";1.4,"..(metal_percent * 2.8)..";"..data.metal_texture.."]"..
		"image[6.68,0;1.4,2.8;melter_gui_gauge.png]"..
		metal_formspec..
		"list[context;bucket_in;4.75,0.2;1,1;]"..
		"list[context;bucket_out;4.75,1.4;1,1;]"..
		"image[5.75,0.2;1,1;gui_furnace_arrow_bg.png^[transformR270]"..
		"image[5.75,1.4;1,1;gui_furnace_arrow_bg.png^[transformR90]"..
		"list[current_player;main;0,4.25;8,1;]"..
		"list[current_player;main;0,5.5;8,3;8]"..
		"listring[context;heat]"..
		"listring[current_player;main]"..
		"listring[context;input]"..
		"listring[current_player;main]"..
		"listring[context;bucket_in]"..
		"listring[current_player;main]"..
		"listring[context;bucket_out]"..
		"listring[current_player;main]"..
		default.get_hotbar_bg(0, 4.25)
end

local function allow_metadata_inventory_put (pos, listname, index, stack, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return 0
	end

	if listname == "bucket_out" then
		if stack:get_name() ~= "bucket:bucket_empty" then
			return 0
		end

		return 1
	end

	if listname == "heat" then
		if stack:get_name() ~= "bucket:bucket_lava" then
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

local function take_from_stack(stack, count)
	-- Take count from stack, return nil if the item count reaches 0
	local newcount = stack:get_count() - count
	if newcount <= 0 then
		return nil
	end

	stack:set_count(newcount)
	return stack
end

local function swap_node(pos, name)
	local node = minetest.get_node(pos)
	if node.name == name then
		return
	end
	node.name = name
	minetest.swap_node(pos, node)
end

local function melter_node_timer(pos, elapsed)
	local refresh = false
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()

	-- Current amount of lava in the block
	local heat_count = meta:get_int("lava_level")

	-- Current amount of metal in the block
	local metal_count = meta:get_int("metal_level")

	-- Current metal used
	local metal = meta:get_string("metal")

	-- Insert lava bucket into tank, return empty bucket
	if inv:get_stack("heat", 1):get_name() == "bucket:bucket_lava" then
		if heat_count + 1000 <= metal_melter.max_fuel then
			heat_count = heat_count + 1000
			inv:set_list("heat", {"bucket:bucket_empty"})
			refresh = true
		end
	end

	-- Handle input bucket, only allow a molten metal
	local bucket_in = inv:get_stack("bucket_in", 1):get_name()
	if bucket_in:find("bucket") and bucket_in ~= "bucket:bucket_empty" then
		local bucket_fluid = fluidity.get_fluid_for_bucket(bucket_in)
		local fluid_is_metal = fluidity.get_metal_for_fluid(bucket_fluid) ~= nil
		local empty_bucket = false

		if fluid_is_metal then
			if metal ~= "" and metal == bucket_fluid then
				if metal_count + 1000 <= metal_melter.max_metal then
					metal_count = metal_count + 1000
					empty_bucket = true
				end
			elseif metal == "" then
				metal_count = 1000
				metal = bucket_fluid
				empty_bucket = true
			end
		end

		if empty_bucket then
			inv:set_list("bucket_in", {"bucket:bucket_empty"})
			refresh = true
		end
	end

	-- Handle bucket output, only allow empty buckets in this slot
	local bucket_out = inv:get_stack("bucket_out", 1):get_name()
	if bucket_out == "bucket:bucket_empty" and metal ~= "" and inv:get_stack("bucket_out", 1):get_count() == 1 then
		local bucket = fluidity.get_bucket_for_fluid(metal)
		if metal_count >= 1000 then
			metal_count = metal_count - 1000
			inv:set_list("bucket_out", {bucket})
			refresh = true

			if metal_count == 0 then
				metal = ""
			end
		end
	end

	-- Handle metal input. Must be a: ingot, lump, block or ore.
	local input = inv:get_stack("input", 1):get_name()
	if input ~= "" then
		local mt, t = metal_melter.get_metal_from_stack(input)
		if mt then
			local metal_name = fluidity.molten_metals[mt]
			if metal_name then
				local cnt = metal_melter.spec[t]
				local heat_consume = math.floor(cnt / 2)
				if metal_count + cnt <= metal_melter.max_metal and heat_count >= heat_consume then
					metal = metal_name
					metal_count = metal_count + cnt
					heat_count = heat_count - heat_consume
					inv:set_stack("input", 1, take_from_stack(inv:get_stack("input", 1), 1))
					refresh = true
				end
			end
		end
	end

	-- Refresh metadata and formspec
	if refresh then
		meta:set_int("lava_level", heat_count)
		meta:set_int("metal_level", metal_count)
		meta:set_string("metal", metal)

		local metal_texture = "default_lava.png"
		local metal_name = ""

		local infotext = "Metal Melter\n"
		infotext = infotext.."Lava: "..heat_count.."/"..metal_melter.max_fuel.." mB \n"
		
		if metal ~= "" then
			metal_texture = "fluidity_"..fluidity.get_metal_for_fluid(metal)..".png"

			local metal_node = minetest.registered_nodes[metal]
			metal_name = fluidity.fluid_name(metal_node.description)
			infotext = infotext..metal_name..": "..metal_count.."/"..metal_melter.max_metal.." mB"
		else
			infotext = infotext.."No Molten Metal"
		end

		if heat_count > 144 then
			swap_node(pos, "metal_melter:metal_melter_filled")
		else
			swap_node(pos, "metal_melter:metal_melter")
		end

		meta:set_string("infotext", infotext)
		meta:set_string("formspec", metal_melter.get_metal_melter_formspec(
			{lava_level=heat_count, metal_level=metal_count, metal_texture=metal_texture, metal=metal_name}))
	end

	-- If true, calls for another clock cycle.
	return refresh
end

local function on_construct(pos)
	local meta = minetest.get_meta(pos)
	meta:set_string("formspec", metal_melter.get_metal_melter_formspec_default())
	
	-- Create inventory
	local inv = meta:get_inventory()
	inv:set_size('input', 1)
	inv:set_size('heat', 1)
	inv:set_size('bucket_in', 1)
	inv:set_size('bucket_out', 1)

	-- Fluid buffers
	meta:set_int('lava_level', 0)
	meta:set_int('metal_level', 0)

	-- Metal source block
	meta:set_string('metal', '')

	-- Default infotext
	meta:set_string("infotext", "Metal Melter Inactive")
end

local function can_dig(pos, player)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	return inv:is_empty("input") and inv:is_empty("heat") and inv:is_empty("bucket_in") and inv:is_empty("bucket_out")
end

minetest.register_node("metal_melter:metal_melter", {
	description = "Metal Melter",
	tiles = {
		"melter_side.png", "melter_side.png",
		"melter_side.png", "melter_side.png",
		"melter_side.png", "melter_front.png"
	},
	paramtype2 = "facedir",
	groups = {cracky=2},
	legacy_facedir_simple = true,
	is_ground_content = false,
	sounds = default.node_sound_stone_defaults(),

	can_dig = can_dig,
	on_timer = melter_node_timer,
	on_construct = on_construct,
	on_metadata_inventory_move = function(pos)
		minetest.get_node_timer(pos):start(1.0)
	end,
	on_metadata_inventory_put = function(pos)
		minetest.get_node_timer(pos):start(1.0)
	end,
	on_blast = function(pos)
		local drops = {}
		default.get_inventory_drops(pos, "input", drops)
		default.get_inventory_drops(pos, "heat", drops)
		default.get_inventory_drops(pos, "bucket_in", drops)
		default.get_inventory_drops(pos, "bucket_out", drops)
		drops[#drops+1] = "metal_melter:metal_melter"
		minetest.remove_node(pos)
		return drops
	end,

	allow_metadata_inventory_put = allow_metadata_inventory_put,
	allow_metadata_inventory_move = allow_metadata_inventory_move,
	allow_metadata_inventory_take = allow_metadata_inventory_take,
})

minetest.register_node("metal_melter:metal_melter_filled", {
	tiles = {
		"melter_side.png", "melter_side.png",
		"melter_side.png", "melter_side.png",
		"melter_side.png", "melter_front.png^melter_front_lava.png"
	},
	paramtype2 = "facedir",
	groups = {cracky=2,not_in_creative_inventory=1},
	legacy_facedir_simple = true,
	is_ground_content = false,
	sounds = default.node_sound_stone_defaults(),

	drop = "metal_melter:metal_melter",
	light_source = 8,
	can_dig = can_dig,
	on_timer = melter_node_timer,
	on_construct = on_construct,

	on_metadata_inventory_move = function(pos)
		minetest.get_node_timer(pos):start(1.0)
	end,
	on_metadata_inventory_put = function(pos)
		minetest.get_node_timer(pos):start(1.0)
	end,

	allow_metadata_inventory_put = allow_metadata_inventory_put,
	allow_metadata_inventory_move = allow_metadata_inventory_move,
	allow_metadata_inventory_take = allow_metadata_inventory_take,
})

-- Set a spec
function metal_melter.set_spec(specname, value)
	metal_melter.spec[specname] = value
end
