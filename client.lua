local editorOpen, placingMode = false, false
local selectedPed, peds = nil, {}
local saveFile = "scene_data.json"
local pedList = {}

----------------------------------------
-- 🔁 CHARGEMENT DES PEDS.JSON
----------------------------------------
CreateThread(function()
    local jsonData = LoadResourceFile(GetCurrentResourceName(), "nui/peds.json")
    if not jsonData then
        print("[pnj_editor] ⚠️ ERREUR : peds.json manquant")
        return
    end

    -- Supprimer un éventuel "L" au début (comme ton fichier)
    if string.sub(jsonData, 1, 1) == "L" then
        jsonData = string.sub(jsonData, 2)
    end

    local success, parsed = pcall(json.decode, jsonData)
    if not success or not parsed then
        print("[pnj_editor] ⚠️ ERREUR : peds.json invalide")
        return
    end

    -- Supporte le format complet avec champ "Name"
    if type(parsed[1]) == "table" and parsed[1].Name then
        for _, ped in ipairs(parsed) do
            if ped.Name and ped.Name ~= "" then
                pedList[#pedList + 1] = ped.Name
            end
        end
    else
        pedList = parsed
    end

    print(("[pnj_editor] ✅ %s modèles chargés"):format(#pedList))
end)

----------------------------------------
-- 🔧 OUVERTURE / FERMETURE DU PANEL
----------------------------------------
RegisterCommand("togglePNJEditor", function()
    if editorOpen then
        editorOpen = false
        SetNuiFocus(false, false)
        SendNUIMessage({ action = "close" })
    else
        editorOpen = true
        SetNuiFocus(true, true)
        SendNUIMessage({ action = "open" })

        -- 🔄 Envoi progressif de la liste complète au NUI
        CreateThread(function()
            local total, sent, batch = #pedList, 0, 300
            while sent < total do
                local chunk = {}
                for i = sent + 1, math.min(sent + batch, total) do
                    chunk[#chunk + 1] = pedList[i]
                end
                SendNUIMessage({ action = "addPeds", peds = chunk })
                sent = sent + #chunk
                Wait(100)
            end
        end)
    end
end)
RegisterKeyMapping("togglePNJEditor", "Ouvrir l’éditeur de PNJ", "keyboard", "F6")

----------------------------------------
-- 🧍 SPAWN D’UN PNJ
----------------------------------------
local function spawnPed(model)
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    local forward = GetEntityForwardVector(playerPed)
    local pos = coords + forward * 2.0
    local heading = GetEntityHeading(playerPed)
    local hash = GetHashKey(model)

    RequestModel(hash)
    while not HasModelLoaded(hash) do Wait(0) end

    local ped = CreatePed(4, hash, pos.x, pos.y, pos.z, heading, false, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    FreezeEntityPosition(ped, true)
    table.insert(peds, ped)
    selectedPed = ped
    SetModelAsNoLongerNeeded(hash)
end

----------------------------------------
-- 🔁 DÉPLACEMENT
----------------------------------------
CreateThread(function()
    while true do
        Wait(0)
        if placingMode and selectedPed and DoesEntityExist(selectedPed) then
            local pos = GetEntityCoords(selectedPed)
            local camRot = GetGameplayCamRot(2)
            local heading = camRot.z
            local forward = vector3(-math.sin(math.rad(heading)), math.cos(math.rad(heading)), 0.0)

            if IsControlPressed(0, 172) then pos += forward * 0.05 end
            if IsControlPressed(0, 173) then pos -= forward * 0.05 end
            if IsControlPressed(0, 174) then SetEntityHeading(selectedPed, GetEntityHeading(selectedPed) - 1.0) end
            if IsControlPressed(0, 175) then SetEntityHeading(selectedPed, GetEntityHeading(selectedPed) + 1.0) end
            if IsControlPressed(0, 10) then pos += vector3(0,0,0.05) end
            if IsControlPressed(0, 11) then pos -= vector3(0,0,0.05) end
            if IsControlJustPressed(0, 178) then DeleteEntity(selectedPed) selectedPed=nil end

            SetEntityCoordsNoOffset(selectedPed, pos.x,pos.y,pos.z,false,false,false)
        end
    end
end)

----------------------------------------
-- 💾 SAUVEGARDE
----------------------------------------
local function saveScene()
    local data = {}
    for _, ped in ipairs(peds) do
        if DoesEntityExist(ped) then
            local c = GetEntityCoords(ped)
            table.insert(data, { model = GetEntityModel(ped), x = c.x, y = c.y, z = c.z, h = GetEntityHeading(ped) })
        end
    end
    SaveResourceFile(GetCurrentResourceName(), saveFile, json.encode(data), -1)
    print("[pnj_editor] Scène sauvegardée.")
end

RegisterCommand("loadscene", function()
    local data = LoadResourceFile(GetCurrentResourceName(), saveFile)
    if not data then print("[pnj_editor] Aucun fichier trouvé.") return end
    local parsed = json.decode(data)
    for _, v in ipairs(parsed) do
        local ped = CreatePed(4, v.model, v.x, v.y, v.z, v.h, false, true)
        SetEntityInvincible(ped, true)
        SetBlockingOfNonTemporaryEvents(ped, true)
        FreezeEntityPosition(ped, true)
        table.insert(peds, ped)
    end
    print("[pnj_editor] Scène chargée avec " .. #parsed .. " PNJ.")
end)

----------------------------------------
-- 🔘 CALLBACKS NUI
----------------------------------------
RegisterNUICallback("spawnPed", function(data, cb) spawnPed(data.model) cb("ok") end)
RegisterNUICallback("togglePlacement", function(_, cb)
    placingMode = not placingMode
    if placingMode then
        SetNuiFocus(false, false)
        SendNUIMessage({ action = "minimize" })
    else
        SetNuiFocus(true, true)
        SendNUIMessage({ action = "restore" })
    end
    cb("ok")
end)
RegisterNUICallback("saveScene", function(_, cb) saveScene() cb("ok") end)
RegisterNUICallback("close", function(_, cb)
    editorOpen, placingMode = false, false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = "close" })
    cb("ok")
end)
