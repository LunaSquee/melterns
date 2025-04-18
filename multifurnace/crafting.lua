local mei = fluidity.external.items

core.register_craft({
    output = 'multifurnace:controller',
    recipe = {
        {
            'metal_melter:heated_brick', 'metal_melter:heated_brick',
            'metal_melter:heated_brick'
        }, {'metal_melter:heated_tank', mei.glass, 'metal_melter:heated_tank'},
        {'metal_melter:heated_brick', mei.furnace, 'metal_melter:heated_brick'}
    }
})

core.register_craft({
    output = 'multifurnace:port',
    recipe = {
        {'metal_melter:heated_brick', '', 'metal_melter:heated_brick'},
        {'metal_melter:heated_brick', '', 'metal_melter:heated_brick'},
        {'metal_melter:heated_brick', '', 'metal_melter:heated_brick'}
    }
})

core.register_craft({
    output = 'multifurnace:faucet',
    recipe = {
        {'metal_melter:heated_brick', '', 'metal_melter:heated_brick'}, {
            'metal_melter:heated_brick', 'metal_melter:heated_brick',
            'metal_melter:heated_brick'
        }
    }
})

core.register_craft({
    output = 'multifurnace:casting_table',
    recipe = {
        {
            'metal_melter:heated_brick', 'metal_melter:heated_brick',
            'metal_melter:heated_brick'
        }, {'metal_melter:heated_brick', '', 'metal_melter:heated_brick'},
        {'metal_melter:heated_brick', '', 'metal_melter:heated_brick'}
    }
})
