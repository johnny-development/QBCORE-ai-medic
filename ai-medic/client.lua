local QBCore = exports['qb-core']:GetCoreObject()

RegisterNetEvent('ai_medic:requestMedic', function()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)

    if Config.Debug then
        print("[AI Medic]: Starting the request for a medic...")
    end

    -- Spawn AI Medic
    RequestModel(Config.MedicModel)
    while not HasModelLoaded(Config.MedicModel) do
        if Config.Debug then
            print("[AI Medic]: Waiting for medic model to load...")
        end
        Wait(1)
    end

    if Config.Debug then
        print("[AI Medic]: Medic model loaded successfully!")
    end

    -- Spawn Medic Farther Away
    local spawnDistance = math.random(Config.SpawnDistance.min, Config.SpawnDistance.max)
    local spawnAngle = math.rad(math.random(0, 360))
    local spawnCoords = vector3(
        playerCoords.x + spawnDistance * math.cos(spawnAngle),
        playerCoords.y + spawnDistance * math.sin(spawnAngle),
        playerCoords.z
    )

    local medicPed = CreatePed(4, Config.MedicModel, spawnCoords.x, spawnCoords.y, spawnCoords.z, 0.0, true, false)
    if DoesEntityExist(medicPed) then
        if Config.Debug then
            print("[AI Medic]: Medic spawned successfully!")
        end
    else
        if Config.Debug then
            print("[AI Medic]: Failed to spawn medic.")
        end
        return
    end

    -- Configure Medic Behavior
    if Config.ImmuneToDamage then
        SetEntityInvincible(medicPed, true) -- Makes the NPC immune to all damage
    end
    if Config.IgnoreExternalEvents then
        SetBlockingOfNonTemporaryEvents(medicPed, true) -- Prevents reactions to explosions, gunfire, etc.
        TaskSetBlockingOfNonTemporaryEvents(medicPed, true)
    end

    if Config.Debug then
        print("[AI Medic]: Medic behavior configured (immune: " .. tostring(Config.ImmuneToDamage) .. ", ignore events: " .. tostring(Config.IgnoreExternalEvents) .. ").")
    end

    -- Make Medic Run to Player
    TaskGoToCoordAnyMeans(medicPed, playerCoords.x, playerCoords.y, playerCoords.z, 2.0, 0, 0, 786603, 0)
    if Config.Debug then
        print("[AI Medic]: Medic is running to the player...")
    end

    local timeout = GetGameTimer() + 30000
    local hasArrived = false

    while GetGameTimer() < timeout do
        local distance = #(playerCoords - GetEntityCoords(medicPed))
        if Config.Debug then
            print(string.format("[AI Medic]: Medic distance to player: %.2f", distance))
        end
        if distance < 2.0 then
            hasArrived = true
            if Config.Debug then
                print("[AI Medic]: Medic has reached the player.")
            end
            break
        end
        Wait(500)
    end

    if not hasArrived then
        if Config.Debug then
            print("[AI Medic]: Medic failed to reach the player. Timing out.")
        end
        TriggerEvent('QBCore:Notify', 'The medic could not reach you.', 'error')
        DeleteEntity(medicPed)
        return
    end

    -- Perform Animation and Healing
    RequestAnimDict("mini@cpr@char_a@cpr_def")
    while not HasAnimDictLoaded("mini@cpr@char_a@cpr_def") do
        if Config.Debug then
            print("[AI Medic]: Waiting for animation dict to load...")
        end
        Wait(1)
    end
    if Config.Debug then
        print("[AI Medic]: Animation dict loaded. Starting CPR animation.")
    end
    TaskPlayAnim(medicPed, "mini@cpr@char_a@cpr_def", "cpr_pumpchest", 8.0, -8.0, -1, 1, 0, false, false, false)

    QBCore.Functions.Progressbar("medic_revive", "Healing you...", 10000, false, true, {}, {}, {}, {}, function()
        if Config.Debug then
            print("[AI Medic]: Healing process completed. Requesting server to revive player.")
        end
        TriggerServerEvent("ai_medic:serverRevive", GetPlayerServerId(PlayerId()))
        ClearPedTasks(medicPed)
        Wait(15000)
        DeleteEntity(medicPed)
        TriggerEvent('QBCore:Notify', 'You have been revived!', 'success')
    end, function()
        if Config.Debug then
            print("[AI Medic]: Healing process canceled.")
        end
        ClearPedTasks(medicPed)
        Wait(15000)
        DeleteEntity(medicPed)
        TriggerEvent('QBCore:Notify', 'Medic action canceled.', 'error')
    end)
end)

-- For custom scripts join the link below your first order is on us
-- https://discord.gg/mQQ2D28XqK
