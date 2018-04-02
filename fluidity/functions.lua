function fluidity.fluid_name(name)
	return name:gsub("% Source$", "")
end

function fluidity.fluid_short(str)
	return string.lower(str):gsub("%s", "_")
end
