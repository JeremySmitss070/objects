TriggerEvent('chat:addSuggestion', '/propfix', 'Verwijder props die vastzitten', {})

TriggerEvent('chat:addSuggestion', '/delete_objects', 'Verwijder objecten die gebugged zijn (Meld bij developers)', {
    { name="radius", help="Voer een radius in om objecten te deleten" }
})

local inDienst = false
ESX = exports['es_extended']:getSharedObject()
RegisterCommand("propfix", function()
    local playerPed = PlayerPedId()

    local nearbyObjects = GetGamePool('CObject')
    local prop = nil

    for _, object in ipairs(nearbyObjects) do
        if DoesEntityExist(object) then
            local attachedEntity = GetEntityAttachedTo(object)
            if attachedEntity == playerPed then
                prop = object
                break
            end
        end
    end

    if prop then
        DetachEntity(prop, true, true)
        DeleteEntity(prop)
        print("Prop die vast zat verwijderd!")
    else
        print("Geen props op je entity.")
    end
end, false)

RegisterCommand("delete_objects", function(source, args, rawCommand)
    local radius = tonumber(args[1])
    local objectHandle, object = FindFirstObject()
    ESX.TriggerServerCallback("esx:isUserAdmin", function(admin)
        if not admin then
            exports['playernames']:templateError()
            return
        end
        if exports['nrp-staffzaak']:inDienst() then
            if radius then
                if DoesEntityExist(object, objectHash) then
                    print("Verwijder hashes binnen een straal van " .. radius .. " meter.")
                    DeleteEntitiesInRadius(radius)
                else
                    ESX.ShowNotification('error', 'Er zijn geen objecten in de buurt om te deleten')
                end
            else
                print("Ongeldige radius opgegeven. Gebruik het commando als volgt: /delete_objects [radius]")
            end
            inDienst = true
        else    
            exports['playernames']:templateErrorA()
        end
    end)
end, false)

function DeleteEntitiesInRadius(radius)
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    -- Zoek en verwijder alle objecten in de buurt
    local objectHandle, object = FindFirstObject()
    local success
    repeat
        local objCoords = GetEntityCoords(object)
        if #(coords - objCoords) <= radius then
            DeleteEntity(object, objectHash)
        end
        success, object = FindNextObject(objectHandle)
    until not success
    EndFindObject(objectHandle)
end

RegisterCommand('spawnobject', function(source, args, rawCommand)
    if args[1] then
        local objectHash = tonumber(args[1])

        if objectHash and IsModelInCdimage(objectHash) and IsModelValid(objectHash) then
            RequestModel(objectHash)
            while not HasModelLoaded(objectHash) do
                Citizen.Wait(0)
            end

            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)

            local spawnedObject = CreateObject(objectHash, playerCoords.x + 1.0, playerCoords.y + 1.0, playerCoords.z, true, true, false)

            PlaceObjectOnGroundProperly(spawnedObject)

            FreezeEntityPosition(spawnedObject, true)

            TriggerEvent('chat:addMessage', {
                color = {255, 0, 0},
                multiline = true,
                args = {"ObjectSpawner", "Object succesvol gespawned en gefreezed met hashkey: " .. objectHash}
            })

            SetModelAsNoLongerNeeded(objectHash)
        else
            TriggerEvent('chat:addMessage', {
                color = {255, 0, 0},
                multiline = true,
                args = {"ObjectSpawner", "Ongeldige hashkey: " .. tostring(args[1])}
            })
        end
    else
        TriggerEvent('chat:addMessage', {
            color = {255, 0, 0},
            multiline = true,
            args = {"ObjectSpawner", "Gebruik: /spawnobject [hashkey]"}
        })
    end
end, false)
