multifurnace.api = {}

local function is_inner (pos)
	local node = minetest.get_node_or_nil(pos)
	return node and node.name == "air"
end

function multifurnace.api.detect_center (inside, limit)
	-- "inside" is the position behind the controller, "inside the furnace"

	-- adjust the x-position until the difference between the outer walls is at most 1
	-- basically this means we center the position inside the furnace on the x axis.
	local xd1 = 1 -- x-difference
	local xd2 = 1

	local zd1 = 1 -- z-difference
	local zd2 = 1

	for i = 1, limit do -- don't check farther than needed
		-- expand the range on the x axis as long as one side has not met a wall
		if is_inner(vector.add(inside, {x = -xd1, y = 0, z = 0})) then
			xd1 = xd1 + 1
		elseif is_inner(vector.add(inside, {x = xd2, y = 0, z = 0})) then
			xd2 = xd2 + 1
		end

		-- if one side hit a wall and the other didn't we might have to re-center our x-position again
		if xd1 - xd2 > 1 then
			-- move x and offsets to the -x
			xd1 = xd1 - 1
			inside = vector.add(inside, {x = -1, y = 0, z = 0})
			xd2 = xd2 + 1
		end
		-- or the right
		if xd2 - xd1 > 1 then
			xd2 = xd2 - 1
			inside = vector.add(inside, {x = 1, y = 0, z = 0})
			xd1 = xd1 + 1
		end

		-- also do exactly the same on the z axis
		if is_inner(vector.add(inside, {x = 0, y = 0, z = -zd1})) then
			zd1 = zd1 + 1
		elseif is_inner(vector.add(inside, {x = 0, y = 0, z = zd2})) then
			zd2 = zd2 + 1
		end

		if zd1 - zd2 > 1 then
			-- move x and offsets to the -x
			zd1 = zd1 - 1
			inside = vector.add(inside, {x = 0, y = 0, z = -1})
			zd2 = zd2 + 1
		end

		-- or the right
		if zd2 - zd1 > 1 then
			zd2 = zd2 - 1
			inside = vector.add(inside, {x = 0, y = 0, z = 1})
			zd1 = zd1 + 1
		end
	end

	return inside
end
