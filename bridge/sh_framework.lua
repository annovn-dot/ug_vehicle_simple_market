FW = {}
local detected = nil

CreateThread(function()
    if Config.Framework == 'auto' then
        if GetResourceState('es_extended') == 'started' then
            detected = 'esx'
        elseif GetResourceState('qb-core') == 'started' then
            detected = 'qb'
        elseif GetResourceState('qbx-core') == 'started' or GetResourceState('qbox-core') == 'started' then
            detected = 'qbox'
        else
            detected = 'esx'
        end
    else
        detected = Config.Framework
    end

    if detected == 'esx' then
        FW.obj = exports['es_extended']:getSharedObject()
    else
        FW.obj = exports['qb-core']:GetCoreObject()
    end

    print(('^2[ug_vehicle_shop]^7 Framework: %s'):format(detected))
end)

function FW.GetIdentifier(src)
    if detected == 'esx' then
        local xPlayer = FW.obj.GetPlayerFromId(src)
        return xPlayer and xPlayer.identifier
    else
        local xPlayer = FW.obj.Functions.GetPlayer(src)
        return xPlayer and xPlayer.PlayerData.citizenid
    end
end

function FW.GetLicense(src)
    if not src then return nil end
    for _, id in ipairs(GetPlayerIdentifiers(src) or {}) do
        if id:sub(1, 8) == 'license:' then
            return id
        end
    end
    return nil
end

function FW.GetName(src)
    if detected == 'esx' then
        local xPlayer = FW.obj.GetPlayerFromId(src)
        return xPlayer and xPlayer.getName() or ('Player %s'):format(src)
    else
        local xPlayer = FW.obj.Functions.GetPlayer(src)
        if not xPlayer then return ('Player %s'):format(src) end
        local pd = xPlayer.PlayerData
        local name = (pd.charinfo and ((pd.charinfo.firstname or '') .. ' ' .. (pd.charinfo.lastname or '')))
        return name ~= '' and name or (pd.name or ('Player %s'):format(src))
    end
end

function FW.GetJob(src)
    if detected == 'esx' then
        local xPlayer = FW.obj.GetPlayerFromId(src)
        return xPlayer and xPlayer.getJob().name or nil
    else
        local xPlayer = FW.obj.Functions.GetPlayer(src)
        return xPlayer and xPlayer.PlayerData.job.name or nil
    end
end

function FW.GetBank(src)
    if detected == 'esx' then
        local xPlayer = FW.obj.GetPlayerFromId(src)
        return xPlayer and xPlayer.getAccount('bank').money or 0
    else
        local xPlayer = FW.obj.Functions.GetPlayer(src)
        return xPlayer and xPlayer.PlayerData.money.bank or 0
    end
end

function FW.RemoveBank(src, amount)
    if detected == 'esx' then
        local xPlayer = FW.obj.GetPlayerFromId(src)
        if xPlayer then
            xPlayer.removeAccountMoney('bank', amount)
            return true
        end
    else
        local xPlayer = FW.obj.Functions.GetPlayer(src)
        if xPlayer then
            xPlayer.Functions.RemoveMoney('bank', amount, 'vehicle-shop')
            return true
        end
    end
    return false
end
