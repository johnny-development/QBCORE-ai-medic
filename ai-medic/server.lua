local QBCore = exports['qb-core']:GetCoreObject()
local medicCooldowns = {}
local MEDIC_FEE = 500 -- Set fee for medic services

-- Function to count players with a specific job
local function countPlayersByJob(job)
    local players = QBCore.Functions.GetPlayers()
    local count = 0
    for _, playerId in pairs(players) do
        local player = QBCore.Functions.GetPlayer(playerId)
        if player and player.PlayerData.job.name == job then
            count = count + 1
        end
    end
    return count
end

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
    local EMSCount = countPlayersByJob('ambulance')
    if EMSCount > 0 then
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

-- Secure Server-Side Revive Logic
RegisterNetEvent('ai_medic:serverRevive', function(targetId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    -- Validate request source
    if not Player then
        print("[AI Medic]: Invalid source for revive request.")
        return
    end

    -- Ensure revive requests only come from valid AI Medic calls
    if Player.PlayerData.job.name ~= 'ambulance' and src ~= targetId then
        print("[AI Medic]: Unauthorized revive attempt detected from source: " .. src)
        return
    end

    -- Perform the revive
    local TargetPlayer = QBCore.Functions.GetPlayer(targetId)
    if TargetPlayer then
        TriggerClientEvent('hospital:client:Revive', targetId) -- Trigger the revive event
        TriggerClientEvent('QBCore:Notify', targetId, 'You have been revived by an AI Medic.', 'success')
        print("[AI Medic]: Player " .. targetId .. " has been revived successfully.")
    else
        print("[AI Medic]: Target player not found for revive.")
    end
end)
