local QBCore = exports['qb-core']:GetCoreObject()

RegisterNetEvent('ai_medic:requestMedic', function()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)

    print("[AI Medic]: Starting the request for a medic...")

    -- Spawn AI Medic
    local medicModel = `s_m_m_doctor_01`

    RequestModel(medicModel)
    while not HasModelLoaded(medicModel) do
        print("[AI Medic]: Waiting for medic model to load...")
        Wait(1)
    end
    print("[AI Medic]: Medic model loaded successfully!")

    -- Spawn Medic Farther Away
    local spawnDistance = math.random(15, 20)
    local spawnAngle = math.rad(math.random(0, 360))
    local spawnCoords = vector3(
        playerCoords.x + spawnDistance * math.cos(spawnAngle),
        playerCoords.y + spawnDistance * math.sin(spawnAngle),
        playerCoords.z
    )

    local medicPed = CreatePed(4, medicModel, spawnCoords.x, spawnCoords.y, spawnCoords.z, 0.0, true, false)
    if DoesEntityExist(medicPed) then
        print("[AI Medic]: Medic spawned successfully!")
    else
        print("[AI Medic]: Failed to spawn medic.")
        return
    end

    -- Make Medic Run to Player
    TaskGoToCoordAnyMeans(medicPed, playerCoords.x, playerCoords.y, playerCoords.z, 2.0, 0, 0, 786603, 0)
    print("[AI Medic]: Medic is running to the player...")

    local timeout = GetGameTimer() + 30000
    local hasArrived = false

    while GetGameTimer() < timeout do
        local distance = #(playerCoords - GetEntityCoords(medicPed))
        print(string.format("[AI Medic]: Medic distance to player: %.2f", distance))
        if distance < 2.0 then
            hasArrived = true
            print("[AI Medic]: Medic has reached the player.")
            break
        end
        Wait(500)
    end

    if not hasArrived then
        print("[AI Medic]: Medic failed to reach the player. Timing out.")
        TriggerEvent('QBCore:Notify', 'The medic could not reach you.', 'error')
        DeleteEntity(medicPed)
        return
    end

    -- Perform Animation and Healing
    RequestAnimDict("mini@cpr@char_a@cpr_def")
    while not HasAnimDictLoaded("mini@cpr@char_a@cpr_def") do
        print("[AI Medic]: Waiting for animation dict to load...")
        Wait(1)
    end
    print("[AI Medic]: Animation dict loaded. Starting CPR animation.")
    TaskPlayAnim(medicPed, "mini@cpr@char_a@cpr_def", "cpr_pumpchest", 8.0, -8.0, -1, 1, 0, false, false, false)

    QBCore.Functions.Progressbar("medic_revive", "Healing you...", 10000, false, true, {}, {}, {}, {}, function()
        print("[AI Medic]: Healing process completed. Requesting server to revive player.")
        TriggerServerEvent("ai_medic:serverRevive", GetPlayerServerId(PlayerId()))
        ClearPedTasks(medicPed)
        Wait(15000)
        DeleteEntity(medicPed)
        TriggerEvent('QBCore:Notify', 'You have been revived!', 'success')
    end, function()
        print("[AI Medic]: Healing process canceled.")
        ClearPedTasks(medicPed)
        Wait(15000)
        DeleteEntity(medicPed)
        TriggerEvent('QBCore:Notify', 'Medic action canceled.', 'error')
    end)
end)
