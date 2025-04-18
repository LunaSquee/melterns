multifurnace.api = {}
multifurnace.loaded_controllers = {}
multifurnace.check_controllers = {}

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

function multifurnace.api.structure_detect(node, pos)
    local back = vector.add(pos, minetest.facedir_to_dir(node.param2))
    local center, min, max = detect_center(back, 16)

    local dimensions = vector.subtract(max, min)

    -- core.debug("Center at "..core.pos_to_string(center, 1)..", min "..core.pos_to_string(min, 1).." max "..core.pos_to_string(max, 1))
    -- core.debug("Dimensions "..core.pos_to_string(dimensions, 1))

    local floor = continuous_floor(min, dimensions)
    if not floor then
        -- core.debug("Floor is not continuous")
        return nil, {}
    end

    local max_height, ports, tanks = continuous_sides(min, dimensions, 16)
    if max_height == 0 then
        -- core.debug("Zero continuous height")
        return nil, {}
    end

    dimensions.y = max_height

    return dimensions, ports, tanks, center, min, max
end

function multifurnace.api.check_controller(pos)
    local check_serial = math.random(10000, 99999)
    local node = core.get_node_or_nil(pos)
    if not node then
        -- not loaded controller
        return
    end

    local dimensions, ports, tanks, min =
        multifurnace.api.structure_detect(node, pos)
    local key = core.pos_to_string(pos)
    local ctrl_meta = core.get_meta(pos)

    if not dimensions then
        ctrl_meta:set_string("serial", "")
        notify_ports_removal(pos)
        update_timer(pos)
        return
    end

    ctrl_meta:set_int("serial", check_serial)
    for _, port in pairs(ports) do
        local meta = core.get_meta(port)
        meta:set_string("controller", key)
        meta:set_int("serial", check_serial)
    end

    local bounds_end = vector.add(min, dimensions)
    local volume = calculate_volume(dimensions)
    multifurnace.loaded_controllers[key] = {
        controller = pos,
        serial = check_serial,
        volume = volume,
        box_min = min,
        box_max = bounds_end,
        ports = ports,
				tanks = tanks,
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
        if close <= 32 then
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

    multifurnace.api.check_controller(pos)
end
