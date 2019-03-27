
local function create_item_entity(istack, cast, tpos)
	local vpos = vector.add(tpos, {x=0,y=0.5,z=0})
	local e = minetest.add_entity(vpos, "multifurnace:table_item")
	e:set_rotation({x = 1.570796, y = 0, z = 0})
	e:get_luaentity():set_item(istack:get_name())
	e:get_luaentity():set_is_cast(cast)
end

local function set_item_entities(inv, pos)
	local vpos = vector.add(pos, {x=0,y=1,z=0})
	local ents = minetest.get_objects_inside_radius(vpos, 1)
	local virtual = {}

	for _,object in pairs(ents) do
		if not object:is_player() and object:get_luaentity() and object:get_luaentity().name == "multifurnace:table_item" then
			table.insert(virtual, object)
		end
	end

	local cast = inv:get_stack("cast", 1)
	local item = inv:get_stack("item", 1)

	if #virtual >= 2 then
		for _,v in pairs(virtual) do
			local lent = v:get_luaentity()
			if lent:is_cast() then
				if cast:is_empty() then
					v:remove()
				else
					lent:set_item(cast:get_name())
				end
			else
				if item:is_empty() then
					v:remove()
				else
					lent:set_item(item:get_name())
				end
			end
		end
	elseif #virtual == 1 then
		local lent = virtual[1]:get_luaentity()
		if lent:is_cast() then
			if cast:is_empty() then
				virtual[1]:remove()
			else
				lent:set_item(cast:get_name())
			end
			if not item:is_empty() then
				create_item_entity(item, false, pos)
			end
		else
			if item:is_empty() then
				virtual[1]:remove()
			else
				lent:set_item(item:get_name())
			end
			if not cast:is_empty() then
				create_item_entity(cast, true, pos)
			end
		end
	else
		if not item:is_empty() then
			create_item_entity(item, false, pos)
		end
		if not cast:is_empty() then
			create_item_entity(cast, true, pos)
		end
	end
end

minetest.register_node("multifurnace:casting_table", {
	description = "Casting Table",
	drawtype = "nodebox",
	paramtype1 = "light",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.5000, -0.5000, -0.5000, -0.2500, 0.1875, -0.2500},
			{0.2500, -0.5000, -0.5000, 0.5000, 0.1875, -0.2500},
			{0.2500, -0.5000, 0.2500, 0.5000, 0.1875, 0.5000},
			{-0.5000, -0.5000, 0.2500, -0.2500, 0.1875, 0.5000},
			{-0.5000, 0.1875, -0.5000, 0.5000, 0.4375, 0.5000},
			{-0.5000, 0.4375, -0.5000, 0.4375, 0.5000, -0.4375},
			{-0.4375, 0.4375, 0.4375, 0.5000, 0.5000, 0.5000},
			{-0.5000, 0.4375, -0.4375, -0.4375, 0.5000, 0.5000},
			{0.4375, 0.4375, -0.5000, 0.5000, 0.5000, 0.4375}
		}
	},
	tiles = {"multifurnace_table_top.png", "multifurnace_table_side.png"},
	groups = { cracky = 1, multifurnace_accessory = 1 },
	on_construct = function (pos)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()

		inv:set_size("cast", 1)
		inv:set_size("item", 1)
	end,
	on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
		local i = itemstack:get_name()
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()

		local cast = metal_caster.get_cast_for_name(i)

		if inv:get_stack("cast", 1):is_empty() and cast then
			inv:set_stack("cast", 1, itemstack:take_item(1))
			set_item_entities(inv, pos)
		--elseif inv:get_stack("item", 1):is_empty() and not cast then
		--	inv:set_stack("item", 1, itemstack:take_item(1))
		--	set_item_entities(inv, pos)
		end

		return itemstack
	end,
	on_punch = function(pos, node, puncher, pointed_thing)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()

		local to_give = nil

		if not inv:get_stack("item", 1):is_empty() then
			to_give = inv:get_stack("item", 1)
			inv:set_list("item", {})
		elseif not inv:get_stack("cast", 1):is_empty() then
			-- TODO: check for liquid
			to_give = inv:get_stack("cast", 1)
			inv:set_list("cast", {})
		end

		if to_give and puncher then
			local inp = puncher:get_inventory()
			if inp:room_for_item("main", to_give) then
				inp:add_item("main", to_give)
			else
				minetest.item_drop(to_give, puncher, vector.add(pos, {x=0,y=1,z=0}))
			end
			set_item_entities(inv, pos)
			return false
		end

		return true
	end,
	can_dig = function(pos)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		return inv:get_stack("item", 1):is_empty() and inv:get_stack("cast", 1):is_empty()
	end,
})

minetest.register_entity("multifurnace:table_item", {
	initial_properties = {
		physical = false,
		collide_with_objects = false,
		visual = "item",
		visual_size = {x = 0.45, y = 0.45, z = 0.5},
		textures = {},
		pointable = false,
		static_save = true,
	},
	item = "air",
	cast = false,
	set_item = function (self, itm)
		self.item = itm
		self.object:set_properties({textures = {self.item}})
	end,
	is_cast = function (self)
		return self.cast
	end,
	set_is_cast = function (self, is)
		self.cast = is == true
	end
})
