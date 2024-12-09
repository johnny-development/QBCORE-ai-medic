local QBCore = exports['qb-core']:GetCoreObject()

RegisterNetEvent('ai_medic:requestMedic', function()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)

    -- Spawn AI Medic
    local medicModel = `s_m_m_doctor_01`
    local carModel = `ambulance`

    RequestModel(medicModel)
    RequestModel(carModel)
    while not HasModelLoaded(medicModel) or not HasModelLoaded(carModel) do
        Wait(1)
    end

    local medicPed = CreatePed(4, medicModel, coords.x + 10, coords.y + 10, coords.z, 0.0, true, false)
    local medicCar = CreateVehicle(carModel, coords.x + 12, coords.y + 12, coords.z, 0.0, true, false)

    TaskWarpPedIntoVehicle(medicPed, medicCar, -1)
    SetVehicleEngineOn(medicCar, true, true, false)

    -- Smooth Driving to Player
    local drivingStyle = 786603 -- Avoid pedestrians, normal traffic
    TaskVehicleDriveToCoordLongrange(medicPed, medicCar, coords.x, coords.y, coords.z, 20.0, drivingStyle, 10.0)

    -- Wait for Arrival
    local distance = #(coords - GetEntityCoords(medicCar))
    while distance > 5.0 do
        Wait(100)
        distance = #(coords - GetEntityCoords(medicCar))
    end

    TaskLeaveVehicle(medicPed, medicCar, 0)
    Wait(1000)

    -- Perform Animation and Healing
    RequestAnimDict("mini@cpr@char_a@cpr_def")
    while not HasAnimDictLoaded("mini@cpr@char_a@cpr_def") do
        Wait(1)
    end
    TaskPlayAnim(medicPed, "mini@cpr@char_a@cpr_def", "cpr_pumpchest", 8.0, -8.0, -1, 1, 0, false, false, false)

    QBCore.Functions.Progressbar("medic_revive", "Healing you...", 10000, false, true, {}, {}, {}, {}, function() -- on success
        TriggerServerEvent("hospital:server:RevivePlayer", GetPlayerServerId(PlayerId()))
        ClearPedTasks(medicPed)
        DeleteEntity(medicPed)
        DeleteEntity(medicCar)
        TriggerEvent('QBCore:Notify', 'You have been revived!', 'success')
    end, function() -- on cancel
        ClearPedTasks(medicPed)
        DeleteEntity(medicPed)
        DeleteEntity(medicCar)
        TriggerEvent('QBCore:Notify', 'Medic action canceled.', 'error')
    end)
end)
