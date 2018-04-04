local textures = {
	pick   = {"tinkering_pickaxe_head.png",  "tinkering_overlay_handle_pickaxe.png"},
	axe    = {"tinkering_axe_head.png",       "tinkering_overlay_handle_axe.png"},
	sword  = {"tinkering_sword_blade.png",  "tinkering_overlay_handle_sword.png"},
	shover = {"tinkering_shovel_head.png", "tinkering_overlay_handle_shovel.png"},

	rod     = "tinkering_tool_rod.png",
	binding = "tinkering_binding.png"
}

local components = {
	pickaxe_head = {description = "%s Pickaxe Head", materials = 1, image = textures.pick[1]},
	axe_head     = {description = "%s Axe Head",     materials = 1, image = textures.axe[1]},
	sword_blade  = {description = "%s Sword Blade",  materials = 1, image = textures.sword[1]},
	shover_head  = {description = "%s Shovel Head",  materials = 1, image = textures.shover[1]},
	tool_rod     = {description = "%s Tool Rod",     materials = 1, image = textures.rod},
	tool_binding = {description = "%s Binding",      materials = 1, image = textures.binding}
}

function tinkering.register_component(data)
	local desc = data.description
	local name = data.name
	local mod  = data.mod_name or "tinkering"

	minetest.register_craftitem(mod..":"..name, {
		description = desc,
		groups = {tinker_component = 1},
		inventory_image = data.image
	})
end

for i, v in pairs(components) do
	if v.materials == 1 then
		for m, s in pairs(tinkering.materials) do
			tinkering.register_component({
				name = m.."_"..i,
				description = v.description:format(s.name),
				image = tinkering.color_filter(v.image, s.color)
			})
		end
	end
end
