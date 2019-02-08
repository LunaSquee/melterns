-- Casts molten metals into a solid form

metal_caster = {}

metal_caster.max_coolant = 8000
metal_caster.max_metal = 16000

-- Use melter values
metal_caster.spec = metal_melter.spec

metal_caster.casts = {
	ingot = {description = "Ingot", result = "ingot",   cost = 1, typenames = {"ingot"}},
	lump  = {description = "Lump",  result = "lump",    cost = 2, typenames = {"lump"}},
	gem   = {description = "Gem",   result = "crystal", cost = 1, typenames = {"crystal", "gem"}}
}

local metal_cache = {}

function metal_caster.get_metal_caster_formspec(water, metal)
	local metal_formspec = "tooltip[6.68,0;0.8,2.45;No Molten Metal]"

	if metal ~= nil then
		metal_formspec = "tooltip[6.68,0;0.8,2.45;"..fluid_lib.buffer_to_string(metal).."]"
	end

	return "size[8,8.5]"..
		default.gui_bg..
		default.gui_bg_img..
		default.gui_slots..
		"list[context;cast;2.7,0.2;1,1;]"..
		"image[2.7,1.35;1,1;gui_furnace_arrow_bg.png^[transformFY]"..
		"list[context;output;2.7,2.5;1,1;]"..
		"image[0.08,2.5;1,1;metal_melter_gui_bucket.png]"..
		"list[context;coolant;0.08,2.5;1,1;]"..
		metal_melter.fluid_bar(0.08, 0, water)..
		"tooltip[0.08,0;0.8,2.45;".. fluid_lib.buffer_to_string(water) .."]"..
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
		"listring[context;coolant]"..
		"listring[current_player;main]"..
		"listring[context;cast]"..
		"listring[current_player;main]"..
		"listring[context;output]"..
		"listring[current_player;main]"..
		"listring[context;bucket_in]"..
		"listring[current_player;main]"..
		"listring[context;bucket_out]"..
		"listring[current_player;main]"..
		default.get_hotbar_bg(0, 4.25)
end

-- Check to see if this cast is able to cast this metal type

local function can_dig(pos, player)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	return inv:is_empty("cast") and inv:is_empty("coolant") and inv:is_empty("bucket_in") and inv:is_empty("bucket_out") and 
		inv:is_empty("output")
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

	if listname == "coolant" then
		if stack:get_name() ~= "bucket:bucket_water" then
			return 0
		end
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

-- Increment a stack by one
local function increment_stack(stack, appendix)
	if stack:is_empty() then
		return appendix
	end

	if stack:get_name() ~= appendix:get_name() then
		return stack
	end

	stack:set_count(stack:get_count() + 1)
	return stack
end

-- Decrement a stack by one
local function decrement_stack(stack)
	if stack:get_count() == 1 then
		return nil
	end

	stack:set_count(stack:get_count() - 1)
	return stack
end

local function in_table(t, n)
	local found = nil
	
	for _, v in pairs(t) do
		if v == n then
			found = v
		end
	end

	return found
end

-- Get the corresponding cast for an item
local function get_cast_for(item)
	local cast = nil
	local typename = nil

	for metal, types in pairs(metal_melter.melts) do
		if typename ~= nil then break end
		for t, items in pairs(types) do
			if in_table(items, item) then
				typename = t
				break
			end
		end
	end

	for cname,v in pairs(metal_caster.casts) do
		if v.result == typename then
			cast = cname
			break
		end
	end
	
	return typename, cast
end


local function find_castable(metal_name, cast_name)
	local cast = metal_caster.casts[cast_name]
	if not cast then return nil end

	local types = metal_melter.melts[metal_name]

	if not types then return nil end

	local typeres = types[cast.result]
	if not typeres then return nil end

	if #typeres > 0 then
		return typeres[1]
	end

	return nil
end

local function get_cast_for_name(name)
	for index, value in pairs(metal_caster.casts) do
		local mod = value.mod_name or "metal_melter"
		if name == mod..":"..index.."_cast" then
			return index
		end
	end

	return nil
end

local function caster_node_timer(pos, elapsed)
	local refresh = false
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()

	-- Current amount of water (coolant) in the block
	local coolant = fluid_lib.get_buffer_data(pos, "water")

	-- Current amount of metal in the block
	local metal = fluid_lib.get_buffer_data(pos, "metal")

	-- Current metal used
	local metal_type = ""

	local dumping = meta:get_int("dump")
	if dumping == 1 then
		metal.amount = 0
		metal.fluid = ""
		refresh = true
		meta:set_int("dump", 0)
	end

	-- Insert water bucket into tank, return empty bucket
	if inv:get_stack("coolant", 1):get_name() == "bucket:bucket_water" then
		if coolant.amount + 1000 <= metal_caster.max_coolant then
			coolant.amount = coolant.amount + 1000
			inv:set_list("coolant", {"bucket:bucket_empty"})
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
	if (bucket_name == "bucket:bucket_empty" or fluidity.florbs.get_is_florb(bucket_out)) and metal and metal.fluid ~= "" and bucket_out:get_count() == 1 then
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

	-- If we have a cast, check if we can cast right now.
	if metal and metal.fluid ~= "" then
		metal_type = fluidity.get_metal_for_fluid(metal.fluid)

		local caststack = inv:get_stack("cast", 1):get_name()
		local castname  = get_cast_for_name(caststack)
		if castname ~= nil then
			-- Cast metal using a cast
			local cast = metal_caster.casts[castname]
			local result_name = find_castable(metal_type, castname)
			if result_name ~= nil then
				local result_cost = cast.cost * metal_caster.spec.ingot
				local coolant_cost = result_cost / 4

				if metal.amount >= result_cost and coolant.amount >= coolant_cost then
					local stack = ItemStack(result_name)
					local output_stack = inv:get_stack("output", 1)
					if output_stack:item_fits(stack) then
						inv:set_stack("output", 1, increment_stack(output_stack, stack))
						metal.amount = metal.amount - result_cost
						coolant.amount = coolant.amount - coolant_cost

						if metal.amount == 0 then
							metal.fluid = ""
						end

						refresh = true
					end
				end
			end
		else
			-- Create a new cast
			local result_cost = metal_caster.spec.cast
			local coolant_cost = result_cost / 4
			if metal.amount >= result_cost and coolant.amount >= coolant_cost then
				local mtype, ctype = get_cast_for(caststack)
				if mtype and ctype then
					local cmod = metal_caster.casts[ctype].mod_name or "metal_melter"
					local stack = ItemStack(cmod..":"..ctype.."_cast")
					local output_stack = inv:get_stack("output", 1)
					local cast_stack = inv:get_stack("cast", 1)
					if output_stack:item_fits(stack) then
						inv:set_stack("output", 1, increment_stack(output_stack, stack))
						inv:set_stack("cast", 1, decrement_stack(cast_stack))
						metal.amount = metal.amount - result_cost
						coolant.amount = coolant.amount - coolant_cost

						if metal.amount == 0 then
							metal.fluid = ""
						end
						
						refresh = true
					end
				end
			end
		end
	end

	meta:set_int("water_fluid_storage", coolant.amount)
	meta:set_int("metal_fluid_storage", metal.amount)
	meta:set_string("metal_fluid", metal.fluid)
	meta:set_string("water_fluid", "default:water_source")

	local infotext = "Metal Caster\n"
	infotext = infotext .. fluid_lib.buffer_to_string(coolant) .. "\n"
	
	if metal and metal.fluid ~= "" then
		infotext = infotext .. fluid_lib.buffer_to_string(metal)
	else
		infotext = infotext .. "No Molten Metal"
	end

	meta:set_string("infotext", infotext)
	meta:set_string("formspec", metal_caster.get_metal_caster_formspec(coolant, metal))

	return refresh
end

local function on_construct(pos)
	local meta = minetest.get_meta(pos)
	meta:set_string("formspec", metal_caster.get_metal_caster_formspec())
	
	-- Create inventory
	local inv = meta:get_inventory()
	inv:set_size('cast', 1)
	inv:set_size('output', 1)
	inv:set_size('coolant', 1)
	inv:set_size('bucket_in', 1)
	inv:set_size('bucket_out', 1)

	-- Water source block
	meta:set_string('water_fluid', 'default:water_source')

	-- Default infotext
	meta:set_string("infotext", "Metal Caster Inactive")
end

-- Register a new cast
function metal_caster.register_cast(name, data)
	local mod      = data.mod_name or minetest.get_current_modname()
	local castname = mod..":"..name.."_cast"

	minetest.register_craftitem(castname, {
		description     = data.description.." Cast\n\nMaterial Cost: "..data.cost,
		inventory_image = "caster_"..name.."_cast.png",
		stack_max       = 1,
		groups          = {tinker_cast=1}
	})

	if not metal_caster.casts[name] then
		data.mod_name = mod
		metal_caster.casts[name] = data
	end

	metal_melter.register_melt(castname, "gold", "cast")
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
		elseif stack_name == "bucket:bucket_water" then
			return inv:add_item("coolant", stack)
		elseif stack_name:find(":bucket_") ~= nil or fluidity.florbs.get_is_florb(stack) then
			return inv:add_item("bucket_in", stack)
		end
		
		return ItemStack(nil)
	end

	pipeworks = {
		connect_sides   = {left = 1, right = 1, back = 1, bottom = 1, top = 1},
		insert_object   = insert_object,
		input_inventory = "output",
	}
end

-- Register the caster
minetest.register_node("metal_melter:metal_caster", {
	description = "Metal Caster",
	tiles = {
		"melter_side.png"..tube_entry, "melter_side.png"..tube_entry,
		"melter_side.png"..tube_entry, "melter_side.png"..tube_entry,
		"melter_side.png"..tube_entry, "caster_front.png"
	},
	paramtype2 = "facedir",
	groups = {
		cracky=2,
		tubedevice = 1,
		tubedevice_receiver = 1,
		fluid_container = 1,
	},
	legacy_facedir_simple = true,
	is_ground_content = false,
	sounds = default.node_sound_stone_defaults(),

	can_dig = can_dig,
	on_timer = caster_node_timer,
	on_construct = on_construct,
	on_metadata_inventory_move = function(pos)
		minetest.get_node_timer(pos):start(1.0)
	end,
	on_metadata_inventory_put = function(pos)
		minetest.get_node_timer(pos):start(1.0)
	end,
	on_metadata_inventory_take = function(pos)
		minetest.get_node_timer(pos):start(1.0)
	end,
	on_receive_fields = on_receive_fields,
	on_blast = function(pos)
		local drops = {}
		default.get_inventory_drops(pos, "cast", drops)
		default.get_inventory_drops(pos, "output", drops)
		default.get_inventory_drops(pos, "coolant", drops)
		default.get_inventory_drops(pos, "bucket_in", drops)
		default.get_inventory_drops(pos, "bucket_out", drops)
		drops[#drops+1] = "metal_melter:metal_caster"
		minetest.remove_node(pos)
		return drops
	end,

	allow_metadata_inventory_put = allow_metadata_inventory_put,
	allow_metadata_inventory_move = allow_metadata_inventory_move,
	allow_metadata_inventory_take = allow_metadata_inventory_take,

	fluid_buffers = {
		water = {
			capacity  = metal_caster.max_coolant,
			accepts   = {"default:water_source"},
			drainable = false,
		},
		metal = {
			capacity = metal_caster.max_metal,
			accepts  = "group:molten_metal",
		}
	},

	tube = pipeworks,
})

fluid_lib.register_node("metal_melter:metal_caster")

for i,v in pairs(metal_caster.casts) do
	metal_caster.register_cast(i, v)
end
