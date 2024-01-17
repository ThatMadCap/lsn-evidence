-- Variables
local CurrentStatusList = {}
local shotAmount = 0

local StatusList = {
    ['fight'] = Lang:t('evidence.red_hands'),
    ['widepupils'] = Lang:t('evidence.wide_pupils'),
    ['redeyes'] = Lang:t('evidence.red_eyes'),
    ['weedsmell'] = Lang:t('evidence.weed_smell'),
    ['gunpowder'] = Lang:t('evidence.gunpowder'),
    ['chemicals'] = Lang:t('evidence.chemicals'),
    ['heavybreath'] = Lang:t('evidence.heavy_breathing'),
    ['sweat'] = Lang:t('evidence.sweat'),
    ['handbleed'] = Lang:t('evidence.handbleed'),
    ['confused'] = Lang:t('evidence.confused'),
    ['alcohol'] = Lang:t('evidence.alcohol'),
    ["heavyalcohol"] = Lang:t('evidence.heavy_alcohol'),
    ["agitated"] = Lang:t('evidence.agitated')
}

local WhitelistedWeapons = {
    `weapon_unarmed`,
    `weapon_snowball`,
    `weapon_stungun`,
    `weapon_petrolcan`,
    `weapon_hazardcan`,
    `weapon_fireextinguisher`
}

-- Functions
local function WhitelistedWeapon(weapon)
    for i = 1, #WhitelistedWeapons do
        if WhitelistedWeapons[i] == weapon then
            return true
        end
    end
    return false
end

-- Events
RegisterNetEvent('evidence:client:SetStatus', function(statusId, time)
    if time > 0 and StatusList[statusId] then
        if (CurrentStatusList == nil or CurrentStatusList[statusId] == nil) or
            (CurrentStatusList[statusId] and CurrentStatusList[statusId].time < 20) then
            CurrentStatusList[statusId] = {
                text = StatusList[statusId],
                time = time
            }
            QBCore.Functions.Notify(CurrentStatusList[statusId].text, 'error')
        end
    elseif StatusList[statusId] then
        CurrentStatusList[statusId] = nil
    end
    TriggerServerEvent('evidence:server:UpdateStatus', CurrentStatusList)
end)

RegisterNetEvent('police:client:SelectEvidence', function(Data)
    QBCore.Debug(Data)
    QBCore.Functions.TriggerCallback('police:server:GetEvidenceByType', function(List)
        if List == nil then
            QBCore.Functions.Notify(Lang:t('error.dont_have_evidence_bag'), 'error')
        else
            local EvidenceBagsMenu = {}

            for _, n in pairs(List) do
                EvidenceBagsMenu[#EvidenceBagsMenu+1] = {opthead = n.label, optdesc = Lang:t('info.select_for_examine_b', {street = n.info.street, label= n.info.label, slot=n.slot}), opticon = 'caret-right',
                    optparams  = {
                        event = 'police:client:ExamineEvidenceBag',
                        args = {Item = n,slot = n.slot}
                    }}
            end

            EvidenceBagsMenu[#EvidenceBagsMenu+1] = {opthead = Lang:t('menu.close_x'),opticon = 'fa-solid fa-xmark', optparams= {event=''}}
            local header = {
                disabled = true,
                header = Data.label..' evidences',
                headerid = 'police_evidencebags_menu', -- unique
                desc = '',
                icon = Data.icon
            }
            ContextSystem.Open(header, EvidenceBagsMenu)
        end
    end, Data.type)
end)

RegisterNetEvent('police:client:ExamineEvidenceBag', function(Data)
    QBCore.Functions.Progressbar('examine_evidence_bag', Lang:t('progressbar.examining', {label = Data.Item.info.label}), 5000, false, false, {
        disableMovement = true,
        disableCarMovement = false,
        disableMouse = false,
        disableCombat = true
    }, {}, {}, {}, function() -- Done
        TriggerServerEvent('police:server:UpdateEvidenceBag', Data.Item, Data.slot)
    end, function() end)
end)

-- Threads
CreateThread(function()
    while true do
        Wait(10000)
        if LocalPlayer.state.isLoggedIn then
            if CurrentStatusList and next(CurrentStatusList) then
                for k, _ in pairs(CurrentStatusList) do
                    if CurrentStatusList[k].time > 0 then
                        CurrentStatusList[k].time = CurrentStatusList[k].time - 10
                    else
                        CurrentStatusList[k].time = 0
                    end
                end
                TriggerServerEvent('evidence:server:UpdateStatus', CurrentStatusList)
            end
            if shotAmount > 0 then
                shotAmount = 0
            end
        end
    end
end)

CreateThread(function() -- Gunpowder Status when shooting
    while true do
        Wait(1)
        local ped = PlayerPedId()
        if IsPedShooting(ped) then
            local weapon = GetSelectedPedWeapon(ped)
            if not WhitelistedWeapon(weapon) then
                shotAmount = shotAmount + 1
                if shotAmount > 5 and (CurrentStatusList == nil or CurrentStatusList['gunpowder'] == nil) then
                    if math.random(1, 10) <= 7 then
                        TriggerEvent('evidence:client:SetStatus', 'gunpowder', 200)
                    end
                end
            end
        end
    end
end)