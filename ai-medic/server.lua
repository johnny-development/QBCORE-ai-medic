local QBCore = exports['qb-core']:GetCoreObject()
local medicCooldowns = {}
local MEDIC_FEE = 500 -- Set fee for medic services

RegisterCommand('requestmedic', function(source, args)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    if not Player then return end

    local identifier = Player.PlayerData.citizenid
    local currentTime = os.time()

    -- Cooldown Check
    if medicCooldowns[identifier] and medicCooldowns[identifier] > currentTime then
        local remainingTime = medicCooldowns[identifier] - currentTime
        TriggerClientEvent('QBCore:Notify', src, 'You must wait ' .. remainingTime .. ' seconds to request a medic again.', 'error')
        return
    end

    -- Check for EMS Online
    local EMS = QBCore.Functions.GetPlayersByJob('ambulance')
    if #EMS > 0 then
        TriggerClientEvent('QBCore:Notify', src, 'EMS is currently online. Please request a real medic.', 'error')
        return
    end

    -- Check Player Money
    if Player.Functions.GetMoney('cash') < MEDIC_FEE then
        TriggerClientEvent('QBCore:Notify', src, 'You don\'t have enough money for medic services.', 'error')
        return
    end

    -- Deduct Fee and Set Cooldown
    Player.Functions.RemoveMoney('cash', MEDIC_FEE)
    medicCooldowns[identifier] = currentTime + 300 -- Cooldown of 300 seconds (5 minutes)
    TriggerClientEvent('ai_medic:requestMedic', src)
end)
