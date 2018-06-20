
fluidity.florbs = {}

local function get_itemdef_field(nodename, fieldname)
    if not minetest.registered_items[nodename] then
        return nil
    end
    return minetest.registered_items[nodename][fieldname]
end

function fluidity.florbs.get_is_florb(stack)
	return minetest.get_item_group(stack:get_name(), "florb") > 0
end

function fluidity.florbs.get_is_empty_florb(stack)
	return minetest.get_item_group(stack:get_name(), "florb_blank") > 0
end

function fluidity.florbs.get_florb_contents(stack)
	if not fluidity.florbs.get_is_florb(stack) then return nil end
	local fcapacity = get_itemdef_field(stack:get_name(), "_florb_capacity")
	local ffluid    = get_itemdef_field(stack:get_name(), "_florb_source")

	local meta = stack:get_meta()
	local contents = meta:get_int("contents")
	if not contents then
		contents = 0
	end

	return contents, ffluid, fcapacity
end

local function update_florb(stack)
	local def_desc = get_itemdef_field(stack:get_name(), "description")
	local meta = stack:get_meta()
	local contents, fluid_name, capacity = fluidity.florbs.get_florb_contents(stack)

	meta:set_string("description", def_desc.."\nContains "..contents.."/"..capacity.." mB")

	return stack
end

function fluidity.florbs.add_fluid(stack, source_name, amount)
	if not fluidity.florbs.get_is_florb(stack) then return nil end
	local source_node = minetest.registered_nodes[source_name]
	local fluid       = fluid_lib.cleanse_node_description(source_name)
	local internal    = fluidity.fluid_short(fluid)
	local florbname   = stack:get_name()

	if minetest.get_item_group(florbname, "florb_blank") > 0 then
		stack = ItemStack(florbname.."_"..internal)
	end

	local meta = stack:get_meta()
	local contents, fluid_name, capacity = fluidity.florbs.get_florb_contents(stack)

	local remainder = 0

	if contents + amount > capacity then
		remainder = (contents + amount) - capacity
		contents = capacity
	else
		contents = contents + amount
	end

	meta:set_int("contents", contents)
	stack = update_florb(stack)

	return stack, remainder
end

function fluidity.florbs.take_fluid(stack, amount)
	if not fluidity.florbs.get_is_florb(stack) then return nil end

	local meta = stack:get_meta()
	local contents, fluid_name, capacity = fluidity.florbs.get_florb_contents(stack)
	local blank = get_itemdef_field(stack:get_name(), "_florb_blank")

	local leftover = 0
	if contents - amount < 0 then
		leftover = (contents - amount) * -1
		contents = 0
	else
		contents = contents - amount
	end

	if contents == 0 then
		stack = ItemStack(blank)
	else
		meta:set_int("contents", contents)
		stack = update_florb(stack)
	end

	return stack, leftover
end

local function register_florbfluid(data)
	local source_node = minetest.registered_nodes[data.source_name]
	local fluid       = fluid_lib.cleanse_node_description(data.source_name)
	local internal    = fluidity.fluid_short(fluid)

	local itemname = data.mod_name..":"..data.florb_name.."_"..internal

	if minetest.registered_items[itemname] then
		return
	end

	local stationary_name = source_node.tiles[1].name:gsub("_source_animated", "")

	-- Register base item
	minetest.register_craftitem(itemname, {
		description     = data.florb_description.." ("..fluid..")",
		inventory_image = stationary_name.."^[noalpha^"..data.textures[1].."^"..data.textures[2].."^[makealpha:255,0,0,",
		_florb_capacity = data.capacity,
		_florb_source   = data.source_name,
		_florb_blank    = data.mod_name..":"..data.florb_name,
		stack_max       = 1,
		groups          = {florb = 1, not_in_creative_inventory = 1}
	})
end

function fluidity.florbs.register_florb(data)
	local mod_name   = data.mod_name or minetest.get_current_modname()
	local florb_name = data.florb_name or 'florb'
	local florb_desc = data.florb_description or 'Florb'
	local textures   = data.textures or {"fluidity_florb.png", "fluidity_florb_mask.png"}
	local capacity   = data.capacity or 1000
	local item_name  = mod_name..":"..florb_name

	if not minetest.registered_items[item_name] then
		-- Register base item
		minetest.register_craftitem(item_name, {
			description     = florb_desc.." (Empty)\nThis item holds millibuckets of fluid.",
			inventory_image = textures[1].."^[noalpha^"..textures[2].."^[makealpha:255,0,0,",
			_florb_capacity = capacity,
			_florb_source   = nil,
			stack_max       = 1,
			groups          = {florb = 1, florb_blank = 1}
		})
	end

	-- Register for all fluids
	if data.fluids then
		-- This tank only uses certain fluids
		for _, v in pairs(data.fluids) do
			register_florbfluid({
				mod_name          = mod_name,
				florb_name        = florb_name,
				florb_description = florb_desc,
				textures          = textures,
				capacity          = capacity,
				source_name       = v
			})
		end
	else
		-- Get all fluids and buckets and cache them
		for i, v in pairs(bucket.liquids) do
			if (i:find("source") ~= nil) then
				-- Add tank
				register_florbfluid({
					mod_name          = mod_name,
					florb_name        = florb_name,
					florb_description = florb_desc,
					textures          = textures,
					capacity          = capacity,
					source_name       = v["source"]
				})
			end
		end
	end
end
