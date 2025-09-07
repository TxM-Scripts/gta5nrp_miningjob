local cfg = Config.Jobs.Mining

Mining = {}
Mining.__index = Mining

function Mining:new(cfg)
    local self = setmetatable({}, Mining)
    self.cfg = cfg
    self.ped = nil
    self.active = false
    self.hasItem = false
    self.propEntity = nil
    self.toolEntity = nil
    self.currentBlip = nil
    self.toolChecked = false
    self.smeltingObj = nil
    return self
end

function Mining:spawnPed()
    RequestModel(self.cfg.Ped)
    while not HasModelLoaded(self.cfg.Ped) do Wait(0) end
    local c = self.cfg.PedBlip.Coords
    self.ped = CreatePed(4, self.cfg.Ped, c.x, c.y, c.z - 1, c.w, false, true)
    SetEntityInvincible(self.ped, true)
    FreezeEntityPosition(self.ped, true)
    SetBlockingOfNonTemporaryEvents(self.ped, true)

    exports.ox_target:addLocalEntity(self.ped, {
        {
            name = "start_" .. self.cfg.JobName,
            icon = self.cfg.Icon or "fa-solid fa-hammer",
            label = "Bắt đầu công việc: " .. self.cfg.JobLabel,
            onSelect = function()
                if not self.active then
                    self.active = true
                    self:onStart()
                end
            end
        },
        {
            name = "stop_" .. self.cfg.JobName,
            icon = "fa-solid fa-xmark",
            label = "Nghỉ công việc: " .. self.cfg.JobLabel,
            onSelect = function()
                if self.active then
                    self:stopJob()
                end
            end
        }
    })

    if self.cfg.PedBlip.Enable then
        local blip = AddBlipForCoord(c.x, c.y, c.z)
        SetBlipSprite(blip, self.cfg.PedBlip.Sprite)
        SetBlipColour(blip, self.cfg.PedBlip.Color)
        SetBlipScale(blip, self.cfg.PedBlip.Scale)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(self.cfg.PedBlip.Title)
        EndTextCommandSetBlipName(blip)
    end
end

function Mining:spawnSmeltingStation()
    if not cfg.Smelting.Prop then return end
    local model = joaat(cfg.Smelting.Prop)
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(0) end
    local coords = cfg.Smelting.Locations[1]
    self.smeltingObj = CreateObject(model, coords.x, coords.y, coords.z - 1, false, false, false)
    SetEntityHeading(self.smeltingObj, coords.w)
    FreezeEntityPosition(self.smeltingObj, true)

    exports.ox_target:addLocalEntity(self.smeltingObj, {
        {
            name = "smelt_" .. cfg.JobName,
            icon = "fa-solid fa-fire",
            label = "Mở lò luyện",
            onSelect = function()
                self:openSmeltMenu()
            end
        }
    })

    if cfg.Smelting.Blip.Enable then
        local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
        SetBlipSprite(blip, cfg.Smelting.Blip.Sprite)
        SetBlipColour(blip, cfg.Smelting.Blip.Color)
        SetBlipScale(blip, cfg.Smelting.Blip.Scale)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(cfg.Smelting.Blip.Label)
        EndTextCommandSetBlipName(blip)
    end
end

function Mining:createBlip(coords, blipCfg)
    if self.currentBlip and DoesBlipExist(self.currentBlip) then
        RemoveBlip(self.currentBlip)
    end
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, blipCfg.Sprite)
    SetBlipColour(blip, blipCfg.Color)
    SetBlipScale(blip, blipCfg.Scale)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(blipCfg.Label)
    EndTextCommandSetBlipName(blip)
    self.currentBlip = blip
end

function Mining:removeBlip()
    if self.currentBlip and DoesBlipExist(self.currentBlip) then
        RemoveBlip(self.currentBlip)
        self.currentBlip = nil
    end
end

function Mining:attachProp(modelName, bone, pos, rot)
    local ped = PlayerPedId()
    local model = joaat(modelName)
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(0) end
    local obj = CreateObject(model, 0,0,0, true, true, true)
    AttachEntityToEntity(obj, ped, GetPedBoneIndex(ped, bone),
        pos.x,pos.y,pos.z, rot.x,rot.y,rot.z,
        true,true,false,true,1,true)
    return obj
end

function Mining:removeEntity(entity)
    if entity and DoesEntityExist(entity) then
        DeleteEntity(entity)
    end
end

function Mining:notify(msg, type)
    lib.notify({ description = msg, type = type })
end

function Mining:hasTool()
    return exports.ox_inventory:Search("count", self.cfg.Tool.Name) > 0
end

MiningJob = setmetatable({}, { __index = Mining })
MiningJob.__index = MiningJob

function MiningJob:new(cfg)
    local self = setmetatable(Mining:new(cfg), MiningJob)
    self.isMining = false
    return self
end

function MiningJob:onStart()
    self:notify(self.cfg.Messages.Start, "inform")
    self:createBlip(self.cfg.Digging.Locations[1], self.cfg.Digging.Blip)

    CreateThread(function()
        while self.active do
            local sleep = 1000
            local ped = PlayerPedId()
            local pos = GetEntityCoords(ped)

            if not self.hasItem then
                for _, coords in ipairs(self.cfg.Digging.Locations) do
                    local dist = #(pos - vec3(coords.x, coords.y, coords.z))
                    if dist < 50 then
                        sleep = 0
                        local m = self.cfg.Digging.Marker
                        DrawMarker(m.type, coords.x, coords.y, coords.z - 1,0,0,0,0,0,0,
                            m.size.x,m.size.y,m.size.z,
                            m.color[1],m.color[2],m.color[3],m.color[4], false,false,2)

                        if dist < 5 and not self.isMining then
                            if not self:hasTool() then
                                if not self.toolChecked then
                                    self:notify(self.cfg.Messages.NeedTool, "error")
                                    self.toolChecked = true
                                end
                            else
                                self.toolChecked = false
                                self:startMining()
                            end
                        else
                            self.toolChecked = false
                        end
                    end
                end
            else
                for _, coords in ipairs(self.cfg.Crushing.Locations) do
                    local dist = #(pos - vec3(coords.x, coords.y, coords.z))
                    if dist < 50 then
                        sleep = 0
                        local m = self.cfg.Crushing.Marker
                        DrawMarker(m.type, coords.x, coords.y, coords.z - 1,0,0,0,0,0,0,
                            m.size.x,m.size.y,m.size.z,
                            m.color[1],m.color[2],m.color[3],m.color[4], false,false,2)
                        if dist < 2 then
                            self:finishCrushing()
                        end
                    end
                end
            end
            Wait(sleep)
        end
    end)
end

function MiningJob:stopJob()
    self.active = false
    self.isMining = false
    self.hasItem = false
    self.toolChecked = false
    self:removeBlip()
    self:removeEntity(self.toolEntity)
    self.toolEntity = nil

    self:removeEntity(self.propEntity)
    self.propEntity = nil
    ClearPedTasks(PlayerPedId())
    self:notify("Bạn đã nghỉ công việc khai thác.", "inform")
end

function MiningJob:startMining()
    if not self:hasTool() then return end
    TriggerServerEvent("gta5nrp_miningjob:server:damageTool", self.cfg.Tool.Name, 2)
    self.isMining = true
    local ped = PlayerPedId()
    self.toolEntity = self:attachProp(self.cfg.Props.Tool, 57005, vec3(0.1,0.0,0.0), vec3(270.0,180.0,0.0))
    local anim = self.cfg.Animations.Mining
    RequestAnimDict(anim.dict)
    while not HasAnimDictLoaded(anim.dict) do Wait(0) end
    TaskPlayAnim(ped, anim.dict, anim.clip, 8.0, -8.0, -1, 49, 0, false, false, false)
    StartMiningMinigame()
end

function MiningJob:onMiningSuccess()
    local ped = PlayerPedId()
    ClearPedTasks(ped)
    self:removeEntity(self.toolEntity)
    self.toolEntity = nil

    local carry = self.cfg.Animations.Carry
    RequestAnimDict(carry.dict)
    while not HasAnimDictLoaded(carry.dict) do Wait(0) end
    local rockPos = vec3(-0.10, -0.05, 0.08) 
    local rockRot = vec3(270.0, 180.0, 0.0)
    self.propEntity = self:attachProp(self.cfg.Props.Rock, 57005, rockPos, rockRot)
    TaskPlayAnim(ped, carry.dict, carry.clip, 8.0, -8.0, -1, 51, 0, false, false, false)

    self.hasItem = true
    self:notify(self.cfg.Messages.GotRock, "inform")
    self:removeBlip()
    self:createBlip(self.cfg.Crushing.Locations[1], self.cfg.Crushing.Blip)
    self.isMining = false
end

function MiningJob:onMiningFail()
    local ped = PlayerPedId()
    ClearPedTasks(ped)
    self:removeEntity(self.toolEntity)
    self.toolEntity = nil
    self.isMining = false
    self:notify(self.cfg.Messages.Fail or "Đào thất bại!", "error")
end

function MiningJob:finishCrushing()
    self:removeEntity(self.propEntity)
    self.propEntity = nil
    ClearPedTasks(PlayerPedId())
    self.hasItem = false
    TriggerServerEvent("gta5nrp_miningjob:server:rewardCrushing")
    self:notify(self.cfg.Messages.BackToMine, "inform")
    self:removeBlip()
    self:createBlip(self.cfg.Digging.Locations[1], self.cfg.Digging.Blip)
end

function Mining:openSmeltMenu()
    local options = {}
    for i, recipe in ipairs(cfg.Reward.Smelting) do
        local labelInputs = {}
        local canCraft = true

        for _, inp in ipairs(recipe.inputs) do
            local item = exports.ox_inventory:Items(inp.name)
            local displayName = item and item.label or inp.name
            table.insert(labelInputs, inp.amount .. "x " .. displayName)

            local have = exports.ox_inventory:Search("count", inp.name)
            if have < inp.amount then
                canCraft = false
            end
        end

        local outItem = exports.ox_inventory:Items(recipe.output.name)
        local outLabel = outItem and outItem.label or recipe.output.name
        local label = table.concat(labelInputs, " + ") .. " → " .. recipe.output.amount .. "x " .. outLabel

        table.insert(options, {
            title = "Công thức " .. i,
            description = label,
            icon = "fa-solid fa-fire",
            disabled = not canCraft,
            onSelect = function()
                if canCraft then
                    local success = lib.progressBar({
                        duration = 10000,
                        label = "Đang luyện " .. outLabel .. "...",
                        useWhileDead = false,
                        canCancel = true,
                        disable = { car = true, move = true, combat = true },
                        anim = {
                            dict = "amb@prop_human_parking_meter@male@base",
                            clip = "base"
                        }
                    })
                    if success then
                        TriggerServerEvent("gta5nrp_miningjob:server:smeltItem", recipe)
                    else
                        lib.notify({ description = "Bạn đã hủy luyện quặng!", type = "error" })
                    end
                end
            end
        })
    end

    lib.registerContext({
        id = "smelt_menu",
        title = "Lò Luyện Quặng",
        options = options
    })
    lib.showContext("smelt_menu")
end

function StartMiningMinigame()
    SetNuiFocus(true, true)
    SendNUIMessage({ action = "open" })
end

RegisterNUICallback("minigameResult", function(data, cb)
    SetNuiFocus(false, false)
    SendNUIMessage({ action = "close" })
    if data.success then
        miningJob:onMiningSuccess()
    else
        miningJob:onMiningFail()
    end
    cb("ok")
end)

CreateThread(function()
    miningJob = MiningJob:new(cfg)
    miningJob:spawnPed()
    miningJob:spawnSmeltingStation()
end)
