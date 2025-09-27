local spawnedByZone = {}
local zoneStates = {}

local function platePrice(amount)
    local millions = math.floor(amount / 1000000)
    local thousands = math.floor((amount % 1000000) / 1000)
    if millions > 0 and thousands > 0 then
        return ("%dM%dK"):format(millions, thousands)
    elseif millions > 0 then
        return ("%dM"):format(millions)
    elseif thousands > 0 then
        return ("%dK"):format(thousands)
    else
        return tostring(amount)
    end
end

local function money(n)
    local s = tostring(math.floor(n))
    local k
    while true do
        s, k = s:gsub('^(-?%d+)(%d%d%d)', '%1,%2')
        if k == 0 then break end
    end
    return s
end

local function doContractProgress(ms)
    local ped = PlayerPedId()
    local ok = lib.progressBar({
        duration = ms or (Config.ContractSigningTime or 5000),
        label = Lang.progress_signing or 'Signing the contract...',
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, car = true, combat = true, mouse = false },
        anim = { scenario = 'WORLD_HUMAN_CLIPBOARD' },
    })
    ClearPedTasks(ped)
    return ok
end

local function startPurchase(idx, mode, confirmTitle, confirmText)
    if not Notify.confirm(confirmTitle, confirmText) then return end
    local completed = doContractProgress()
    if completed then
        TriggerServerEvent('ug_vehicle_shop:buy', idx, mode)
    else
        lib.notify({
            title = 'Vehicle Shop',
            description = Lang.purchase_cancelled or 'Purchase cancelled.',
            type =
            'error'
        })
    end
end

local function protectDisplayVehicle(veh)
    FreezeEntityPosition(veh, true)
    SetEntityInvincible(veh, true)
    -- bullet, fire, explosion, collision, melee, steam, unknown, drown
    SetEntityProofs(veh, true, true, true, true, true, true, true, true)
    SetVehicleDoorsLocked(veh, 2)
    SetVehicleUndriveable(veh, true)
    SetVehicleCanBreak(veh, false)
    SetVehicleTyresCanBurst(veh, false)
    SetVehicleExplodesOnHighExplosionDamage(veh, false)
    SetVehicleDoorsLockedForAllPlayers(veh, true)

    local es = Entity(veh)
    if es and es.state then
          es.state:set('ug_market', true, true)
    end
end

local function isSpawnFree(x, y, z, r)
    r = r or (Config.SpawnCheckRadius or 3.5)

    if IsAnyVehicleNearPoint(x, y, z, r) then
        if Config.SpawnDebug then
            print(('[ug_vehicle_shop] Spawn blocked: IsAnyVehicleNearPoint (r=%.1f)'):format(r))
        end
        return false
    end

    local origin = vector3(x, y, z)

    local function EnumerateVehicles()
        return coroutine.wrap(function()
            local handle, veh = FindFirstVehicle()
            if not handle or handle == -1 then return end
            local ok = true
            repeat
                coroutine.yield(veh)
                ok, veh = FindNextVehicle(handle)
            until not ok
            EndFindVehicle(handle)
        end)
    end

    for veh in EnumerateVehicles() do
        if DoesEntityExist(veh) then
            local vpos = GetEntityCoords(veh)
            if #(origin - vpos) < (r + 0.75) then
                if Config.SpawnDebug then
                    print(('[ug_vehicle_shop] Spawn blocked: vehicle %.2fm away'):format(#(origin - vpos)))
                end
                return false
            end
        end
    end

    return true
end

local function buildOptions(idx, v)
    local currency = Config.CurrencyLabel or '$'
    local priceStr = string.format(' (%s%s)', currency, money(v.price))
    local opts = {}

    if v.allowOrg and v.jobRequirement ~= nil then
        opts[#opts + 1] = {
            name = 'ug_buy_org_' .. idx,
            label = Lang.target_buy_org .. priceStr,
            icon = 'fa-solid fa-building',
            onSelect = function()
                startPurchase(idx, 'org', Lang.confirm_title_org, Lang.confirm_msg_org)
            end
        }
    end

    if v.allowPrivate then
        opts[#opts + 1] = {
            name = 'ug_buy_priv_' .. idx,
            label = Lang.target_buy_priv .. priceStr,
            icon = 'fa-solid fa-car',
            onSelect = function()
                if v.allowOrg then
                    startPurchase(idx, 'priv', Lang.confirm_title_priv, Lang.confirm_msg_priv)
                else
                    startPurchase(idx, 'priv', Lang.confirm_title_priv, Lang.confirm_msg_priv_only)
                end
            end
        }
    end

    return opts
end


local function addTargetsForVehicle(veh, idx, v)
    exports[Config.TargetResource]:addLocalEntity(veh, buildOptions(idx, v))
end

local function buildFloatTextLines(v)
    local currency = Config.CurrencyLabel or '$'
    local priceStr = ("Price: %s%s"):format(currency, money(v.price))
    return {
        v.modelName or v.model,
        v.model,
        priceStr,
        ("Job: %s"):format(v.jobRequirement or '—'),
        "Garages:",
        ("Priv: %s"):format(v.defaultGaragePriv or '—'),
        ("Org: %s"):format(v.defaultGarageOrg or '—'),
    }
end

local function drawTxt3DLines(coords, lines)
    SetDrawOrigin(coords.x, coords.y, coords.z, 0)
    local y = 0.0
    for i = 1, #lines do
        SetTextFont(0)
        SetTextProportional(0)
        SetTextScale(0.20, 0.20)
        SetTextColour(255, 255, 255, 215)
        SetTextEdge(2, 0, 0, 0, 150)
        SetTextOutline()
        SetTextCentre(true)

        BeginTextCommandDisplayText("STRING")
        AddTextComponentSubstringPlayerName(lines[i])
        EndTextCommandDisplayText(0.0, y)

        if lines[i] == "Garages:" then
            y = y + 0.028
        else
            y = y + 0.020
        end
    end
    ClearDrawOrigin()
end

local function spawnDisplaysForZone(zoneId)
    if spawnedByZone[zoneId] and #spawnedByZone[zoneId] > 0 then return end
    spawnedByZone[zoneId] = {}

    for i, v in ipairs(Config.Vehicles) do
        if v.zoneId == zoneId then
            local hash = GetHashKey(v.model)
            RequestModel(hash)
            while not HasModelLoaded(hash) do Wait(50) end

            local veh = CreateVehicle(hash, v.coords.x, v.coords.y, v.coords.z, v.coords.w, false, false)
            SetEntityAsMissionEntity(veh, true, true)
            SetVehicleOnGroundProperly(veh)
            SetVehicleDirtLevel(veh, 0.0)
            SetVehicleFixed(veh)

            protectDisplayVehicle(veh)

            if Config.ShowPlatePrice then
                SetVehicleNumberPlateText(veh, platePrice(v.price))
            end

            addTargetsForVehicle(veh, i, v)
            spawnedByZone[zoneId][#spawnedByZone[zoneId] + 1] = { ent = veh, data = v }
        end
    end
end

local function clearDisplaysForZone(zoneId)
    local list = spawnedByZone[zoneId]
    if not list then return end
    for _, s in ipairs(list) do
        if DoesEntityExist(s.ent) then
            exports[Config.TargetResource]:removeLocalEntity(s.ent)
            DeleteEntity(s.ent)
        end
    end
    spawnedByZone[zoneId] = {}
end

CreateThread(function()
    if not (lib and lib.zones and lib.zones.box) then
        print('^3[ug_vehicle_shop]^7 ox_lib zones not found; vehicles will NOT spawn.')
        return
    end

    for id, z in pairs(Config.Zones) do
        zoneStates[id] = false

        lib.zones.box({
            coords   = z.center,
            size     = z.size,
            rotation = z.rotation or 0.0,
            debug    = Config.ZonesDebug or false,
            onEnter  = function()
                zoneStates[id] = true
                spawnDisplaysForZone(id)
            end,
            onExit   = function()
                zoneStates[id] = false
                clearDisplaysForZone(id)
            end
        })
    end
end)

AddEventHandler('onResourceStart', function(res)
    if GetCurrentResourceName() ~= res then return end
    if not Config.RespawnOnStart then return end
    for id, inside in pairs(zoneStates) do
        if inside then spawnDisplaysForZone(id) end
    end
end)

AddEventHandler('onResourceStop', function(res)
    if GetCurrentResourceName() ~= res then return end
    for id, _ in pairs(spawnedByZone) do clearDisplaysForZone(id) end
end)

CreateThread(function()
    while true do
        local wait = 500
        if Config.ShowFloatingText then
            local ped = PlayerPedId()
            local pcoords = GetEntityCoords(ped)
            for id, inside in pairs(zoneStates) do
                if inside and spawnedByZone[id] and #spawnedByZone[id] > 0 then
                    for _, s in ipairs(spawnedByZone[id]) do
                        if DoesEntityExist(s.ent) then
                            local v = s.data
                            local sc = GetEntityCoords(s.ent)
                            if #(pcoords - sc) < 25.0 then
                                local lines = buildFloatTextLines(v)
                                drawTxt3DLines(sc + vector3(0.0, 0.0, 1.2), lines)
                                wait = 0
                            end
                        end
                    end
                end
            end
        end
        Wait(wait)
    end
end)

RegisterNetEvent('ug_vehicle_shop:deliver', function(model, plate, spawn, mode)
    local hash = GetHashKey(model)
    RequestModel(hash)
    while not HasModelLoaded(hash) do Wait(0) end

    local x, y, z, h
    if spawn ~= nil then
        x, y, z, h = spawn.x, spawn.y, spawn.z, (spawn.w or spawn.heading or 0.0)
    else
        local ped = PlayerPedId()
        local pos = GetEntityCoords(ped)
        x, y, z, h = pos.x, pos.y, pos.z, GetEntityHeading(ped)
    end

    if not isSpawnFree(x, y, z, Config.SpawnCheckRadius) then
        if Config.SpawnDebug then
            DrawMarker(1, x, y, z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 2.5, 2.5, 0.8, 255, 50, 50, 150, false, false, 2,
                false, nil, nil, false)
            print(('[ug_vehicle_shop] Spawn blocked at (%.2f, %.2f, %.2f) — sending to garage'):format(x, y, z))
        end
        local msg = (mode == 'org') and (Lang.bought_org or 'Vehicle delivered to your organization garage.')
            or (Lang.bought_priv or 'Vehicle delivered to your private garage.')
        lib.notify({ title = 'Vehicle Shop', description = msg, type = 'success' })
        SetModelAsNoLongerNeeded(hash)
        return
    end

    local veh = CreateVehicle(hash, x, y, z, h, true, false)
    SetVehicleOnGroundProperly(veh)
    SetVehicleNumberPlateText(veh, plate)
    SetModelAsNoLongerNeeded(hash)
end)

RegisterNetEvent('ug_vehicle_shop:notify', function(level, msg)
    if level == 'success' then
        lib.notify({ title = 'Vehicle Shop', description = msg, type = 'success' })
    else
        lib.notify({ title = 'Vehicle Shop', description = msg, type = 'error' })
    end
end)

