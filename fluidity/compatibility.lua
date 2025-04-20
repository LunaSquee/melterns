-- Override external resources by minetest.conf
local cset = core.settings
local prefix = "melterns_resource_"
local mtg = core.get_modpath("default") ~= nil
local mcl = core.get_modpath("mcl_core") ~= nil
local xcm = core.get_modpath("xcompat") ~= nil

fluidity.external = {}
fluidity.external.ref = {}
fluidity.external.sounds = {}
fluidity.external.items = {}

-------------------------
-- Formspec references --
-------------------------

-- All of these can be configured with setting "melterns_resource_" + last table key
-- e.g. melterns_resource_player_inv_width = 9
fluidity.external.ref.player_inv_width = 8
fluidity.external.ref.gui_furnace_arrow = "gui_furnace_arrow_bg.png"
fluidity.external.ref.default_water = "default_water.png"

-- Item slot background can be configured with setting "melterns_resource_itemslot_bg"
fluidity.external.ref.get_itemslot_bg  = function() return "" end
fluidity.external.ref.gui_player_inv   = function(center_on, y)
	local width = fluidity.external.ref.player_inv_width
	y = y or 5
	center_on = center_on or 11.75
	local x = center_on / 2 - (((width - 1) * 0.25) + width) / 2
	return fluidity.external.ref.get_itemslot_bg(x, y, width, 1) ..
		   "list[current_player;main;"..x..","..y..";"..width..",1;]" ..
		   fluidity.external.ref.get_itemslot_bg(x, y + 1.375, width, 3) ..
		   "list[current_player;main;"..x..","..(y + 1.375)..";"..width..",3;"..width.."]"
end

------------
-- Sounds --
------------

-- All of the ingredients can be configured with setting "melterns_resource_sound_" + last table key
-- e.g. melterns_resource_sound_node_sound_stone = sound.ogg
fluidity.external.sounds.node_sound_stone = ""
fluidity.external.sounds.node_sound_gravel = ""
fluidity.external.sounds.node_sound_wood = ""

-----------------
-- Ingredients --
-----------------

-- All of the ingredients can be configured with setting "melterns_resource_" + last table key
-- e.g. melterns_resource_bucket_water = bucket:bucket_water
fluidity.external.items.bucket_water = "bucket:bucket_water"
fluidity.external.items.bucket_lava = "bucket:bucket_lava"
fluidity.external.items.lava = "default:lava_source"
fluidity.external.items.water = "default:water_source"
fluidity.external.items.stick = "default:stick"
fluidity.external.items.gravel = "default:gravel"
fluidity.external.items.sand = "default:sand"
fluidity.external.items.clay = "default:clay"
fluidity.external.items.glass = "default:glass"
fluidity.external.items.steel_ingot = "default:steel_ingot"
fluidity.external.items.furnace = "default:furnace"
fluidity.external.items.flint = "default:flint"
fluidity.external.items.diamond = "default:diamond"
fluidity.external.items.group_wood = "wood"
fluidity.external.items.group_stone = "stone"

-------------------------------
-- Built-in Game/Mod support --
-------------------------------

-- Minetest Game support
if mtg then
  fluidity.external.sounds.node_sound_stone = default.node_sound_stone_defaults()
  fluidity.external.sounds.node_sound_gravel = default.node_sound_gravel_defaults()
  fluidity.external.sounds.node_sound_wood = default.node_sound_wood_defaults()
end

-- VoxeLibre support
if mcl then
  fluidity.external.ref.default_water = "mcl_core_water_source_animation.png"

  fluidity.external.ref.get_itemslot_bg  = mcl_formspec.get_itemslot_bg_v4
  fluidity.external.ref.player_inv_width = 9
  fluidity.external.ref.gui_player_inv   = function(center_on, y)
                y = y or 5
                center_on = center_on or 11.75
                local x = center_on / 2 - ((8 * 0.25) + 9) / 2
                return mcl_formspec.get_itemslot_bg_v4(x, y, 9, 3)..
                       "list[current_player;main;"..x..","..y..";9,3;9]" ..
                       mcl_formspec.get_itemslot_bg_v4(x, y + 4, 9, 1)..
                       "list[current_player;main;"..x..","..(y + 4)..";9,1;]"
  end

  fluidity.external.sounds.node_sound_stone = mcl_sounds.node_sound_stone_defaults()
  fluidity.external.sounds.node_sound_gravel = mcl_sounds.node_sound_gravel_defaults()
  fluidity.external.sounds.node_sound_wood = mcl_sounds.node_sound_wood_defaults()

  fluidity.external.items.bucket_water = "mcl_buckets:bucket_water"
  fluidity.external.items.bucket_lava = "mcl_buckets:bucket_lava"

  fluidity.external.items.lava = "mcl_core:lava_source"
  fluidity.external.items.water = "mcl_core:water_source"

  fluidity.external.items.stick = "mcl_core:stick"
  fluidity.external.items.gravel = "mcl_core:gravel"
  fluidity.external.items.sand = "mcl_core:sand"
  fluidity.external.items.clay = "mcl_core:clay_lump"
  fluidity.external.items.glass = "mcl_core:glass"
  fluidity.external.items.steel_ingot = "mcl_core:iron_ingot"
  fluidity.external.items.furnace = "mcl_blast_furnace:blast_furnace"

  fluidity.external.items.flint = "mcl_core:flint"
  fluidity.external.items.diamond = "mcl_core:diamond"
end

-----------------------
-- xcompat overrides --
-----------------------

if xcm then
  local xcm_mat = xcompat.materials
  local xcm_sounds = xcompat.sounds

  fluidity.external.sounds.node_sound_stone = xcm_sounds.node_sound_stone_defaults()
  fluidity.external.sounds.node_sound_gravel = xcm_sounds.node_sound_gravel_defaults()
  fluidity.external.sounds.node_sound_wood = xcm_sounds.node_sound_wood_defaults()

  fluidity.external.items.bucket_water = xcm_mat.bucket_water
  fluidity.external.items.water = xcm_mat.water_source
  fluidity.external.items.stick = xcm_mat.stick
  fluidity.external.items.gravel = xcm_mat.gravel
  fluidity.external.items.sand = xcm_mat.sand
  fluidity.external.items.clay = xcm_mat.clay_lump
  fluidity.external.items.glass = xcm_mat.glass
  fluidity.external.items.steel_ingot = xcm_mat.steel_ingot
  fluidity.external.items.flint = xcm_mat.flint
  fluidity.external.items.diamond = xcm_mat.diamond
end

------------------------
-- Settings overrides --
------------------------

if cset:has(prefix .. "player_inv_width") then
  fluidity.external.ref.player_inv_width = tonumber(cset:get(prefix .. "player_inv_width"))
end

if cset:has(prefix .. "gui_furnace_arrow") then
  fluidity.external.ref.gui_furnace_arrow = cset:get(prefix .. "gui_furnace_arrow")
end

if cset:has(prefix .. "default_water") then
  fluidity.external.ref.default_water = cset:get(prefix .. "default_water")
end

if cset:has(prefix .. "itemslot_bg") then
  local image = cset:get(prefix .. "itemslot_bg")
  fluidity.external.ref.get_itemslot_bg = function(x, y, w, h)
      local str = ""
      for ix = 1, w do
          for iy = 1, h do
              str = str .. "image[" .. (x + ((ix - 1) * 0.25)) .. "," ..
                        (y + ((iy - 1) * 0.25)) .. ";1,1;" .. image .. "]"
          end
      end
      return str
  end
end

-- Sounds

for sound in pairs(fluidity.external.sounds) do
  local key = prefix .. "sound_" .. sound
  if cset:has(key) then fluidity.external.sounds[key] = cset:get(key) end
end

-- Ingredients

for item in pairs(fluidity.external.items) do
  local key = prefix .. item
  if cset:has(key) then fluidity.external.items[key] = cset:get(key) end
end
