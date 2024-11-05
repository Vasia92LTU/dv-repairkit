local QBCore = exports['qb-core']:GetCoreObject()

-- Function to create a usable repair kit
QBCore.Functions.CreateUseableItem("repairkit", function(source)
    local Player = QBCore.Functions.GetPlayer(source)
    TriggerClientEvent("DevaltuRepairSystem:client:useRepairKit", source)
end)

-- Event to remove the repair kit from the player's inventory
RegisterNetEvent('DevaltuRepairSystem:server:RemoveRepairKit', function()
    local Player = QBCore.Functions.GetPlayer(source)
    if Player then
        Player.Functions.RemoveItem("repairkit", 1)  -- Deduct one repair kit
        TriggerClientEvent('inventory:client:ItemBox', source, QBCore.Shared.Items["repairkit"], "remove")
    end
end)
