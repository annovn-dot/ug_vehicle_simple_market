Config                        = {}

Config.SpawnDebug             = false
Config.ZonesDebug             = false

-- Framework: 'esx' | 'qb' | 'qbox' | 'auto'
Config.Framework              = 'auto'

-- set to true if you use UG Keys System so you receive keys when vehicle bought
Config.UGKeysSystem           = false

-- Target resource name
Config.TargetResource         = 'ox_target'

-- Logging
Config.UseDiscordLogs         = false
Config.DiscordWebhook         = '' -- paste your webhook or leave empty to disable

-- Display
Config.ShowFloatingText       = true
Config.ShowPlatePrice         = true
Config.AlwaysLockDisplays     = true
Config.RespawnOnStart         = true

-- DB config (classic ESX schema: props JSON in `vehicle`)
-- if nil gets skipped
Config.DB                     = {
    VehiclesTable = 'owned_vehicles', -- 'owned_vehicles' or 'player_vehicles'
    LicenseColumn = nil,              -- qb or qbox for raw license 'license'
    OwnerColumn   = 'owner',          -- esx - 'owner', qb, qbox - 'citizenid'
    PlateColumn   = 'plate',
    HashColumn    = 'hash',           -- used on qb or qbox, esx - nil
    ModelColumn   = nil,              -- esx - no separate model column, qb or qbox - 'vehicle'
    ModsColumn    = 'vehicle',        -- esx - 'vehicle', qb or qbox 'mods', props JSON goes here
    TypeColumn    = 'type',           -- esx - 'type', qb or qbox - nil
    StoredColumn  = 'stored',         -- our UG garage system uses this, qb or qbox is 'state'
    JobColumn     = 'job',            -- used in our UG garage system mostly, you may not need this
    GarageColumn  = 'garage',
    ParkingColumn = 'parking',
    MileageColumn = nil,
}

-- Keep only default for type
Config.DBDefaults             = { type = 'car' }

-- Money
Config.CurrencyLabel          = '$'
Config.BankOnly               = true -- always bank

-- Delivery
Config.DeliverImmediate       = true -- If true: SPAWN at zone spawn
Config.SpawnCheckRadius       = 2.0  -- when DeliverImmediate, ensure no vehicles within this radius
Config.DeliveryMessagePrivate = 'You bought a vehicle — delivered to your private garage.'
Config.DeliveryMessageOrg     = 'You bought a service vehicle — delivered to your organization garage.'
Config.ContractSigningTime    = 15000

