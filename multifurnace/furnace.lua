local mer = fluidity.external.ref
local mei = fluidity.external.items

local fuel_consumption = 5

local function update_timer(pos)
    local t = core.get_node_timer(pos)
    if not t:is_started() then t:start(1.0) end
end

-----------------------
-- Buffer operations --
-----------------------

-- List liquids in the controller
local function all_liquids(pos)
    local meta = core.get_meta(pos)
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
local function set_hot(pos, buf, empty)
    local meta = core.get_meta(pos)
    local stacks, total = all_liquids(pos)

    if not stacks[buf] or stacks[buf]:is_empty() then return false end

    local current_one = stacks[1]
    local new_one = stacks[buf]

    meta:set_string("buffer1", new_one:to_string())
    meta:set_string("buffer" .. buf, empty and "" or current_one:to_string())
    if empty then meta:set_int("buffers", #stacks - 1) end

    return true
end

-- Reorganize the buffers, remove empty ones
local function clean_buffer_list(pos)
    local meta = core.get_meta(pos)
    local stacks, total = all_liquids(pos)
    local new = {}

    for i, v in pairs(stacks) do
        if not v:is_empty() then table.insert(new, v) end
    end

    for i, v in pairs(new) do meta:set_string("buffer" .. i, v:to_string()) end

    meta:set_int("buffers", #new)
end

-- Returns how much of the first buffer fluid can be extracted
local function can_take_liquid(pos, want_mb)
    local meta = core.get_meta(pos)
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
local function take_liquid(pos, want_mb)
    local meta = core.get_meta(pos)
    local stacks = all_liquids(pos)
    local found = stacks[1]
    local fluid, count = can_take_liquid(pos, want_mb)

    if fluid == "" or count == 0 or fluid ~= found:get_name() then
        return fluid, 0
    end

    local previous_count = found:get_count()
    local new_count = previous_count - count
    local new_stack = ItemStack(found:get_name() .. " " .. new_count)
    meta:set_string("buffer1", new_stack:to_string())

    if new_count == 0 then clean_buffer_list(pos) end

    return fluid, count
end

-- Calculate furnace fluid capacity
local function total_capacity(pos)
    local info = multifurnace.api.get_controller_info(pos)
    return info and (info.volume * 1000) or 1000
end

-- Can you fit this liquid inside the furnace
local function can_put_liquid(pos, liquid)
    local stacks, storage = all_liquids(pos)
    local total = total_capacity(pos)
    local append = liquid:get_count()

    if total == storage or storage + liquid:get_count() > total then
        return false
    end

    return true
end

local function put_liquid(pos, liquid)
    local meta = core.get_meta(pos)
    local stacks, storage = all_liquids(pos)
    local total = total_capacity(pos)
    local append = liquid:get_count()

    if not can_put_liquid(pos, liquid) then return false end

    -- Find a buffer, if not available, create a new one
    local buf = nil
    for i, v in pairs(stacks) do
        if v:get_name() == liquid:get_name() or v:is_empty() then
            buf = i
            break
        end
    end

    if not buf then buf = #stacks + 1 end

    if stacks[buf] then
        local st = stacks[buf]
        local stc = st:get_count() + append
        st:set_count(stc)
        meta:set_string("buffer" .. buf, st:to_string())
    else
        liquid:set_count(append)
        meta:set_string("buffer" .. buf, liquid:to_string())
        meta:set_int("buffers", buf)
    end

    return true
end

local function furnace_lava_count(tanks)
    local total = 0
    local capacity = 0
    for _, tank in pairs(tanks) do
        local buf = fluid_lib.get_buffer_data(tank, "buffer")
        if buf then
            if buf.fluid == mei.lava and buf.amount > 0 and buf.drainable then
                total = total + buf.amount
            end
            capacity = capacity + buf.capacity
        end
    end
    return total, capacity
end

local function furnace_take_lava(tanks, amount)
    local left_to_take = amount
    for _, tank in pairs(tanks) do
        if left_to_take <= 0 then break end
        local buf = fluid_lib.get_buffer_data(tank, "buffer")
        if buf then
            if buf.fluid == mei.lava and buf.amount > 0 and buf.drainable then
                local can_take = fluid_lib.can_take_from_buffer(tank, "buffer",
                                                                left_to_take)
                if can_take > 0 then
                    fluid_lib.take_from_buffer(tank, "buffer", can_take)
                    left_to_take = left_to_take - can_take
                    update_timer(tank)
                end

                if can_take == amount then break end
            end
        end
    end
end

--------------------------
-- Controller Operation --
--------------------------

local function fluid_bar(fluid, amount, x, y, w, h)
    local texture = mer.default_water
    local name = ""
    local metric = 0

    if fluid and fluid ~= "" and core.registered_nodes[fluid] ~= nil then
        texture = core.registered_nodes[fluid].tiles[1]
        name = fluid_lib.cleanse_node_description(fluid) .. " (" ..
                   fluid_lib.comma_value(amount) .. " " .. fluid_lib.unit .. ")"
        if type(texture) == "table" then texture = texture.name end
    end

    return
        "image[" .. x .. "," .. y .. ";" .. w .. "," .. h .. ";" .. texture ..
            "^[resize:64x128]" .. "tooltip[" .. x .. "," .. y .. ";" .. w .. "," ..
            h .. ";" .. name .. "]"
end

local function get_fluids_formspec(stacks, max, x, y, w, h)
    local spec = "image[" .. x .. "," .. y .. ";" .. w .. "," .. h ..
                     ";melter_gui_barbg.png]"
    local last_y = h + y

    for _, k in pairs(stacks) do
        local count = k:get_count()
        local percent = count / max
        local height = math.max(h * percent, 0.05)
        last_y = last_y - height
        spec = spec .. fluid_bar(k:get_name(), count, x, last_y, w, height)
    end

    return spec .. "image[" .. x .. "," .. y .. ";" .. w .. "," .. h ..
               ";melter_gui_gauge.png]"
end

local function get_slot_progress_bars(progresses, x, y, columns, rows)
    local spec = ""
    for i, v in pairs(progresses) do
        local slot_i = i - 1
        local slot_x_i = slot_i % columns
        local slot_y_i = math.floor(slot_i / columns)
        local slot_x = x + slot_x_i + (slot_x_i * 0.25) + 1
        local slot_y = y + slot_y_i + (slot_y_i * 0.25)
        local bar = "multifurnace_temp_gradient_bg.png^[lowpart:" .. v ..
                        ":multifurnace_temp_gradient.png"
        spec =
            spec .. "image[" .. slot_x .. "," .. slot_y .. ";0.15,1;" .. bar ..
                "]"
    end
    return spec
end

local function get_slot_backgrounds(x, y, slots, columns, rows)
    local spec = ""
    for row = 0, rows do
        local rowy = row + (row * 0.25) + y
        local cols_in_row = math.min(slots - row * columns, columns)
        spec = spec .. mer.get_itemslot_bg(x, rowy, cols_in_row, 1)
    end
    return spec
end

local function get_formspec(info, progresses, stacks, capacity, lava_count,
                            lava_capacity)
    local columns = 5
    local max_rows = 5
    local rows = math.ceil(info.volume / columns)
    local actual_columns = (info.volume < columns) and info.volume or columns

    local fluids_spec = get_fluids_formspec(stacks, capacity, 7.75, 0.375, 2.5,
                                            max_rows + ((max_rows - 1) * 0.25))
    local slot_progress_bars = get_slot_progress_bars(progresses, 0.15, 0.15,
                                                      actual_columns, rows)
    local lava_buffer = metal_melter.fluid_bar(10.5, 0.375, {
        fluid = mei.lava,
        amount = lava_count,
        capacity = lava_capacity
    })
    local slots = get_slot_backgrounds(0.15, 0.15, info.volume, columns, rows)
    local scroll_height = (rows + ((rows) * 0.25)) * 10 - 60

    return "formspec_version[4]size[11.75,12.75]" ..
               "scroll_container[0.375,0.375;6.75,6;meltscroll;vertical]" ..
               slots .. "list[context;melt;0.15,0.15;" .. actual_columns .. "," ..
               rows .. "]" .. slot_progress_bars .. "scroll_container_end[]" ..
               "scrollbaroptions[max=" .. (scroll_height) .. "]" ..
               "scrollbar[6.95,0.375;0.5,6;vertical;meltscroll;]" .. fluids_spec ..
               lava_buffer .. mer.gui_player_inv(nil, 7.35) ..
               "listring[current_player;main]" .. "listring[context;melt]" ..
               "listring[current_player;main]"
end

local function controller_timer(pos, elapsed)
    local meta = core.get_meta(pos)
    local inv = meta:get_inventory()
    local refresh = false
    local info = multifurnace.api.get_controller_info(pos)

    if not info then
        meta:set_string("formspec", "")
        return false
    end

    local items = inv:get_list("melt")
    local lava_count, lava_capacity = furnace_lava_count(info.tanks)
    local capacity = total_capacity(pos)
    local progresses = {}

    for index, stack in pairs(items) do
        local melt_item = stack:get_name()
        if melt_item ~= "" then
            progresses[index] = -1
            local melt_metal, metal_type =
                metal_melter.get_metal_from_stack(melt_item)
            if melt_metal then
                local item_progress = meta:get_int("melt" .. index)
                if lava_count > fuel_consumption then
                    if not item_progress then
                        -- not started yet
                        item_progress = 10
                        meta:set_int("melt" .. index, item_progress)
                        furnace_take_lava(info.tanks, fuel_consumption)
                        refresh = true
                    elseif item_progress < 100 then
                        -- increment melt timer
                        item_progress = item_progress + 10
                        meta:set_int("melt" .. index, item_progress)
                        furnace_take_lava(info.tanks, fuel_consumption)
                        refresh = true
                    else
                        -- melt item down
                        -- put fluid into a buffer
                        local fluid = fluidity.molten_metals[melt_metal]
                        local count = metal_melter.spec[metal_type]
                        local fit = put_liquid(pos,
                                               ItemStack(fluid .. " " .. count))
                        if fit then
                            meta:set_string("melt" .. index, "")
                            inv:set_stack("melt", index, "")
                            item_progress = 0
                            refresh = true
                        end
                    end
                end
                progresses[index] = item_progress
            end
        end
    end

    inv:set_size("melt", info.volume)

    local stacks, total = all_liquids(pos)
    meta:set_string("formspec", get_formspec(info, progresses, stacks, capacity,
                                             lava_count, lava_capacity))

    return refresh
end

local function allow_metadata_inventory_put(pos, listname, index, stack, player)
    if core.is_protected(pos, player:get_player_name()) then return 0 end

    local meta = core.get_meta(pos)
    local inv = meta:get_inventory()
    local current = inv:get_stack(listname, index)
    if current:get_name() == "" or current:get_count() < 1 then return 1 end

    return 0
end

local function allow_metadata_inventory_move(pos, from_list, from_index,
                                             to_list, to_index, count, player)
    local meta = core.get_meta(pos)
    local inv = meta:get_inventory()
    local stack = inv:get_stack(from_list, from_index)
    return allow_metadata_inventory_put(pos, to_list, to_index, stack, player)
end

local function allow_metadata_inventory_take(pos, listname, index, stack, player)
    if core.is_protected(pos, player:get_player_name()) then return 0 end
    return stack:get_count()
end

local function get_port_controller(pos)
    local meta = core.get_meta(pos)
    local key = meta:get_string("controller")
    if not key or key == "" then return nil end
    local ctrl_pos = core.string_to_pos(key)
    local ctrl_meta = core.get_meta(ctrl_pos)
    return ctrl_pos, ctrl_meta
end

-------------------
-- Registrations --
-------------------

core.register_node("multifurnace:controller", {
    description = "Multifurnace Controller",
    tiles = {
        "metal_melter_heatbrick.png", "metal_melter_heatbrick.png",
        "metal_melter_heatbrick.png", "metal_melter_heatbrick.png",
        "metal_melter_heatbrick.png",
        "metal_melter_heatbrick.png^multifurnace_controller_face.png"
    },
    groups = {cracky = 3, multifurnace = 1},
    paramtype2 = "facedir",
    is_ground_content = false,
    on_timer = controller_timer,
    on_construct = function(pos)
        local meta = core.get_meta(pos)
        local inv = meta:get_inventory()
        inv:set_size("melt", 1)
    end,
    on_destruct = function(pos) multifurnace.api.remove_controller(pos) end,
    on_metadata_inventory_move = update_timer,
    on_metadata_inventory_put = update_timer,
    on_metadata_inventory_take = update_timer,
    allow_metadata_inventory_put = allow_metadata_inventory_put,
    allow_metadata_inventory_move = allow_metadata_inventory_move,
    allow_metadata_inventory_take = allow_metadata_inventory_take,
    _mcl_hardness = 2,
    _mcl_blast_resistance = 2
})

core.register_node("multifurnace:port", {
    description = "Multifurnace Port",
    tiles = {
        "metal_melter_heatbrick.png", "metal_melter_heatbrick.png",
        "metal_melter_heatbrick.png", "metal_melter_heatbrick.png",
        "metal_melter_heatbrick.png^multifurnace_intake_back.png",
        "metal_melter_heatbrick.png^multifurnace_intake_face.png"
    },
    groups = {cracky = 3, multifurnace = 2, fluid_container = 1},
    fluid_buffers = {},
    node_io_can_put_liquid = function(pos, node, side) return true end,
    node_io_can_take_liquid = function(pos, node, side) return true end,
    node_io_accepts_millibuckets = function(pos, node, side) return true end,
    node_io_take_liquid = function(pos, node, side, taker, want_liquid,
                                   want_millibuckets)
        local ctrl, ctrl_meta = get_port_controller(pos)
        if not ctrl then return nil end
        local name, took = take_liquid(ctrl, want_millibuckets)
        update_timer(ctrl)
        return {name = name, millibuckets = took}
    end,
    node_io_get_liquid_size = function(pos, node, side) return 1 end,
    node_io_get_liquid_name = function(pos, node, side, index)
        local ctrl, ctrl_meta = get_port_controller(pos)
        if not ctrl then return "" end
        local can_take = can_take_liquid(ctrl, total_capacity(ctrl))
        return can_take
    end,
    node_io_get_liquid_stack = function(pos, node, side, index)
        local ctrl, ctrl_meta = get_port_controller(pos)
        if not ctrl then return ItemStack(nil) end
        local can_take, count = can_take_liquid(ctrl, total_capacity(ctrl))
        if can_take == "" then return ItemStack(nil) end
        return ItemStack(can_take .. " " .. count)
    end,
	node_io_put_liquid = function(pos, node, side, putter, liquid, millibuckets)
		local ctrl, ctrl_meta = get_port_controller(pos)
		if not ctrl then return millibuckets end

		if put_liquid(ctrl, ItemStack(liquid .. " " .. millibuckets)) then
            update_timer(ctrl)
            return 0
        end
        
        return millibuckets
	end,
	node_io_room_for_liquid = function(pos, node, side, liquid, millibuckets)
		local ctrl, ctrl_meta = get_port_controller(pos)
		if not ctrl then return 0 end

		if can_put_liquid(ctrl, ItemStack(liquid .. " " .. millibuckets)) then
            return millibuckets
        end

		return 0
	end,
    paramtype2 = "facedir",
    is_ground_content = false,
    on_destruct = function(pos) multifurnace.api.remove_port(pos) end,
    on_construct = function(pos)
        multifurnace.api.component_changed_nearby(pos)
    end,
    _mcl_hardness = 2,
    _mcl_blast_resistance = 2
})

core.override_item("metal_melter:heated_bricks", {
    on_destruct = function(pos)
        multifurnace.api.component_changed_nearby(pos)
    end,
    on_construct = function(pos)
        multifurnace.api.component_changed_nearby(pos)
    end
})

core.register_abm({
    label = "Update Multifurnace structures",
    nodenames = {"multifurnace:controller"},
    without_neighbors = {"multifurnace:controller"},
    interval = 5,
    chance = 1,
    action = function(pos) multifurnace.api.detect_changes(pos) end
})

core.register_lbm({
    name = "multifurnace:load_controllers",
    nodenames = {"multifurnace:controller"},
    action = function(pos) multifurnace.api.detect_changes(pos) end
})
