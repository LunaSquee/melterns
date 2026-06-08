local S = core.get_translator("melterns")

if not mcl_craftguide then
	return
end

local TAB_MELTING = "melterns:item_to_fluid"
local TAB_CASTING = "melterns:fluid_to_item"

local function append_unique(items, seen, item)
	if item and item ~= "" and core.registered_items[item] and not seen[item] then
		seen[item] = true
		items[#items + 1] = item
	end
end

local function fluid_for_metal(metal)
	return fluidity.molten_metals[metal]
end

local function fluid_texture(fluid)
	local def = core.registered_nodes[fluid]
	local texture = def and def.tiles and def.tiles[1]
	if type(texture) == "table" then
		texture = texture.name
	end
	return texture or "unknown_node.png"
end

local function fluid_description(fluid)
	local def = core.registered_nodes[fluid]
	return def and (def._fluid_name or def.description) or fluid
end

local function fluid_button(ctx, x, y, fluid, amount, target_tab, show_usages)
	local action = table.concat({
		"fluid",
		fluid,
		target_tab or "",
		show_usages and "1" or "0",
	}, "|")
	local field = ctx:field_name(action)
	local tooltip = S("@1 (@2 mB)", fluid_description(fluid), amount)

	return ("image_button[%f,%f;1.1,1.1;%s;%s;;false;false;]" ..
		"tooltip[%s;%s]"):format(
			x,
			y,
			core.formspec_escape(fluid_texture(fluid) .. "^[resize:64x64"),
			field,
			field,
			core.formspec_escape(tooltip)
		)
end

local function handle_fluid_button(ctx, field_name)
	local fluid, tab, usages = field_name:match("^fluid|([^|]+)|([^|]*)|([01])$")
	if not fluid then
		return false
	end

	mcl_craftguide.show(
		ctx.player:get_player_name(),
		fluid,
		usages == "1",
		nil,
		tab ~= "" and tab or nil
	)
	return false
end

local function arrow(ctx, x, y)
	return ctx:image(x, y, 0.9, 0.7, "craftguide_arrow.png")
end

local function get_all_items()
	local items = {}
	local seen = {}

	for metal, types in pairs(fluidity.melts) do
		append_unique(items, seen, fluid_for_metal(metal))
		for _, type_items in pairs(types) do
			for _, item in pairs(type_items) do
				append_unique(items, seen, item)
			end
		end
	end

	for _, cast in pairs(metal_caster.casts) do
		append_unique(items, seen, cast.castname)
	end

	return items
end

local function melting_recipes(item, show_usages)
	local recipes = {}

	for metal, types in pairs(fluidity.melts) do
		local fluid = fluid_for_metal(metal)
		if fluid then
			for typename, type_items in pairs(types) do
				local amount = metal_melter.spec[typename]
				if amount then
					for _, input in pairs(type_items) do
						local relevant = show_usages and input == item or
							not show_usages and fluid == item
						if relevant and core.registered_items[input] then
							recipes[#recipes + 1] = {
								type = TAB_MELTING,
								width = 1,
								items = { input },
								output = fluid,
								input = input,
								output_fluid = fluid,
								amount = amount,
							}
						end
					end
				end
			end
		end
	end

	return recipes
end

local function append_casting_recipe(recipes, item, show_usages, recipe)
	local relevant = not show_usages and recipe.output == item
	if show_usages then
		relevant = recipe.input_fluid == item or recipe.cast == item or
			recipe.model == item
	end
	if relevant then
		recipes[#recipes + 1] = recipe
	end
end

local function casting_recipes(item, show_usages)
	local recipes = {}

	for metal, fluid in pairs(fluidity.molten_metals) do
		for cast_name, cast in pairs(metal_caster.casts) do
			local output = metal_caster.find_castable(metal, cast_name)
			if output and cast.castname then
				append_casting_recipe(recipes, item, show_usages, {
					type = TAB_CASTING,
					width = 2,
					items = { cast.castname },
					output = output,
					input_fluid = fluid,
					cast = cast.castname,
					amount = metal_caster.spec.ingot * (cast.cost or 1),
					kind = "cast",
				})
			end
		end

		local blocks = fluidity.melts[metal] and fluidity.melts[metal].block
		if blocks then
			for _, output in ipairs(blocks) do
				if core.registered_items[output] then
					append_casting_recipe(recipes, item, show_usages, {
						type = TAB_CASTING,
						width = 1,
						items = {},
						output = output,
						input_fluid = fluid,
						amount = metal_melter.spec.block,
						kind = "basin",
					})
					break
				end
			end
		end
	end

	local gold = fluid_for_metal("gold")
	if gold then
		for _, cast in pairs(metal_caster.casts) do
			local models = {}
			for _, types in pairs(fluidity.melts) do
				local type_items = types[cast.result]
				if type_items then
					for _, model in ipairs(type_items) do
						if core.registered_items[model] then
							models[#models + 1] = model
						end
					end
				end
			end

			for _, model in ipairs(models) do
				append_casting_recipe(recipes, item, show_usages, {
					type = TAB_CASTING,
					width = 2,
					items = { model },
					output = cast.castname,
					input_fluid = gold,
					model = model,
					amount = metal_caster.spec.cast,
					kind = "cast_creation",
				})
			end
		end
	end

	return recipes
end

mcl_craftguide.register_tab(TAB_MELTING, {
	description = S("Melting"),
	icon = "multifurnace:controller",
	order = 60,
	get_items = get_all_items,
	get_recipes = melting_recipes,
	build = function(ctx)
		local recipe = ctx.recipe
		return table.concat({
			ctx:item_button(0.6, 0.8, recipe.input),
			arrow(ctx, 2.0, 1.0),
			fluid_button(ctx, 3.3, 0.8, recipe.output_fluid, recipe.amount,
				TAB_CASTING, true),
			ctx:label(3.45, 2.1, S("@1 mB", recipe.amount)),
		})
	end,
	handle = handle_fluid_button,
})

mcl_craftguide.register_tab(TAB_CASTING, {
	description = S("Solidifying"),
	icon = "multifurnace:faucet",
	order = 61,
	get_items = get_all_items,
	get_recipes = casting_recipes,
	build = function(ctx)
		local recipe = ctx.recipe
		local fs = {
			fluid_button(ctx, 0.4, 0.8, recipe.input_fluid, recipe.amount,
				TAB_MELTING, false),
			ctx:label(0.55, 2.1, S("@1 mB", recipe.amount)),
		}

		if recipe.cast or recipe.model then
			fs[#fs + 1] = ctx:label(1.6, 1.15, "+")
			fs[#fs + 1] = ctx:item_button(1.9, 0.8, recipe.cast or recipe.model)
			fs[#fs + 1] = arrow(ctx, 3.25, 1.0)
			fs[#fs + 1] = ctx:item_button(4.45, 0.8, recipe.output)
		else
			fs[#fs + 1] = arrow(ctx, 2.0, 1.0)
			fs[#fs + 1] = ctx:item_button(3.3, 0.8, recipe.output)
		end

		return table.concat(fs)
	end,
	handle = handle_fluid_button,
})

mcl_craftguide.register_station("multifurnace:controller", {
	is_recipe_supported = function(recipe)
		return recipe.type == TAB_MELTING
	end,
})

mcl_craftguide.register_station("multifurnace:casting_table", {
	is_recipe_supported = function(recipe)
		return recipe.type == TAB_CASTING and
			(recipe.kind == "cast" or recipe.kind == "cast_creation")
	end,
})

mcl_craftguide.register_station("multifurnace:casting_basin", {
	is_recipe_supported = function(recipe)
		return recipe.type == TAB_CASTING and recipe.kind == "basin"
	end,
})
