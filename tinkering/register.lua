
-- Register components and base tools
local start_load = os.clock()
local num_components = 0
local num_tools = 0

-- Create base tools
for m, s in pairs(tinkering.materials) do
	tinkering.register_material_tool(m)
	num_tools = num_tools + 1
end

-- Register tool components
for i, v in pairs(tinkering.components) do
	tinkering.register_component(i, v)
	num_components = num_components + 1
end

print(("[tinkering] Added %d components and %d base tools in %f seconds."):format(num_components, num_tools, os.clock() - start_load))
