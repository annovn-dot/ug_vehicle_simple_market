local function discordLog(title, description, color)
  if not Config.UseDiscordLogs or Config.DiscordWebhook == '' then return end
  PerformHttpRequest(Config.DiscordWebhook, function() end, 'POST', json.encode({
    embeds = { {
      title = title,
      description = description,
      color = color or 3447003,
      footer = { text = 'ug_vehicle_shop' },
      timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ')
    } }
  }), { ['Content-Type'] = 'application/json' })
end

local StringCharset, NumberCharset = {}, {}
for i = 48, 57 do NumberCharset[#NumberCharset + 1] = string.char(i) end
for i = 65, 90 do StringCharset[#StringCharset + 1] = string.char(i) end
for i = 97, 122 do StringCharset[#StringCharset + 1] = string.char(i) end

local function RandomInt(len)
  if len > 0 then return RandomInt(len - 1) .. NumberCharset[math.random(1, #NumberCharset)] end
  return ''
end
local function RandomStr(len)
  if len > 0 then return RandomStr(len - 1) .. StringCharset[math.random(1, #StringCharset)] end
  return ''
end

local function GeneratePlate()
  local plate = (RandomInt(1) .. RandomStr(2) .. RandomInt(3) .. RandomStr(2)):upper()
  local q = ('SELECT %s FROM %s WHERE %s = ? LIMIT 1'):format(
    Config.DB.PlateColumn, Config.DB.VehiclesTable, Config.DB.PlateColumn
  )
  local exists = MySQL.scalar.await(q, { plate })
  if exists then return GeneratePlate() end
  return plate
end

local function modelHashOf(model)
  if type(model) == 'number' then return model end
  if joaat then return joaat(model) end
  if GetHashKey then return GetHashKey(model) end
  return 0
end

local function defaultProps(plate, model)
  return {
    modFrame = -1,
    modBrakes = -1,
    modVanityPlate = -1,
    color1 = 122,
    modLivery = -1,
    customSecondaryColor = { 0, 0, 0 },
    modRoof = -1,
    modTrimA = -1,
    bodyHealth = 1000.0,
    modSpeakers = -1,
    modHorns = -1,
    modFrontWheels = -1,
    neonEnabled = { false, false, false, false },
    modOrnaments = -1,
    tyreBurst = {},
    tyreSmokeColor = { 255, 255, 255 },
    fuelLevel = 60.0,
    modSuspension = -1,
    plate = plate,
    modAirFilter = -1,
    modHydrolic = -1,
    modGrille = -1,
    engineHealth = 1000.0,
    modStruts = -1,
    modAerials = -1,
    modWindows = -1,
    modTank = -1,
    tyresCanBurst = 1,
    modXenon = false,
    interiorColor = 0,
    modBackWheels = -1,
    modDashboard = -1,
    wheelColor = 156,
    dashboardColor = 0,
    modSteeringWheel = -1,
    modCustomBackWheels = false,
    doorsBroken = {},
    modDoorSpeaker = -1,
    modAPlate = -1,
    modCustomFrontWheels = false,
    tankHealth = 1000.0,
    modTrunk = -1,
    modExhaust = -1,
    modTrimB = -1,
    modArmor = -1,
    windowTint = -1,
    modFender = -1,
    xenonColor = 255,
    modSpoilers = -1,
    wheels = 5,
    model = GetHashKey and GetHashKey(model) or model,
    pearlescentColor = 18,
    modRearBumper = -1,
    modRightFender = -1,
    modFrontBumper = -1,
    extras = {},
    neonColor = { 255, 255, 255 },
    modSideSkirt = -1,
    plateIndex = 0,
    modEngine = -1,
    modSmokeEnabled = false,
    modLightbar = -1,
    modDial = -1,
    modEngineBlock = -1,
    modHood = -1,
    customPrimaryColor = { 0, 0, 0 },
    modPlateHolder = -1,
    modArchCover = -1,
    modTransmission = -1,
    dirtLevel = 0.0,
    color2 = 0,
    modShifterLeavers = -1,
    modTurbo = false,
    modRoofLivery = -1,
    modSeats = -1
  }
end

local function insertVehicle(src, owner, plate, model, mode, vcfg)
  local cols, vals, qmarks = {}, {}, {}
  local function add(col, val)
    if col and val ~= nil then
      cols[#cols + 1] = col
      vals[#vals + 1] = val
      qmarks[#qmarks + 1] = '?'
    end
  end

  if Config.DB.LicenseColumn then
    local license = FW.GetLicense(src)
    if license then
      add(Config.DB.LicenseColumn, license)
    end
  end

  if Config.DB.HashColumn then
    add(Config.DB.HashColumn, modelHashOf(model))
  end

  add(Config.DB.OwnerColumn, owner)
  add(Config.DB.PlateColumn, plate)
  add(Config.DB.ModsColumn, json.encode(defaultProps(plate, model)))
  add(Config.DB.ModelColumn, model)
  add(Config.DB.TypeColumn, Config.DBDefaults.type)
  add(Config.DB.StoredColumn, 1)
  if mode == 'org' then add(Config.DB.JobColumn, vcfg.jobRequirement or nil) end
  add(Config.DB.GarageColumn, (mode == 'org') and vcfg.defaultGarageOrg or vcfg.defaultGaragePriv)
  add(Config.DB.ParkingColumn, nil)
  if Config.DB.MileageColumn then add(Config.DB.MileageColumn, 0) end

  local sql = ('INSERT INTO %s (%s) VALUES (%s)')
      :format(Config.DB.VehiclesTable, table.concat(cols, ','), table.concat(qmarks, ','))
  MySQL.insert.await(sql, vals)
end

RegisterNetEvent('ug_vehicle_shop:buy', function(index, mode)
  local src = source
  local vcfg = Config.Vehicles[index]
  if not vcfg then return end

  local job = FW.GetJob(src)
  if vcfg.jobRequirement and vcfg.jobRequirement ~= job then
    return TriggerClientEvent('ug_vehicle_shop:notify', src, 'error', Lang.wrong_job)
  end

  local bank = FW.GetBank(src)
  if (bank or 0) < vcfg.price then
    return TriggerClientEvent('ug_vehicle_shop:notify', src, 'error', Lang.not_enough_money)
  end

  if not FW.RemoveBank(src, vcfg.price) then
    return TriggerClientEvent('ug_vehicle_shop:notify', src, 'error', Lang.charge_error)
  end

  local owner = FW.GetIdentifier(src)
  local plate = GeneratePlate()
  insertVehicle(src, owner, plate, vcfg.model, mode or 'priv', vcfg)

  if Config.UGKeysSystem then
    Wait(2000)
    TriggerClientEvent('keys:received', src, plate)
  end

  local buyer = FW.GetName(src)
  discordLog(Lang.log_title,
    ("%s (ID %d) purchased %s for %s%d (%s) [%s]")
    :format(buyer or 'Unknown', src, vcfg.model, Config.CurrencyLabel, vcfg.price, plate, (mode or 'priv'):upper()),
    3066993)

  if Config.DeliverImmediate then
    local z = Config.Zones[vcfg.zoneId]
    local spawn = z and z.spawn or nil
    TriggerClientEvent('ug_vehicle_shop:deliver', src, vcfg.model, plate, spawn, mode or 'priv')
  else
    if mode == 'org' then
      TriggerClientEvent('ug_vehicle_shop:notify', src, 'success', Lang.bought_org)
    else
      TriggerClientEvent('ug_vehicle_shop:notify', src, 'success', Lang.bought_priv)
    end
  end
end)
