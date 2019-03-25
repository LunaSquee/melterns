
local furnaces = {}

local function update_timer (pos)
	local t = minetest.get_node_timer(pos)
	if not t:is_started() then
		t:start(1.0)
	end
end

-----------------------
-- Buffer operations --
-----------------------

-- List liquids in the controller
local function all_liquids (pos)
	local meta = minetest.get_meta(pos)
	local count = meta:get_int("buffers")
	local stacks = {}
	local total = 0

	if count == 0 then return stacks, total end

	for i = 1, count do
		stacks[i] = ItemStack(meta:get_string("buffer" .. i))
		total = total + stacks[i]:get_count()
	end

	return stacks, total
end

-- Set the bottom-most buffer
local function set_hot (pos, buf)
	local meta = minetest.get_meta(pos)
	local stacks, total = all_liquids(pos)

	if not stacks[buf] or stacks[buf]:is_empty() then
		return false
	end

	local current_one = stacks[1]
	local new_one = stacks[buf]

	meta:set_string("buffer1", new_one:to_string())
	meta:set_string("buffer" .. buf, current_one:to_string())

	return true
end

-- Reorganize the buffers, remove empty ones
local function clean_buffer_list (pos)
	local meta = minetest.get_meta(pos)
	local stacks, total = all_liquids(pos)
	local new = {}

	for i,v in pairs(stacks) do
		if not v:is_empty() then
			table.insert(new, v)
		end
	end

	for i, v in pairs(new) do
		meta:set_string("buffer" .. i, v:to_string())
	end

	meta:set_int("buffers", #new)
end

-- Returns how much of the first buffer fluid can be extracted
local function can_take_liquid (pos, want_mb)
	local meta = minetest.get_meta(pos)
	local stacks = all_liquids(pos)
	local found = stacks[1]

	if found and found:is_empty() then
		clean_buffer_list(pos)
		return "", 0
	end

	if not found then return "", 0 end

	local count = 0
	if found:get_count() < want_mb then
		count = found:get_count()
	else
		count = want_mb
	end

	return found:get_name(), count
end


-- Take liquid from the first buffer
local function take_liquid (pos, want_mb)
	local meta = minetest.get_meta(pos)
	local stacks = all_liquids(pos)
	local found = stacks[1]
	local fluid,count = can_take_liquid(pos, want_mb)

	if fluid == "" or count == 0 or fluid ~= found:get_name() then
		return fluid, 0
	end

	found = ItemStack(fluid)
	found:set_count(count)

	meta:set_string("buffer1", found:to_string())

	return fluid, count
end

-- Calculate furnace fluid capacity
local function total_capacity (pos)
	return 8000 -- TODO
end

-- Can you fit this liquid inside the furnace
local function can_put_liquid (pos, liquid)
	local stacks, storage = all_liquids(pos)
	local total = total_capacity(pos)
	local append = liquid:get_count()

	if total == storage then
		append = 0
	elseif storage + liquid:get_count() > total then
		append = total - storage
	end

	return append
end

-- Returns leftovers
local function put_liquid (pos, liquid)
	local stacks, storage = all_liquids(pos)
	local total = total_capacity(pos)
	local append = can_put_liquid(pos, liquid)
	local leftovers = liquid:get_count() - append

	if append == 0 then
		return leftovers
	end

	-- Find a buffer, if not available, create a new one
	local buf = nil
	for i,v in pairs(stacks) do
		if v:get_name() == liquid:get_name() then
			buf = i
			break
		end
	end

	if not buf then
		buf = #stacks + 1
	end

	if stacks[buf] then
		local st = stacks[buf]
		local stc = st:get_count() + append
		st:set_count(stc)
		meta:set_string("buffer" .. buf, st:to_string())
	else
		liquid:set_count(append)
		meta:set_string("buffer" .. buf, liquid:to_string())
	end

	return leftovers
end

--------------------------
-- Controller Operation --
--------------------------

-- Detect a structure based on controller
local function detect_structure (pos)
	local node = minetest.get_node(pos)
	local back = vector.add(pos, minetest.facedir_to_dir(node.param2))

	local center = multifurnace.api.detect_center(back, 32)

	-- TODO...
end

-- If pos is part of the structure, this will return a position
local function get_controller (pos)
	-- body
end

local function controller_timer (pos, elapsed)
	local refresh = false
	local meta = minetest.get_meta(pos)

	return refresh
end

-------------------
-- Registrations --
-------------------

minetest.register_node("multifurnace:controller", {
	description = "Multifurnace Controller",
	tiles = {
		"metal_melter_heatbrick.png", "metal_melter_heatbrick.png", "metal_melter_heatbrick.png",
		"metal_melter_heatbrick.png", "metal_melter_heatbrick.png", "metal_melter_heatbrick.png^multifurnace_controller_face.png",
	},
	groups = {cracky = 3, multifurnace = 1},
	paramtype2 = "facedir",
	is_ground_content = false,
	on_timer = controller_timer,
	on_rightclick = function (pos)
		detect_structure(pos)
	end
})

minetest.register_node("multifurnace:port", {
	description = "Multifurnace Port",
	tiles = {
		"metal_melter_heatbrick.png", "metal_melter_heatbrick.png", "metal_melter_heatbrick.png",
		"metal_melter_heatbrick.png", "metal_melter_heatbrick.png^multifurnace_intake_back.png",
		"metal_melter_heatbrick.png^multifurnace_intake_face.png",
	},
	groups = {cracky = 3, multifurnace = 2},
	paramtype2 = "facedir",
	is_ground_content = false,
})
