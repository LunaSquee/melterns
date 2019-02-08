-- Melts metals using lava as a heat source.

-- Max lava that can be held by the melter.
metal_melter.max_fuel = 8000

-- Spec divided by this number is the lava usage.
metal_melter.lava_usage = 9

-- Max metal that can be held by the melter.
metal_melter.max_metal = 16000

-- How much metal is given for melting a typename (in millibuckets).
metal_melter.spec = {
	ingot   = 144,
	crystal = 144,
	block   = 1296,
	lump    = 288,
	cast    = 288,
	ore     = 288,
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

function metal_melter.get_metal_melter_formspec(lava, metal)
	local metal_formspec = "tooltip[6.68,0;0.8,2.45;No Molten Metal]"

	if metal ~= nil then
		metal_formspec = "tooltip[6.68,0;0.8,2.45;"..fluid_lib.buffer_to_string(metal).."]"
	end

	return "size[8,8.5]"..
		default.gui_bg..
		default.gui_bg_img..
		default.gui_slots..
		"image[2.25,0.2;1,1;metal_melter_gui_lump.png]"..
		"list[context;input;2.25,0.2;1,1;]"..
		"image[2.25,1.4;1,1;metal_melter_gui_bucket.png]"..
		"list[context;heat;2.25,1.4;1,1;]"..
		"image[1.3,1.4;1,1;gui_furnace_arrow_bg.png^[transformR90]"..
		metal_melter.fluid_bar(0.08, 0, lava)..
		"tooltip[0.08,0;0.8,2.45;".. fluid_lib.buffer_to_string(lava) .."]"..
		metal_melter.fluid_bar(6.68, 0, metal)..
		metal_formspec..
		"image[4.7,0.2;1,1;metal_melter_gui_bucket.png]"..
		"image[4.7,1.4;1,1;metal_melter_gui_bucket.png]"..
		"list[context;bucket_in;4.7,0.2;1,1;]"..
		"list[context;bucket_out;4.7,1.4;1,1;]"..
		"image[5.7,0.2;1,1;gui_furnace_arrow_bg.png^[transformR270]"..
		"image[5.7,1.4;1,1;gui_furnace_arrow_bg.png^[transformR90]"..
		"button[6.68,2.48;1.33,1;dump;Dump]"..
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

local function get_bucket_for_fluid(src)
	local bucket = bucket.liquids[src]
	if not bucket then return nil end
	return bucket.itemname
end

local function allow_metadata_inventory_put (pos, listname, index, stack, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return 0
	end

	if listname == "bucket_out" then
		if stack:get_name() ~= "bucket:bucket_empty" and not fluidity.florbs.get_is_florb(stack) then
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
	local lava  = fluid_lib.get_buffer_data(pos, "lava")

	-- Current metal used
	local metal = fluid_lib.get_buffer_data(pos, "metal")

	local dumping = meta:get_int("dump")
	if dumping == 1 then
		metal.amount = 0
		metal.fluid = ""
		refresh = true
		meta:set_int("dump", 0)
	end

	-- Insert lava bucket into tank, return empty bucket
	if inv:get_stack("heat", 1):get_name() == "bucket:bucket_lava" then
		if lava.amount + 1000 <= metal_melter.max_fuel then
			lava.amount = lava.amount + 1000
			inv:set_list("heat", {"bucket:bucket_empty"})
			refresh = true
		end
	end

	-- Handle input bucket, only allow a molten metal
	local bucket_in   = inv:get_stack("bucket_in", 1)
	local bucket_name = bucket_in:get_name()
	if (bucket_name:find("bucket") and bucket_name ~= "bucket:bucket_empty") or (not fluidity.florbs.get_is_empty_florb(bucket_in) and
			fluidity.florbs.get_is_florb(bucket_in)) then
		local is_florb = fluidity.florbs.get_is_florb(bucket_in)
		if is_florb then
			local contents, fluid_name, capacity = fluidity.florbs.get_florb_contents(bucket_in)
			local fluid_metal = fluidity.get_metal_for_fluid(fluid_name)
			if fluid_metal and (fluid_name == metal.fluid or metal.fluid == "") then
				local take = 1000

				if metal.amount + take > metal_melter.max_metal then
					take = metal_melter.max_metal - metal.amount
				end

				-- Attempt to take 1000 millibuckets from the florb
				local stack,res = fluidity.florbs.take_fluid(bucket_in, take)
				if res > 0 then
					take = take - res
				end

				metal.fluid = fluid_name
				metal.amount = metal.amount + take
				inv:set_list("bucket_in", {stack})
				refresh = true
			end
		else
			local bucket_fluid = bucket.get_liquid_for_bucket(bucket_name)
			local fluid_is_metal = fluidity.get_metal_for_fluid(bucket_fluid) ~= nil
			local empty_bucket = false

			if fluid_is_metal then
				if metal.fluid ~= "" and metal.fluid == bucket_fluid then
					if metal.amount + 1000 <= metal_melter.max_metal then
						metal.amount = metal.amount + 1000
						empty_bucket = true
					end
				elseif metal.fluid == "" then
					metal.amount = 1000
					metal.fluid = bucket_fluid
					empty_bucket = true
				end
			end

			if empty_bucket then
				inv:set_list("bucket_in", {"bucket:bucket_empty"})
				refresh = true
			end
		end
	end

	-- Handle bucket output, only allow empty buckets in this slot
	local bucket_out = inv:get_stack("bucket_out", 1)
	bucket_name      = bucket_out:get_name()
	if (bucket_name == "bucket:bucket_empty" or fluidity.florbs.get_is_florb(bucket_out)) and metal.fluid ~= "" and bucket_out:get_count() == 1 then
		local is_florb = fluidity.florbs.get_is_florb(bucket_out)
		if is_florb then
			local contents, fluid_name, capacity = fluidity.florbs.get_florb_contents(bucket_out)
			local fluid_metal = fluidity.get_metal_for_fluid(fluid_name)
			if not fluid_name or fluid_name == metal.fluid then
				local take = 1000

				if metal.amount < take then
					take = metal.amount
				end

				-- Attempt to put 1000 millibuckets into the florb
				local stack,res = fluidity.florbs.add_fluid(bucket_out, metal.fluid, take)
				if res > 0 then
					take = take - res
				end

				metal.amount = metal.amount - take
				inv:set_list("bucket_out", {stack})
				refresh = true

				if metal.amount == 0 then
					metal.fluid = ""
				end
			end
		else
			local bucket = get_bucket_for_fluid(metal.fluid)
			if bucket and metal.amount >= 1000 then
				metal.amount = metal.amount - 1000
				inv:set_list("bucket_out", {bucket})
				refresh = true

				if metal.amount == 0 then
					metal.fluid = ""
				end
			end
		end
	end

	-- Handle metal input. Must be a: ingot, lump, block or ore.
	local input = inv:get_stack("input", 1):get_name()
	if input ~= "" then
		local mt, t = metal_melter.get_metal_from_stack(input)
		if mt then
			local metal_name = fluidity.molten_metals[mt]
			if metal_name and (metal.fluid == "" or metal.fluid == metal_name) then
				local cnt = metal_melter.spec[t]
				local heat_consume = math.floor(cnt / metal_melter.lava_usage)
				if metal.amount + cnt <= metal_melter.max_metal and lava.amount >= heat_consume then
					metal.fluid = metal_name
					metal.amount = metal.amount + cnt
					lava.amount = lava.amount - heat_consume
					inv:set_stack("input", 1, take_from_stack(inv:get_stack("input", 1), 1))
					refresh = true
				end
			end
		end
	end

	-- Refresh metadata and formspec
	meta:set_int("lava_fluid_storage", lava.amount)
	meta:set_int("metal_fluid_storage", metal.amount)
	meta:set_string("metal_fluid", metal.fluid)
	meta:set_string("lava_fluid", "default:lava_source")

	local infotext = "Metal Melter\n"
	infotext = infotext .. fluid_lib.buffer_to_string(lava) .. "\n"
	
	if metal and metal.fluid ~= "" then
		infotext = fluid_lib.buffer_to_string(metal)
	else
		infotext = infotext .. "No Molten Metal"
	end

	if lava.amount > 144 then
		swap_node(pos, "metal_melter:metal_melter_filled")
	else
		swap_node(pos, "metal_melter:metal_melter")
	end

	meta:set_string("infotext", infotext)
	meta:set_string("formspec", metal_melter.get_metal_melter_formspec(lava, metal))

	-- If true, calls for another clock cycle.
	return refresh
end

local function on_construct(pos)
	local meta = minetest.get_meta(pos)
	meta:set_string("formspec", metal_melter.get_metal_melter_formspec())
	
	-- Create inventory
	local inv = meta:get_inventory()
	inv:set_size('input', 1)
	inv:set_size('heat', 1)
	inv:set_size('bucket_in', 1)
	inv:set_size('bucket_out', 1)

	-- Lava source block
	meta:set_string('lava_fluid', 'default:lava_source')

	-- Default infotext
	meta:set_string("infotext", "Metal Melter Inactive")
end

local function can_dig(pos, player)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	return inv:is_empty("input") and inv:is_empty("heat") and inv:is_empty("bucket_in") and inv:is_empty("bucket_out")
end

local function on_receive_fields(pos, formname, fields, sender)
	if sender and minetest.is_protected(pos, sender:get_player_name()) then
		return 0
	end

	local meta = minetest.get_meta(pos)
	if fields["dump"] then
		meta:set_int('dump', 1)
		minetest.get_node_timer(pos):start(1.0)
	end
end

-- Pipeworks integration
local pipeworks = {}
local tube_entry = ""
if minetest.get_modpath("pipeworks") ~= nil then
	tube_entry = "^pipeworks_tube_connection_metallic.png"

	local function insert_object(pos, node, stack, direction, owner)
		local stack_name = stack:get_name()
		local inv        = minetest.get_meta(pos):get_inventory()

		minetest.get_node_timer(pos):start(1.0)

		if stack_name == "bucket:bucket_empty" or fluidity.florbs.get_is_empty_florb(stack) then
			return inv:add_item("bucket_out", stack)
		elseif stack_name == "bucket:bucket_lava" then
			return inv:add_item("heat", stack)
		elseif stack_name:find(":bucket_") ~= nil or fluidity.florbs.get_is_florb(stack) then
			return inv:add_item("bucket_in", stack)
		else
			return inv:add_item("input", stack)
		end
	end

	pipeworks = {
		connect_sides   = {left = 1, right = 1, back = 1, bottom = 1, top = 1},
		insert_object   = insert_object,
		input_inventory = "bucket_out",
	}
end

minetest.register_node("metal_melter:metal_melter", {
	description = "Metal Melter",
	tiles = {
		"melter_side.png"..tube_entry, "melter_side.png"..tube_entry,
		"melter_side.png"..tube_entry, "melter_side.png"..tube_entry,
		"melter_side.png"..tube_entry, "melter_front.png"
	},
	paramtype2 = "facedir",
	groups = {
		cracky = 2,
		tubedevice = 1,
		tubedevice_receiver = 1,
		fluid_container = 1,
	},
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
	on_receive_fields = on_receive_fields,

	allow_metadata_inventory_put = allow_metadata_inventory_put,
	allow_metadata_inventory_move = allow_metadata_inventory_move,
	allow_metadata_inventory_take = allow_metadata_inventory_take,

	fluid_buffers = {
		lava = {
			capacity  = metal_melter.max_fuel,
			accepts   = {"default:lava_source"},
			drainable = false,
		},
		metal = {
			capacity = metal_melter.max_metal
		}
	},

	tube = pipeworks,
})

minetest.register_node("metal_melter:metal_melter_filled", {
	tiles = {
		"melter_side.png"..tube_entry, "melter_side.png"..tube_entry,
		"melter_side.png"..tube_entry, "melter_side.png"..tube_entry,
		"melter_side.png"..tube_entry, "melter_front.png^melter_front_lava.png"
	},
	paramtype2 = "facedir",
	groups = {
		cracky = 2,
		tubedevice = 1,
		tubedevice_receiver = 1,
		not_in_creative_inventory = 1,
		fluid_container = 1,
	},
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
	on_receive_fields = on_receive_fields,

	allow_metadata_inventory_put = allow_metadata_inventory_put,
	allow_metadata_inventory_move = allow_metadata_inventory_move,
	allow_metadata_inventory_take = allow_metadata_inventory_take,

	fluid_buffers = {
		lava = {
			capacity  = metal_melter.max_fuel,
			accepts   = {"default:lava_source"},
			drainable = false,
		},
		metal = {
			capacity = metal_melter.max_metal
		}
	},

	tube = pipeworks,
})

fluid_lib.register_node("metal_melter:metal_melter")
fluid_lib.register_node("metal_melter:metal_melter_filled")

-- Set a spec
function metal_melter.register_melt_value(specname, value)
	metal_melter.spec[specname] = value
end
