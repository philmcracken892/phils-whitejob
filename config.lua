Config = {
    InteractionDistance = 3.0,
    
    -- Server details for Discord webhook links
    ServerIP = "123.45.67.89",  -- e.g., "123.45.67.89"
    ServerPort = "30120",          -- Your server port
    
    -- Discord Webhook Settings
    EnableWebHook = true,
    WHTitle = "New Job Application",
    WHColor = 5814783,
    WHName = "Job Applications",
    WHLink = "",
    WHLogo = "",
    
    AvailableJobs = {
        { job = 'vallaw', label = 'Valentine Deputy', grade = 0 },
        { job = 'blklaw', label = 'Blackwater Law', grade = 0 },
        { job = 'stdenlaw', label = 'Saint Denis Law', grade = 0 },
        { job = 'rholaw', label = 'Rhodes Law', grade = 0 },
        { job = 'strlaw', label = 'Strawberry Law', grade = 0 },
        { job = 'bountyhunter', label = 'Bounty Hunter', grade = 0 },
        { job = 'medic', label = 'Medic', grade = 0 },
		{ job = 'fireman', label = 'fireman', grade = 0 },
		{ job = 'undertaker', label = 'undertaker', grade = 0 },
    },
    
    Locations = {
        {
            name = "Job Application Center",
            coords = vector3(-795.79, -1202.89, 43.19),
            promptText = 'Talk to Job Officer',
            promptKey = 0xF3830D8E, -- J key
            showBlip = true,
            blipData = {
                sprite = GetHashKey("blip_ambient_newspaper"),
                scale = 0.8,
                color = 4,
                name = 'Job Application Center'
            },
            pedModel = 'casp_coachrobbery_lenny_males_01',
            pedHeading = 120.57, 
            onInteract = function()
                OpenJobApplicationMenu()
            end
        }
    }
}