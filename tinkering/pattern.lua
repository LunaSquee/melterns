tinkering.pattern = {}

-- Register a new pattern
function tinkering.register_pattern(name, data)
	local mod    = data.mod_name or "tinkering"
	local desc   = data.description

	tinkering.pattern[name] = data

	minetest.register_craftitem(mod..":"..name.."_pattern", {
		description     = desc.." Pattern",
		inventory_image = "tinkering_"..name.."_pattern.png",
		groups          = {pattern=1}
	})
end

-- Create blank pattern
minetest.register_craftitem("tinkering:blank_pattern", {
	description     = "Blank Pattern",
	inventory_image = "tinkering_blank_pattern.png",
	groups          = {pattern=1}
})
