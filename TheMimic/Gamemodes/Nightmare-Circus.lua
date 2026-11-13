local KazeUI = KazeUI or loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/KazeHub/UI/refs/heads/main/UILibrary.lua.txt"
))()

local Window = KazeUI:CreateWindow({
    Title = "NIGHTMARE CIRCUS",
    Author = "KAZE",
    Version = "",
    Size = UDim2.fromOffset(700, 400),
    Icon = "79414074886215",
    Theme = "Obsidian",           -- only theme that exists now
    PerformanceMode = true,       -- keep it light
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

local Ronnie = Window:CreateTab({
    Title = "Ronnie's Games",
    Icon = "play"
})

Ronnie:Button({
    Title = "Skip Ronnie's Games",
    Description = "",
    Callback = function()
        task.spawn(function()
            local char = game:GetService("Players").LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            
            if hrp then
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
                char:PivotTo(CFrame.new(1812, -61, 4520))
            end
        end)
    end
})

local espMonstersActive = false

local function getMonsters()
    local targets = {}
    local s1 = workspace:FindFirstChild("Section1")
    if s1 then
        local m1 = s1:FindFirstChild("Monster")
        if m1 and m1:FindFirstChild("Ronnie") then
            table.insert(targets, m1.Ronnie)
        end
        
        local m2 = s1:FindFirstChild("Monster2")
        if m2 and m2:FindFirstChild("Bruno") then
            table.insert(targets, m2.Bruno)
        end
    end
    return targets
end

Ronnie:Toggle({
    Title = "ESP Roonie & Bruno",
    Default = false,
    Callback = function(state)
        espMonstersActive = state
        
        if not espMonstersActive then
            for _, target in ipairs(getMonsters()) do
                local hl = target:FindFirstChild("KazeMonsterESP")
                if hl then hl:Destroy() end
            end
            return
        end
        
        task.spawn(function()
            while espMonstersActive do
                for _, target in ipairs(getMonsters()) do
                    if not target:FindFirstChild("KazeMonsterESP") then
                        local hl = Instance.new("Highlight")
                        hl.Name = "KazeMonsterESP"
                        hl.FillColor = Color3.fromRGB(255, 0, 0)
                        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                        hl.FillTransparency = 0.4
                        hl.OutlineTransparency = 0
                        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                        hl.Parent = target
                    end
                end
                task.wait(0.5) -- Check every 0.5s for zero lag
            end
        end)
    end
})

Ronnie:Button({
    Title = "Start",
    Callback = function()
        task.spawn(function()
            pcall(function()
                local player = game:GetService("Players").LocalPlayer
                local char = player.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                if root then
                    local originalPos = root.CFrame
                    root.CFrame = CFrame.new(-119.516685, 41.0885391, 180.59729, 0.999178648, 0.040521495, 9.03382897e-07, -9.03382897e-07, 4.4465065e-05, -1, -0.040521495, 0.999178648, 4.4465065e-05)
                    task.wait(0.1)
                    root.CFrame = originalPos
                end
            end)
        end)
    end
})

Ronnie:Section("MiniGames")

local _w = game:GetService("Workspace")
local _rs = game:GetService("ReplicatedStorage")
local _cam = _w.CurrentCamera
local _l = game:GetService("Players").LocalPlayer

Ronnie:Button({
    Title = "Auto Ring Toss",
    Callback = function()
        local char = _l.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        task.spawn(function()
            local targetPos = Vector3.new(-317, 15, 144)
            local safePos = Vector3.new(-136, 15, 248)

            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
            hrp.CFrame = CFrame.new(targetPos)
            task.wait(0.5)

            local ringToss = _w:FindFirstChild("Section1") and _w.Section1:FindFirstChild("Games") and _w.Section1.Games:FindFirstChild("RingToss")
            local ring = ringToss and ringToss:FindFirstChild("ring")
            local prompt = ring and ring:FindFirstChildWhichIsA("ProximityPrompt", true)
            
            if ring and prompt then
                local maxDist = prompt.MaxActivationDistance
                local originalCamType = _cam.CameraType
                local originalCamCFrame = _cam.CFrame
                
                prompt.MaxActivationDistance = 250
                prompt.RequiresLineOfSight = false
                
                _cam.CameraType = Enum.CameraType.Scriptable
                _cam.CFrame = CFrame.new(_cam.CFrame.Position, ring.Position)
                
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
                hrp.CFrame = CFrame.new(ring.Position)
                task.wait(0.3)
                
                pcall(function() prompt:InputHoldBegin() end)
                task.wait(prompt.HoldDuration + 0.1)
                pcall(function() prompt:InputHoldEnd() end)
                
                _cam.CameraType = originalCamType
                _cam.CFrame = originalCamCFrame
                prompt.MaxActivationDistance = maxDist
            end

            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
            hrp.CFrame = CFrame.new(safePos)
            task.wait(0.5) 

            local Event = _rs:WaitForChild("modules"):WaitForChild("Packet"):WaitForChild("Reliable")
            
            local throws = {
                {-0.72057506723631803, 0.10509947484189813},
                {-0.45505300427259399, 0.073720243844118974},
                {0.018066198514086196, 0.063910384408452287},
                {0.36272513995324229, 0.16427150334824214},
                {0.77721826835950081, 0.11494349349628795},
                {-0.76166853890377539, 0.2715261178937825}
            }

            for i, coords in ipairs(throws) do
                pcall(function()
                    Event:FireServer("Section1/RingThrow", coords[1], coords[2])
                end)
                task.wait(1)
            end
        end)
    end
})

Ronnie:Button({
    Title = "Auto Mini Golf",
    Callback = function()
        local char = _l.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        task.spawn(function()
            local safePos = Vector3.new(-136, 15, 248)
            
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
            hrp.CFrame = CFrame.new(20, 17, 124)
            task.wait(0.5)

            local miniGolf = _w:FindFirstChild("Section1") and _w.Section1:FindFirstChild("Games") and _w.Section1.Games:FindFirstChild("MiniGolf")
            local proxPart = miniGolf and miniGolf:FindFirstChild("ProxPart")
            local prompt = proxPart and proxPart:FindFirstChildWhichIsA("ProximityPrompt", true)

            if prompt and proxPart then
                local maxDist = prompt.MaxActivationDistance
                local originalCamType = _cam.CameraType
                local originalCamCFrame = _cam.CFrame
                
                prompt.MaxActivationDistance = 250
                prompt.RequiresLineOfSight = false
                
                _cam.CameraType = Enum.CameraType.Scriptable
                _cam.CFrame = CFrame.new(_cam.CFrame.Position, proxPart.Position)
                
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
                hrp.CFrame = CFrame.new(proxPart.Position)
                task.wait(0.3)
                
                pcall(function() prompt:InputHoldBegin() end)
                task.wait(prompt.HoldDuration + 0.1)
                pcall(function() prompt:InputHoldEnd() end)
                
                _cam.CameraType = originalCamType
                _cam.CFrame = originalCamCFrame
                prompt.MaxActivationDistance = maxDist
            end

            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
            hrp.CFrame = CFrame.new(safePos)
            task.wait(0.5)

            local targetPos = Vector3.new(22.928955078125, 14.93798828125, 116.233642578125)

            for i = 1, 5 do
                task.wait(2)
                local golfBall = miniGolf and miniGolf:FindFirstChild("GolfBall")
                local hole = miniGolf and miniGolf:FindFirstChild("Hole")
                
                if golfBall and hole and golfBall:IsA("BasePart") then
                    if (golfBall.Position - targetPos).Magnitude <= 15 then
                        golfBall.AssemblyLinearVelocity = Vector3.zero
                        golfBall.AssemblyAngularVelocity = Vector3.zero
                        golfBall.CFrame = hole.CFrame
                    end
                end
            end
        end)
    end
})

Ronnie:Button({
    Title = "Auto Basketball",
    Callback = function()
        local char = _l.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        task.spawn(function()
            local safePos = Vector3.new(-136, 15, 248)

            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
            hrp.CFrame = CFrame.new(55, 37, -78)
            task.wait(0.5)

            local basketball = _w:FindFirstChild("Section1") and _w.Section1:FindFirstChild("Games") and _w.Section1.Games:FindFirstChild("Basketball")
            local promptPart = basketball and basketball:FindFirstChild("PromptPart")
            local prompt = promptPart and promptPart:FindFirstChildWhichIsA("ProximityPrompt", true)

            if prompt and promptPart then
                local maxDist = prompt.MaxActivationDistance
                local originalCamType = _cam.CameraType
                local originalCamCFrame = _cam.CFrame

                prompt.MaxActivationDistance = 250
                prompt.RequiresLineOfSight = false

                _cam.CameraType = Enum.CameraType.Scriptable
                _cam.CFrame = CFrame.new(_cam.CFrame.Position, promptPart.Position)

                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
                hrp.CFrame = CFrame.new(promptPart.Position)
                task.wait(0.3)

                pcall(function() prompt:InputHoldBegin() end)
                task.wait(prompt.HoldDuration + 0.1)
                pcall(function() prompt:InputHoldEnd() end)

                _cam.CameraType = originalCamType
                _cam.CFrame = originalCamCFrame
                prompt.MaxActivationDistance = maxDist
            end

            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
            hrp.CFrame = CFrame.new(safePos)

            task.wait(0.5)

            local Event = _rs:WaitForChild("modules"):WaitForChild("Packet"):WaitForChild("Reliable")

            for i = 1, 7 do
                pcall(function()
                    Event:FireServer("Section1/BasketballHold")
                end)
                task.wait(1.2)
                pcall(function()
                    Event:FireServer("Section1/BasketballRelease", 1.207594269013498)
                end)
                task.wait(3)
            end
        end)
    end
})

Ronnie:Button({
    Title = "Auto High Striker",
    Callback = function()
        local char = _l.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        task.spawn(function()
            local safePos = Vector3.new(-136, 15, 248)

            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
            hrp.CFrame = CFrame.new(-32, 32, 39)
            task.wait(0.5)

            local games = _w:FindFirstChild("Section1") and _w.Section1:FindFirstChild("Games")
            local highStriker = games and games:FindFirstChild("High Striker")
            local proxPart = highStriker and highStriker:FindFirstChild("ProxPart")
            local prompt = proxPart and proxPart:FindFirstChildWhichIsA("ProximityPrompt", true)

            if prompt and proxPart then
                local maxDist = prompt.MaxActivationDistance
                local originalCamType = _cam.CameraType
                local originalCamCFrame = _cam.CFrame

                prompt.MaxActivationDistance = 250
                prompt.RequiresLineOfSight = false

                _cam.CameraType = Enum.CameraType.Scriptable
                _cam.CFrame = CFrame.new(_cam.CFrame.Position, proxPart.Position)

                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
                hrp.CFrame = CFrame.new(proxPart.Position)
                task.wait(0.3)

                pcall(function() prompt:InputHoldBegin() end)
                task.wait(prompt.HoldDuration + 0.1)
                pcall(function() prompt:InputHoldEnd() end)

                _cam.CameraType = originalCamType
                _cam.CFrame = originalCamCFrame
                prompt.MaxActivationDistance = maxDist
            end

            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
            hrp.CFrame = CFrame.new(safePos)
            task.wait(0.5)

            local Event = _rs:WaitForChild("modules"):WaitForChild("Packet"):WaitForChild("Reliable")

            for i = 1, 5 do
                for j = 1, 50 do
                    pcall(function()
                        Event:FireServer("Section1/HighStrikerClick")
                    end)
                    task.wait(0.016)
                end
                task.wait(5)
            end
        end)
    end
})

Ronnie:Button({
    Title = "Auto Pop Balloon",
    Callback = function()
        local char = _l.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        task.spawn(function()
            local safePos = Vector3.new(-136, 15, 248)
            
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
            hrp.CFrame = CFrame.new(-251, 15, -98)
            task.wait(0.5)

            local popTheBalloon = _w:FindFirstChild("Section1") and _w.Section1:FindFirstChild("Games") and _w.Section1.Games:FindFirstChild("PopTheBalloon")
            local cameraPart = popTheBalloon and popTheBalloon:FindFirstChild("Camera")
            local prompt = cameraPart and cameraPart:FindFirstChildWhichIsA("ProximityPrompt", true)

            if prompt and cameraPart then
                local maxDist = prompt.MaxActivationDistance
                local originalCamType = _cam.CameraType
                local originalCamCFrame = _cam.CFrame

                prompt.MaxActivationDistance = 250
                prompt.RequiresLineOfSight = false

                _cam.CameraType = Enum.CameraType.Scriptable
                _cam.CFrame = CFrame.new(_cam.CFrame.Position, cameraPart.Position)

                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
                hrp.CFrame = CFrame.new(cameraPart.Position)
                task.wait(0.3)

                pcall(function() prompt:InputHoldBegin() end)
                task.wait(prompt.HoldDuration + 0.1)
                pcall(function() prompt:InputHoldEnd() end)

                _cam.CameraType = originalCamType
                _cam.CFrame = originalCamCFrame
                prompt.MaxActivationDistance = maxDist
            end

            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
            hrp.CFrame = CFrame.new(safePos)

            local Event = _rs:WaitForChild("modules"):WaitForChild("Packet"):WaitForChild("Reliable")

            local throws = {
                {0.92983092006390555, 0.89542727483312756},
                {0.47093705174143813, 0.80153832697161831},
                {0.036195629164746154, 0.74118300407687365},
                {-0.49997853250524144, 0.92895904767845361},
                {-0.85742993934714073, 0.86190105835211672},
                {-0.88158521777057908, 0.063844312016687901},
                {-0.43718631318775103, 0.050425747557683961},
                {-0.0024464656540977578, 0.097370231554315942},
                {0.52407672269342787, 0.14431387001724777},
                {0.90085119312209305, 0.13090282980158738},
                {0.95398411201377131, -0.82810749216782142},
                {0.45644895597730872, -0.72080072975517329},
                {0.026543031897521139, -0.74763104407419312},
                {0.026543031897521139, -0.74763104407419312},
                {-0.4178620035126015, -0.79457443089019031},
                {-0.4178620035126015, -0.79457443089019031},
                {-0.92989102209431795, -0.85493072010916382}
            }

            task.wait(0.5)
            
            for i = 1, 5 do
                for _, coords in ipairs(throws) do
                    pcall(function()
                        Event:FireServer("Section1/DartsThrow", coords[1], coords[2])
                    end)
                    task.wait(0.5)
                end
                task.wait(0.5)
            end
        end)
    end
})

Ronnie:Button({
    Title = "Auto Dunk Booth",
    Callback = function()
        local char = _l.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        task.spawn(function()
            local safePos = Vector3.new(-136, 15, 248)

            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
            hrp.CFrame = CFrame.new(-89, 16, 100)
            task.wait(0.5)

            local games = _w:FindFirstChild("Section1") and _w.Section1:FindFirstChild("Games")
            local dunkBooth = games and games:FindFirstChild("DunkBooth")
            local proxPart = dunkBooth and dunkBooth:FindFirstChild("ProxPart")
            local prompt = proxPart and proxPart:FindFirstChildWhichIsA("ProximityPrompt", true)

            if prompt and proxPart then
                local maxDist = prompt.MaxActivationDistance
                local originalCamType = _cam.CameraType
                local originalCamCFrame = _cam.CFrame

                prompt.MaxActivationDistance = 250
                prompt.RequiresLineOfSight = false

                _cam.CameraType = Enum.CameraType.Scriptable
                _cam.CFrame = CFrame.new(_cam.CFrame.Position, proxPart.Position)

                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
                hrp.CFrame = CFrame.new(proxPart.Position)
                task.wait(0.3)

                pcall(function() prompt:InputHoldBegin() end)
                task.wait(prompt.HoldDuration + 0.1)
                pcall(function() prompt:InputHoldEnd() end)

                _cam.CameraType = originalCamType
                _cam.CFrame = originalCamCFrame
                prompt.MaxActivationDistance = maxDist
            end

            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
            hrp.CFrame = CFrame.new(safePos)
            task.wait(0.5)

            local Event = _rs:WaitForChild("modules"):WaitForChild("Packet"):WaitForChild("Reliable")

            for i = 1, 7 do
                pcall(function()
                    Event:FireServer("Section1/DunkThrow", 0.28738536237459611, 0.26089486988199567)
                end)
                task.wait(4)
            end
        end)
    end
})

Ronnie:Button({
    Title = "Auto Whack a Clown",
    Callback = function()
        local char = _l.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        task.spawn(function()
            local safePos = Vector3.new(-136, 15, 248)
            
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
            hrp.CFrame = CFrame.new(-65, 15, -140)
            task.wait(0.5)

            local whackGame = _w:FindFirstChild("Section1") and _w.Section1:FindFirstChild("Games") and _w.Section1.Games:FindFirstChild("WhackAClown")
            local hammer = whackGame and whackGame:FindFirstChild("Hammer")
            local prompt = hammer and hammer:FindFirstChildWhichIsA("ProximityPrompt", true)

            if prompt and hammer then
                local maxDist = prompt.MaxActivationDistance
                local originalCamType = _cam.CameraType
                local originalCamCFrame = _cam.CFrame

                prompt.MaxActivationDistance = 250
                prompt.RequiresLineOfSight = false
                _cam.CameraType = Enum.CameraType.Scriptable
                _cam.CFrame = CFrame.new(_cam.CFrame.Position, hammer.Position)

                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
                hrp.CFrame = CFrame.new(hammer.Position)
                task.wait(0.3)

                pcall(function() prompt:InputHoldBegin() end)
                task.wait(prompt.HoldDuration + 0.1)
                pcall(function() prompt:InputHoldEnd() end)

                _cam.CameraType = originalCamType
                _cam.CFrame = originalCamCFrame
                prompt.MaxActivationDistance = maxDist
            end

            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
            hrp.CFrame = CFrame.new(safePos)
            task.wait(0.5)

            local Event = _rs:WaitForChild("modules"):WaitForChild("Packet"):WaitForChild("Reliable")
            local clownsFolder = whackGame and whackGame:FindFirstChild("Clowns")
            local playerGui = _l:WaitForChild("PlayerGui", 5)
            local gui4 = playerGui and playerGui:WaitForChild("Gui4", 5)
            local targetFrame = gui4 and gui4:GetChildren()[2]
            local titleLabel = targetFrame and targetFrame:FindFirstChildOfClass("TextLabel")

            while true do
                if titleLabel and titleLabel.Visible and titleLabel.ContentText == "Whack a Clown" then
                    for _, clown in ipairs(clownsFolder:GetChildren()) do
                        if clown:FindFirstChildOfClass("Highlight") then
                            Event:FireServer("Section1/Whack", clown)
                        end
                    end
                    task.wait(0.05)
                else
                    task.wait(0.5)
                end
            end
        end)
    end
})

local Dimitra = Window:CreateTab({
    Title = "Dimitra's Games",
    Icon = "play"
})

local dimitraActive = false

Dimitra:Toggle({
    Title = "ESP Dimitra",
    Default = false,
    Callback = function(state)
        dimitraActive = state
        if not dimitraActive then
            pcall(function()
                local dimitra = workspace:FindFirstChild("Section2") and workspace.Section2:FindFirstChild("Monster") and workspace.Section2.Monster:FindFirstChild("Dimitra")
                if dimitra and dimitra:FindFirstChild("KazeDimitraESP") then
                    dimitra.KazeDimitraESP:Destroy()
                end
            end)
        else
            task.spawn(function()
                while dimitraActive do
                    pcall(function()
                        local dimitra = workspace:FindFirstChild("Section2") and workspace.Section2:FindFirstChild("Monster") and workspace.Section2.Monster:FindFirstChild("Dimitra")
                        if dimitra and not dimitra:FindFirstChild("KazeDimitraESP") then
                            local hl = Instance.new("Highlight")
                            hl.Name = "KazeDimitraESP"
                            hl.FillColor = Color3.fromRGB(255, 0, 0)
                            hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                            hl.FillTransparency = 0.4
                            hl.OutlineTransparency = 0
                            hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                            hl.Parent = dimitra
                        end
                    end)
                    task.wait(1)
                end
            end)
        end
    end
})

Dimitra:Button({
    Title = "Auto Moon Relic",
    Callback = function()
        local _w = game:GetService("Workspace")
        local _rs = game:GetService("ReplicatedStorage")
        local _cam = _w.CurrentCamera
        local _l = game:GetService("Players").LocalPlayer

        local char = _l.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        task.spawn(function()
            local safePos = Vector3.new(1812, -61, 4520)

            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
            hrp.CFrame = CFrame.new(1692, -61, 4494)
            task.wait(0.5)

            local p3 = _w:FindFirstChild("Section2") and _w.Section2:FindFirstChild("MainObjective") and _w.Section2.MainObjective:FindFirstChild("Puzzle3")
            local promptPart = p3 and p3:FindFirstChild("PromptPart")
            local prompt = promptPart and promptPart:FindFirstChildWhichIsA("ProximityPrompt", true)

            if prompt and promptPart then
                local maxDist = prompt.MaxActivationDistance
                local originalCamType = _cam.CameraType
                local originalCamCFrame = _cam.CFrame

                prompt.MaxActivationDistance = 250
                prompt.RequiresLineOfSight = false
                _cam.CameraType = Enum.CameraType.Scriptable
                _cam.CFrame = CFrame.new(_cam.CFrame.Position, promptPart.Position)

                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
                hrp.CFrame = CFrame.new(promptPart.Position)
                task.wait(0.3)

                pcall(function() prompt:InputHoldBegin() end)
                task.wait(prompt.HoldDuration + 0.1)
                pcall(function() prompt:InputHoldEnd() end)

                _cam.CameraType = originalCamType
                _cam.CFrame = originalCamCFrame
                prompt.MaxActivationDistance = maxDist
            end

            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
            hrp.CFrame = CFrame.new(safePos)
            task.wait(0.5)

            local Event = _rs:WaitForChild("modules"):WaitForChild("Packet"):WaitForChild("Reliable")
            for i = 1, 8 do
                Event:FireServer("Section2/MoonPuzzleProgress", i)
                task.wait(0.1)
            end
            Event:FireServer("Section2/MoonPuzzleComplete")
        end)
    end
})

Dimitra:Button({
    Title = "Auto Fate Relic",
    Callback = function()
        local _w = game:GetService("Workspace")
        local _rs = game:GetService("ReplicatedStorage")
        local _cam = _w.CurrentCamera
        local _l = game:GetService("Players").LocalPlayer

        local char = _l.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        task.spawn(function()
            local safePos = Vector3.new(1812, -61, 4520)

            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
            hrp.CFrame = CFrame.new(1824, -62, 4591)
            task.wait(0.5)

            local p4 = _w:FindFirstChild("Section2") and _w.Section2:FindFirstChild("MainObjective") and _w.Section2.MainObjective:FindFirstChild("Puzzle4")
            local promptPart = p4 and p4:FindFirstChild("PromptPart")
            local prompt = promptPart and promptPart:FindFirstChildWhichIsA("ProximityPrompt", true)

            if prompt and promptPart then
                local maxDist = prompt.MaxActivationDistance
                local originalCamType = _cam.CameraType
                local originalCamCFrame = _cam.CFrame

                prompt.MaxActivationDistance = 250
                prompt.RequiresLineOfSight = false
                _cam.CameraType = Enum.CameraType.Scriptable
                _cam.CFrame = CFrame.new(_cam.CFrame.Position, promptPart.Position)

                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
                hrp.CFrame = CFrame.new(promptPart.Position)
                task.wait(0.3)

                pcall(function() prompt:InputHoldBegin() end)
                task.wait(prompt.HoldDuration + 0.1)
                pcall(function() prompt:InputHoldEnd() end)

                _cam.CameraType = originalCamType
                _cam.CFrame = originalCamCFrame
                prompt.MaxActivationDistance = maxDist
            end

            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
            hrp.CFrame = CFrame.new(safePos)
            task.wait(0.5)

            local Event = _rs:WaitForChild("modules"):WaitForChild("Packet"):WaitForChild("Reliable")
            for i = 1, 5 do
                Event:FireServer("Section2/TarotPuzzleProgress", i)
                task.wait(0.1)
            end
            Event:FireServer("Section2/TarotPuzzleComplete")
        end)
    end
})

Dimitra:Button({
    Title = "Auto Star Relic",
    Callback = function()
        local _w = game:GetService("Workspace")
        local _rs = game:GetService("ReplicatedStorage")
        local _cam = _w.CurrentCamera
        local _l = game:GetService("Players").LocalPlayer

        local char = _l.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        task.spawn(function()
            local safePos = Vector3.new(1812, -61, 4520)

            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
            hrp.CFrame = CFrame.new(1584, -61, 4286)
            task.wait(0.5)

            local p1 = _w:FindFirstChild("Section2") and _w.Section2:FindFirstChild("MainObjective") and _w.Section2.MainObjective:FindFirstChild("Puzzle1")
            local promptPart = p1 and p1:FindFirstChild("PromptPart")
            local prompt = promptPart and promptPart:FindFirstChildWhichIsA("ProximityPrompt", true)

            if prompt and promptPart then
                local maxDist = prompt.MaxActivationDistance
                local originalCamType = _cam.CameraType
                local originalCamCFrame = _cam.CFrame

                prompt.MaxActivationDistance = 250
                prompt.RequiresLineOfSight = false
                _cam.CameraType = Enum.CameraType.Scriptable
                _cam.CFrame = CFrame.new(_cam.CFrame.Position, promptPart.Position)

                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
                hrp.CFrame = CFrame.new(promptPart.Position)
                task.wait(0.3)

                pcall(function() prompt:InputHoldBegin() end)
                task.wait(prompt.HoldDuration + 0.1)
                pcall(function() prompt:InputHoldEnd() end)

                _cam.CameraType = originalCamType
                _cam.CFrame = originalCamCFrame
                prompt.MaxActivationDistance = maxDist
            end

            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
            hrp.CFrame = CFrame.new(safePos)
            task.wait(0.5)

            local Event = _rs:WaitForChild("modules"):WaitForChild("Packet"):WaitForChild("Reliable")
            for i = 1, 5 do
                Event:FireServer("Section2/StarPuzzleProgress", i)
                task.wait(0.1)
            end
            Event:FireServer("Section2/StarPuzzleComplete")
        end)
    end
})

Dimitra:Button({
    Title = "Teleport to Eye Relic",
    Description = "",
    Callback = function()
        task.spawn(function()
            local char = game:GetService("Players").LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            
            if hrp then
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
                char:PivotTo(CFrame.new(1812, -61, 4520))
            end
        end)
    end
})

local eyeRelicActive = false

Dimitra:Toggle({
    Title = "Eye Relic [Nightmare]",
    Default = false,
    Callback = function(Value)
        eyeRelicActive = Value

        if eyeRelicActive then
            task.spawn(function()
                local Workspace = game:GetService("Workspace")
                local player = game:GetService("Players").LocalPlayer
                local lastPuzzleSignature = ""

                while eyeRelicActive do
                    pcall(function()
                        local puzzle = Workspace:FindFirstChild("Section2") 
                            and Workspace.Section2:FindFirstChild("MainObjective") 
                            and Workspace.Section2.MainObjective:FindFirstChild("Puzzle2")

                        if puzzle then
                            local mirrorsFolder = puzzle:FindFirstChild("Mirrors")
                            local statuesFolder = puzzle:FindFirstChild("EyeStatues")
                            local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")

                            if mirrorsFolder and statuesFolder and hrp then
                                local detectedMirrors = {} 
                                local recordedMirrors = {}
                                local signatureString = ""

                                local collecting = true
                                local lastActivationTime = tick()

                                while collecting and eyeRelicActive do
                                    local foundNewThisCycle = false

                                    for i = 1, 4 do
                                        if not recordedMirrors[i] then
                                            local mirror = mirrorsFolder:FindFirstChild("Mirror" .. i)
                                            local eye = mirror and mirror:FindFirstChild("Eye")

                                            if eye then
                                                local isVisible = false
                                                for _, part in ipairs(eye:GetChildren()) do
                                                    if part:IsA("BasePart") and part.Transparency == 0 then
                                                        isVisible = true
                                                        break
                                                    end
                                                end

                                                if isVisible then
                                                    table.insert(detectedMirrors, {index = i, time = tick()})
                                                    recordedMirrors[i] = true
                                                    signatureString = signatureString .. i
                                                    foundNewThisCycle = true
                                                    lastActivationTime = tick()
                                                end
                                            end
                                        end
                                    end

                                    if not foundNewThisCycle then
                                        if tick() - lastActivationTime > 1.5 and #detectedMirrors > 0 then
                                            collecting = false
                                        end
                                    end

                                    task.wait(0.02)
                                end

                                table.sort(detectedMirrors, function(a, b)
                                    return a.time < b.time
                                end)

                                local sequence = {}
                                local finalSignature = ""
                                for _, data in ipairs(detectedMirrors) do
                                    table.insert(sequence, data.index)
                                    finalSignature = finalSignature .. data.index
                                end

                                if #sequence > 0 and finalSignature ~= lastPuzzleSignature then
                                    lastPuzzleSignature = finalSignature

                                    for _, idx in ipairs(sequence) do
                                        if not eyeRelicActive then break end

                                        local statue = statuesFolder:FindFirstChild("Eye" .. idx)
                                        local targetPart = statue and (statue.PrimaryPart or statue:FindFirstChildWhichIsA("BasePart"))
                                        local prompt = statue and statue:FindFirstChild("Prompt") and statue.Prompt:FindFirstChild("ProximityPrompt")

                                        if targetPart and prompt then
                                            hrp.CFrame = targetPart.CFrame * CFrame.new(0, 0, -3)
                                            task.wait(0.3)

                                            fireproximityprompt(prompt)
                                            
                                            task.wait(0.2)
                                        end
                                    end

                                    task.wait(1.5)
                                    lastPuzzleSignature = ""
                                end
                            end
                        end
                    end)
                    task.wait(0.3)
                end
            end)
        end
    end
})

local eyeRelicActive = false

Dimitra:Toggle({
    Title = "Eye Relic [Normal]",
    Default = false,
    Callback = function(Value)
        eyeRelicActive = Value

        if eyeRelicActive then
            task.spawn(function()
                local Workspace = game:GetService("Workspace")
                local player = game:GetService("Players").LocalPlayer
                local lastPuzzleSignature = ""

                -- Opposite Mapping Table
                local mirrorToEyeMap = {
                    [4] = 1, -- Mirror4 -> Eye1
                    [3] = 2, -- Mirror3 -> Eye2
                    [2] = 3, -- Mirror2 -> Eye3
                    [1] = 4  -- Mirror1 -> Eye4
                }

                while eyeRelicActive do
                    pcall(function()
                        local puzzle = Workspace:FindFirstChild("Section2") 
                            and Workspace.Section2:FindFirstChild("MainObjective") 
                            and Workspace.Section2.MainObjective:FindFirstChild("Puzzle2")

                        if puzzle then
                            local mirrorsFolder = puzzle:FindFirstChild("Mirrors")
                            local statuesFolder = puzzle:FindFirstChild("EyeStatues")
                            local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")

                            if mirrorsFolder and statuesFolder and hrp then
                                local detectedMirrors = {} 
                                local recordedMirrors = {}
                                local signatureString = ""

                                local collecting = true
                                local lastActivationTime = tick()

                                while collecting and eyeRelicActive do
                                    local foundNewThisCycle = false

                                    for i = 1, 4 do
                                        if not recordedMirrors[i] then
                                            local mirror = mirrorsFolder:FindFirstChild("Mirror" .. i)
                                            local eye = mirror and mirror:FindFirstChild("Eye")

                                            if eye then
                                                local isVisible = false
                                                for _, part in ipairs(eye:GetChildren()) do
                                                    if part:IsA("BasePart") and part.Transparency == 0 then
                                                        isVisible = true
                                                        break
                                                    end
                                                end

                                                if isVisible then
                                                    table.insert(detectedMirrors, {index = i, time = tick()})
                                                    recordedMirrors[i] = true
                                                    signatureString = signatureString .. i
                                                    foundNewThisCycle = true
                                                    lastActivationTime = tick()
                                                end
                                            end
                                        end
                                    end

                                    if not foundNewThisCycle then
                                        if tick() - lastActivationTime > 1.5 and #detectedMirrors > 0 then
                                            collecting = false
                                        end
                                    end

                                    task.wait(0.02)
                                end

                                table.sort(detectedMirrors, function(a, b)
                                    return a.time < b.time
                                end)

                                local sequence = {}
                                local finalSignature = ""
                                for _, data in ipairs(detectedMirrors) do
                                    -- I-convert ang mirror index papunta sa kabaligtaran nitong eye index
                                    local mappedEyeIndex = mirrorToEyeMap[data.index] or data.index
                                    table.insert(sequence, mappedEyeIndex)
                                    finalSignature = finalSignature .. mappedEyeIndex
                                end

                                if #sequence > 0 and finalSignature ~= lastPuzzleSignature then
                                    lastPuzzleSignature = finalSignature

                                    for _, mappedIdx in ipairs(sequence) do
                                        if not eyeRelicActive then break end

                                        local statue = statuesFolder:FindFirstChild("Eye" .. mappedIdx)
                                        local targetPart = statue and (statue.PrimaryPart or statue:FindFirstChildWhichIsA("BasePart"))
                                        local prompt = statue and statue:FindFirstChild("Prompt") and statue.Prompt:FindFirstChild("ProximityPrompt")

                                        if targetPart and prompt then
                                            hrp.CFrame = targetPart.CFrame * CFrame.new(0, 0, -3)
                                            task.wait(0.3)

                                            fireproximityprompt(prompt)
                                            
                                            task.wait(0.2)
                                        end
                                    end

                                    task.wait(1.5)
                                    lastPuzzleSignature = ""
                                end
                            end
                        end
                    end)
                    task.wait(0.3)
                end
            end)
        end
    end
})

Dimitra:Button({
    Title = "Auto Wish for Leave",
    Callback = function()
        local _w = game:GetService("Workspace")
        local _rs = game:GetService("ReplicatedStorage")
        local _cam = _w.CurrentCamera
        local _l = game:GetService("Players").LocalPlayer

        local char = _l.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        task.spawn(function()
            local safePos = Vector3.new(1812, -61, 4520)

            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
            hrp.CFrame = CFrame.new(1826, -89, 4346)
            task.wait(0.5)

            local section2 = _w:FindFirstChild("Section2")
            local mainObj = section2 and section2:FindFirstChild("MainObjective")
            local crystalWish = mainObj and mainObj:FindFirstChild("CrystalBallWish")
            local promptPart = crystalWish and crystalWish:FindFirstChild("PromptPart")
            local prompt = promptPart and promptPart:FindFirstChildWhichIsA("ProximityPrompt", true)

            if prompt and promptPart then
                local maxDist = prompt.MaxActivationDistance
                local originalCamType = _cam.CameraType
                local originalCamCFrame = _cam.CFrame

                prompt.MaxActivationDistance = 250
                prompt.RequiresLineOfSight = false

                _cam.CameraType = Enum.CameraType.Scriptable
                _cam.CFrame = CFrame.new(_cam.CFrame.Position, promptPart.Position)

                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
                hrp.CFrame = CFrame.new(promptPart.Position)
                task.wait(0.3)

                pcall(function() prompt:InputHoldBegin() end)
                task.wait(prompt.HoldDuration + 0.1)
                pcall(function() prompt:InputHoldEnd() end)

                _cam.CameraType = originalCamType
                _cam.CFrame = originalCamCFrame
                prompt.MaxActivationDistance = maxDist
            end

            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
            hrp.CFrame = CFrame.new(safePos)
            task.wait(0.5)

            local Event = _rs:WaitForChild("modules"):WaitForChild("Packet"):WaitForChild("Reliable")
            pcall(function()
                Event:FireServer("Section2/CrystalBallWishPick", "Leave")
            end)
        end)
    end
})

Dimitra:Section("Final Stage")

Dimitra:Button({
    Title = "Instant Kill",
    Description = "",
    Callback = function()
        task.spawn(function()
            local boss = workspace:FindFirstChild("Section3") 
                and workspace.Section3:FindFirstChild("DimitraBOSS")
                
            if boss then
                local humanoid = boss:FindFirstChildOfClass("Humanoid")
                
                if humanoid then
                    -- I-set ang health sa 0 para mamatay agad
                    humanoid.Health = 0
                end
            end
        end)
    end
})

local bunnyAutoEnabled = false

Dimitra:Toggle({
    Title = "Auto Bunny",
    Default = false,
    Callback = function(state)
        bunnyAutoEnabled = state
        if state then
            task.spawn(function()
                local _w = game:GetService("Workspace")
                local _cam = _w.CurrentCamera
                local _l = game:GetService("Players").LocalPlayer
                
                while bunnyAutoEnabled do
                    local bunny = _w:FindFirstChild("BunnySpawn")
                    if bunny then
                        local prompt = bunny:FindFirstChildWhichIsA("ProximityPrompt", true)
                        local targetPart = bunny:IsA("BasePart") and bunny or bunny.PrimaryPart or bunny:FindFirstChildWhichIsA("BasePart")
                        
                        if prompt and prompt.Enabled and targetPart then
                            local char = _l.Character
                            local hrp = char and char:FindFirstChild("HumanoidRootPart")
                            if hrp then
                                local maxDist = prompt.MaxActivationDistance
                                local originalCamType = _cam.CameraType
                                local originalCamCFrame = _cam.CFrame
                                
                                prompt.MaxActivationDistance = 250
                                prompt.RequiresLineOfSight = false
                                _cam.CameraType = Enum.CameraType.Scriptable
                                _cam.CFrame = CFrame.new(_cam.CFrame.Position, targetPart.Position)
                                
                                hrp.AssemblyLinearVelocity = Vector3.zero
                                hrp.AssemblyAngularVelocity = Vector3.zero
                                hrp.CFrame = CFrame.new(targetPart.Position)
                                task.wait(0.3)
                                
                                pcall(function() prompt:InputHoldBegin() end)
                                task.wait(prompt.HoldDuration + 0.1)
                                pcall(function() prompt:InputHoldEnd() end)
                                
                                _cam.CameraType = originalCamType
                                _cam.CFrame = originalCamCFrame
                                prompt.MaxActivationDistance = maxDist
                                
                                task.wait(2)
                            end
                        end
                    end
                    task.wait(0.5)
                end
            end)
        end
    end
})
