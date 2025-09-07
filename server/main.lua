local function damageTool(src, toolName, amount)
    local items = exports.ox_inventory:Search(src, 'slots', toolName)
    if not items or #items == 0 then return end
    local item = items[1]
    local meta = item.metadata or {}
    local durability = meta.durability or 100
    durability = durability - amount
    if durability > 0 then
        exports.ox_inventory:SetMetadata(src, item.slot, { durability = durability })
    else
        exports.ox_inventory:RemoveItem(src, toolName, 1, nil, item.slot)
        TriggerClientEvent('ox_lib:notify', src, {
            type = "error",
            description = "Rìu đã gãy!"
        })
    end
end

RegisterNetEvent("gta5nrp_miningjob:server:damageTool", function(toolName, amount)
    local src = source
    damageTool(src, toolName, amount)
end)

RegisterNetEvent("gta5nrp_miningjob:server:rewardCrushing", function()
    local src = source
    local rewards = Config.Jobs.Mining.Reward.Crushing
    local pool = {}
    for _, reward in ipairs(rewards) do
        if not reward.chance or math.random(100) <= reward.chance then
            table.insert(pool, reward)
        end
    end
    if #pool > 0 then
        local picked = pool[math.random(#pool)]
        exports.ox_inventory:AddItem(src, picked.name, picked.amount)
        TriggerClientEvent("ox_lib:notify", src, {
            type = "success",
            description = "Bạn nhận được: " .. picked.amount .. "x " .. picked.name
        })
    else
        TriggerClientEvent("ox_lib:notify", src, {
            type = "error",
            description = "Không nhận được gì từ đá này!"
        })
    end
end)

RegisterNetEvent("gta5nrp_miningjob:server:smeltItem", function(recipe)
    local src = source
    if not recipe or not recipe.inputs or not recipe.output then return end
    for _, input in ipairs(recipe.inputs) do
        local count = exports.ox_inventory:Search(src, "count", input.name)
        if count < input.amount then
            TriggerClientEvent("ox_lib:notify", src, {
                type = "error",
                description = ("Thiếu %dx %s"):format(input.amount, input.name)
            })
            return
        end
    end
    for _, input in ipairs(recipe.inputs) do
        exports.ox_inventory:RemoveItem(src, input.name, input.amount)
    end
    exports.ox_inventory:AddItem(src, recipe.output.name, recipe.output.amount)

    TriggerClientEvent("ox_lib:notify", src, {
        type = "success",
        description = ("Bạn đã luyện thành công %dx %s"):format(recipe.output.amount, recipe.output.name)
    })
end)
