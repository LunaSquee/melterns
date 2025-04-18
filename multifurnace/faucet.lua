-- Faucet is a simple liquid transfer node

local FAUCET_PER_SECOND = metal_melter.spec.ingot

local function update_timer (pos)
	local t = minetest.get_node_timer(pos)
	if not t:is_started() then
		t:start(1.0)
	end
end

local function faucet_flow (pos, meta)
	local angled = minetest.get_node(pos)
	local back = vector.add(pos, minetest.facedir_to_dir(angled.param2))
	local backnode = minetest.get_node(back)
	local backreg = minetest.registered_nodes[backnode.name]

	if not backreg.node_io_can_take_liquid or not backreg.node_io_can_take_liquid(back, backnode, "front")
		or not backreg.node_io_take_liquid then
		return false
	end

	local stack
	if backreg.node_io_get_liquid_stack then
		stack = backreg.node_io_get_liquid_stack(back, backnode, "front", 1)
	end

	if not stack or stack:is_empty() then
		return false
	end

	return stack:get_name(), stack:get_count(), back
end

local function faucet_activate (pos)
	local meta = minetest.get_meta(pos)
	local source, amount, bhind = faucet_flow(pos, meta)

	if meta:get_string("flowing") ~= "" then return false end
	if not source or amount == 0 then return end

	local e = minetest.add_entity(pos, "multifurnace:faucet_flow")
	e:get_luaentity():set_faucet(pos)
	e:get_luaentity():set_source(source)

	meta:set_string("flowing", source)
	meta:set_int("flowing_capacity", amount)
	update_timer(pos)
end

local function faucet_timer (pos, elapsed)
	local refresh = false
	local meta = minetest.get_meta(pos)
	local liquid = meta:get_string("flowing")
	local source, amount, bhind = faucet_flow(pos, meta)

	while true do
		if liquid == "" then break end
		if source ~= liquid or amount <= 0 then
			liquid = ""
			break
		end

		local bhindnode = minetest.get_node(bhind)
		local bhindreg = minetest.registered_nodes[bhindnode.name]

		local target = vector.subtract(pos, {x=0,y=1,z=0})
		local tnode = minetest.get_node(target)
		local treg = minetest.registered_nodes[tnode.name]
		if not treg.node_io_can_put_liquid or not treg.node_io_can_put_liquid(target, tnode, "top")
			or not treg.node_io_room_for_liquid then
			liquid = ""
			break
		end

		local flowcap = amount
		if flowcap > FAUCET_PER_SECOND then
			flowcap = FAUCET_PER_SECOND
		end

		local room = treg.node_io_room_for_liquid(target, tnode, "top", liquid, flowcap)
		if room > 0 and treg.node_io_put_liquid then
			local over = treg.node_io_put_liquid(target, tnode, "top", nil, liquid, room)

			if treg.on_timer then
				update_timer(target)
			end
		else
			liquid = ""
			break
		end

		bhindreg.node_io_take_liquid(bhind, bhindnode, "front", nil, source, room)
		if bhindreg.on_timer then
			update_timer(bhind)
		end

		refresh = true
		break
	end

	meta:set_string("flowing", liquid)

	return refresh
end
minetest.register_node("multifurnace:faucet", {
	description = "Multifurnace Faucet",
	tiles = {"metal_melter_heatbrick.png"},
	groups = {cracky = 3, multifurnace_accessory = 1},
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.1875, -0.1875, 0.1250, 0.1875, -0.1250, 0.5000},
			{-0.1875, -0.1250, 0.1250, -0.1250, 0.06250, 0.5000},
			{0.1250, -0.1250, 0.1250, 0.1875, 0.06250, 0.5000}
		}
	},
	paramtype = "light",
	paramtype2 = "facedir",
	is_ground_content = false,
	on_rightclick = faucet_activate,
	on_timer = faucet_timer,
	_mcl_hardness = 2,
	_mcl_blast_resistance = 2,
})

-- Flow entity

minetest.register_entity("multifurnace:faucet_flow", {
	initial_properties = {
		physical = false,
		collide_with_objects = false,
		visual = "mesh",
		mesh = "multifurnace_faucet_flow.obj",
		visual_size = {x = 5, y = 5},
		textures = {},
		backface_culling = true,
		pointable = false,
		static_save = false,
	},
	faucet = nil,
	source = "",
	timer = 0,
	set_faucet = function (self, faucet)
		self.faucet = faucet

		-- Set correct orientation in regards to the faucet
		local node = minetest.get_node(faucet)
		local orient = minetest.facedir_to_dir(node.param2)
		orient = vector.multiply(orient, -1)
		local angle = minetest.dir_to_yaw(orient)
		self.object:set_yaw(angle)
	end,
	set_source = function (self, source)
		self.source = source

		-- Set appropriate fluid texture
		local tiles = minetest.registered_nodes[source]
		if not tiles.liquid_alternative_flowing then return end
		local flowing = minetest.registered_nodes[tiles.liquid_alternative_flowing]
		if not flowing.tiles or type(flowing.tiles[1]) ~= "string" then return end

		self.object:set_properties({textures = {
			flowing.tiles[1]
		}})
	end,
	on_step = function (self, dt)
		self.timer = self.timer + 1

		-- Remove self when the faucet is destroyed or is no longer marked as flowing
		if self.timer >= 10 then
			local node = minetest.get_node(self.faucet)
			if not node or node.name ~= "multifurnace:faucet" then
				self.object:remove()
				return
			end

			local meta = minetest.get_meta(self.faucet)
			if meta:get_string("flowing") ~= self.source then
				self.object:remove()
				return
			end

			self.timer = 0
		end
	end
})
