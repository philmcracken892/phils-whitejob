local isAdmin = false
local createdBlips = {}  
local prompts = {}
local spawnedPeds = {}
local playerLoaded = false

RegisterNetEvent('rsg_job_application:setIsAdmin', function(adminStatus)
    isAdmin = adminStatus
end)


function SpawnPedAtLocation(loc)
    if not loc.pedModel then return nil end
    
    local pedHash = GetHashKey(loc.pedModel)
    
    RequestModel(pedHash)
    while not HasModelLoaded(pedHash) do
        Citizen.Wait(0)
    end
    
    local ped = CreatePed(pedHash, loc.coords.x, loc.coords.y, loc.coords.z, loc.pedHeading or 0.0, false, true, 0, 0)
    
    SetEntityCanBeDamaged(ped, false)
    SetEntityInvincible(ped, true)
    Citizen.InvokeNative(0x283978A15512B2FE, ped, true)
    FreezeEntityPosition(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedCanRagdollFromPlayerImpact(ped, false)
    SetEntityAsMissionEntity(ped, true, true)
    SetModelAsNoLongerNeeded(pedHash)
    
    return ped
end

-- Function to remove all spawned peds
function RemoveAllSpawnedPeds()
    for _, ped in ipairs(spawnedPeds) do
        if DoesEntityExist(ped) then
            DeleteEntity(ped)
        end
    end
    spawnedPeds = {}
end

-- THIS IS THE KEY - When player is fully loaded, check for pending applications
RegisterNetEvent('RSGCore:Client:OnPlayerLoaded', function()
    playerLoaded = true
   
    
    
    Citizen.Wait(2000)
    
    
    TriggerServerEvent('rsg_job_application:checkIsAdmin')
    
    
    TriggerServerEvent('rsg_job_application:checkPendingApplications')
end)


AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        Citizen.Wait(1000)
        
       
        local playerPed = PlayerPedId()
        if playerPed and playerPed ~= 0 and DoesEntityExist(playerPed) then
            playerLoaded = true
            
            
            TriggerServerEvent('rsg_job_application:checkIsAdmin')
            TriggerServerEvent('rsg_job_application:checkPendingApplications')
        end
    end
end)


Citizen.CreateThread(function()
    
    while not playerLoaded do
        Citizen.Wait(100)
    end

    for _, loc in ipairs(Config.Locations) do
        
        if loc.showBlip then
            local blip = Citizen.InvokeNative(0x554D9D53F696D002, 1664425300, loc.coords.x, loc.coords.y, loc.coords.z)
            SetBlipSprite(blip, loc.blipData.sprite, true)
            SetBlipScale(blip, loc.blipData.scale)
            Citizen.InvokeNative(0x9CB1A1623062F402, blip, loc.blipData.name)
            Citizen.InvokeNative(0x662D364ABF16DE2F, blip, GetHashKey("BLIP_MODIFIER_MP_COLOR_" .. tostring(loc.blipData.color)))
            Citizen.InvokeNative(0x9029B2F3DA924928, blip, true)
            table.insert(createdBlips, blip)  
        end

       
        if loc.pedModel then
            local ped = SpawnPedAtLocation(loc)
            if ped then
                table.insert(spawnedPeds, ped)
            end
        end

        
        local prompt = PromptRegisterBegin()
        PromptSetControlAction(prompt, loc.promptKey)
        PromptSetText(prompt, Citizen.InvokeNative(0xFA925AC00EB830B9, 10, "LITERAL_STRING", loc.promptText, Citizen.ResultAsLong()))
        PromptSetEnabled(prompt, false)
        PromptSetVisible(prompt, false)
        PromptSetHoldMode(prompt, true)
        PromptRegisterEnd(prompt)
        table.insert(prompts, { data = loc, prompt = prompt })
    end

    
    while true do
        Citizen.Wait(0)
        local playerPed = PlayerPedId()
        local coords = GetEntityCoords(playerPed)

        for _, entry in ipairs(prompts) do
            local loc = entry.data
            local dist = #(coords - loc.coords)
            
            if dist <= Config.InteractionDistance then
                PromptSetEnabled(entry.prompt, true)
                PromptSetVisible(entry.prompt, true)

                if PromptHasHoldModeCompleted(entry.prompt) then
                    loc.onInteract()
                    Citizen.Wait(500)
                end
            else
                PromptSetEnabled(entry.prompt, false)
                PromptSetVisible(entry.prompt, false)
            end
        end
    end
end)


function OpenJobApplicationMenu()
    local options = {}

   
    for _, job in ipairs(Config.AvailableJobs) do
        table.insert(options, {
            title = 'Apply for ' .. job.label,
            description = 'Submit an application for the ' .. job.label .. ' position.',
            onSelect = function()
                local input = lib.inputDialog('Job Application - ' .. job.label, {
                    {
                        type = 'input',
                        label = 'Reason for Application',
                        description = 'Why do you want this job? (max 400 characters)',
                        required = true,
                        min = 10,
                        max = 400
                    }
                })
                if input and input[1] then
                    TriggerServerEvent('rsg_job_application:submitApplication', job.job, job.grade, input[1])
                else
                    lib.notify({
                        title = 'Application Cancelled',
                        description = 'You must provide a reason to apply.',
                        type = 'error'
                    })
                end
            end
        })
    end

    
    if isAdmin then
        table.insert(options, {
            title = '?? Manage Applications',
            description = 'View and manage pending job applications (Admin Only).',
            onSelect = function()
                print('Requesting pending applications')
                TriggerServerEvent('rsg_job_application:getApplications')
            end
        })
    end

    lib.registerContext({
        id = 'job_application_menu',
        title = 'Job Application Center',
        options = options
    })
    lib.showContext('job_application_menu')
end

-- Event handler for admin menu
RegisterNetEvent('rsg_job_application:openAdminMenu')
AddEventHandler('rsg_job_application:openAdminMenu', function(applications)
    OpenAdminApplicationMenu(applications)
end)


function OpenAdminApplicationMenu(applications)
    if not applications or type(applications) ~= 'table' then
        lib.notify({
            title = 'Error',
            description = 'Invalid application data received.',
            type = 'error'
        })
        return
    end

    if #applications == 0 then
        lib.notify({
            title = 'No Applications',
            description = 'There are no pending job applications.',
            type = 'inform'
        })
        return
    end

    local options = {}
    for i, app in ipairs(applications) do
        if app.id and app.citizenid and app.job and app.grade and app.reason then
            table.insert(options, {
                title = 'Application #' .. app.id .. ' - ' .. app.job,
                description = 'CitizenID: ' .. app.citizenid .. ' | Job: ' .. app.job .. ' | Grade: ' .. app.grade .. ' | Reason: ' .. app.reason,
                menu = 'application_actions_' .. app.id
            })
        end
    end

    if #options == 0 then
        lib.notify({
            title = 'No Valid Applications',
            description = 'No valid pending applications found.',
            type = 'inform'
        })
        return
    end

    local success, err = pcall(function()
        lib.registerContext({
            id = 'admin_job_applications',
            title = 'Pending Job Applications',
            options = options
        })
        lib.showContext('admin_job_applications')
    end)

    if not success then
        lib.notify({
            title = 'Error',
            description = 'Failed to display application menu.',
            type = 'error'
        })
        return
    end

    -- Register individual application action menus
    for _, app in ipairs(applications) do
        if app.id then
            lib.registerContext({
                id = 'application_actions_' .. app.id,
                title = 'Manage Application #' .. app.id,
                options = {
                    {
                        title = '? Approve Application',
                        description = 'Assign ' .. app.job .. ' (Grade ' .. app.grade .. ') to CitizenID: ' .. app.citizenid,
                        onSelect = function()
                            TriggerServerEvent('rsg_job_application:approveApplication', app.id, app.citizenid, app.job, app.grade)
                        end
                    },
                    {
                        title = '? Deny Application',
                        description = 'Reject the application for CitizenID: ' .. app.citizenid,
                        onSelect = function()
                            TriggerServerEvent('rsg_job_application:denyApplication', app.id, app.citizenid)
                        end
                    }
                }
            })
        end
    end
end


RegisterNetEvent('rsg_job_application:applicationSubmitted')
AddEventHandler('rsg_job_application:applicationSubmitted', function(success, message)
    if success then
        lib.notify({
            title = 'Application Submitted',
            description = message or 'Your job application has been submitted successfully!',
            type = 'success'
        })
    else
        lib.notify({
            title = 'Application Failed',
            description = message or 'Failed to submit your application.',
            type = 'error'
        })
    end
end)

RegisterNetEvent('rsg_job_application:applicationApproved')
AddEventHandler('rsg_job_application:applicationApproved', function(success, message)
    if success then
        lib.notify({
            title = 'Application Approved',
            description = message or 'Application has been approved successfully!',
            type = 'success'
        })
    else
        lib.notify({
            title = 'Approval Failed',
            description = message or 'Failed to approve application.',
            type = 'error'
        })
    end
end)

RegisterNetEvent('rsg_job_application:applicationDenied')
AddEventHandler('rsg_job_application:applicationDenied', function(success, message)
    if success then
        lib.notify({
            title = 'Application Denied',
            description = message or 'Application has been denied.',
            type = 'inform'
        })
    else
        lib.notify({
            title = 'Denial Failed',
            description = message or 'Failed to deny application.',
            type = 'error'
        })
    end
end)

-- Resource cleanup
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        -- Remove all blips
        for _, blip in ipairs(createdBlips) do
            if DoesBlipExist(blip) then
                RemoveBlip(blip)
            end
        end

        -- Disable all prompts
        for _, entry in ipairs(prompts) do
            if entry.prompt then
                PromptSetEnabled(entry.prompt, false)
                PromptSetVisible(entry.prompt, false)
            end
        end

        -- Remove all spawned peds
        RemoveAllSpawnedPeds()
    end
end)