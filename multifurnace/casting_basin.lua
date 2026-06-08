local S = core.get_translator("melterns")

local function update_timer(pos)
    local t = core.get_node_timer(pos)
    if not t:is_started() then t:start(1.0) end
end

local function update_fluid_entity(pos)
    local meta = core.get_meta(pos)
    local liquid = meta:get_string("liquid")
    local amount = meta:get_int("liquid_amount")
    local total = meta:get_int("liquid_total")
    local texture_modifier = nil
    local solidify = meta:get_int("solidify")
    local fields = meta:to_table().fields or {}
    core.log("action", "[multifurnace:casting_basin] update pos=" ..
                 core.pos_to_string(pos) .. " metadata=" .. core.serialize(fields))

    if liquid == "" or amount <= 0 or total <= 0 then
        core.log("action", "[multifurnace:casting_basin] removing fluid entity" ..
                     " liquid=" .. tostring(liquid) .. " amount=" ..
                     tostring(amount) .. " total=" .. tostring(total))
        multifurnace.fluid_entity.remove(pos)
        return
    end

    if solidify > 0 then
        local def = core.registered_items[core.get_node(pos).name]
        local cooldown = def._multifurnace_casting_cooldown
        local colorize = math.floor(140 * solidify / cooldown + 0.5)
        texture_modifier = "^[colorize:#000000:" .. colorize
    end

    multifurnace.fluid_entity.create_box(pos, {
        x = pos.x - 0.3,
        y = pos.y - 0.24,
        z = pos.z - 0.3
    }, {
        x = 0.6,
        y = 0.77,
        z = 0.6
    }, {{
        fluid = liquid,
        fill_ratio = amount / total,
        texture_modifier = texture_modifier,
        debug_label = "casting_basin"
    }})
end

local function create_item_entity(istack, pos)
    local vpos = vector.add(pos, {x = 0, y = 0.2, z = 0})
    local e = core.add_entity(vpos, "multifurnace:table_item")
    e:set_properties({
        visual_size = {x = 0.32, y = 0.32, z = 0.32},
        collisionbox = {0, 0.31, 0, 0, 0.31, 0}
    })
    e:get_luaentity():set_item(istack:get_name())
    e:get_luaentity():set_is_cast(false)
end

local function set_item_entity(inv, pos)
    local vpos = vector.add(pos, {x = 0, y = 1, z = 0})
    local ents = core.get_objects_inside_radius(vpos, 1)
    local virtual = {}

    for _, object in pairs(ents) do
        if not object:is_player() and object:get_luaentity() and
            object:get_luaentity().name == "multifurnace:table_item" then
            table.insert(virtual, object)
        end
    end

    local item = inv:get_stack("item", 1)

    if item:is_empty() then
        for _, object in pairs(virtual) do object:remove() end
        return
    end

    if #virtual == 0 then
        create_item_entity(item, pos)
    else
        virtual[1]:get_luaentity():set_item(item:get_name())
        for i = 2, #virtual do virtual[i]:remove() end
    end
end

local function on_timer(pos, elapsed)
    local meta = core.get_meta(pos)
    local inv = meta:get_inventory()
    local item = inv:get_stack("item", 1)

    if not item:is_empty() then return false end

    local liquid = meta:get_string("liquid")
    local liqc = meta:get_int("liquid_amount")
    local liqt = meta:get_int("liquid_total")
    local result, required = multifurnace.api.get_basin_recipe(liquid, liqt)
    meta:set_int("liquid_total", required)

    if not result then return false end

    local def = core.registered_items[core.get_node(pos).name]
    local cooldown = def._multifurnace_casting_cooldown
    local solidify = meta:get_int("solidify")

    if liqc >= required then
        if solidify < cooldown then
            meta:set_int("solidify", solidify + 1)
            update_fluid_entity(pos)
            return true
        end

        meta:set_string("liquid", "")
        meta:set_int("liquid_amount", 0)
        meta:set_int("solidify", 0)
        update_fluid_entity(pos)
        inv:set_stack("item", 1, ItemStack(result))
        set_item_entity(inv, pos)
    end

    return false
end

core.register_node("multifurnace:casting_basin", {
    description = S("Casting Basin"),
    drawtype = "nodebox",
    paramtype1 = "light",
    node_box = {
        type = "fixed",
        fixed = {
            {-0.5000, -0.5000, -0.5000, 0.5000, -0.2500, 0.5000},
            {-0.5000, -0.2500, -0.5000, 0.5000, 0.5000, -0.3125},
            {-0.5000, -0.2500, 0.3125, 0.5000, 0.5000, 0.5000},
            {-0.5000, -0.2500, -0.3125, -0.3125, 0.5000, 0.3125},
            {0.3125, -0.2500, -0.3125, 0.5000, 0.5000, 0.3125}
        }
    },
    tiles = {
        "multifurnace_table_top.png",
        "metal_melter_heatbrick.png",
        "metal_melter_heatbrick.png",
        "metal_melter_heatbrick.png",
        "metal_melter_heatbrick.png",
        "metal_melter_heatbrick.png"
    },
    groups = {
        cracky = 2,
        pickaxey = 2,
        multifurnace_accessory = 1,
        tubedevice = 1,
        tubedevice_receiver = 1
    },
    tube = {
        can_remove = function(pos, node, stack, dir, invname, spos)
            local meta = core.get_meta(pos)
            local inv = meta:get_inventory()
            if meta:get_int("solidify") <= 0 and invname == "item" and
                not inv:get_stack("item", 1):is_empty() then
                return 1
            end
            return 0
        end,
        remove_items = function(pos, node, stack, dir, count, invname, spos)
            local meta = core.get_meta(pos)
            local inv = meta:get_inventory()
            if meta:get_int("solidify") <= 0 and invname == "item" and
                not inv:get_stack("item", 1):is_empty() then
                stack = inv:remove_item("item", stack)
                set_item_entity(inv, pos)
                update_timer(pos)
                return stack
            end
            return ItemStack(nil)
        end,
        can_insert = function(pos, node, stack, direction) return false end,
        input_inventory = {"item"},
        connect_sides = {left = 1, right = 1, back = 1, bottom = 1, front = 1}
    },
    on_construct = function(pos)
        local inv = core.get_meta(pos):get_inventory()
        inv:set_size("item", 1)
    end,
    on_destruct = function(pos)
        multifurnace.fluid_entity.remove(pos)
    end,
    on_punch = function(pos, node, puncher, pointed_thing)
        local meta = core.get_meta(pos)
        local inv = meta:get_inventory()
        local to_give = nil

        if meta:get_int("solidify") <= 0 and
            not inv:get_stack("item", 1):is_empty() then
            to_give = inv:get_stack("item", 1)
            inv:set_list("item", {})
        end

        if to_give and puncher then
            local inp = puncher:get_inventory()
            if inp:room_for_item("main", to_give) then
                inp:add_item("main", to_give)
            else
                core.item_drop(to_give, puncher,
                               vector.add(pos, {x = 0, y = 1, z = 0}))
            end
            set_item_entity(inv, pos)
            return false
        end

        return true
    end,
    can_dig = function(pos)
        local meta = core.get_meta(pos)
        local inv = meta:get_inventory()
        return inv:get_stack("item", 1):is_empty() and
                   meta:get_int("liquid_amount") <= 0 and
                   meta:get_int("solidify") <= 0
    end,
    on_timer = on_timer,
    node_io_can_put_liquid = function(pos, node, side, liquid, millibuckets)
        if liquid == nil and not millibuckets then return true end

        local meta = core.get_meta(pos)
        local inv = meta:get_inventory()
        local liq = meta:get_string("liquid")
        local liqc = meta:get_int("liquid_amount")
        local liqt = meta:get_int("liquid_total")
        local result, required = multifurnace.api.get_basin_recipe(liquid, liqt)
        local add = millibuckets

        -- Don't allow adding fluid when there's an item or there's something solidifying
        if not result or not inv:get_stack("item", 1):is_empty() or
            meta:get_int("solidify") > 0 then return 0 end

        if liq ~= liquid and liq ~= "" then return 0 end
        if liqc == required then return 0 end
        if liqc + millibuckets > required then add = required - liqc end

        return add
    end,
    node_io_can_take_liquid = function(pos, node, side) return false end,
    node_io_accepts_millibuckets = function(pos, node, side) return true end,
    node_io_put_liquid = function(pos, node, side, putter, liquid, millibuckets)
        local meta = core.get_meta(pos)
        local liq = meta:get_string("liquid")
        local liqc = meta:get_int("liquid_amount")
        local liqt = meta:get_int("liquid_total")
        local result, required = multifurnace.api.get_basin_recipe(liquid, liqt)
        local add = millibuckets
        local leftovers = 0

        if not result or (liq ~= liquid and liq ~= "") then
            return millibuckets
        end
        if liqc == required then return millibuckets end
        if liqc + millibuckets > required then
            leftovers = liqc + millibuckets - required
            add = required - liqc
        end

        meta:set_string("liquid", liquid)
        meta:set_int("liquid_amount", liqc + add)
        meta:set_int("liquid_total", required)
        update_fluid_entity(pos)
        update_timer(pos)

        return leftovers
    end,
    node_io_get_liquid_size = function(pos, node, side) return 1 end,
    node_io_get_liquid_name = function(pos, node, side, index)
        return core.get_meta(pos):get_string("liquid")
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

core.register_lbm({
    label = "Draw Casting Basin entities",
    name = "multifurnace:casting_basin_load",
    nodenames = {"multifurnace:casting_basin"},
    run_at_every_load = true,
    action = function(pos, node)
        local inv = core.get_meta(pos):get_inventory()
        set_item_entity(inv, pos)
        update_fluid_entity(pos)
    end
})

if core.get_modpath("tubelib") then
    core.override_item("multifurnace:casting_basin", {
        after_place_node = function(pos, placer)
            tubelib.add_node(pos, "multifurnace:casting_basin")
        end,
        after_dig_node = function(pos) tubelib.remove_node(pos) end
    })

    tubelib.register_node("multifurnace:casting_basin", {}, {
        on_pull_item = function(pos, side)
            local meta = core.get_meta(pos)
            local inv = meta:get_inventory()
            if meta:get_int("solidify") <= 0 and
                not inv:get_stack("item", 1):is_empty() then
                local stack = inv:remove_item("item", inv:get_stack("item", 1))
                set_item_entity(inv, pos)
                update_timer(pos)
                return stack
            end
        end,
        on_push_item = function() return false end,
        on_unpull_item = function() return false end
    })
end
