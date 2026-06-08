multifurnace.fluid_entity = {}

local ENTITY_NAME = "multifurnace:fluid_level"
local META_CENTER = "fluid_entity_center"
local META_COUNT = "fluid_entity_count"

local function get_texture(fluid)
    local def = fluid and core.registered_nodes[fluid]
    local flowing = def and def.liquid_alternative_flowing and
                        core.registered_nodes[def.liquid_alternative_flowing]
    local texture = flowing and flowing.tiles and flowing.tiles[1]

    if not texture then texture = def and def.tiles and def.tiles[1] end

    if type(texture) == "table" then texture = texture.name end
    if type(texture) == "string" then return texture end
end

local function get_entity_textures(fluid, modifier)
    local texture = get_texture(fluid) or get_texture(fluidity.external.items.lava)
    if modifier then texture = texture .. modifier end

    return {texture, texture, texture, texture, texture, texture}
end

local function debug_log(label, message)
    if label then
        core.log("action", "[multifurnace:" .. label .. "] " .. message)
    end
end

local function get_glow(fluid)
    local def = fluid and core.registered_nodes[fluid]
    return def and def.light_source or 0
end

local function remove_near(pos)
    local objects = core.get_objects_inside_radius(pos, 0.75)
    for _, object in pairs(objects) do
        local entity = object:get_luaentity()
        if entity and entity.name == ENTITY_NAME then object:remove() end
    end
end

function multifurnace.fluid_entity.create_box(owner_pos, box_min, box_size, layers)
    if not layers or #layers == 0 then
        multifurnace.fluid_entity.remove(owner_pos)
        return
    end

    local meta = core.get_meta(owner_pos)
    multifurnace.fluid_entity.remove(owner_pos)

    local y_offset = 0
    local created = 0

    for _, layer in ipairs(layers) do
        local height = box_size.y * layer.fill_ratio
        if height > 0 then
            local base_texture = get_texture(layer.fluid) or
                                     get_texture(fluidity.external.items.lava)
            local textures = get_entity_textures(layer.fluid,
                                                 layer.texture_modifier)
            local glow = get_glow(layer.fluid)
            local center = {
                x = box_min.x + box_size.x / 2,
                y = box_min.y + y_offset + height / 2,
                z = box_min.z + box_size.z / 2
            }
            debug_log(layer.debug_label, "calculated fluid=" ..
                          tostring(layer.fluid) .. " fill_ratio=" ..
                          tostring(layer.fill_ratio) .. " height=" ..
                          tostring(height) .. " center=" ..
                          core.pos_to_string(center) .. " base_texture=" ..
                          tostring(base_texture) .. " modifier=" ..
                          tostring(layer.texture_modifier) .. " final_texture=" ..
                          tostring(textures[1]) .. " glow=" .. tostring(glow))
            local object = core.add_entity(center, ENTITY_NAME)

            if object then
                created = created + 1
                object:set_properties({
                    visual_size = {x = box_size.x, y = height, z = box_size.z},
                    textures = textures,
                    glow = glow
                })
                local properties = object:get_properties()
                debug_log(layer.debug_label, "entity updated texture=" ..
                              tostring(properties.textures and
                                           properties.textures[1]) ..
                              " visual_size=" ..
                              core.serialize(properties.visual_size) .. " glow=" ..
                              tostring(properties.glow))
                meta:set_string(META_CENTER .. created, core.pos_to_string(center))
            else
                debug_log(layer.debug_label, "core.add_entity failed at " ..
                              core.pos_to_string(center))
            end

            y_offset = y_offset + height
        end
    end

    meta:set_int(META_COUNT, created)
end

function multifurnace.fluid_entity.remove(controller_pos)
    local meta = core.get_meta(controller_pos)
    local count = meta:get_int(META_COUNT)
    local center = core.string_to_pos(meta:get_string(META_CENTER))

    if center then remove_near(center) end

    for i = 1, count do
        center = core.string_to_pos(meta:get_string(META_CENTER .. i))
        if center then remove_near(center) end
        meta:set_string(META_CENTER .. i, "")
    end

    meta:set_string(META_CENTER, "")
    meta:set_int(META_COUNT, 0)
end

core.register_entity(ENTITY_NAME, {
    initial_properties = {
        physical = false,
        collide_with_objects = false,
        visual = "cube",
        visual_size = {x = 1, y = 1, z = 1},
        textures = get_entity_textures(fluidity.external.items.lava),
        pointable = false,
        static_save = false
    }
})
