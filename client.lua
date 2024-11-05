local QBCore = exports['qb-core']:GetCoreObject()

-- Event to open the repair menu on the client-side
RegisterNetEvent("DevaltuRepairSystem:client:useRepairKit")
AddEventHandler("DevaltuRepairSystem:client:useRepairKit", function()
    local playerPed = PlayerPedId()
    local vehicle = QBCore.Functions.GetClosestVehicle()

    if DoesEntityExist(vehicle) and #(GetEntityCoords(playerPed) - GetEntityCoords(vehicle)) < 5.0 then
        -- Open the repair menu or directly call the repair functionality
        exports['qb-menu']:openMenu({
            {
                header = "Repair Menu",
                isMenuHeader = true
            },
            {
                header = "Repair Engine",
                txt = "Fix issues with the engine",
                params = {
                    event = "repair:engine"
                }
            },
            {
                header = "Repair Body",
                txt = "Fix issues with the body",
                params = {
                    event = "repair:body"
                }
            },
            {
                header = "Clean Vehicle",
                txt = "Clean the exterior of the vehicle",
                params = {
                    event = "repair:clean"
                }
            }
        })
    else
        QBCore.Functions.Notify("You need to be near a vehicle to use the repair kit.", "error")
    end
end)
-- Define multiple workbench locations
local workbenchLocations = {
    vector3(159.3941, -3014.1926, 5.1348), -- First location
    vector3(142.05082, -3019.8, 7.2499284),      -- Second location
    vector3(123.45, -567.89, 30.12)        -- Add more locations as needed
}
-- Create the 3D text UI for each workbench location
Citizen.CreateThread(function()
    for i, location in ipairs(workbenchLocations) do
        exports['dvltu-textui']:create3DTextUI("dv-workbench-" .. i, {
            coords = location,
            displayDist = 15.0,
            interactDist = 2.0,
            enableKeyClick = true,
            keyNum = 38, -- Key E
            key = "E",
            text = "Repair Vehicle",
            theme = "green",
            job = "all",
            canInteract = function()
                return true
            end,
            triggerData = {
                triggerName = "repair:workbench", -- Event to trigger when interacting
                args = { location = location } -- Pass location for identifying which workbench
            }
        })
    end
end)

-- Workbench repair event
RegisterNetEvent("repair:workbench")
AddEventHandler("repair:workbench", function(data)
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local vehicle = QBCore.Functions.GetClosestVehicle()

    -- Check proximity to the specified workbench location
    local distance = #(playerCoords - data.location)
    if distance <= 2.0 and DoesEntityExist(vehicle) then
        -- Start repair process
        QBCore.Functions.Progressbar("repair_vehicle", "Repairing Vehicle...", 15000, false, true, {
            disableMovement = true,
            disableCarMovement = true,
            disableMouse = false,
            disableCombat = true,
        }, {}, {}, {}, function() -- On success
            SetVehicleFixed(vehicle)
            QBCore.Functions.Notify("Vehicle repaired to 100% health!", "success")
        end, function() -- On cancel
            QBCore.Functions.Notify("Vehicle repair cancelled.", "error")
        end)
    else
        QBCore.Functions.Notify("No vehicle nearby to repair or not close enough to workbench.", "error")
    end
end)

-- Clean up all text UIs when the script stops
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        for i = 1, #workbenchLocations do
            exports['dvltu-textui']:delete3DTextUI("dv-workbench-" .. i)
        end
    end
end)
-- Engine repair function
RegisterNetEvent("repair:engine")
AddEventHandler("repair:engine", function()
    -- Your existing engine repair logic
end)

-- Body repair function
RegisterNetEvent("repair:body")
AddEventHandler("repair:body", function()
    -- Your existing body repair logic
end)


RegisterNetEvent("repair:engine")
AddEventHandler("repair:engine", function()
    local playerPed = PlayerPedId()
    local vehicle = QBCore.Functions.GetClosestVehicle()

    -- Check if player is outside the vehicle
    if not IsPedInAnyVehicle(playerPed, false) then
        if DoesEntityExist(vehicle) then
            -- Start the minigame before the repair process
            exports['skillchecks']:startAlphabetGame(5000, 5, function(success)
                if success then
                    -- Open the hood of the vehicle
                    SetVehicleDoorOpen(vehicle, 4, false, false) -- 4 is the index for the hood

                    -- Load the mechanic animation dictionary
                    RequestAnimDict("mini@repair")
                    while not HasAnimDictLoaded("mini@repair") do
                        Wait(100)
                    end

                    -- Play the mechanic repair animation
                    TaskPlayAnim(playerPed, "mini@repair", "fixing_a_ped", 8.0, -8.0, 10000, 49, 0, false, false, false)

                    -- Progress bar for engine repair
                    QBCore.Functions.Progressbar("repair_engine", "Repairing Engine...", 10000, false, true, {
                        disableMovement = true,
                        disableCarMovement = true,
                        disableMouse = false,
                        disableCombat = true,
                    }, {}, {}, {}, function() -- On success
                        ClearPedTasksImmediately(playerPed) -- Stop the animation once repair is done

                        local currentEngineHealth = GetVehicleEngineHealth(vehicle)
                        local maxHealth = 350.0
                        
                        -- Limit engine health to 35%
                        if currentEngineHealth < maxHealth then
                            SetVehicleEngineHealth(vehicle, maxHealth)
                        else
                            QBCore.Functions.Notify("Engine is already above 35% health.", "error")
                        end

                        -- Deduct one repair kit after use
                        TriggerServerEvent("DevaltuRepairSystem:server:RemoveRepairKit")
                        QBCore.Functions.Notify("Engine repaired to 35% maximum health!", "success")

                        -- Close the hood after repair
                        SetVehicleDoorShut(vehicle, 4, false)
                    end, function() -- On cancel
                        -- Stop animation if repair is canceled
                        ClearPedTasksImmediately(playerPed)
                        
                        -- Close the hood if repair is canceled
                        SetVehicleDoorShut(vehicle, 4, false)
                        QBCore.Functions.Notify("Engine repair cancelled.", "error")
                    end)
                else
                    -- If minigame fails
                    QBCore.Functions.Notify("You failed the skill check. Engine repair cannot start.", "error")
                end
            end)
        else
            QBCore.Functions.Notify("You need to be near a vehicle to repair the engine.", "error")
        end
    else
        QBCore.Functions.Notify("Exit the vehicle to use the repair kit.", "error")
    end
end)


-- Body repair function with welding animation, door opening, and restriction when inside vehicle
RegisterNetEvent("repair:body")
AddEventHandler("repair:body", function()
    local playerPed = PlayerPedId()
    local vehicle = QBCore.Functions.GetClosestVehicle()

    -- Check if player is outside the vehicle
    if not IsPedInAnyVehicle(playerPed, false) then
        if DoesEntityExist(vehicle) then
            -- Start the minigame before the repair
            exports['skillchecks']:startAlphabetGame(5000, 8, function(success)
                if success then
                    -- Open all doors of the vehicle
                    for i = 0, 3 do -- 0 to 3 represents the front left, front right, rear left, and rear right doors
                        SetVehicleDoorOpen(vehicle, i, false, false)
                    end

                    -- Load the welding animation dictionary
                    RequestAnimDict("amb@world_human_welding@male@base")
                    while not HasAnimDictLoaded("amb@world_human_welding@male@base") do
                        Wait(100)
                    end

                    -- Play welding animation
                    TaskPlayAnim(playerPed, "amb@world_human_welding@male@base", "base", 8.0, -8.0, 8000, 49, 0, false, false, false)

                    -- Progress bar for body repair
                    QBCore.Functions.Progressbar("repair_body", "Repairing Body...", 8000, false, true, {
                        disableMovement = true,
                        disableCarMovement = true,
                        disableMouse = false,
                        disableCombat = true,
                    }, {}, {}, {}, function() -- On success
                        SetVehicleDeformationFixed(vehicle) -- Fix vehicle body deformation
                        TriggerServerEvent("DevaltuRepairSystem:server:RemoveRepairKit") -- Deduct one repair kit after use
                        QBCore.Functions.Notify("Body repaired successfully!", "success")

                        -- Close all doors after repair
                        for i = 0, 3 do
                            SetVehicleDoorShut(vehicle, i, false)
                        end

                        -- Stop animation once repair is done
                        ClearPedTasksImmediately(playerPed)
                    end, function() -- On cancel
                        -- Stop animation if repair is canceled
                        ClearPedTasksImmediately(playerPed)

                        -- Close all doors if repair is canceled
                        for i = 0, 3 do
                            SetVehicleDoorShut(vehicle, i, false)
                        end

                        QBCore.Functions.Notify("Body repair cancelled.", "error")
                    end)
                else
                    -- If minigame fails
                    QBCore.Functions.Notify("You failed the skill check. Body repair cannot start.", "error")
                end
            end)
        else
            QBCore.Functions.Notify("You need to be near a vehicle to repair the body.", "error")
        end
    else
        QBCore.Functions.Notify("Exit the vehicle to use the repair kit.", "error")
    end
end)

-- Clean vehicle function with cleaning animation
local QBCore = exports['qb-core']:GetCoreObject()

RegisterNetEvent("repair:clean")
AddEventHandler("repair:clean", function()
    local playerPed = PlayerPedId()
    local vehicle = QBCore.Functions.GetClosestVehicle()

    -- Check if player is outside the vehicle
    if not IsPedInAnyVehicle(playerPed, false) then
        if DoesEntityExist(vehicle) then
            -- Start the minigame before cleaning
            exports['skillchecks']:startAlphabetGame(5000, 5, function(success)
                if success then
                    -- Load the cleaning animation dictionary
                    RequestAnimDict("timetable@floyd@clean_kitchen@base")
                    while not HasAnimDictLoaded("timetable@floyd@clean_kitchen@base") do
                        Wait(100)
                    end

                    -- Play cleaning animation
                    TaskPlayAnim(playerPed, "timetable@floyd@clean_kitchen@base", "base", 8.0, -8.0, 8000, 49, 0, false, false, false)

                    -- Progress bar for cleaning
                    QBCore.Functions.Progressbar("clean_vehicle", "Cleaning Vehicle...", 8000, false, true, {
                        disableMovement = true,
                        disableCarMovement = true,
                        disableMouse = false,
                        disableCombat = true,
                    }, {}, {}, {}, function() -- On success
                        ClearPedTasksImmediately(playerPed) -- Stop the animation once cleaning is done
                        SetVehicleDirtLevel(vehicle, 0.0) -- Clean the vehicle

                        -- Deduct one repair kit after use
                        TriggerServerEvent("DevaltuRepairSystem:server:RemoveRepairKit")
                        QBCore.Functions.Notify("Vehicle cleaned successfully!", "success")
                    end, function() -- On cancel
                        -- Stop animation if cleaning is canceled
                        ClearPedTasksImmediately(playerPed)
                        QBCore.Functions.Notify("Vehicle cleaning cancelled.", "error")
                    end)
                else
                    -- If minigame fails
                    QBCore.Functions.Notify("You failed the skill check. Cleaning cannot start.", "error")
                end
            end)
        else
            QBCore.Functions.Notify("You need to be near a vehicle to clean it.", "error")
        end
    else
        QBCore.Functions.Notify("Exit the vehicle to use the cleaning kit.", "error")
    end
end)


