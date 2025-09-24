-- Vehicles (each has zoneId to decide when will appear in the world)
-- Rule: if jobRequirement is set, that job is required (for both org/private).
-- If allowPrivate = false, only Organization option shows.
-- If allowOrg = false, only Private option shows.
-- If jobRequirement = nil, only Private shows.

Config.Vehicles = {
    {
        price = 80000,
        model = 'police',
        modelName = 'Vapid Police Cruiser',
        jobRequirement = 'police',
        allowOrg = true,
        allowPrivate = true,
        defaultGarageOrg = 'MRPD',
        defaultGaragePriv = 'A',
        coords = vec4(456.2492, -1023.9431, 28.4429, 0.6348),
        zoneId = 1,
    },
    {
        price = 1200000,
        model = 'police2',
        modelName = 'Vapid Police Interceptor',
        jobRequirement = 'police',
        allowOrg = true,
        allowPrivate = false,
        defaultGarageOrg = 'MRPD',
        defaultGaragePriv = 'A',
        coords = vec4(452.7766, -1024.1239, 28.5163, 0.2614),
        zoneId = 1,
    },
    {
        price = 25000,
        model = 'flatbed',
        modelName = 'MTL Flatbed',
        jobRequirement = nil,
        allowOrg = false,
        allowPrivate = true,
        defaultGarageOrg = nil,
        defaultGaragePriv = 'IMPOUND_A',
        coords = vec4(400.1040, -1648.3007, 29.3842, 229.9346),
        zoneId = 2,
    },
}
