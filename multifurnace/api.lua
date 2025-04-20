multifurnace.api = {}
multifurnace.loaded_controllers = {}
multifurnace.check_controllers = {}

-------------------------
-- Multinode detection --
-------------------------

local function is_inner(pos)
    local node = minetest.get_node_or_nil(pos)
    return node and node.name == "air"
end

local function update_timer(pos)
    local t = minetest.get_node_timer(pos)
    if not t:is_started() then t:start(1.0) end
end

local function detect_center(inside, limit)
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

    local min = vector.subtract(inside, vector.new(xd1 - 1, 0, zd1 - 1))
    local max = vector.add(inside, vector.new(xd2 - 1, 0, zd2 - 1))

    return inside, min, max
end

local function continuous_floor(min, dimensions)
    local continuous = true
    for x = 0, dimensions.x do
        for z = 0, dimensions.z do
            local npos = vector.add(min, {x = x, y = -1, z = z})
            local node = core.get_node_or_nil(npos)
            if not node or core.get_item_group(node.name, "multifurnace") == 0 then
                -- core.debug("node at "..core.pos_to_string(npos, 1).." is "..(node and node.name or "nil"))
                continuous = false
                break
            end
        end
    end
    return continuous
end

local function continuous_sides(min, dimensions, max_height)
    local ports = {}
    local tanks = {}
    local height = 0

    local function check_pos(pos)
        local node = core.get_node_or_nil(pos)
        if not node then
            -- core.debug("Node at "..core.pos_to_string(pos, 1).." is non-existent")
            return false
        end

        local group = core.get_item_group(node.name, "multifurnace")
        local tank_group = core.get_item_group(node.name, "fluid_container")
        if group == 0 then
            -- core.debug("Node at "..core.pos_to_string(pos, 1).." is not in group, is "..node.name)
            return false
        end

        if group == 2 then
            -- core.debug("  Node at "..core.pos_to_string(pos, 1).." is a port")
            table.insert(ports, pos)
        end

        if tank_group > 0 then table.insert(tanks, pos) end

        return true
    end

    for y = 0, max_height do
        local continuous = true
        for x = 0, dimensions.x do
            if not continuous then break end
            local near_wall = vector.add(min, {x = x, y = y, z = -1})
            local far_wall = vector.add(min,
                                        {x = x, y = y, z = dimensions.z + 1})

            if not check_pos(near_wall) or not check_pos(far_wall) then
                continuous = false
            end
        end

        for z = 0, dimensions.z do
            if not continuous then break end
            local near_wall = vector.add(min, {x = -1, y = y, z = z})
            local far_wall = vector.add(min,
                                        {x = dimensions.x + 1, y = y, z = z})

            if not check_pos(near_wall) or not check_pos(far_wall) then
                continuous = false
            end
        end

        if continuous then
            height = height + 1
        else
            break
        end
    end

    return height, ports, tanks
end

local function calculate_volume(dimensions)
    return (dimensions.x + 1) * (dimensions.z + 1) * dimensions.y
end

local function notify_ports_removal(pos)
    local key = core.pos_to_string(pos)
    if multifurnace.loaded_controllers[key] then
        for _, port in pairs(multifurnace.loaded_controllers[key].ports) do
            local meta = core.get_meta(port)
            meta:set_string("controller", "")
            meta:set_string("serial", "")
        end
        multifurnace.loaded_controllers[key] = nil
    end
end

function multifurnace.api.structure_detect(node, pos, max_dim)
    local back = vector.add(pos, minetest.facedir_to_dir(node.param2))
    local center, min, max = detect_center(back, max_dim - 1)

    local dimensions = vector.subtract(max, min)

    -- core.debug("Center at "..core.pos_to_string(center, 1)..", min "..core.pos_to_string(min, 1).." max "..core.pos_to_string(max, 1))
    -- core.debug("Dimensions "..core.pos_to_string(dimensions, 1))

    local floor = continuous_floor(min, dimensions)
    if not floor then
        -- core.debug("Floor is not continuous")
        return nil, {}
    end

    local max_height, ports, tanks = continuous_sides(min, dimensions, max_dim)
    if max_height == 0 then
        -- core.debug("Zero continuous height")
        return nil, {}
    end

    dimensions.y = max_height

    return dimensions, ports, tanks, center, min, max
end

-----------------------
-- Furnace lifecycle --
-----------------------

function multifurnace.api.check_controller(pos)
    local check_serial = math.random(10000, 99999)
    local node = core.get_node_or_nil(pos)
    if not node then
        -- not loaded controller
        return
    end

    local def = core.registered_nodes[node.name]
    local dimensions, ports, tanks, min =
        multifurnace.api.structure_detect(node, pos,
                                          def._multifurnace_max_dimensions or 8)
    local key = core.pos_to_string(pos)
    local ctrl_meta = core.get_meta(pos)

    if not dimensions then
        ctrl_meta:set_string("serial", "")
        notify_ports_removal(pos)
        update_timer(pos)
        return
    end

    -- Check for overlapping volumes
    local bounds_end = vector.add(min, dimensions)
    for other_key, other_ctrl in pairs(multifurnace.loaded_controllers) do
        if key ~= other_key and vector.equals(other_ctrl.box_min, min) and
            vector.equals(other_ctrl.box_max, bounds_end) then
            update_timer(pos)
            return
        end
    end

    ctrl_meta:set_int("serial", check_serial)
    for _, port in pairs(ports) do
        local meta = core.get_meta(port)
        meta:set_string("controller", key)
        meta:set_int("serial", check_serial)
    end

    local volume = calculate_volume(dimensions)
    multifurnace.loaded_controllers[key] = {
        controller = pos,
        serial = check_serial,
        volume = volume,
        box_min = min,
        box_max = bounds_end,
        max_dim = def._multifurnace_max_dimensions,
        fuel_consumption = def._multifurnace_fuel_consumption,
        ports = ports,
        tanks = tanks
    }
    update_timer(pos)
end

function multifurnace.api.remove_controller(pos)
    local node = core.get_node_or_nil(pos)
    if not node then
        -- not loaded controller
        return
    end

    local key = core.pos_to_string(pos)
    notify_ports_removal(pos)
    multifurnace.loaded_controllers[key] = nil
    multifurnace.api.component_changed_nearby(pos)
end

function multifurnace.api.remove_port(pos)
    local node = core.get_node_or_nil(pos)
    if not node then
        -- not loaded controller
        return
    end

    local meta = core.get_meta(pos)
    local controller = meta:get_string("controller")
    if not controller or controller == "" then return end

    local ctrl_pos = core.string_to_pos(controller)
    local key = core.pos_to_string(ctrl_pos)

    local ctrl_info = multifurnace.loaded_controllers[key]
    if not ctrl_info then return end

    local indexof = -1
    for i, k in ipairs(ctrl_info.ports) do
        if vector.equals(k, pos) then indexof = i end
    end

    if indexof >= 0 then table.remove(ctrl_info.ports, indexof) end

    multifurnace.check_controllers[key] = ctrl_info.serial
end

function multifurnace.api.get_controller_info(pos)
    local node = core.get_node_or_nil(pos)
    if not node then
        -- not loaded controller
        return
    end

    local key = core.pos_to_string(pos)
    return multifurnace.loaded_controllers[key]
end

function multifurnace.api.component_changed_nearby(pos)
    for key, ctrl in pairs(multifurnace.loaded_controllers) do
        local close = vector.distance(pos, ctrl.controller)
        if close <= (ctrl.max_dim + 2) then
            local key = core.pos_to_string(ctrl.controller)
            multifurnace.check_controllers[key] = ctrl.serial
        end
    end
end

function multifurnace.api.detect_changes(pos)
    local key = core.pos_to_string(pos)
    local loaded = multifurnace.loaded_controllers[key]
    local serial = multifurnace.check_controllers[key]

    multifurnace.check_controllers[key] = nil

    if loaded and (serial == nil or loaded.serial ~= serial) then return end

    -- Need to defer the change detection a little bit
    -- TODO: find a better method, this is currently required to prevent two controllers using the same volume
    core.after(math.random(1, 10) / 10,
               function() multifurnace.api.check_controller(pos) end)
end

-----------------------
-- Casting table API --
-----------------------

local function cast_amount(ctype)
    if ctype == fluid_lib.get_empty_bucket() then return 1000 end
    if not metal_caster.casts[ctype] then return nil end
    return metal_caster.spec.ingot * (metal_caster.casts[ctype].cost or 1)
end

function multifurnace.api.get_part_recipe(part)
    local itemdef = core.registered_items[part]
    local ingot = fluidity.get_metal_for_item(part, "ingot")
    local typename = ingot and "ingot" or itemdef._tinker_component
    if not typename then return nil end
    local cast = metal_caster.casts[typename]
    if not cast then return nil end
    return typename, cast.castname
end

function multifurnace.api.can_insert_item(item)
    local cast = metal_caster.get_cast_for_name(item)
    local recipe = multifurnace.api.get_part_recipe(item)
    local bucket = item == fluid_lib.get_empty_bucket()

    return cast or recipe or bucket
end

function multifurnace.api.get_recipe(cast_item, liquid, current_total)
    local part_name, new_cast = multifurnace.api.get_part_recipe(cast_item)
    local bucket = cast_item == fluid_lib.get_empty_bucket() and cast_item or
                       nil
    local ctype = bucket or part_name or
                      metal_caster.get_cast_for_name(cast_item)
    local amount = cast_amount(ctype)
    local required = current_total

    if not ctype then
        required = metal_caster.spec.ingot
    elseif current_total ~= amount then
        required = amount
    end

    if liquid == "" or not ctype then return nil, required, false end

    local metal = fluidity.get_metal_for_fluid(liquid)
    if new_cast and metal ~= "gold" then return nil, required, false end

    local result = nil
    local output_cast = false
    if new_cast then
        result = new_cast
        output_cast = true
    elseif bucket then
        result = fluid_lib.get_bucket_for_source(liquid)
        output_cast = true
    else
        result = metal_caster.find_castable(metal, ctype)
    end

    return result, required, output_cast
end
