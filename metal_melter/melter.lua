-- Melts metals using lava as a heat source.

-- Max lava that can be held by the melter.
metal_melter.max_fuel = 8000

-- Spec divided by this number is the lava usage.
metal_melter.lava_usage = 9

-- Max metal that can be held by the melter.
metal_melter.max_metal = 16000

-- How much metal is given for melting a typename (in millibuckets).
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
	local heat_count = meta:get_int("lava_fluid_storage")

	-- Current amount of metal in the block
	local metal_count = meta:get_int("metal_fluid_storage")

	-- Current metal used
	local metal = meta:get_string("metal_fluid")

	local dumping = meta:get_int("dump")
	if dumping and dumping == 1 then
		metal_count = 0
		metal = ""
		refresh = true
		meta:set_int("dump", 0)
	end

	-- Insert lava bucket into tank, return empty bucket
	if inv:get_stack("heat", 1):get_name() == "bucket:bucket_lava" then
		if heat_count + 1000 <= metal_melter.max_fuel then
			heat_count = heat_count + 1000
			inv:set_list("heat", {"bucket:bucket_empty"})
			refresh = true
		end
	end

	-- Handle input bucket, only allow a molten metal
	local bucket_in   = inv:get_stack("bucket_in", 1)
	local bucket_name = bucket_in:get_name()
	if (bucket_name:find("bucket") and bucket_name ~= "bucket:bucket_empty") or (not fluidity.florbs.get_is_empty_florb(bucket_in) and fluidity.florbs.get_is_florb(bucket_in)) then
		local is_florb = fluidity.florbs.get_is_florb(bucket_in)
		if is_florb then
			local contents, fluid_name, capacity = fluidity.florbs.get_florb_contents(bucket_in)
			local fluid_metal = fluidity.get_metal_for_fluid(fluid_name)
			if fluid_metal and (fluid_name == metal or metal == "") then
				local take = 1000

				if metal_count + take > metal_melter.max_metal then
					take = metal_melter.max_metal - metal_count
				end

				-- Attempt to take 1000 millibuckets from the florb
				local stack,res = fluidity.florbs.take_fluid(bucket_in, take)
				if res > 0 then
					take = take - res
				end

				metal = fluid_name
				metal_count = metal_count + take
				inv:set_list("bucket_in", {stack})
				refresh = true
			end
		else
			local bucket_fluid = fluidity.get_fluid_for_bucket(bucket_name)
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
	end

	-- Handle bucket output, only allow empty buckets in this slot
	local bucket_out = inv:get_stack("bucket_out", 1)
	bucket_name      = bucket_out:get_name()
	if (bucket_name == "bucket:bucket_empty" or fluidity.florbs.get_is_florb(bucket_out)) and metal ~= "" and bucket_out:get_count() == 1 then
		local is_florb = fluidity.florbs.get_is_florb(bucket_out)
		if is_florb then
			local contents, fluid_name, capacity = fluidity.florbs.get_florb_contents(bucket_out)
			local fluid_metal = fluidity.get_metal_for_fluid(fluid_name)
			if not fluid_name or fluid_name == metal then
				local take = 1000

				if metal_count < take then
					take = metal_count
				end

				-- Attempt to put 1000 millibuckets into the florb
				local stack,res = fluidity.florbs.add_fluid(bucket_out, metal, take)
				if res > 0 then
					take = take - res
				end

				metal_count = metal_count - take
				inv:set_list("bucket_out", {stack})
				refresh = true

				if metal_count == 0 then
					metal = ""
				end
			end
		else
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
	end

	-- Handle metal input. Must be a: ingot, lump, block or ore.
	local input = inv:get_stack("input", 1):get_name()
	if input ~= "" then
		local mt, t = metal_melter.get_metal_from_stack(input)
		if mt then
			local metal_name = fluidity.molten_metals[mt]
			if metal_name and (metal == "" or metal == metal_name) then
				local cnt = metal_melter.spec[t]
				local heat_consume = math.floor(cnt / metal_melter.lava_usage)
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
	meta:set_int("lava_fluid_storage", heat_count)
	meta:set_int("metal_fluid_storage", metal_count)
	meta:set_string("metal_fluid", metal)

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
	meta:set_int('lava_fluid_storage', 0)
	meta:set_int('metal_fluid_storage', 0)

	-- Metal source block
	meta:set_string('metal_fluid', '')
	meta:set_string('lava_fluid',  'default:lava_source')

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
			capacity = metal_melter.max_fuel,
			accepts  = {"default:lava_source"}
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
			capacity = metal_melter.max_fuel,
			accepts  = {"default:lava_source"}
		},
		metal = {
			capacity = metal_melter.max_metal
		}
	},

	tube = pipeworks,
})

-- Set a spec
function metal_melter.set_spec(specname, value)
	metal_melter.spec[specname] = value
end
