local function update_timer(pos)
    local t = core.get_node_timer(pos)
    if not t:is_started() then t:start(1.0) end
end

local function create_item_entity(istack, cast, tpos)
    local vpos = vector.add(tpos, {x = 0, y = 0.5, z = 0})
    local e = core.add_entity(vpos, "multifurnace:table_item")
    e:set_rotation({x = 1.570796, y = 0, z = 0})
    e:get_luaentity():set_item(istack:get_name())
    e:get_luaentity():set_is_cast(cast)
end

local function set_item_entities(inv, pos)
    local vpos = vector.add(pos, {x = 0, y = 1, z = 0})
    local ents = core.get_objects_inside_radius(vpos, 1)
    local virtual = {}

    for _, object in pairs(ents) do
        if not object:is_player() and object:get_luaentity() and
            object:get_luaentity().name == "multifurnace:table_item" then
            table.insert(virtual, object)
        end
    end

    local cast = inv:get_stack("cast", 1)
    local item = inv:get_stack("item", 1)

    if #virtual >= 2 then
        for _, v in pairs(virtual) do
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
        if not item:is_empty() then create_item_entity(item, false, pos) end
        if not cast:is_empty() then create_item_entity(cast, true, pos) end
    end
end

local function on_timer(pos, elapsed)
    local refresh = false
    local meta = core.get_meta(pos)
    local node = core.get_node(pos)
    local inv = meta:get_inventory()

    local cast = inv:get_stack("cast", 1)
    local item = inv:get_stack("item", 1)

    if not node or cast:is_empty() or not item:is_empty() then return false end

    local def = core.registered_items[node.name]
    local cooldown = def._multifurnace_casting_cooldown
    local liquid = meta:get_string("liquid")
    local liqc = meta:get_int("liquid_amount")
    local liqt = meta:get_int("liquid_total")

    local name = cast:get_name()
    local result, required, output_cast =
        multifurnace.api.get_recipe(name, liquid, liqt)
    meta:set_int("liquid_total", required)

    if not result then return false end

    local solidify = meta:get_int("solidify")

    if liqc >= required then
        if solidify < cooldown then
            refresh = true
            meta:set_int("solidify", solidify + 1)
        else
            liquid = ""
            liqc = 0
            item = ItemStack(result)
            refresh = false

            -- Set result

            meta:set_string("liquid", liquid)
            meta:set_int("liquid_amount", liqc)
            meta:set_int("solidify", 0)

            if output_cast then
                inv:set_stack("item", 1, "")
                inv:set_stack("cast", 1, item)
            else
                inv:set_stack("item", 1, item)
            end

            set_item_entities(inv, pos)
        end
    end

    return refresh
end

core.register_node("multifurnace:casting_table", {
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
    groups = {cracky = 1, multifurnace_accessory = 1},
    on_construct = function(pos)
        local meta = core.get_meta(pos)
        local inv = meta:get_inventory()

        inv:set_size("cast", 1)
        inv:set_size("item", 1)
    end,
    on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
        local i = itemstack:get_name()
        local meta = core.get_meta(pos)
        local inv = meta:get_inventory()

        if inv:get_stack("cast", 1):is_empty() and
            multifurnace.api.can_insert_item(i) then
            inv:set_stack("cast", 1, itemstack:take_item(1))
            set_item_entities(inv, pos)
            update_timer(pos)
        end

        return itemstack
    end,
    on_punch = function(pos, node, puncher, pointed_thing)
        local meta = core.get_meta(pos)
        local inv = meta:get_inventory()

        local to_give = nil

        if not inv:get_stack("item", 1):is_empty() then
            to_give = inv:get_stack("item", 1)
            inv:set_list("item", {})
        elseif not inv:get_stack("cast", 1):is_empty() then
            local liq = meta:get_int("liquid_amount")
            if liq > 0 then
                meta:set_int("liquid_amount", 0)
                meta:set_string("liquid", "")
                meta:set_int("solidify", 0)
            end

            to_give = inv:get_stack("cast", 1)
            inv:set_list("cast", {})
        end

        if to_give and puncher then
            local inp = puncher:get_inventory()
            if inp:room_for_item("main", to_give) then
                inp:add_item("main", to_give)
            else
                core.item_drop(to_give, puncher,
                               vector.add(pos, {x = 0, y = 1, z = 0}))
            end
            set_item_entities(inv, pos)
            return false
        end

        return true
    end,
    can_dig = function(pos)
        local meta = core.get_meta(pos)
        local inv = meta:get_inventory()
        return inv:get_stack("item", 1):is_empty() and
                   inv:get_stack("cast", 1):is_empty()
    end,
    on_timer = on_timer,
    node_io_can_put_liquid = function(pos, node, side) return true end,
    node_io_can_take_liquid = function(pos, node, side) return false end,
    node_io_accepts_millibuckets = function(pos, node, side) return true end,
    node_io_put_liquid = function(pos, node, side, putter, liquid, millibuckets)
        local meta = core.get_meta(pos)
        local liq = meta:get_string("liquid")
        local liqc = meta:get_int("liquid_amount")
        local liqt = meta:get_int("liquid_total")
        local add = millibuckets

        local leftovers = 0

        if (liq ~= liquid and liq ~= "") or liqt == 0 then
            return millibuckets
        end
        if liqc == liqt then return millibuckets end
        if liqc + millibuckets > liqt then
            leftovers = liqc + millibuckets - liqt
            add = liqt - liqc
        end

        meta:set_string("liquid", liquid)
        meta:set_int("liquid_amount", liqc + add)
        update_timer(pos)

        return leftovers
    end,
    node_io_room_for_liquid = function(pos, node, side, liquid, millibuckets)
        local meta = core.get_meta(pos)
        local inv = meta:get_inventory()
        local liq = meta:get_string("liquid")
        local liqc = meta:get_int("liquid_amount")
        local liqt = meta:get_int("liquid_total")
        local add = millibuckets

        -- Don't allow adding fluid when there's an item or there's something solidifying
        if not inv:get_stack("item", 1):is_empty() or meta:get_int("solidify") >
            0 then return 0 end

        if (liq ~= liquid and liq ~= "") or liqt == 0 then return 0 end
        if liqc == liqt then return 0 end
        if liqc + millibuckets > liqt then add = liqt - liqc end

        return add
    end,
    node_io_get_liquid_size = function(pos, node, side) return 1 end,
    node_io_get_liquid_name = function(pos, node, side, index)
        local meta = core.get_meta(pos)
        return meta:get_string("liquid")
    end,
    node_io_get_liquid_stack = function(pos, node, side, index)
        local meta = core.get_meta(pos)

        return ItemStack(meta:get_string("liquid") .. " " ..
                             meta:get_int("liquid_amount"))
    end,
    _mcl_hardness = 2,
    _mcl_blast_resistance = 2,
    _multifurnace_casting_cooldown = 3
})

core.register_entity("multifurnace:table_item", {
    initial_properties = {
        physical = false,
        collide_with_objects = false,
        visual = "item",
        visual_size = {x = 0.45, y = 0.45, z = 0.5},
        textures = {},
        pointable = false,
        static_save = false
    },
    item = "air",
    cast = false,
    set_item = function(self, itm)
        self.item = itm
        self.object:set_properties({textures = {self.item}})
    end,
    is_cast = function(self) return self.cast end,
    set_is_cast = function(self, is) self.cast = is == true end
})

core.register_lbm({
    label = "Draw Casting Table entities",
    name = "multifurnace:casting_table_load",
    nodenames = {"multifurnace:casting_table"},
    run_at_every_load = true,
    action = function(pos, node)
        local meta = core.get_meta(pos)
        local inv = meta:get_inventory()
        set_item_entities(inv, pos)
    end
})
