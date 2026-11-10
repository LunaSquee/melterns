multifurnace.util = {}

function multifurnace.util.drop_stack(pos, stack)
    stack = ItemStack(stack)
    if stack:is_empty() then return end

    core.add_item({
        x = pos.x + math.random() - 0.5,
        y = pos.y,
        z = pos.z + math.random() - 0.5
    }, stack)
end
