local success, KazeUILib = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/KazeHub/UI/refs/heads/main/UI-Test"))()
end)
local KazeUI = KazeUI or (success and KazeUILib)

if not KazeUI then
    warn("Failed to load KazeUI library!")
    return
end

local Window = KazeUI:CreateWindow({
    Title = "THE MIMIC X KEN CARSON",
    Author = "KAZE",
    Version = "",
    Size = UDim2.fromOffset(500, 370),
    Icon = "79414074886215",
    Theme = "https://images3.alphacoders.com/124/1244059.jpg",
    GlowStyle = "Sequence",
    GlowColor = true,
    HidableTab = true,

    PopupTitle = "Welcome to KAZE HUB",
    PopupContent = "Thank You for using my script!",
    DiscordLink = "https://discord.gg/DKGRny4DD",
    DiscordName = "Join our server",
    YoutubeLink = "https://www.youtube.com/@Kaze_Hub",
    YoutubeName = "KazeHub",

    OpenButton = {
        Icon = "79414074886215",
        Shape = "square", 
        Hidable = false,
        Size = UDim2.fromOffset(60, 60)
    },
})

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local Main = Window:CreateTab({ Title = "Player", Icon = "user" })

Main:Section("Client")

local InstantPromptEnabled = false
local PromptConnection
local OriginalHoldDurations = {}

local function SetInstantPrompt(prompt)
    if not prompt:IsA("ProximityPrompt") then return end

    if OriginalHoldDurations[prompt] == nil then
        OriginalHoldDurations[prompt] = prompt.HoldDuration
    end

    if InstantPromptEnabled then
        prompt.HoldDuration = 0
    end
end

local function RestorePrompts()
    for prompt, duration in pairs(OriginalHoldDurations) do
        if prompt.Parent then
            prompt.HoldDuration = duration
        end
        OriginalHoldDurations[prompt] = nil
    end
end

Main:Toggle({
    Title = "Instant Prompt",
    Default = false,
    Callback = function(state)
        InstantPromptEnabled = state

        if PromptConnection then
            PromptConnection:Disconnect()
            PromptConnection = nil
        end

        if state then
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("ProximityPrompt") then
                    SetInstantPrompt(obj)
                end
            end

            PromptConnection = workspace.DescendantAdded:Connect(function(obj)
                if InstantPromptEnabled and obj:IsA("ProximityPrompt") then
                    SetInstantPrompt(obj)
                end
            end)
        else
            RestorePrompts()
        end
    end
})

local Lighting = game:GetService("Lighting")

local FB_ENABLED = false
local fbConnection
local origAmbient = Lighting.Ambient
local origOutdoorAmbient = Lighting.OutdoorAmbient
local origBrightness = Lighting.Brightness
local origClockTime = Lighting.ClockTime
local origShadows = Lighting.GlobalShadows

Main:Toggle({
    Title = "FullBright",
    Default = false,
    Callback = function(s)
        FB_ENABLED = s
        if fbConnection then 
            fbConnection:Disconnect() 
            fbConnection = nil
        end
        
        if FB_ENABLED then
            local function applyBright()
                local a = Color3.fromRGB(178, 178, 178)
                if Lighting.Ambient ~= a then Lighting.Ambient = a end
                if Lighting.OutdoorAmbient ~= a then Lighting.OutdoorAmbient = a end
                if Lighting.Brightness ~= 2 then Lighting.Brightness = 2 end
                if Lighting.ClockTime ~= 14 then Lighting.ClockTime = 14 end
                if Lighting.GlobalShadows ~= false then Lighting.GlobalShadows = false end
            end
            
            applyBright()
            fbConnection = Lighting.Changed:Connect(applyBright)
        else
            Lighting.Ambient = origAmbient
            Lighting.OutdoorAmbient = origOutdoorAmbient
            Lighting.Brightness = origBrightness
            Lighting.ClockTime = origClockTime
            Lighting.GlobalShadows = origShadows
        end
    end
})

local CachedCharacter = LocalPlayer.Character
local CachedHumanoid = CachedCharacter and CachedCharacter:FindFirstChildOfClass("Humanoid")
local CachedHRP = CachedCharacter and CachedCharacter:FindFirstChild("HumanoidRootPart")
local CachedNoclipParts = {}

local function rebuildNoclipParts(char)
    CachedNoclipParts = {}
    if not char then return end
    for _, p in ipairs(char:GetChildren()) do
        if p:IsA("BasePart") then
            CachedNoclipParts[#CachedNoclipParts + 1] = p
        elseif p:IsA("Accessory") then
            local h = p:FindFirstChild("Handle")
            if h and h:IsA("BasePart") then
                CachedNoclipParts[#CachedNoclipParts + 1] = h
            end
        end
    end
end
rebuildNoclipParts(CachedCharacter)

LocalPlayer.CharacterAdded:Connect(function(char)
    CachedCharacter = char
    CachedHumanoid = char:FindFirstChildOfClass("Humanoid") or char:WaitForChild("Humanoid", 5)
    CachedHRP = char:FindFirstChild("HumanoidRootPart") or char:WaitForChild("HumanoidRootPart", 5)
    task.defer(function()
        task.wait(0.15)
        rebuildNoclipParts(char)
    end)
end)

LocalPlayer.CharacterRemoving:Connect(function()
    CachedCharacter = nil
    CachedHumanoid = nil
    CachedHRP = nil
    CachedNoclipParts = {}
end)

local NoclipEnabled = false
local noclipConnection

Main:Toggle({
    Title = "Noclip",
    Default = false,
    Callback = function(s)
        NoclipEnabled = s
        if noclipConnection then
            noclipConnection:Disconnect()
            noclipConnection = nil
        end
        
        if NoclipEnabled then
            if #CachedNoclipParts == 0 and CachedCharacter then
                rebuildNoclipParts(CachedCharacter)
            end
            noclipConnection = RunService.Stepped:Connect(function()
                for i = 1, #CachedNoclipParts do
                    local part = CachedNoclipParts[i]
                    if part and part.Parent and part.CanCollide then
                        part.CanCollide = false
                    end
                end
            end)
        end
    end
})

local tpwalking = nil
local tpwalkStack = 0
local TPSpeed = 1

Main:Slider({
    Title = "TP Walk Speed",
    Min = 1,
    Max = 20,
    Default = 1,
    Callback = function(v)
        TPSpeed = v
    end
})

Main:Toggle({
    Title = "Enable TP Walk",
    Default = false,
    Callback = function(s)
        if tpwalking then
            tpwalking:Disconnect()
            tpwalking = nil
        end
        
        if s then
            tpwalking = RunService.Heartbeat:Connect(function(delta)
                local character = LocalPlayer.Character
                local humanoid = character and character:FindFirstChildWhichIsA("Humanoid")
                
                if not (character and humanoid and humanoid.Parent) then
                    if tpwalking then 
                        tpwalking:Disconnect() 
                        tpwalking = nil 
                    end
                    return
                end

                if humanoid.MoveDirection.Magnitude > 0 then
                    character:TranslateBy(humanoid.MoveDirection * (TPSpeed + tpwalkStack) * delta * 10)
                end
            end)
        else
            tpwalkStack = 0
        end
    end
})

local WalkSpeedEnabled = false
local WalkSpeedValue = 16
local OriginalWalkSpeed = 16
local Connection = nil

local function GetHumanoid()
    local Char = LocalPlayer.Character
    if not Char then return nil end
    return Char:FindFirstChildOfClass("Humanoid")
end

local function ApplyWalkSpeed()
    local Hum = GetHumanoid()
    if Hum then
        Hum.WalkSpeed = WalkSpeedValue
    end
end

local function StopWalkSpeed()
    local Hum = GetHumanoid()
    if Hum then
        Hum.WalkSpeed = OriginalWalkSpeed
    end
    if Connection then
        Connection:Disconnect()
        Connection = nil
    end
end

local function StartWalkSpeed()
    local Hum = GetHumanoid()
    if Hum then
        OriginalWalkSpeed = Hum.WalkSpeed
    end
    
    ApplyWalkSpeed()
    
    if Connection then
        Connection:Disconnect()
    end
    
    Connection = RunService.Heartbeat:Connect(function()
        if WalkSpeedEnabled then
            ApplyWalkSpeed()
        end
    end)
end

Main:Slider({
    Title = "WalkSpeed Value",
    Min = 16,
    Max = 1000,
    Default = 16,
    Callback = function(v)
        WalkSpeedValue = math.clamp(v, 16, 1000)
        if WalkSpeedEnabled then
            ApplyWalkSpeed()
        end
    end
})

Main:Toggle({
    Title = "WalkSpeed",
    Default = false,
    Callback = function(v)
        WalkSpeedEnabled = v
        if WalkSpeedEnabled then
            StartWalkSpeed()
        else
            StopWalkSpeed()
        end
    end
})

LocalPlayer.CharacterAdded:Connect(function()
    if WalkSpeedEnabled then
        task.wait(1)
        local Hum = GetHumanoid()
        if Hum then
            OriginalWalkSpeed = Hum.WalkSpeed
        end
        ApplyWalkSpeed()
    end
end)

_G.KAZE_WalkSpeed = {
    Enable = function()
        WalkSpeedEnabled = true
        StartWalkSpeed()
    end,
    Disable = function()
        WalkSpeedEnabled = false
        StopWalkSpeed()
    end,
    SetValue = function(Value)
        WalkSpeedValue = math.clamp(Value, 16, 1000)
        if WalkSpeedEnabled then
            ApplyWalkSpeed()
        end
    end,
    IsEnabled = function() return WalkSpeedEnabled end,
    GetValue = function() return WalkSpeedValue end
}

local TargetFlySpeed = 16
local FLY_ENABLED = false
local flyConnection

Main:Slider({
    Title = "Fly Speed",
    Min = 16,
    Max = 100,
    Default = 16,
    Callback = function(val)
        TargetFlySpeed = val
    end
})

Main:Toggle({
    Title = "Enable Fly",
    Default = false,
    Callback = function(state)
        FLY_ENABLED = state
        
        local function stopFly()
            if flyConnection then 
                flyConnection:Disconnect() 
                flyConnection = nil 
            end
            
            local character = LocalPlayer.Character
            local hrp = character and character:FindFirstChild("HumanoidRootPart")
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            
            if humanoid then
                humanoid.PlatformStand = false
            end
            if hrp then
                hrp.Anchored = false
                hrp.AssemblyAngularVelocity = Vector3.zero
                hrp.AssemblyLinearVelocity = Vector3.zero
            end
        end
        
        stopFly()
        
        if FLY_ENABLED then
            local camera = workspace.CurrentCamera
            
            flyConnection = RunService.RenderStepped:Connect(function(dt)
                local hrp = CachedHRP
                local humanoid = CachedHumanoid
                if not hrp or not hrp.Parent then
                    local character = LocalPlayer.Character
                    hrp = character and character:FindFirstChild("HumanoidRootPart")
                    humanoid = character and character:FindFirstChildOfClass("Humanoid")
                    CachedHRP = hrp
                    CachedHumanoid = humanoid
                end
                if hrp and humanoid then
                    local moveDir = humanoid.MoveDirection
                    
                    if moveDir.Magnitude > 0 then
                        hrp.Anchored = false
                        hrp.AssemblyLinearVelocity = Vector3.zero
                        hrp.AssemblyAngularVelocity = Vector3.zero
                        
                        local cameraCF = camera.CFrame
                        local relativeVector = cameraCF:VectorToObjectSpace(moveDir)
                        local flyDirection = (cameraCF.RightVector * relativeVector.X) + (cameraCF.LookVector * -relativeVector.Z)
                        
                        if flyDirection.Magnitude > 0 then
                            flyDirection = flyDirection.Unit
                        end
                        
                        hrp.CFrame = CFrame.lookAlong(hrp.Position, flyDirection) + (flyDirection * (TargetFlySpeed * dt))
                    else
                        hrp.AssemblyLinearVelocity = Vector3.zero
                        hrp.AssemblyAngularVelocity = Vector3.zero
                        hrp.Anchored = true
                    end
                end
            end)
        end
    end
})

local GameTab = Window:CreateTab({
    Title = "Game",
    Icon = "gamepad-2"
})

GameTab:Button({
    Title = "Low GFX",
    Callback = function()
        local DISABLE_SHADOWS = true
        local DISABLE_POST_PROCESSING = true
        local DISABLE_PARTICLES = true
        local DISABLE_TEXTURES = true

        pcall(function()
            if DISABLE_SHADOWS then
                Lighting.GlobalShadows = false
                Lighting.ShadowSoftness = 0
            end

            if DISABLE_POST_PROCESSING then
                for _, child in ipairs(Lighting:GetChildren()) do
                    if child:IsA("PostEffect") or child:IsA("Atmosphere") or child:IsA("Sky") then
                        child:Destroy()
                    end
                end
            end

            if Terrain then
                Terrain.WaterWaveSize = 0
                Terrain.WaterWaveTransparency = 1
                Terrain.WaterReflectance = 0
                pcall(function()
                    sethiddenproperty(Terrain, "Decoration", false)
                end)
            end

            for _, obj in ipairs(Workspace:GetDescendants()) do
                if DISABLE_PARTICLES and (obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles")) then
                    obj.Enabled = false
                elseif DISABLE_TEXTURES and (obj:IsA("Decal") or obj:IsA("Texture")) then
                    obj.Transparency = 1
                elseif obj:IsA("BasePart") then
                    obj.CastShadow = false
                    obj.Material = Enum.Material.SmoothPlastic
                end
            end
        end)

        pcall(function()
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = "Performance Booster",
                Text = "Low GFX Applied Successfully!",
                Duration = 3
            })
        end)
    end
})

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local function getCharacterRoot()
    local char = LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local MainTab = Window:CreateTab({
    Title = "Main",
    Icon = "house"
})

MainTab:Button({
    Title = "Teleport to lever",
    Callback = function()
        pcall(function()
            local hrp = getCharacterRoot()
            local lever = Workspace.Intro.Task.Lever
            if hrp and lever then
                hrp.CFrame = lever:IsA("Model") and lever:GetPivot() or lever.CFrame
            end
        end)
    end
})

MainTab:Button({
    Title = "Teleport to note",
    Callback = function()
        pcall(function()
            local hrp = getCharacterRoot()
            local note = Workspace.Note.Note
            if hrp and note then
                hrp.CFrame = note.CFrame
            end
        end)
    end
})

local fuseIndex = 1
MainTab:Button({
    Title = "Teleport to Fuse",
    Callback = function()
        pcall(function()
            local hrp = getCharacterRoot()
            if not hrp then return end
            
            local targets = {}
            local children = Workspace.FuseLocations:GetChildren()
            if children[2] then table.insert(targets, children[2]) end
            if Workspace.FuseLocations:FindFirstChild("Fuse") then table.insert(targets, Workspace.FuseLocations.Fuse) end
            if children[3] then table.insert(targets, children[3]) end
            
            if #targets > 0 then
                if fuseIndex > #targets then fuseIndex = 1 end
                local target = targets[fuseIndex]
                hrp.CFrame = target:IsA("Model") and target:GetPivot() or (target:IsA("BasePart") and target.CFrame or target:GetPivot())
                fuseIndex = fuseIndex + 1
            end
        end)
    end
})

local cpIndex = 1
MainTab:Button({
    Title = "Teleport to ControlPanel",
    Callback = function()
        pcall(function()
            local hrp = getCharacterRoot()
            if not hrp then return end
            
            local targets = {}
            local children = Workspace.ControlPanels:GetChildren()
            if children[4] then table.insert(targets, children[4]) end
            if Workspace.ControlPanels:FindFirstChild("ControlPanel") then table.insert(targets, Workspace.ControlPanels.ControlPanel) end
            if children[3] then table.insert(targets, children[3]) end
            
            if #targets > 0 then
                if cpIndex > #targets then cpIndex = 1 end
                local target = targets[cpIndex]
                hrp.CFrame = target:IsA("Model") and target:GetPivot() or target.CFrame
                cpIndex = cpIndex + 1
            end
        end)
    end
})

MainTab:Button({
    Title = "Skip Fuse Task",
    Callback = function()
        pcall(function()
            local hrp = getCharacterRoot()
            if hrp then
                hrp.CFrame = CFrame.new(19, 3, 112)
            end
        end)
    end
})

MainTab:Button({
    Title = "TP Electric Room",
    Callback = function()
        pcall(function()
            local hrp = getCharacterRoot()
            if hrp then
                hrp.CFrame = CFrame.new(103, 3, -134)
            end
        end)
    end
})

MainTab:Button({
    Title = "TP to Exit Door",
    Callback = function()
        pcall(function()
            local hrp = getCharacterRoot()
            if hrp then
                hrp.CFrame = CFrame.new(16, 3, -214)
            end
        end)
    end
})


MainTab:Button({
    Title = "Auto escape",
    Callback = function()
        pcall(function()
            local hrp = getCharacterRoot()
            local safeGoal = Workspace.ChaseSequence.SAFEGOAL
            if hrp and safeGoal then
                hrp.CFrame = safeGoal:IsA("Model") and safeGoal:GetPivot() or safeGoal.CFrame
            end
        end)
    end
})

local ESPTab = Window:CreateTab({
    Title = "ESP",
    Icon = "eye"
})

local itemsActive = false
ESPTab:Toggle({
    Title = "ESP Items",
    Default = false,
    Callback = function(state)
        itemsActive = state
        if not itemsActive then
            pcall(function()
                for _, obj in ipairs({Workspace.Intro.Task.Lever, Workspace.Note.Note, Workspace.FuseLocations:GetChildren()[2], Workspace.FuseLocations.Fuse, Workspace.FuseLocations:GetChildren()[3], Workspace.Flask}) do
                    if obj and obj:FindFirstChild("KazeItemESP") then
                        obj.KazeItemESP:Destroy()
                    end
                end
            end)
        else
            task.spawn(function()
                while itemsActive do
                    pcall(function()
                        local targets = {
                            Workspace.Intro.Task.Lever,
                            Workspace.Note.Note,
                            Workspace.FuseLocations:GetChildren()[2],
                            Workspace.FuseLocations.Fuse,
                            Workspace.FuseLocations:GetChildren()[3],
                            Workspace.Flask
                        }
                        for _, obj in ipairs(targets) do
                            if obj and not obj:FindFirstChild("KazeItemESP") then
                                local hl = Instance.new("Highlight")
                                hl.Name = "KazeItemESP"
                                hl.FillColor = Color3.fromRGB(0, 255, 255)
                                hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                                hl.FillTransparency = 0.4
                                hl.OutlineTransparency = 0
                                hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                                hl.Parent = obj
                            end
                        end
                    end)
                    task.wait(1)
                end
            end)
        end
    end
})

local controlValveActive = false
ESPTab:Toggle({
    Title = "ESP Control",
    Default = false,
    Callback = function(state)
        controlValveActive = state
        if not controlValveActive then
            pcall(function()
                for _, obj in ipairs({Workspace.ControlPanels:GetChildren()[4], Workspace.ControlPanels.ControlPanel, Workspace.ControlPanels:GetChildren()[3]}) do
                    if obj and obj:FindFirstChild("KazeCVESP") then
                        obj.KazeCVESP:Destroy()
                    end
                end
            end)
        else
            task.spawn(function()
                while controlValveActive do
                    pcall(function()
                        local targets = {
                            Workspace.ControlPanels:GetChildren()[4],
                            Workspace.ControlPanels.ControlPanel,
                            Workspace.ControlPanels:GetChildren()[3]
                        }
                        for _, obj in ipairs(targets) do
                            if obj and not obj:FindFirstChild("KazeCVESP") then
                                local hl = Instance.new("Highlight")
                                hl.Name = "KazeCVESP"
                                hl.FillColor = Color3.fromRGB(255, 165, 0)
                                hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                                hl.FillTransparency = 0.4
                                hl.OutlineTransparency = 0
                                hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                                hl.Parent = obj
                            end
                        end
                    end)
                    task.wait(1)
                end
            end)
        end
    end
})


local xgataActive = false
ESPTab:Toggle({
    Title = "ESP XGata",
    Default = false,
    Callback = function(state)
        xgataActive = state
        if not xgataActive then
            pcall(function()
                local xgata = Workspace.Monster and Workspace.Monster:FindFirstChild("XGata")
                if xgata and xgata:FindFirstChild("KazeXGataESP") then
                    xgata.KazeXGataESP:Destroy()
                end
            end)
        else
            task.spawn(function()
                while xgataActive do
                    pcall(function()
                        local xgata = Workspace.Monster and Workspace.Monster:FindFirstChild("XGata")
                        if xgata and not xgata:FindFirstChild("KazeXGataESP") then
                            local hl = Instance.new("Highlight")
                            hl.Name = "KazeXGataESP"
                            hl.FillColor = Color3.fromRGB(255, 0, 0)
                            hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                            hl.FillTransparency = 0.4
                            hl.OutlineTransparency = 0
                            hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                            hl.Parent = xgata
                        end
                    end)
                    task.wait(1)
                end
            end)
        end
    end
})
