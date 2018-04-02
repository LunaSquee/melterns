-- Register tanks for each fluid

fluidity.bucket_cache = {}

-- Get fluid source block name for bucket item
function fluidity.get_fluid_for_bucket(itemname)
	for i,v in pairs(fluidity.bucket_cache) do
		if v == itemname then
			return i
		end
	end
end

-- Get bucket item name for fluid source block
function fluidity.get_bucket_for_fluid(source)
	return fluidity.bucket_cache[source]
end

function fluidity.get_fluid_node(name)
	return minetest.registered_nodes[name]
end

local function get_nodedef_field(nodename, fieldname)
    if not minetest.registered_nodes[nodename] then
        return nil
    end
    return minetest.registered_nodes[nodename][fieldname]
end

local function bucket_fill(pos, node, clicker, itemstack, pointed_thing)
	local stackname = itemstack:get_name()
	local nodename  = node.name
	local stack     = "bucket:bucket_empty"
	local meta      = minetest.get_meta(pos)

	if not stackname:find("bucket") then
		return itemstack
	end
	
	local tankfluid = get_nodedef_field(node.name, "fluidity_fluid")
	local tankname  = get_nodedef_field(node.name, "_dataname")
	local tankcap   = get_nodedef_field(node.name, "_capacity")
	local tankmod   = get_nodedef_field(node.name, "_mod")

	local fluidcount = meta:get_int("fluid")
	if stackname == "bucket:bucket_empty" then
		if tankfluid == nil then
			return itemstack
		end
		
		fluidcount = fluidcount - 1
		stack = fluidity.get_bucket_for_fluid(tankfluid)

		if fluidcount == 0 then
			nodename = tankmod..":"..tankname
			tankfluid = nil
		end
	else
		local srcnode = fluidity.get_fluid_for_bucket(stackname)
		
		if (tankfluid ~= srcnode and tankfluid ~= nil) or (fluidcount >= tankcap) then
			return itemstack
		end

		if tankfluid == nil then
			local source_node    = fluidity.get_fluid_node(srcnode)
			local fluid_name     = fluidity.fluid_name(source_node.description)
			local shorthand_name = fluidity.fluid_short(fluid_name)

			nodename = tankmod..":"..tankname.."_"..shorthand_name

			if not minetest.registered_nodes[nodename] then
				return itemstack
			end

			tankfluid = srcnode
		end

		fluidcount = fluidcount + 1
	end

	meta:set_int("fluid", fluidcount)

	if tankfluid then
		local source_node = fluidity.get_fluid_node(tankfluid)
		local fluid_name  = fluidity.fluid_name(source_node.description)

		meta:set_string("infotext", "Tank of "..fluid_name.."("..fluidcount.."/"..tankcap..")")
	else
		meta:set_string("infotext", "Empty Tank")
	end

	local param2 = (fluidcount/tankcap)*63

	minetest.swap_node(pos, {name=nodename,param1=node.param1,param2=param2})

	return ItemStack(stack)
end

-- Register a tank for a specific fluid
local function register_tankfluid(data)
	local source_node = fluidity.get_fluid_node(data.source_name)
	local fluid       = fluidity.fluid_name(source_node.description)
	local internal    = fluidity.fluid_short(fluid)

	minetest.register_node(data.mod_name..":"..data.tank_name.."_"..internal, {
		description = data.tank_description.." ("..fluid..")",
		drawtype = "glasslike_framed",
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
function fluidity.register_fluid_tank(data)
	local modname  = data.mod_name or 'fluidity'
	local tankname = data.tank_name or 'fluid_tank'
	local tankdesc = data.tank_description or 'Fluid Tank'
	local tiles    = data.tiles or {"default_glass.png", "default_glass_detail.png"}
	local capacity = data.capacity or 64

	minetest.register_node(modname..":"..tankname, {
		description = tankdesc,
		drawtype = "glasslike_framed",
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
		groups = {cracky = 1, oddly_breakable_by_hand = 3, fluidity_tank = 1},
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

fluidity.register_fluid_tank({
	mod_name         = "fluidity",
	tank_name        = "fluid_tank",
	tank_description = "Fluid Tank",
	capacity         = 64,
	tiles            = {"default_glass.png", "default_glass_detail.png"}
})
