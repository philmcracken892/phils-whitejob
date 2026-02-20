local RSGCore = exports['rsg-core']:GetCoreObject()


local function generateToken()
    return tostring(math.random(100000, 999999)) .. '_' .. os.time()
end


local pendingTokens = {}


Citizen.CreateThread(function()
    while true do
        Citizen.Wait(3600000)
        local currentTime = os.time()
        for token, data in pairs(pendingTokens) do
            if data.expires < currentTime then
                pendingTokens[token] = nil
            end
        end
    end
end)


local function GetCharacterName(citizenid, callback)
    MySQL.Async.fetchScalar('SELECT charinfo FROM players WHERE citizenid = ?', {citizenid}, function(charinfo)
        if charinfo then
            local data = json.decode(charinfo)
            if data then
                callback(data.firstname .. ' ' .. data.lastname)
                return
            end
        end
        callback('Unknown')
    end)
end


local function ProcessApplication(token, action)
    if not pendingTokens[token] then
        
        return false, 'Invalid or expired token'
    end
    
    local app = pendingTokens[token]
    
    if app.expires < os.time() then
        pendingTokens[token] = nil
        
        return false, 'Token has expired'
    end
    
    if action == 'approve' then
        MySQL.Async.execute('UPDATE job_applications SET status = ?, notified = ? WHERE id = ?', {'approved', 0, app.id}, function(affectedRows)
            if affectedRows > 0 then
                local Player = RSGCore.Functions.GetPlayerByCitizenId(app.citizenid)
                if Player then
                    Player.Functions.SetJob(app.job, app.grade)
                    TriggerClientEvent('ox_lib:notify', Player.PlayerData.source, {
                        title = 'Job Application Approved',
                        description = 'Your application has been approved! You are now a ' .. app.job,
                        type = 'success'
                    })
                    MySQL.Async.execute('UPDATE job_applications SET notified = ? WHERE id = ?', {1, app.id})
                   
                else
                   
                end
            end
        end)
        pendingTokens[token] = nil
        return true, 'Application approved successfully'
    elseif action == 'deny' then
        MySQL.Async.execute('UPDATE job_applications SET status = ?, notified = ? WHERE id = ?', {'denied', 0, app.id}, function(affectedRows)
            if affectedRows > 0 then
                local Player = RSGCore.Functions.GetPlayerByCitizenId(app.citizenid)
                if Player then
                    TriggerClientEvent('ox_lib:notify', Player.PlayerData.source, {
                        title = 'Job Application Denied',
                        description = 'Your job application has been denied.',
                        type = 'error'
                    })
                    MySQL.Async.execute('UPDATE job_applications SET notified = ? WHERE id = ?', {1, app.id})
                end
               
            end
        end)
        pendingTokens[token] = nil
        return true, 'Application denied'
    end
    
    return false, 'Invalid action'
end


SetHttpHandler(function(req, res)
    local path = req.path
    local action, token = path:match("^/(%w+)/(.+)$")
    
    if not action or not token then
        res.writeHead(404, {["Content-Type"] = "text/html"})
        res.send([[
            <html>
            <head>
                <title>Not Found</title>
                <style>
                    body { font-family: 'Segoe UI', Arial, sans-serif; text-align: center; padding: 50px; background: linear-gradient(135deg, #1a1a2e 0%, #16213e 100%); color: #fff; min-height: 100vh; margin: 0; }
                    .container { background: rgba(255,255,255,0.1); padding: 40px; border-radius: 15px; max-width: 500px; margin: 0 auto; backdrop-filter: blur(10px); }
                    h1 { color: #f44336; margin-bottom: 20px; }
                    p { color: #ccc; }
                </style>
            </head>
            <body>
                <div class="container">
                    <h1>❌ 404 - Not Found</h1>
                    <p>Invalid request path.</p>
                </div>
            </body>
            </html>
        ]])
        return
    end
    
    if action == 'approve' then
        local success, message = ProcessApplication(token, 'approve')
        res.writeHead(200, {["Content-Type"] = "text/html"})
        if success then
            res.send([[
                <html>
                <head>
                    <title>Application Approved</title>
                    <style>
                        body { font-family: 'Segoe UI', Arial, sans-serif; text-align: center; padding: 50px; background: linear-gradient(135deg, #1a1a2e 0%, #16213e 100%); color: #fff; min-height: 100vh; margin: 0; }
                        .container { background: rgba(255,255,255,0.1); padding: 40px; border-radius: 15px; max-width: 500px; margin: 0 auto; backdrop-filter: blur(10px); }
                        h1 { color: #4CAF50; margin-bottom: 20px; }
                        p { color: #ccc; }
                        .icon { font-size: 60px; margin-bottom: 20px; }
                    </style>
                </head>
                <body>
                    <div class="container">
                        <div class="icon">✅</div>
                        <h1>Application Approved!</h1>
                        <p>The job application has been successfully approved.</p>
                        <p>The player will receive their new job when they log in (or immediately if online).</p>
                        <p style="margin-top: 30px; font-size: 12px; color: #888;">You can close this window.</p>
                    </div>
                </body>
                </html>
            ]])
        else
            res.send([[
                <html>
                <head>
                    <title>Error</title>
                    <style>
                        body { font-family: 'Segoe UI', Arial, sans-serif; text-align: center; padding: 50px; background: linear-gradient(135deg, #1a1a2e 0%, #16213e 100%); color: #fff; min-height: 100vh; margin: 0; }
                        .container { background: rgba(255,255,255,0.1); padding: 40px; border-radius: 15px; max-width: 500px; margin: 0 auto; backdrop-filter: blur(10px); }
                        h1 { color: #f44336; margin-bottom: 20px; }
                        p { color: #ccc; }
                        .icon { font-size: 60px; margin-bottom: 20px; }
                    </style>
                </head>
                <body>
                    <div class="container">
                        <div class="icon">❌</div>
                        <h1>Error</h1>
                        <p>]] .. message .. [[</p>
                        <p style="margin-top: 20px; font-size: 12px; color: #888;">This link may have already been used or expired.</p>
                    </div>
                </body>
                </html>
            ]])
        end
    elseif action == 'deny' then
        local success, message = ProcessApplication(token, 'deny')
        res.writeHead(200, {["Content-Type"] = "text/html"})
        if success then
            res.send([[
                <html>
                <head>
                    <title>Application Denied</title>
                    <style>
                        body { font-family: 'Segoe UI', Arial, sans-serif; text-align: center; padding: 50px; background: linear-gradient(135deg, #1a1a2e 0%, #16213e 100%); color: #fff; min-height: 100vh; margin: 0; }
                        .container { background: rgba(255,255,255,0.1); padding: 40px; border-radius: 15px; max-width: 500px; margin: 0 auto; backdrop-filter: blur(10px); }
                        h1 { color: #FF9800; margin-bottom: 20px; }
                        p { color: #ccc; }
                        .icon { font-size: 60px; margin-bottom: 20px; }
                    </style>
                </head>
                <body>
                    <div class="container">
                        <div class="icon">🚫</div>
                        <h1>Application Denied</h1>
                        <p>The job application has been denied.</p>
                        <p>The player will be notified if they are online.</p>
                        <p style="margin-top: 30px; font-size: 12px; color: #888;">You can close this window.</p>
                    </div>
                </body>
                </html>
            ]])
        else
            res.send([[
                <html>
                <head>
                    <title>Error</title>
                    <style>
                        body { font-family: 'Segoe UI', Arial, sans-serif; text-align: center; padding: 50px; background: linear-gradient(135deg, #1a1a2e 0%, #16213e 100%); color: #fff; min-height: 100vh; margin: 0; }
                        .container { background: rgba(255,255,255,0.1); padding: 40px; border-radius: 15px; max-width: 500px; margin: 0 auto; backdrop-filter: blur(10px); }
                        h1 { color: #f44336; margin-bottom: 20px; }
                        p { color: #ccc; }
                        .icon { font-size: 60px; margin-bottom: 20px; }
                    </style>
                </head>
                <body>
                    <div class="container">
                        <div class="icon">❌</div>
                        <h1>Error</h1>
                        <p>]] .. message .. [[</p>
                        <p style="margin-top: 20px; font-size: 12px; color: #888;">This link may have already been used or expired.</p>
                    </div>
                </body>
                </html>
            ]])
        end
    else
        res.writeHead(404, {["Content-Type"] = "text/html"})
        res.send([[
            <html>
            <head>
                <title>Not Found</title>
                <style>
                    body { font-family: 'Segoe UI', Arial, sans-serif; text-align: center; padding: 50px; background: linear-gradient(135deg, #1a1a2e 0%, #16213e 100%); color: #fff; min-height: 100vh; margin: 0; }
                    .container { background: rgba(255,255,255,0.1); padding: 40px; border-radius: 15px; max-width: 500px; margin: 0 auto; backdrop-filter: blur(10px); }
                    h1 { color: #f44336; margin-bottom: 20px; }
                    p { color: #ccc; }
                </style>
            </head>
            <body>
                <div class="container">
                    <h1>❌ 404 - Not Found</h1>
                    <p>Unknown action.</p>
                </div>
            </body>
            </html>
        ]])
    end
end)


local function SendWebhook(citizenid, job, grade, reason, appId)
    if not Config.EnableWebHook then return end
    
    local token = generateToken()
    pendingTokens[token] = {
        id = appId,
        citizenid = citizenid,
        job = job,
        grade = grade,
        expires = os.time() + 604800
    }
    
    GetCharacterName(citizenid, function(charName)
        local resourceName = GetCurrentResourceName()
        
        -- Use config values for server IP and port
        local approveUrl = string.format("http://%s:%s/%s/approve/%s", Config.ServerIP, Config.ServerPort, resourceName, token)
        local denyUrl = string.format("http://%s:%s/%s/deny/%s", Config.ServerIP, Config.ServerPort, resourceName, token)
        
        local jobLabel = job
        for _, jobConfig in ipairs(Config.AvailableJobs) do
            if jobConfig.job == job then
                jobLabel = jobConfig.label
                break
            end
        end
        
        local embed = {
            {
                ["title"] = Config.WHTitle,
                ["description"] = string.format(
                    "**Character Name:** %s\n**Citizen ID:** %s\n**Requested Job:** %s\n**Grade:** %s\n\n**Reason for Application:**\n```%s```\n\n**⚠️ Works even if player is offline!**",
                    charName, citizenid, jobLabel, grade, reason
                ),
                ["color"] = Config.WHColor,
                ["fields"] = {
                    {
                        ["name"] = "✅ Approve",
                        ["value"] = "[Click to Approve](" .. approveUrl .. ")",
                        ["inline"] = true
                    },
                    {
                        ["name"] = "❌ Deny",
                        ["value"] = "[Click to Deny](" .. denyUrl .. ")",
                        ["inline"] = true
                    }
                },
                ["footer"] = {
                    ["text"] = Config.WHName .. " | Link expires in 7 days",
                    ["icon_url"] = Config.WHLogo
                },
                ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ")
            }
        }
        
        PerformHttpRequest(Config.WHLink, function(err, text, headers)
            if err and err ~= 204 then
                
            else
                
            end
        end, 'POST', json.encode({
            username = Config.WHName,
            avatar_url = Config.WHLogo,
            embeds = embed
        }), { ['Content-Type'] = 'application/json' })
    end)
end


local function IsPlayerAdmin(source)
    local Player = RSGCore.Functions.GetPlayer(source)
    if not Player then return false end
    return RSGCore.Functions.HasPermission(source, 'admin') or Player.PlayerData.job.name == 'admin'
end


RegisterNetEvent('rsg_job_application:checkIsAdmin', function()
    local src = source
    local isAdmin = IsPlayerAdmin(src)
    TriggerClientEvent('rsg_job_application:setIsAdmin', src, isAdmin)
end)


RegisterServerEvent('rsg_job_application:checkPendingApplications')
AddEventHandler('rsg_job_application:checkPendingApplications', function()
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    if not Player then 
        
        return 
    end
    
    local citizenid = Player.PlayerData.citizenid
    
    
   
    MySQL.Async.fetchAll('SELECT * FROM job_applications WHERE citizenid = ? AND status = ? AND notified = ?', 
        {citizenid, 'approved', 0}, 
        function(applications)
            if applications and #applications > 0 then
               
                
                for _, app in ipairs(applications) do
                    
                    
                   
                    Player.Functions.SetJob(app.job, app.grade)
                    
                   
                    local jobLabel = app.job
                    for _, jobConfig in ipairs(Config.AvailableJobs) do
                        if jobConfig.job == app.job then
                            jobLabel = jobConfig.label
                            break
                        end
                    end
                    
                   
                    TriggerClientEvent('ox_lib:notify', src, {
                        title = 'Job Application Approved!',
                        description = 'Your application for ' .. jobLabel .. ' was approved! Welcome to the team!',
                        type = 'success',
                        duration = 10000
                    })
                    
                    
                    MySQL.Async.execute('UPDATE job_applications SET notified = ? WHERE id = ?', {1, app.id})
                    
                    
                end
            else
                
            end
            
           
            MySQL.Async.fetchAll('SELECT * FROM job_applications WHERE citizenid = ? AND status = ? AND notified = ?', 
                {citizenid, 'denied', 0}, 
                function(deniedApps)
                    if deniedApps and #deniedApps > 0 then
                        for _, app in ipairs(deniedApps) do
                            local jobLabel = app.job
                            for _, jobConfig in ipairs(Config.AvailableJobs) do
                                if jobConfig.job == app.job then
                                    jobLabel = jobConfig.label
                                    break
                                end
                            end
                            
                            TriggerClientEvent('ox_lib:notify', src, {
                                title = 'Job Application Denied',
                                description = 'Your application for ' .. jobLabel .. ' was denied.',
                                type = 'error',
                                duration = 10000
                            })
                            
                            MySQL.Async.execute('UPDATE job_applications SET notified = ? WHERE id = ?', {1, app.id})
                        end
                    end
                end
            )
        end
    )
end)


RegisterNetEvent('rsg_job_application:submitApplication', function(job, grade, reason)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    if not Player then
        TriggerClientEvent('rsg_job_application:applicationSubmitted', src, false, 'Player data not found.')
        return
    end
    
    local citizenid = Player.PlayerData.citizenid
    
    MySQL.Async.fetchScalar('SELECT COUNT(*) FROM job_applications WHERE citizenid = ? AND job = ? AND status = ?', 
        {citizenid, job, 'pending'}, 
        function(count)
            if count and count > 0 then
                TriggerClientEvent('rsg_job_application:applicationSubmitted', src, false, 'You already have a pending application for this job!')
                return
            end
            
            MySQL.Async.insert('INSERT INTO job_applications (citizenid, job, grade, reason, status, notified) VALUES (?, ?, ?, ?, ?, ?)',
                {citizenid, job, grade, reason, 'pending', 0},
                function(insertId)
                    if insertId then
                        TriggerClientEvent('rsg_job_application:applicationSubmitted', src, true, 'Your application has been submitted!')
                        SendWebhook(citizenid, job, grade, reason, insertId)
                    else
                        TriggerClientEvent('rsg_job_application:applicationSubmitted', src, false, 'Database error.')
                    end
                end
            )
        end
    )
end)


RegisterNetEvent('rsg_job_application:getApplications', function()
    local src = source
    
    if not IsPlayerAdmin(src) then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Access Denied',
            description = 'You do not have permission to view applications.',
            type = 'error'
        })
        return
    end
    
    MySQL.Async.fetchAll('SELECT * FROM job_applications WHERE status = ?', {'pending'}, function(applications)
        TriggerClientEvent('rsg_job_application:openAdminMenu', src, applications or {})
    end)
end)


RegisterNetEvent('rsg_job_application:approveApplication', function(appId, citizenid, job, grade)
    local src = source
    
    if not IsPlayerAdmin(src) then
        TriggerClientEvent('rsg_job_application:applicationApproved', src, false, 'Access denied.')
        return
    end
    
    MySQL.Async.execute('UPDATE job_applications SET status = ?, notified = ? WHERE id = ?', {'approved', 0, appId}, function(affectedRows)
        if affectedRows > 0 then
            local Player = RSGCore.Functions.GetPlayerByCitizenId(citizenid)
            if Player then
                Player.Functions.SetJob(job, grade)
                
                local jobLabel = job
                for _, jobConfig in ipairs(Config.AvailableJobs) do
                    if jobConfig.job == job then
                        jobLabel = jobConfig.label
                        break
                    end
                end
                
                TriggerClientEvent('ox_lib:notify', Player.PlayerData.source, {
                    title = 'Job Application Approved',
                    description = 'Your application has been approved! You are now a ' .. jobLabel,
                    type = 'success'
                })
                MySQL.Async.execute('UPDATE job_applications SET notified = ? WHERE id = ?', {1, appId})
               
            else
                
            end
            
            TriggerClientEvent('rsg_job_application:applicationApproved', src, true, 'Application approved successfully!')
            
            MySQL.Async.fetchAll('SELECT * FROM job_applications WHERE status = ?', {'pending'}, function(applications)
                TriggerClientEvent('rsg_job_application:openAdminMenu', src, applications or {})
            end)
        else
            TriggerClientEvent('rsg_job_application:applicationApproved', src, false, 'Failed to approve application.')
        end
    end)
end)


RegisterNetEvent('rsg_job_application:denyApplication', function(appId, citizenid)
    local src = source
    
    if not IsPlayerAdmin(src) then
        TriggerClientEvent('rsg_job_application:applicationDenied', src, false, 'Access denied.')
        return
    end
    
    MySQL.Async.execute('UPDATE job_applications SET status = ?, notified = ? WHERE id = ?', {'denied', 0, appId}, function(affectedRows)
        if affectedRows > 0 then
            local Player = RSGCore.Functions.GetPlayerByCitizenId(citizenid)
            if Player then
                TriggerClientEvent('ox_lib:notify', Player.PlayerData.source, {
                    title = 'Job Application Denied',
                    description = 'Your job application has been denied.',
                    type = 'error'
                })
                MySQL.Async.execute('UPDATE job_applications SET notified = ? WHERE id = ?', {1, appId})
            end
            
            TriggerClientEvent('rsg_job_application:applicationDenied', src, true, 'Application denied.')
            
            MySQL.Async.fetchAll('SELECT * FROM job_applications WHERE status = ?', {'pending'}, function(applications)
                TriggerClientEvent('rsg_job_application:openAdminMenu', src, applications or {})
            end)
        else
            TriggerClientEvent('rsg_job_application:applicationDenied', src, false, 'Failed to deny application.')
        end
    end)
end)

-- Database initialization
MySQL.ready(function()
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `job_applications` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `citizenid` VARCHAR(50) NOT NULL,
            `job` VARCHAR(50) NOT NULL,
            `grade` INT NOT NULL,
            `reason` TEXT NOT NULL,
            `status` VARCHAR(20) DEFAULT 'pending',
            `notified` TINYINT(1) DEFAULT 0,
            `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ]])
    
    
end)

