Job Application System - README
📋 Overview
A comprehensive job application system for RedM that allows players to apply for whitelisted jobs through an interactive NPC. Admins can approve or deny applications directly from Discord webhooks or in-game.

🎮 For Players
How to Apply for a Job
Find the Job Application Center

Look for the blip on your map (newspaper icon)
Located at coordinates: -795.79, -1202.89, 43.19 (Valentine area by default)
Talk to the Job Officer

Approach the NPC at the Job Application Center
Press and hold J when prompted
Submit Your Application

Select the job you want to apply for
Write a detailed reason (10-400 characters) explaining why you want the job
Submit your application
Wait for Approval

Your application will be sent to server administrators
You'll receive a notification when your application is approved or denied
If you're offline when approved, you'll automatically get the job when you log back in!
Available Jobs
Valentine Deputy
Blackwater Law
Saint Denis Law
Rhodes Law
Strawberry Law
Bounty Hunter
Medic
Important Notes
✅ You can only have one pending application per job at a time
✅ Applications work even if you're offline when they're reviewed
✅ You'll be notified in-game when your application status changes
👨‍💼 For Administrators
Setup Instructions
Install the Resource

text

- Place the resource in your resources folder
- Add `ensure phils-whitejo` to your server.cfg
Configure Settings (in config.lua)

Lua

ServerIP = "YOUR_SERVER_IP"     -- Your server's public IP
ServerPort = "30120"             -- Your server port
WHLink = "YOUR_DISCORD_WEBHOOK"  -- Discord webhook URL
Database Setup

The script automatically creates the job_applications table on first run
No manual database setup required!
Managing Applications
Method 1: Discord Webhook (Recommended)
When a player submits an application, you'll receive a Discord notification with:

Character name and Citizen ID
Requested job and grade
Their application reason
Two clickable links:
✅ Approve - Instantly gives them the job (works even if offline!)
❌ Deny - Rejects the application
Benefits:

Manage applications from anywhere (phone, Discord app, etc.)
No need to be in-game
Links expire after 7 days for security
Method 2: In-Game Menu
Go to the Job Application Center NPC
Press and hold J
Select "🔧 Manage Applications" (Admin only option)
View all pending applications with details
Approve or deny each application
Admin Permissions
Admins are detected by:

RSGCore admin permissions, OR
Having the job name admin
Discord Webhook Setup
Go to your Discord server settings
Navigate to Integrations → Webhooks
Create a new webhook for your desired channel
Copy the webhook URL
Paste it in config.lua under WHLink
Configuration Options
Lua

Config = {
    -- Distance to interact with NPC
    InteractionDistance = 3.0,
    
    -- Your server details (REQUIRED for Discord links)
    ServerIP = "123.45.67.89",
    ServerPort = "30120",
    
    -- Discord Webhook Settings
    EnableWebHook = true,
    WHTitle = "New Job Application",
    WHColor = 5814783,
    WHName = "Job Applications",
    WHLink = "YOUR_WEBHOOK_URL_HERE",
    
    -- Add/remove jobs here
    AvailableJobs = {
        { job = 'vallaw', label = 'Valentine Deputy', grade = 0 },
        -- Add more jobs...
    },
    
    -- NPC location and settings
    Locations = {
        {
            coords = vector3(-795.79, -1202.89, 43.19),
            promptText = 'Talk to Job Officer',
            promptKey = 0xF3830D8E, -- J key
            showBlip = true,
            pedModel = 'casp_coachrobbery_lenny_males_01',
            pedHeading = 120.57,
        }
    }
}
Adding New Jobs
Open config.lua
Add to the AvailableJobs table:
Lua

{ job = 'jobname', label = 'Display Name', grade = 0 },
Make sure the job exists in your RSGCore shared jobs
Changing NPC Location
Edit the Locations table in config.lua:

Lua

coords = vector3(x, y, z),      -- New coordinates
pedHeading = 90.0,              -- Direction NPC faces
pedModel = 'model_name',        -- NPC model hash
Database Table Structure
SQL

job_applications
- id (INT, Primary Key)
- citizenid (VARCHAR 50)
- job (VARCHAR 50)
- grade (INT)
- reason (TEXT)
- status (VARCHAR 20) - 'pending', 'approved', 'denied'
- notified (TINYINT) - 0 or 1
- created_at (TIMESTAMP)
Troubleshooting
Discord links not working:

Check that ServerIP and ServerPort are correct
Ensure your server's HTTP port is open/forwarded
Verify the webhook URL is correct
Jobs not setting for offline players:

Make sure RSGCore:Client:OnPlayerLoaded event is working
Check server console for "[Job Applications]" logs
Verify the job exists in RSGCore shared jobs
Players can't see the NPC:

Check the coordinates in config
Ensure the ped model exists
Verify resource started properly (ensure phils-whitejo)
🔒 Security Features
✅ Admin-only approval access
✅ One application per job limit
✅ Discord webhook tokens expire after 7 days
✅ Database validation on all actions
✅ No duplicate applications allowed
📝 Support
For issues or questions, check:

Server console for error messages
F8 console (client-side) for errors
Database table exists and is accessible
Config values are properly set
Version: 1.0.0
Author: phil mcracken
Dependencies: rsg-core, ox_lib, oxmysql
