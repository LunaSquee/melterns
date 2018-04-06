-- Register tanks for each fluid

fluidity.bucket_cache = {}
fluidity.tanks = {}

-- Get fluid source block name for bucket item.
function fluidity.get_fluid_for_bucket(itemname)
	for i,v in pairs(fluidity.bucket_cache) do
		if v == itemname then
			return i
		end
	end
end

-- Get bucket item name for fluid source block.
function fluidity.get_bucket_for_fluid(source)
	return fluidity.bucket_cache[source]
end

-- Ensure that this fluid node exists.
function fluidity.get_fluid_node(name)
	return minetest.registered_nodes[name]
end

-- Get a nodedef field.
local function get_nodedef_field(nodename, fieldname)
    if not minetest.registered_nodes[nodename] then
        return nil
    end
    return minetest.registered_nodes[nodename][fieldname]
end

-- Ensure that the node is a tank.
function fluidity.tanks.get_is_tank(node)
	return minetest.get_item_group(node, "fluidity_tank") > 0
end

-- Ensure that the node is an empty tank.
function fluidity.tanks.get_is_empty_tank(node)
	return minetest.get_item_group(node, "fluidity_tank_empty") > 0
end

-- Get tank data at position.
-- Returns fluid name, fluid level, capacity, base tank name and the mod it was added from.
-- Base tank name and mod name are used to construct different variants of this tank type.
function fluidity.tanks.get_tank_at(pos)
	local meta = minetest.get_meta(pos)
	local node = minetest.get_node(pos)
	
	if not fluidity.tanks.get_is_tank(node.name) then return nil end

	local ffluid     = get_nodedef_field(node.name, "fluidity_fluid")
	local fcapacity  = get_nodedef_field(node.name, "_capacity")
	local fbasetank  = get_nodedef_field(node.name, "_dataname")
	local fmod       = get_nodedef_field(node.name, "_mod")
	local fluidcount = meta:get_int("fluid")

	return ffluid, fluidcount, fcapacity, fbasetank, fmod
end

-- Check to see if a fluid can go in the tank and pos.
function fluidity.tanks.can_fluid_go_in_tank(pos, fluid)
	local fluid_name, count, capacity, base_tank, mod = fluidity.tanks.get_tank_at(pos)
	if not fluid_name then return true end
	if fluid_name ~= fluid then return false end
	if count == capacity then return false end

	local source_node    = fluidity.get_fluid_node(fluid)
	local fluid_desc     = fluidity.fluid_name(source_node.description)
	local shorthand_name = fluidity.fluid_short(fluid_desc)
	
	if not minetest.registered_nodes[mod..":"..base_tank.."_"..shorthand_name] then return false end

	return true
end

-- Fill the tank at pos with fluid.
-- Overfilling means it will return an integer as the second variable that shows the amount over the capacity.
function fluidity.tanks.fill_tank_at(pos, fluid, amount, overfill)
	local fluid_name, count, capacity, base_tank, mod = fluidity.tanks.get_tank_at(pos)
	if not fluid_name == fluid and fluid_name ~= nil then return nil end
	local node = minetest.get_node(pos)
	local meta = minetest.get_meta(pos)
	local node_name = mod..":"..base_tank 

	local remainder = 0
	if count + amount > capacity then
		if overfill then
			remainder = (count + amount) - capacity
			count = capacity
		else
			return nil
		end
	else
		count = count + amount
	end

	local source_node    = fluidity.get_fluid_node(fluid)
	local fluid_desc     = fluidity.fluid_name(source_node.description)
	local shorthand_name = fluidity.fluid_short(fluid_desc)

	node_name = mod..":"..base_tank.."_"..shorthand_name
	if not minetest.registered_nodes[node_name] then return nil end

	meta:set_int("fluid", count)
	meta:set_string("infotext", "Tank of "..fluid_desc.."("..count.."/"..capacity.." mB)")

	local param2 = math.min((count/capacity)*63, 63)

	minetest.swap_node(pos, {name=node_name,param1=node.param1,param2=param2})

	return fluid, remainder
end

-- Take some fluid from the tank at pos.
-- Underfill returns an integer as the second variable indicating level below zero.
function fluidity.tanks.take_from_tank_at(pos, amount, underfill)
	local fluid_name, count, capacity, base_tank, mod = fluidity.tanks.get_tank_at(pos)
	if not fluid_name then return nil end
	local node      = minetest.get_node(pos)
	local meta      = minetest.get_meta(pos)
	local node_name = mod..":"..base_tank
	local fluid     = fluid_name

	local leftover = 0
	if count - amount < 0 then
		if underfill then
			leftover = (count - amount) * -1
			count = 0
		else
			return nil
		end
	else
		count = count - amount
	end

	if count == 0 then
		fluid = nil
	end

	meta:set_int("fluid", count)

	if fluid then
		local source_node    = fluidity.get_fluid_node(fluid)
		local fluid_desc     = fluidity.fluid_name(source_node.description)
		local shorthand_name = fluidity.fluid_short(fluid_desc)

		node_name = mod..":"..base_tank.."_"..shorthand_name

		meta:set_string("infotext", "Tank of "..fluid_desc.."("..count.."/"..capacity.." mB)")
	else
		meta:set_string("infotext", "Empty Tank")
	end

	local param2 = math.min((count/capacity)*63, 63)

	minetest.swap_node(pos, {name=node_name,param1=node.param1,param2=param2})

	return fluid_name, leftover
end

local function bucket_fill(pos, node, clicker, itemstack, pointed_thing)
	local stackname = itemstack:get_name()
	local stack     = "bucket:bucket_empty"

	if not stackname:find("bucket") then
		return itemstack
	end
	
	if stackname == "bucket:bucket_empty" then
		if fluidity.tanks.get_is_empty_tank(node.name) then
			return itemstack
		end
		
		local fluid = fluidity.tanks.take_from_tank_at(pos, 1000)
		if not fluid then
			return itemstack
		end

		stack = fluidity.get_bucket_for_fluid(fluid)
	else
		local srcnode = fluidity.get_fluid_for_bucket(stackname)
		
		if not fluidity.tanks.can_fluid_go_in_tank(pos, srcnode) then
			return itemstack
		end

		local fluid = fluidity.tanks.fill_tank_at(pos, srcnode, 1000)

		if fluid == nil then
			return itemstack
		end
	end

	return ItemStack(stack)
end

-- Register a tank for a specific fluid
local function register_tankfluid(data)
	local source_node = fluidity.get_fluid_node(data.source_name)
	local fluid       = fluidity.fluid_name(source_node.description)
	local internal    = fluidity.fluid_short(fluid)

	minetest.register_node(data.mod_name..":"..data.tank_name.."_"..internal, {
		description = data.tank_description.." ("..fluid..")",
		drawtype = "glasslike_framed_optional",
		paramtype = "light",
		paramtype2 = "glasslikeliquidlevel",
		drop = data.mod_name..":"..data.tank_name,
		fluidity_fluid = data.source_name,
		place_param2 = 0,
		special_tiles = source_node.tiles,
		is_ground_content = false,
		sunlight_propagates = true,
		on_rightclick = bucket_fill,
		_mod = data.mod_name,
		_dataname = data.tank_name,
		_capacity = data.capacity,
		groups = {cracky = 1, not_in_creative_inventory = 1, oddly_breakable_by_hand = 3, fluidity_tank = 1},
		tiles = data.tiles
	})
end

-- Register a new tank
function fluidity.tanks.register_fluid_tank(data)
	local modname  = data.mod_name or minetest.get_current_modname()
	local tankname = data.tank_name or 'fluid_tank'
	local tankdesc = data.tank_description or 'Fluid Tank'
	local tiles    = data.tiles or {"default_glass.png", "default_glass_detail.png"}
	local capacity = data.capacity or 64000

	minetest.register_node(modname..":"..tankname, {
		description = tankdesc,
		drawtype = "glasslike_framed_optional",
		paramtype = "light",
		paramtype2 = "glasslikeliquidlevel",
		is_ground_content = false,
		sunlight_propagates = true,
		fluidity_fluid = nil,
		on_construct = function ( pos )
			local meta = minetest.get_meta(pos)
			meta:set_int("fluid", 0)
			meta:set_string("infotext", "Empty "..tankdesc)
		end,
		on_rightclick = bucket_fill,
		_mod = modname,
		_dataname = tankname,
		_capacity = capacity,
		groups = {cracky = 1, oddly_breakable_by_hand = 3, fluidity_tank = 1, fluid_tank_empty = 1},
		tiles = tiles
	})

	if data.fluids then
		-- This tank only uses certain fluids
		for _, v in pairs(data.fluids) do
			register_tankfluid({
				mod_name         = modname,
				tank_name        = tankname,
				tank_description = tankdesc,
				tiles            = tiles,
				capacity         = capacity,
				source_name      = v
			})
		end
	else
		-- Get all fluids and buckets and cache them
		for i, v in pairs(bucket.liquids) do
			if (i:find("source") ~= nil) then
				-- Cache bucket
				fluidity.bucket_cache[v["source"]] = v.itemname

				-- Add tank
				register_tankfluid({
					mod_name         = modname,
					tank_name        = tankname,
					tank_description = tankdesc,
					tiles            = tiles,
					capacity         = capacity,
					source_name      = v["source"]
				})
			end
		end
	end
end
