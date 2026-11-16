local KazeUI = KazeUI or loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/KazeHub/UI/refs/heads/main/UILibrary.lua.txt"
))()

local Window = KazeUI:CreateWindow({
    Title = "THE MIMIC",
    Author = "KAZE",
    Version = "JEALOUSY IV",
    Size = UDim2.fromOffset(700, 400),
    Icon = "79414074886215",
    Theme = "Obsidian",
    PerformanceMode = true,
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
local OriginalHoldDurations = setmetatable({}, {__mode = "k"})

Main:Toggle({
    Title = "Instant Prompt",
    Default = false,
    Callback = function(state)
        InstantPromptEnabled = state
        if PromptConnection then PromptConnection:Disconnect() PromptConnection = nil end

        if state then
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("ProximityPrompt") then
                    if OriginalHoldDurations[obj] == nil then OriginalHoldDurations[obj] = obj.HoldDuration end
                    obj.HoldDuration = 0
                end
            end
            PromptConnection = workspace.DescendantAdded:Connect(function(obj)
                if InstantPromptEnabled and obj:IsA("ProximityPrompt") then
                    if OriginalHoldDurations[obj] == nil then OriginalHoldDurations[obj] = obj.HoldDuration end
                    obj.HoldDuration = 0
                end
            end)
        else
            for prompt, duration in pairs(OriginalHoldDurations) do
                if prompt.Parent then prompt.HoldDuration = duration end
            end
            table.clear(OriginalHoldDurations)
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
        if fbConnection then fbConnection:Disconnect() fbConnection = nil end
        
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
            if h and h:IsA("BasePart") then CachedNoclipParts[#CachedNoclipParts + 1] = h end
        end
    end
end
rebuildNoclipParts(CachedCharacter)

LocalPlayer.CharacterAdded:Connect(function(char)
    CachedCharacter = char
    CachedHumanoid = char:FindFirstChildOfClass("Humanoid") or char:WaitForChild("Humanoid", 5)
    CachedHRP = char:FindFirstChild("HumanoidRootPart") or char:WaitForChild("HumanoidRootPart", 5)
    task.defer(function() task.wait(0.15) rebuildNoclipParts(char) end)
end)
LocalPlayer.CharacterRemoving:Connect(function()
    CachedCharacter = nil CachedHumanoid = nil CachedHRP = nil CachedNoclipParts = {}
end)

local NoclipEnabled = false
local noclipConnection

Main:Toggle({
    Title = "Noclip",
    Default = false,
    Callback = function(s)
        NoclipEnabled = s
        if noclipConnection then noclipConnection:Disconnect() noclipConnection = nil end
        if NoclipEnabled then
            if #CachedNoclipParts == 0 and CachedCharacter then rebuildNoclipParts(CachedCharacter) end
            noclipConnection = RunService.Stepped:Connect(function()
                for i = 1, #CachedNoclipParts do
                    local part = CachedNoclipParts[i]
                    if part and part.Parent and part.CanCollide then part.CanCollide = false end
                end
            end)
        end
    end
})

local tpwalking = nil
local tpwalkStack = 0
local TPSpeed = 1

Main:Slider({ Title = "TP Walk Speed", Min = 1, Max = 20, Default = 1, Callback = function(v) TPSpeed = v end })

Main:Toggle({
    Title = "Enable TP Walk",
    Default = false,
    Callback = function(s)
        if tpwalking then tpwalking:Disconnect() tpwalking = nil end
        if s then
            tpwalking = RunService.Heartbeat:Connect(function(delta)
                local character = LocalPlayer.Character
                local humanoid = character and character:FindFirstChildWhichIsA("Humanoid")
                if not (character and humanoid and humanoid.Parent) then
                    if tpwalking then tpwalking:Disconnect() tpwalking = nil end
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

local function GetHumanoid() return LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") end
local function ApplyWalkSpeed() local Hum = GetHumanoid() if Hum then Hum.WalkSpeed = WalkSpeedValue end end
local function StopWalkSpeed() local Hum = GetHumanoid() if Hum then Hum.WalkSpeed = OriginalWalkSpeed end if Connection then Connection:Disconnect() Connection = nil end end

local function StartWalkSpeed()
    local Hum = GetHumanoid()
    if Hum then OriginalWalkSpeed = Hum.WalkSpeed end
    ApplyWalkSpeed()
    if Connection then Connection:Disconnect() end
    Connection = RunService.Heartbeat:Connect(function() if WalkSpeedEnabled then ApplyWalkSpeed() end end)
end

Main:Slider({ Title = "WalkSpeed Value", Min = 16, Max = 1000, Default = 16, Callback = function(v) WalkSpeedValue = math.clamp(v, 16, 1000) if WalkSpeedEnabled then ApplyWalkSpeed() end end })
Main:Toggle({ Title = "WalkSpeed", Default = false, Callback = function(v) WalkSpeedEnabled = v if WalkSpeedEnabled then StartWalkSpeed() else StopWalkSpeed() end end })

LocalPlayer.CharacterAdded:Connect(function()
    if WalkSpeedEnabled then
        task.wait(1)
        local Hum = GetHumanoid()
        if Hum then OriginalWalkSpeed = Hum.WalkSpeed end
        ApplyWalkSpeed()
    end
end)

_G.KAZE_WalkSpeed = {
    Enable = function() WalkSpeedEnabled = true StartWalkSpeed() end,
    Disable = function() WalkSpeedEnabled = false StopWalkSpeed() end,
    SetValue = function(Value) WalkSpeedValue = math.clamp(Value, 16, 1000) if WalkSpeedEnabled then ApplyWalkSpeed() end end,
    IsEnabled = function() return WalkSpeedEnabled end,
    GetValue = function() return WalkSpeedValue end
}

local TargetFlySpeed = 16
local FLY_ENABLED = false
local flyConnection

Main:Slider({ Title = "Fly Speed", Min = 16, Max = 100, Default = 16, Callback = function(val) TargetFlySpeed = val end })

Main:Toggle({
    Title = "Enable Fly",
    Default = false,
    Callback = function(state)
        FLY_ENABLED = state
        local function stopFly()
            if flyConnection then flyConnection:Disconnect() flyConnection = nil end
            local character = LocalPlayer.Character
            local hrp = character and character:FindFirstChild("HumanoidRootPart")
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            if humanoid then humanoid.PlatformStand = false end
            if hrp then hrp.Anchored = false hrp.AssemblyAngularVelocity = Vector3.zero hrp.AssemblyLinearVelocity = Vector3.zero end
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
                    CachedHRP = hrp CachedHumanoid = humanoid
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
                        if flyDirection.Magnitude > 0 then flyDirection = flyDirection.Unit end
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

Main:Keybind({
    Title = "Hide & Open",
    Default = Enum.KeyCode.Q,
    Callback = function()
        Window:Toggle()
    end
})

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local GameTab = Window:CreateTab({ Title = "Game", Icon = "gamepad-2" })
local GameFPS = GameTab:CreateSubTab({ Title = "FPS Boost", Icon = "zap", Default = true })
local GameMain = GameTab:CreateSubTab({ Title = "Main", Icon = "gamepad-2", Default = false })
local GameYen = GameTab:CreateSubTab({ Title = "Yen", Icon = "coins", Default = false })

GameFPS:Button({
    Title = "Low GFX",
    Callback = function()
        task.spawn(function()
            pcall(function()
                local Lighting = game:GetService("Lighting")
                local Terrain = workspace:FindFirstChildOfClass("Terrain")

                Lighting.GlobalShadows = false
                Lighting.ShadowSoftness = 0

                for _, child in ipairs(Lighting:GetChildren()) do
                    if child:IsA("PostEffect") or child:IsA("Atmosphere") or child:IsA("Sky") then
                        child:Destroy()
                    end
                end

                if Terrain then
                    Terrain.WaterWaveSize = 0
                    Terrain.WaterWaveTransparency = 1
                    Terrain.WaterReflectance = 0
                    pcall(function() sethiddenproperty(Terrain, "Decoration", false) end)
                end

                local count = 0
                for _, obj in ipairs(workspace:GetDescendants()) do
                    if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") then
                        obj.Enabled = false
                    elseif obj:IsA("Decal") or obj:IsA("Texture") then
                        obj.Transparency = 1
                    elseif obj:IsA("BasePart") then
                        obj.CastShadow = false
                        obj.Material = Enum.Material.SmoothPlastic
                    end
                    
                    count = count + 1
                    if count % 1000 == 0 then
                        task.wait()
                    end
                end
            end)
        end)
    end
})


local autoPressE = false

GameMain:Toggle({
    Title = "Auto Free Yourself",
    Default = false,
    Callback = function(state)
        autoPressE = state
        if not autoPressE then return end

        task.spawn(function()
            local VirtualInputManager = game:GetService("VirtualInputManager")
            local PlayerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
            
            -- Cache the path so it doesn't search every frame
            local quickTimeGui = PlayerGui:WaitForChild("QuickTime")
            local grabbedUI = quickTimeGui:WaitForChild("GrabbedUI")

            while autoPressE do
                -- Check if the UI actually exists and is visible
                if grabbedUI and grabbedUI.Parent and grabbedUI.Visible then
                    pcall(function()
                        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
                        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
                    end)
                end
                task.wait(0.05) -- Yields 20 times a second, saving massive CPU
            end
        end)
    end
})

local isAutoPromptToggled = false
local isEspToggled = false
local yenEspHolders = {}
local yenEspConnection = nil
local autoPromptTask = nil
local PROXIMITY_RANGE = 15

local function getCharacterRoot()
    local char = LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

GameYen:Button({
    Title = "Yen Collect",
    Callback = function()
        task.spawn(function()
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end

            local mimicFolder = Workspace:FindFirstChild("MimicCurrencySpawns")
            local yenFolder = mimicFolder and mimicFolder:FindFirstChild("Yen")
            if not yenFolder then return end

            local originalCFrame = hrp.CFrame

            while true do
                local items = yenFolder:GetChildren()
                if #items == 0 then break end
                
                local item = items[1]
                local targetPart = item:IsA("BasePart") and item or (item:IsA("Model") and (item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart", true)))
                
                if targetPart then
                    hrp.AssemblyLinearVelocity = Vector3.zero
                    hrp.AssemblyAngularVelocity = Vector3.zero
                    char:PivotTo(targetPart.CFrame + Vector3.new(0, 3, 0))
                    task.wait(0.1)

                    local prompt = item:FindFirstChildWhichIsA("ProximityPrompt", true)
                    if prompt then
                        prompt.HoldDuration = 0
                        prompt.RequiresLineOfSight = false
                        pcall(function()
                            if fireproximityprompt then
                                fireproximityprompt(prompt, 0)
                            else
                                prompt:InputHoldBegin()
                                prompt:InputHoldEnd()
                            end
                        end)
                    end
                    task.wait(0.1)
                else
                    task.wait(0.1)
                end
            end

            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
            char:PivotTo(originalCFrame)
        end)
    end
})

local function clearYenEsp()
    if yenEspConnection then
        yenEspConnection:Disconnect()
        yenEspConnection = nil
    end
    for item, holderData in pairs(yenEspHolders) do
        if holderData then
            pcall(function()
                if holderData.Highlight then holderData.Highlight:Destroy() end
                if holderData.Billboard then holderData.Billboard:Destroy() end
            end)
        end
    end
    yenEspHolders = {}
end

local function addYenEspToItem(item)
    if not item or yenEspHolders[item] then return end
    local targetPart = item:IsA("BasePart") and item or (item:IsA("Model") and (item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart", true))) or item:FindFirstChildWhichIsA("BasePart", true)
    if not targetPart then return end

    pcall(function()
        local highlight = Instance.new("Highlight")
        highlight.FillColor = Color3.fromRGB(255, 215, 0)
        highlight.OutlineColor = Color3.fromRGB(0, 0, 0)
        highlight.FillTransparency = 0.4
        highlight.OutlineTransparency = 0
        highlight.Adornee = item
        highlight.Parent = item

        local billboard = Instance.new("BillboardGui")
        billboard.Adornee = targetPart
        billboard.Size = UDim2.new(0, 80, 0, 24)
        billboard.StudsOffset = Vector3.new(0, 2, 0)
        billboard.AlwaysOnTop = true
        billboard.Parent = targetPart

        local textLabel = Instance.new("TextLabel")
        textLabel.Size = UDim2.new(1, 0, 1, 0)
        textLabel.BackgroundTransparency = 1
        textLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
        textLabel.TextSize = 12
        textLabel.Font = Enum.Font.SourceSansBold
        textLabel.Text = "Yen"
        textLabel.Parent = billboard

        local textStroke = Instance.new("UIStroke")
        textStroke.Color = Color3.fromRGB(0, 0, 0)
        textStroke.Thickness = 1.5
        textStroke.Parent = textLabel

        yenEspHolders[item] = { Highlight = highlight, Billboard = billboard, TextLabel = textLabel, Part = targetPart }
    end)
end

local function removeYenEspFromItem(item)
    if yenEspHolders[item] then
        pcall(function()
            if yenEspHolders[item].Highlight then yenEspHolders[item].Highlight:Destroy() end
            if yenEspHolders[item].Billboard then yenEspHolders[item].Billboard:Destroy() end
        end)
        yenEspHolders[item] = nil
    end
end

GameYen:Toggle({
    Title = "Auto Collect Yen Nearby",
    Default = false,
    Callback = function(state)
        isAutoPromptToggled = state
        if autoPromptTask then
            pcall(function() task.cancel(autoPromptTask) end)
            autoPromptTask = nil
        end
        if not state then return end

        autoPromptTask = task.spawn(function()
            while isAutoPromptToggled do
                local hrp = getCharacterRoot()
                local mimic = Workspace:FindFirstChild("MimicCurrencySpawns")
                local yen = mimic and mimic:FindFirstChild("Yen")
                
                if hrp and yen then
                    for _, item in ipairs(yen:GetChildren()) do
                        if not isAutoPromptToggled then break end
                        local targetPart = item:IsA("BasePart") and item or (item:IsA("Model") and (item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart", true)))
                        
                        if targetPart and (targetPart.Position - hrp.Position).Magnitude <= PROXIMITY_RANGE then
                            local prompt = item:FindFirstChildWhichIsA("ProximityPrompt", true)
                            if prompt then
                                prompt.HoldDuration = 0
                                pcall(function() if fireproximityprompt then fireproximityprompt(prompt, 0) end end)
                            end
                        end
                    end
                end
                task.wait(0.05)
            end
        end)
    end
})

GameYen:Toggle({
    Title = "ESP Yen",
    Default = false,
    Callback = function(state)
        isEspToggled = state
        clearYenEsp()
        if not isEspToggled then return end

        local mimic = Workspace:FindFirstChild("MimicCurrencySpawns")
        local yen = mimic and mimic:FindFirstChild("Yen")
        
        if yen then
            for _, item in ipairs(yen:GetChildren()) do
                addYenEspToItem(item)
            end
            yen.ChildAdded:Connect(function(item) if isEspToggled then addYenEspToItem(item) end end)
        end

        yenEspConnection = task.spawn(function()
            while isEspToggled do
                local hrp = getCharacterRoot()
                for item, data in pairs(yenEspHolders) do
                    if item and item.Parent and data.Part and data.Part.Parent and data.TextLabel then
                        if hrp then
                            local dist = math.floor((data.Part.Position - hrp.Position).Magnitude)
                            data.TextLabel.Text = string.format("Yen [%sm]", dist)
                        else
                            data.TextLabel.Text = "Yen"
                        end
                    else
                        removeYenEspFromItem(item)
                    end
                end
                task.wait(0.2)
            end
        end)
    end
})

local GozuTab = Window:CreateTab({ Title = "Gozu & Mezu Stage", Icon = "chess-knight" })

GozuTab:Button({
    Title = "Start [Multiplayer]",
    Callback = function()
        task.spawn(function()
            local intro = workspace:FindFirstChild("Intro [no script]")
            local cutscene = intro and intro:FindFirstChild("Cutscene")
            local doorTrigger = cutscene and cutscene:FindFirstChild("DoorTrigger")
            local char = game.Players.LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            
            if doorTrigger and hrp and firetouchinterest then
                firetouchinterest(hrp, doorTrigger, 0)
                task.wait(0.1)
                firetouchinterest(hrp, doorTrigger, 1)
            end
        end)
    end
})

GozuTab:Button({
    Title = "Skip [Solo]",
    Callback = function()
        task.spawn(function()
            local section1 = workspace:FindFirstChild("Section1")
            local npc = section1 and section1:FindFirstChild("NPC")
            local npcTrigger = npc and npc:FindFirstChild("Trigger")
            local char = game.Players.LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            
            if npcTrigger and hrp then
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
                hrp.CFrame = npcTrigger.CFrame
                
                if firetouchinterest then
                    firetouchinterest(hrp, npcTrigger, 0)
                    task.wait(0.1)
                    firetouchinterest(hrp, npcTrigger, 1)
                end
            end
        end)
    end
})

local HeartStage = Window:CreateTab({ Title = "Heart Stage", Icon = "heart" })

local HeartMain = HeartStage:CreateSubTab({ Title = "Main", Icon = "house", Default = true })

HeartMain:Button({
    Title = "Talk",
    Callback = function()
        task.spawn(function()
            local section1 = workspace:FindFirstChild("Section1")
            local npc = section1 and section1:FindFirstChild("NPC")
            local npcTrigger = npc and npc:FindFirstChild("Trigger")
            local char = game.Players.LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            
            if npcTrigger and hrp then
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
                hrp.CFrame = npcTrigger.CFrame
                
                if firetouchinterest then
                    firetouchinterest(hrp, npcTrigger, 0)
                    task.wait(0.1)
                    firetouchinterest(hrp, npcTrigger, 1)
                end
            end
        end)
    end
})

HeartMain:Button({
    Title = "Auto Spin",
    Callback = function()
        task.spawn(function()
            local hrp = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            local section1 = workspace:FindFirstChild("Section1")
            local spinModel = section1 and section1:FindFirstChild("Puzzle") and section1.Puzzle:FindFirstChild("SpinModel")
            
            if spinModel and hrp then
                local prompt = spinModel:FindFirstChild("ProximityPrompt", true)
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
                hrp.CFrame = CFrame.new(-71.80, 49.34, 10.63)
                
                if prompt then
                    prompt.Enabled = true
                    for i = 1, 15 do
                        pcall(function() fireproximityprompt(prompt) end)
                        task.wait(1)
                    end
                end
            end
        end)
    end
})

HeartMain:Button({
    Title = "Teleport to Chase",
    Callback = function()
        task.spawn(function()
            local hrp = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
                hrp.CFrame = CFrame.new(-265.142731, 53.6106415, -32.7704659, -1, 0, 0, 0, -1, 0, 0, 0, 1)
            end
        end)
    end
})

local HeartESP = HeartStage:CreateSubTab({ Title = "ESP", Icon = "eye", Default = false })

local heartEspEnabled = false
local heartEspObjects = {}
local heartEspConn = nil

local function clearHeartEsp()
    if heartEspConn then
        heartEspConn:Disconnect()
        heartEspConn = nil
    end
    for _, obj in pairs(heartEspObjects) do
        if obj and obj.Parent then obj:Destroy() end
    end
    heartEspObjects = {}
end

HeartESP:Toggle({
    Title = "ESP Hearts",
    Default = false,
    Callback = function(state)
        heartEspEnabled = state
        clearHeartEsp()
        if not heartEspEnabled then return end

        local section1 = workspace:FindFirstChild("Section1")
        local puzzle = section1 and section1:FindFirstChild("Puzzle")
        local heartsFolder = puzzle and puzzle:FindFirstChild("Hearts")
        if not heartsFolder then return end

        local function addEsp(model)
            if not model or heartEspObjects[model] then return end
            local hl = Instance.new("Highlight")
            hl.FillColor = Color3.fromRGB(0, 255, 0)
            hl.OutlineColor = Color3.fromRGB(255, 255, 255)
            hl.FillTransparency = 0.5
            hl.OutlineTransparency = 0
            hl.Adornee = model
            hl.Parent = model
            heartEspObjects[model] = hl
        end

        for _, child in ipairs(heartsFolder:GetChildren()) do
            addEsp(child)
        end

        local addedConn = heartsFolder.ChildAdded:Connect(function(child)
            if heartEspEnabled then
                task.wait(0.05)
                addEsp(child)
            end
        end)

        local removedConn = heartsFolder.ChildRemoved:Connect(function(child)
            if heartEspObjects[child] then
                heartEspObjects[child]:Destroy()
                heartEspObjects[child] = nil
            end
        end)

        heartEspConn = RunService.Heartbeat:Connect(function()
            if not heartEspEnabled then
                addedConn:Disconnect()
                removedConn:Disconnect()
            end
        end)
    end
})

local HeartChase = HeartStage:CreateSubTab({ Title = "Chase", Icon = "footprints", Default = false })

HeartChase:Button({
    Title = "Finish Chase",
    Callback = function()
        task.spawn(function()
            local hrp = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
                hrp.CFrame = CFrame.new(-100, 4, -396)
            end
        end)
    end
})

local GrinDemonTab = Window:CreateTab({ Title = "GrinDemon Stage", Icon = "Skull" })

local GrinMain = GrinDemonTab:CreateSubTab({ Title = "Main", Icon = "play", Default = true })
local GrinESP = GrinDemonTab:CreateSubTab({ Title = "ESP", Icon = "eye", Default = false })

local isPreppingTorch = false

GrinMain:Button({
    Title = "Prep & Light Torch",
    Callback = function()
        if isPreppingTorch then return end
        isPreppingTorch = true
        
        task.spawn(function()
            local ReplicatedStorage = game:GetService("ReplicatedStorage")
            local maze = workspace:FindFirstChild("Section1") and workspace.Section1:FindFirstChild("Maze")
            if not maze then isPreppingTorch = false return end
            
            local crafting = maze:FindFirstChild("Crafting")
            local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
            local hrp = char:WaitForChild("HumanoidRootPart")
            local targetCFrame = CFrame.new(-78.08, 4.00, -421.98)

            local function firePrompt(p)
                if not p or not p:IsA("ProximityPrompt") or not p.Enabled then return false end
                pcall(function() fireproximityprompt(p) end)
                return true
            end

            local function getItemCount(itemName)
                local count = 0
                local backpack = LocalPlayer:FindFirstChild("Backpack")
                local character = LocalPlayer.Character
                for _, container in ipairs({backpack, character}) do
                    if container then
                        for _, item in ipairs(container:GetChildren()) do
                            if item.Name == itemName then count += 1 end
                        end
                    end
                end
                return count
            end

            local function hasItems()
                return getItemCount("Cloth") >= 1 and getItemCount("Stick") >= 2
            end

            local holes = maze:FindFirstChild("Holes")
            if holes then
                for _, hole in ipairs(holes:GetChildren()) do
                    if hasItems() then break end
                    if hole.Name == "Hole" and hole:IsA("BasePart") then
                        local p = hole:FindFirstChildWhichIsA("ProximityPrompt", true)
                        if p and p.Enabled then
                            hrp.AssemblyLinearVelocity = Vector3.zero
                            hrp.AssemblyAngularVelocity = Vector3.zero
                            hrp.CFrame = hole.CFrame + Vector3.new(0, 3, 0)
                            task.wait(0.3)
                            
                            local startTime = tick()
                            while not hasItems() and p.Parent and p.Enabled and (tick() - startTime < 10) do
                                firePrompt(p)
                                task.wait(0.2)
                            end
                        end
                    end
                end
            end

            if not hasItems() then 
                hrp.CFrame = targetCFrame 
                isPreppingTorch = false
                return 
            end

            local tables = crafting and crafting:FindFirstChild("Tables")
            local monster = tables and tables:FindFirstChild("Monster")
            if not monster then 
                hrp.CFrame = targetCFrame 
                isPreppingTorch = false
                return 
            end

            local monsterPart = monster:IsA("BasePart") and monster or monster.PrimaryPart or monster:FindFirstChildWhichIsA("BasePart", true)
            local monsterPrompt = monster:FindFirstChildWhichIsA("ProximityPrompt", true)
            if not monsterPart or not monsterPrompt then 
                hrp.CFrame = targetCFrame 
                isPreppingTorch = false
                return 
            end

            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
            hrp.CFrame = monsterPart.CFrame + Vector3.new(0, 3, 0)
            task.wait(0.3)
            firePrompt(monsterPrompt)
            task.wait(0.1)

            local packages = ReplicatedStorage:FindFirstChild("Packages")
            local packetFunc = packages and packages:FindFirstChild("Packet") and packages.Packet:FindFirstChild("PacketFunction")
            if packetFunc then
                pcall(function()
                    packetFunc:InvokeServer(0, {
                        ["__args"] = {},
                        ["__tree"] = {[1] = "CraftingService", [2] = "Interact"},
                        ["__callType"] = 0
                    })
                end)
            end

            local torch = nil
            local torchStart = tick()
            while tick() - torchStart < 5 do
                local backpack = LocalPlayer:FindFirstChild("Backpack")
                local character = LocalPlayer.Character
                torch = (character and character:FindFirstChild("Torch")) or (backpack and backpack:FindFirstChild("Torch"))
                if torch then break end
                task.wait(0.1)
            end

            if not torch then 
                hrp.CFrame = targetCFrame 
                isPreppingTorch = false
                return 
            end

            char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
            hrp = char:WaitForChild("HumanoidRootPart")
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            if humanoid and torch.Parent ~= char then
                humanoid:EquipTool(torch)
                task.wait(0.2)
            end

            local flameFolder = crafting and crafting:FindFirstChild("ArmFlames")
            local flameModel = flameFolder and flameFolder:FindFirstChild("ArmFlames")
            if not flameModel or not flameModel:IsA("Model") then 
                hrp.CFrame = targetCFrame 
                isPreppingTorch = false
                return 
            end

            local flamePart = flameModel.PrimaryPart or flameModel:FindFirstChildWhichIsA("BasePart", true)
            local flamePrompt = flameModel:FindFirstChildWhichIsA("ProximityPrompt", true)
            if not flamePart or not flamePrompt then 
                hrp.CFrame = targetCFrame 
                isPreppingTorch = false
                return 
            end

            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
            hrp.CFrame = flamePart.CFrame + Vector3.new(0, 3, 0)
            task.wait(0.3)
            firePrompt(flamePrompt)
            task.wait(0.2)

            hrp.CFrame = targetCFrame
            isPreppingTorch = false
        end)
    end
})

GrinMain:Button({
    Title = "Teleport & Throw Torch",
    Callback = function()
        task.spawn(function()
            local maze = workspace:FindFirstChild("Section1") and workspace.Section1:FindFirstChild("Maze")
            if not maze then return end

            local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
            local hrp = char:WaitForChild("HumanoidRootPart")

            local torch = char:FindFirstChild("Torch") or (LocalPlayer:FindFirstChild("Backpack") and LocalPlayer.Backpack:FindFirstChild("Torch"))
            if not torch then return end
            
            local remote = torch:FindFirstChild("RemoteEvent", true)
            if not remote or not remote:IsA("RemoteEvent") then return end

            local safeParts = {}
            for _, obj in ipairs(workspace:GetChildren()) do
                if obj.Name == "Part" and obj:IsA("BasePart") then
                    table.insert(safeParts, obj)
                end
            end

            local demons = {}
            for _, name in ipairs({"GrinDemon", "GrinDemonNM"}) do
                local demon = maze:FindFirstChild(name)
                if demon and demon:IsA("Model") then table.insert(demons, demon) end
            end
            if #demons == 0 then return end

            local function getRoot(demon)
                return demon:FindFirstChild("HumanoidRootPart") or demon.PrimaryPart or demon:FindFirstChildWhichIsA("BasePart", true)
            end

            local function getHitbox(demon)
                return demon:FindFirstChild("Hitbox") or demon:FindFirstChild("Head") or demon:FindFirstChildWhichIsA("BasePart", true)
            end

            local function nearPart(pos)
                for _, part in ipairs(safeParts) do
                    if (pos - part.Position).Magnitude <= 30 then return true end
                end
                return false
            end

            local target, root
            for _, demon in ipairs(demons) do
                local r = getRoot(demon)
                if r and not nearPart(r.Position) then
                    target = demon
                    root = r
                    break
                end
            end
            
            if not target or not root then return end

            local targetPosition = root.Position
            local lookVector = root.CFrame.LookVector
            local behindPosition = targetPosition - (lookVector * 30) + Vector3.new(0, 5, 0)

            local attempts = 0
            while nearPart(behindPosition) and attempts < 10 do
                task.wait(0.05)
                attempts += 1
                root = getRoot(target)
                if not root then return end
                targetPosition = root.Position
                lookVector = root.CFrame.LookVector
                behindPosition = targetPosition - (lookVector * 30) + Vector3.new(0, 5, 0)
            end

            if nearPart(behindPosition) then return end

            local actualHitbox = getHitbox(target)
            local aimTarget = actualHitbox and actualHitbox.Position or targetPosition
            
            local perfectAim = CFrame.lookAt(behindPosition, aimTarget, Vector3.yAxis)
            
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
            hrp.CFrame = perfectAim
            task.wait(0.15)

            pcall(function() 
                remote:FireServer(perfectAim) 
            end)

            task.wait(0.2)
            hrp.CFrame = CFrame.new(-78.08, 4.00, -421.98)
        end)
    end
})

GrinMain:Button({
    Title = "Exit GrinDemon",
    Callback = function()
        task.spawn(function()
            local RunService = game:GetService("RunService")
            local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
            local hrp = char:WaitForChild("HumanoidRootPart")

            if not hrp then return end

            local startPos = Vector3.new(-327.53, 6.59, -970.35)
            local endCFrame = CFrame.new(-325.580658, 15.3886156, -1113.81494, 1, 0, 0, 0, 1, 0, 0, 0, 1)
            local speed = 45

            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
            char:PivotTo(CFrame.new(startPos))
            task.wait(0.5)

            local connection
            connection = RunService.Heartbeat:Connect(function(dt)
                if not hrp or not hrp.Parent then
                    if connection then connection:Disconnect() end
                    return
                end

                local currentPos = hrp.Position
                local targetPos = endCFrame.Position
                local distance = (targetPos - currentPos).Magnitude

                if distance <= 1 then
                    hrp.CFrame = endCFrame
                    hrp.AssemblyLinearVelocity = Vector3.zero
                    hrp.AssemblyAngularVelocity = Vector3.zero
                    if connection then connection:Disconnect() end
                    return
                end

                local direction = (targetPos - currentPos).Unit
                local step = math.min(speed * dt, distance)
                local newPos = currentPos + (direction * step)

                hrp.CFrame = CFrame.new(newPos, newPos + endCFrame.LookVector)
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
            end)
        end)
    end
})

local espGrinEnabled = false
local grinHighlights = {}
local grinBillboards = {}
local grinConnections = {}

local function applyGrinESP(model)
    if not model or grinHighlights[model] or not model:IsA("Model") then return end
    
    local hl = Instance.new("Highlight")
    hl.Name = "GrinESP_Highlight"
    hl.FillColor = Color3.fromRGB(255, 0, 0)
    hl.OutlineColor = Color3.fromRGB(0, 0, 0)
    hl.FillTransparency = 0.5
    hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Adornee = model
    hl.Parent = model
    grinHighlights[model] = hl
    
    local bb = Instance.new("BillboardGui")
    bb.Name = "GrinESP_Name"
    bb.Size = UDim2.new(0, 200, 0, 50)
    bb.StudsOffset = Vector3.new(0, 3, 0)
    bb.AlwaysOnTop = true
    bb.Parent = model
    
    local tl = Instance.new("TextLabel")
    tl.Size = UDim2.new(1, 0, 1, 0)
    tl.BackgroundTransparency = 1
    tl.Text = "GrinESP"
    tl.TextColor3 = Color3.fromRGB(255, 0, 0)
    tl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    tl.TextStrokeTransparency = 0
    tl.TextSize = 13
    tl.Font = Enum.Font.FredokaOne
    tl.Parent = bb
    grinBillboards[model] = bb
end

GrinESP:Toggle({
    Title = "Grin Demon",
    Default = false,
    Callback = function(state)
        espGrinEnabled = state
        
        for _, hl in pairs(grinHighlights) do pcall(function() hl:Destroy() end) end
        for _, bb in pairs(grinBillboards) do pcall(function() bb:Destroy() end) end
        for _, conn in ipairs(grinConnections) do pcall(function() conn:Disconnect() end) end
        table.clear(grinHighlights)
        table.clear(grinBillboards)
        table.clear(grinConnections)
        
        if not espGrinEnabled then return end
        
        task.spawn(function()
            local maze = workspace:FindFirstChild("Section1") and workspace.Section1:FindFirstChild("Maze")
            if not maze then return end
            
            local grin1 = maze:FindFirstChild("GrinDemonNM")
            local grin2 = maze:FindFirstChild("GrinDemon")
            
            if grin1 then applyGrinESP(grin1) end
            if grin2 then applyGrinESP(grin2) end
            
            table.insert(grinConnections, maze.ChildAdded:Connect(function(inst)
                if espGrinEnabled and (inst.Name == "GrinDemonNM" or inst.Name == "GrinDemon") then
                    applyGrinESP(inst)
                end
            end))
        end)
    end
})

local BellStage = Window:CreateTab({ Title = "Bells Stage", Icon = "bell" })

local BellMain = BellStage:CreateSubTab({ Title = "Main", Icon = "house", Default = true })
local BellChase = BellStage:CreateSubTab({ Title = "Chase", Icon = "footprints", Default = false })

local autoEquipSlashEnabled = false
local slashConnection = nil

BellMain:Toggle({
    Title = "Auto Equip & Slash",
    Default = false,
    Callback = function(state)
        autoEquipSlashEnabled = state
        
        if slashConnection then
            slashConnection:Disconnect()
            slashConnection = nil
        end
        
        if not autoEquipSlashEnabled then return end
        
        slashConnection = game:GetService("RunService").Heartbeat:Connect(function()
            if not autoEquipSlashEnabled then return end
            
            local char = game.Players.LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local backpack = game.Players.LocalPlayer:FindFirstChild("Backpack")
            
            if hum and backpack then
                local sword = char:FindFirstChild("Bone Sword") or backpack:FindFirstChild("Bone Sword")
                
                if sword then
                    if sword.Parent ~= char then
                        pcall(function()
                            hum:EquipTool(sword)
                        end)
                    else
                        pcall(function()
                            sword:Activate()
                        end)
                    end
                end
            end
        end)
    end
})

local SelectedBell = nil
local BellMap = {}
local SolvedDoors = {}
local LastValidDoor = nil

local RomanNumerals = {
    [1] = "I", [2] = "II", [3] = "III", [4] = "IV",
    [5] = "V", [6] = "VI", [7] = "VII", [8] = "VIII"
}

local function GetHRP()
    local player = game:GetService("Players").LocalPlayer
    local char = player.Character or player.CharacterAdded:Wait()
    return char:FindFirstChild("HumanoidRootPart")
end

local function GetBellTarget(bell)
    if not bell then return nil, nil end
    local modelTwo = bell:FindFirstChild("2")
    local targetCFrame = nil  
    local prompt = nil  
    
    if modelTwo then  
        prompt = modelTwo:FindFirstChildWhichIsA("ProximityPrompt", true)  
        if modelTwo:IsA("Model") and modelTwo.PrimaryPart then  
            targetCFrame = modelTwo.PrimaryPart.CFrame  
        else  
            local part = modelTwo:FindFirstChildWhichIsA("BasePart", true)  
            if part then targetCFrame = part.CFrame end  
        end  
    end  
    
    if not targetCFrame then  
        local fallbackPart = bell.PrimaryPart or bell:FindFirstChildWhichIsA("BasePart", true)  
        if fallbackPart then targetCFrame = fallbackPart.CFrame end  
    end  
    
    if not prompt then  
        prompt = bell:FindFirstChildWhichIsA("ProximityPrompt", true)  
    end  
    
    return targetCFrame, prompt
end

local function RefreshBells()
    local section2 = workspace:FindFirstChild("Section2")
    local folder = section2 and section2:FindFirstChild("Bells")
    BellMap = {}  
    local values = {}  
    local detectedBells = {}  
    
    if folder then  
        for _, bell in ipairs(folder:GetChildren()) do  
            if bell:IsA("Model") and bell.Name == "Bell" then  
                table.insert(detectedBells, bell)  
            end  
        end  
    end  

    for i = 1, 8 do  
        local roman = RomanNumerals[i]  
        local name = "Bell " .. roman  
        table.insert(values, name)  
        if detectedBells[i] then  
            BellMap[name] = detectedBells[i]  
        end  
    end  
    return values
end

local function IsWhite(part)
    local c = part.Color
    local isRGBWhite = (c.R > 0.85 and c.G > 0.85 and c.B > 0.85)
    local isBrickWhite = string.find(part.BrickColor.Name:lower(), "white") ~= nil
    return isRGBWhite or isBrickWhite
end

local function GetShapeNames(surfaceGui)
    local shapeNames = {}
    if not surfaceGui then return shapeNames end
    
    for _, child in ipairs(surfaceGui:GetChildren()) do
        if not child:IsA("UIListLayout") and not child:IsA("UIGridLayout") and not child:IsA("UIPadding") then
            table.insert(shapeNames, child.Name)
        end
    end
    return shapeNames
end

BellMain:Button({
    Title = "Kill Flies",
    Callback = function()
        task.spawn(function()
            local player = game:GetService("Players").LocalPlayer
            local char = player.Character or player.CharacterAdded:Wait()
            local hrp = char:WaitForChild("HumanoidRootPart")
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            
            local backpack = player:FindFirstChild("Backpack")
            local boneSword = (char:FindFirstChild("Bone Sword")) or (backpack and backpack:FindFirstChild("Bone Sword"))
            
            if boneSword and humanoid then
                if boneSword.Parent ~= char then
                    humanoid:EquipTool(boneSword)
                    task.wait(0.2)
                end
            end
            
            local flyFolder = workspace:FindFirstChild("Section2")
                and workspace.Section2:FindFirstChild("FlyNoobs")
                and workspace.Section2.FlyNoobs:FindFirstChild("Flies")
                
            if not flyFolder then return end
            
            for _, roamArea in ipairs(flyFolder:GetChildren()) do
                if roamArea.Name == "RoamArea" then
                    local model = roamArea:FindFirstChildWhichIsA("Model")
                    if model then
                        local targetPart = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
                        
                        if targetPart and hrp then
                            hrp.AssemblyLinearVelocity = Vector3.zero
                            hrp.AssemblyAngularVelocity = Vector3.zero
                            hrp.CFrame = targetPart.CFrame
                            
                            local currentSword = char:FindFirstChild("Bone Sword")
                            if currentSword then
                                pcall(function() currentSword:Activate() end)
                            end
                            
                            task.wait(0.5)
                        end
                    end
                end
            end
        end)
    end
})

BellMain:BoxDropdown({
    Title = "Bells",
    SearchBar = true,
    Options = (function()
        local opts = {}
        for _, name in ipairs(RefreshBells()) do
            table.insert(opts, { Text = name, Icon = "bell" })
        end
        return opts
    end)(),
    Default = "Select Bell",
    Callback = function(value)
        SelectedBell = value
    end
})

BellMain:Button({
    Title = "Teleport & Auto Solve",
    Callback = function()
        if not SelectedBell then return end
        task.spawn(function()
            RefreshBells()  
            local bell = BellMap[SelectedBell]  
            if not bell then return end  

            local targetCFrame, prompt = GetBellTarget(bell)  
            local hrp = GetHRP()  

            if targetCFrame and hrp then  
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
                hrp.CFrame = targetCFrame + Vector3.new(0, 5, 0)  
            end  
              
            task.wait(0.2)  

            local puzzleContainer = bell:FindFirstChild("2") or bell:FindFirstChildWhichIsA("Model") or bell  
            local ReplicatedStorage = game:GetService("ReplicatedStorage")  
            local PacketFunction = ReplicatedStorage:FindFirstChild("Packages")   
                and ReplicatedStorage.Packages:FindFirstChild("Packet")   
                and ReplicatedStorage.Packages.Packet:FindFirstChild("PacketFunction")  

            if not PacketFunction then return end  

            local currentSequence = {}  
            local activeState = {}  
            local connections = {}  

            for _, child in ipairs(puzzleContainer:GetDescendants()) do  
                if child.Name == "Buttons" and child:IsA("BasePart") then  
                    local function checkColor()  
                        if IsWhite(child) then  
                            if not activeState[child] then  
                                activeState[child] = true  
                                table.insert(currentSequence, child)  
                            end  
                        else  
                            activeState[child] = false  
                        end  
                    end  
                    table.insert(connections, child:GetPropertyChangedSignal("Color"):Connect(checkColor))  
                    table.insert(connections, child:GetPropertyChangedSignal("BrickColor"):Connect(checkColor))  
                end  
            end  

            if prompt then  
                prompt.Enabled = true  
                if fireproximityprompt then  
                    pcall(function() fireproximityprompt(prompt) end)  
                else  
                    pcall(function()  
                        prompt:InputHoldBegin()  
                        prompt:InputHoldEnd()  
                    end)  
                end  
            end  

            for round = 1, 3 do  
                local startTime = tick()  
                local lastRecordedCount = 0  
                local quietTime = tick()  

                repeat  
                    task.wait(0.05)  
                    if #currentSequence > lastRecordedCount then  
                        lastRecordedCount = #currentSequence  
                        quietTime = tick()  
                    end  
                until (tick() - quietTime > 1.2 and #currentSequence > 0) or (tick() - startTime > 7)  

                if #currentSequence == 0 then break end  

                if round > 1 and #currentSequence > 0 then  
                    table.remove(currentSequence, 1)  
                end  

                local roundToFire = {unpack(currentSequence)}  
                local totalButtons = #roundToFire  

                task.wait(0.2)  

                for idx, btnPart in ipairs(roundToFire) do  
                    if idx == totalButtons then  
                        table.clear(currentSequence)  
                        activeState = {}  
                    end  

                    pcall(function()  
                        PacketFunction:InvokeServer(0, {  
                            ["__args"] = { [1] = btnPart },  
                            ["__tree"] = { [1] = "PuzzleService", [2] = "Clicked" },  
                            ["__callType"] = 0,  
                        })  
                    end)  
                    task.wait(0.12)  
                end  
                task.wait(0.3)  
            end  

            for _, conn in ipairs(connections) do  
                pcall(function() conn:Disconnect() end)  
            end  
        end)
    end
})

BellMain:Button({
    Title = "Auto Solve Door",
    Callback = function()
        task.spawn(function()
            local player = game:GetService("Players").LocalPlayer
            local char = player.Character or player.CharacterAdded:Wait()
            local hrp = char:FindFirstChild("HumanoidRootPart")

            local ReplicatedStorage = game:GetService("ReplicatedStorage")
            local PacketFunction = ReplicatedStorage:FindFirstChild("Packages") 
                and ReplicatedStorage.Packages:FindFirstChild("Packet") 
                and ReplicatedStorage.Packages.Packet:FindFirstChild("PacketFunction")

            if not PacketFunction then return end

            local doorsFolder = workspace:FindFirstChild("Section2") 
                and workspace.Section2:FindFirstChild("PuzzleDoor")
                and workspace.Section2.PuzzleDoor:FindFirstChild("Doors")

            if not doorsFolder then return end

            local targetDoor = nil
            local targetSurfaceGui = nil
            local shortestDistance = math.huge

            for _, door in ipairs(doorsFolder:GetChildren()) do
                if not SolvedDoors[door] then
                    local surfaceGui = door:FindFirstChild("Shapes", true)
                        and door:FindFirstChild("Combos", true)
                        and door:FindFirstChild("SurfaceGui", true)

                    if surfaceGui and #GetShapeNames(surfaceGui) > 0 then
                        local doorCFrame = door.PrimaryPart and door.PrimaryPart.CFrame or door:GetPivot()
                        local dist = (hrp.Position - doorCFrame.Position).Magnitude

                        if dist < shortestDistance then
                            shortestDistance = dist
                            targetDoor = door
                            targetSurfaceGui = surfaceGui
                        end
                    end
                end
            end

            if not targetDoor then
                if LastValidDoor then
                    targetDoor = LastValidDoor
                    targetSurfaceGui = LastValidDoor:FindFirstChild("Shapes", true)
                        and LastValidDoor:FindFirstChild("Combos", true)
                        and LastValidDoor:FindFirstChild("SurfaceGui", true)
                else
                    for _, door in ipairs(doorsFolder:GetChildren()) do
                        local surfaceGui = door:FindFirstChild("Shapes", true)
                            and door:FindFirstChild("Combos", true)
                            and door:FindFirstChild("SurfaceGui", true)

                        if surfaceGui and #GetShapeNames(surfaceGui) > 0 then
                            targetDoor = door
                            targetSurfaceGui = surfaceGui
                            break
                        end
                    end
                end
            end

            if not targetDoor or not targetSurfaceGui then return end

            SolvedDoors[targetDoor] = true
            LastValidDoor = targetDoor

            local targetCFrame = targetDoor.PrimaryPart and targetDoor.PrimaryPart.CFrame or targetDoor:GetPivot()
            if hrp and targetCFrame then
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
                hrp.CFrame = targetCFrame + Vector3.new(0, 3, 5)
            end

            task.wait(0.5)

            local prompt = targetDoor:FindFirstChildWhichIsA("ProximityPrompt", true)
            if prompt then
                prompt.Enabled = true
                if fireproximityprompt then
                    pcall(function() fireproximityprompt(prompt) end)
                else
                    pcall(function()
                        prompt:InputHoldBegin()
                        prompt:InputHoldEnd()
                    end)
                end
            end

            local shapes1 = GetShapeNames(targetSurfaceGui)
            if #shapes1 > 0 then
                pcall(function()
                    PacketFunction:InvokeServer(0, {
                        ["__args"] = { [1] = shapes1 },
                        ["__tree"] = { [1] = "DoorPuzzleService", [2] = "Clicked" },
                        ["__callType"] = 0
                    })
                end)
            end

            task.wait(0.5)

            local shapes2 = GetShapeNames(targetSurfaceGui)
            if #shapes2 > 0 then
                pcall(function()
                    PacketFunction:InvokeServer(0, {
                        ["__args"] = { [1] = shapes2 },
                        ["__tree"] = { [1] = "DoorPuzzleService", [2] = "Clicked" },
                        ["__callType"] = 0
                    })
                end)
            end
        end)
    end
})

BellChase:Button({
    Title = "Auto Win",
    Callback = function()
        task.spawn(function()
            local player = game:GetService("Players").LocalPlayer
            local char = player.Character or player.CharacterAdded:Wait()
            local hrp = char:FindFirstChild("HumanoidRootPart")

            local section2_5 = workspace:FindFirstChild("Section2.5")
            local chaseSequence = section2_5 and section2_5:FindFirstChild("ChaseSequence")
            local endChase = chaseSequence and chaseSequence:FindFirstChild("EndChase")

            if endChase and hrp then
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
                local targetCFrame = endChase:IsA("Model") and endChase:GetPivot() or endChase.CFrame
                hrp.CFrame = targetCFrame + Vector3.new(0, 3, 0)
            end
        end)
    end
})

local BellESP = BellStage:CreateSubTab({ Title = "ESP", Icon = "eye" })

local ESPConfig = { Flies = false, Dodomeki = false, Bells = false }
local activeHighlights = {}
local activeBillboards = {}
local activeTextLabels = {}
local espConnections = {}
local updateConnection = nil
local lastUpdate = 0

local function clearAllESP()
    for obj, hl in pairs(activeHighlights) do pcall(function() hl:Destroy() end) end
    for obj, bb in pairs(activeBillboards) do pcall(function() bb:Destroy() end) end
    table.clear(activeHighlights)
    table.clear(activeBillboards)
    table.clear(activeTextLabels)
    for _, conn in ipairs(espConnections) do pcall(function() conn:Disconnect() end) end
    table.clear(espConnections)
    if updateConnection then updateConnection:Disconnect() updateConnection = nil end
end

local function removeESP(obj)
    if activeHighlights[obj] then
        pcall(function() activeHighlights[obj]:Destroy() end)
        activeHighlights[obj] = nil
    end
    if activeBillboards[obj] then
        pcall(function() activeBillboards[obj]:Destroy() end)
        activeBillboards[obj] = nil
    end
    if activeTextLabels[obj] then
        activeTextLabels[obj] = nil
    end
end

local function applyESP(obj, name, color, withText)
    if not obj or activeHighlights[obj] or not (obj:IsA("Model") or obj:IsA("BasePart")) then return end
    
    local part = obj:IsA("BasePart") and obj or obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart", true)
    if not part then return end

    local hl = Instance.new("Highlight")
    hl.Name = "KazeESP"
    hl.FillColor = color
    hl.OutlineColor = Color3.fromRGB(255, 255, 255)
    hl.FillTransparency = 0.5
    hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Adornee = obj
    hl.Parent = obj
    activeHighlights[obj] = hl

    if withText then
        local bb = Instance.new("BillboardGui")
        bb.Name = "KazeESPTxt"
        bb.Size = UDim2.new(0, 200, 0, 50)
        bb.StudsOffset = Vector3.new(0, 3, 0)
        bb.AlwaysOnTop = true
        bb.Parent = part
        activeBillboards[obj] = bb

        local tl = Instance.new("TextLabel")
        tl.Size = UDim2.new(1, 0, 1, 0)
        tl.BackgroundTransparency = 1
        tl.TextStrokeTransparency = 0
        tl.TextColor3 = color
        tl.TextSize = 13
        tl.Font = Enum.Font.FredokaOne
        tl.Text = name
        tl.Parent = bb
        activeTextLabels[obj] = tl
    end
end

local function setupFlies()
    local fliesFolder = workspace:FindFirstChild("Section2") and workspace.Section2:FindFirstChild("FlyNoobs") and workspace.Section2.FlyNoobs:FindFirstChild("Flies")
    if not fliesFolder then return end

    for _, roamArea in ipairs(fliesFolder:GetChildren()) do
        if roamArea.Name == "RoamArea" then
            local model = roamArea:FindFirstChildWhichIsA("Model")
            if model and ESPConfig.Flies then
                applyESP(model, "Fly", Color3.fromRGB(255, 165, 0), true)
            end
            
            table.insert(espConnections, roamArea.ChildAdded:Connect(function(inst)
                if ESPConfig.Flies then applyESP(inst, "Fly", Color3.fromRGB(255, 165, 0), true) end
            end))
        end
    end
end

local function setupDodomeki()
    local monsterFolder = workspace:FindFirstChild("Section2") and workspace.Section2:FindFirstChild("Monster")
    if not monsterFolder then return end

    local dodomeki = monsterFolder:FindFirstChild("Dodomeki")
    if dodomeki and ESPConfig.Dodomeki then
        applyESP(dodomeki, "Dodomeki", Color3.fromRGB(255, 0, 0), true)
    end
    
    table.insert(espConnections, monsterFolder.ChildAdded:Connect(function(inst)
        if ESPConfig.Dodomeki and inst.Name == "Dodomeki" then 
            applyESP(inst, "Dodomeki", Color3.fromRGB(255, 0, 0), true) 
        end
    end))
end

local function setupBells()
    local bellsFolder = workspace:FindFirstChild("Section2") and workspace.Section2:FindFirstChild("Bells")
    if not bellsFolder then return end

    for _, bell in ipairs(bellsFolder:GetChildren()) do
        if bell:IsA("Model") and ESPConfig.Bells then
            local bellModel = bell:FindFirstChild("BellModel")
            if bellModel then
                applyESP(bellModel, bell.Name, Color3.fromRGB(255, 255, 0), false)
            end
        end
    end
    
    table.insert(espConnections, bellsFolder.ChildAdded:Connect(function(inst)
        if ESPConfig.Bells and inst:IsA("Model") then 
            local bellModel = inst:FindFirstChild("BellModel")
            if bellModel then
                applyESP(bellModel, inst.Name, Color3.fromRGB(255, 255, 0), false) 
            end
        end
    end))
end

local function updateDistances()
    local char = game.Players.LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    for obj, tl in pairs(activeTextLabels) do
        if obj and obj.Parent and tl and tl.Parent then
            local part = obj:IsA("BasePart") and obj or obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart", true)
            if part then
                local dist = math.floor((hrp.Position - part.Position).Magnitude)
                local baseName = obj:IsA("Model") and obj.Name or "Fly"
                tl.Text = baseName .. " [" .. dist .. "m]"
            end
        else
            removeESP(obj)
        end
    end
end

local function refreshAllESP()
    clearAllESP()
    
    if ESPConfig.Flies then setupFlies() end
    if ESPConfig.Dodomeki then setupDodomeki() end
    if ESPConfig.Bells then setupBells() end

    if ESPConfig.Flies or ESPConfig.Dodomeki or ESPConfig.Bells then
        updateConnection = game:GetService("RunService").Heartbeat:Connect(function()
            if tick() - lastUpdate > 0.2 then
                lastUpdate = tick()
                updateDistances()
            end
        end)
    end
end

BellESP:Toggle({
    Title = "ESP Flies",
    Default = false,
    Callback = function(state)
        ESPConfig.Flies = state
        refreshAllESP()
    end
})

BellESP:Toggle({
    Title = "ESP Dodomeki",
    Default = false,
    Callback = function(state)
        ESPConfig.Dodomeki = state
        refreshAllESP()
    end
})

BellESP:Toggle({
    Title = "ESP Bells",
    Default = false,
    Callback = function(state)
        ESPConfig.Bells = state
        refreshAllESP()
    end
})

local BellBoat = BellStage:CreateSubTab({ Title = "Boat Stage", Icon = "sailboat", Default = false })

BellBoat:Button({
    Title = "Start Enzukai",
    Callback = function()
        task.spawn(function()
            local intro = workspace:FindFirstChild("Section2.5") 
                and workspace["Section2.5"]:FindFirstChild("MindGame") 
                and workspace["Section2.5"].MindGame:FindFirstChild("Intro")
                
            local trigger1 = intro and intro:FindFirstChild("Trigger")
            local trigger2 = intro and intro:FindFirstChild("Trigger2")
                
            local char = game.Players.LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            
            if hrp and firetouchinterest then
                if trigger1 then
                    firetouchinterest(hrp, trigger1, 0)
                    task.wait(0.1)
                    firetouchinterest(hrp, trigger1, 1)
                end
                
                task.wait(0.5)
                
                if trigger2 then
                    firetouchinterest(hrp, trigger2, 0)
                    task.wait(0.1)
                    firetouchinterest(hrp, trigger2, 1)
                end
            end
        end)
    end
})

local autoEnzukaiTask = nil

BellBoat:Toggle({
    Title = "Auto Enzukai",
    Default = false,
    Callback = function(Value)
        if autoEnzukaiTask then
            task.cancel(autoEnzukaiTask)
            autoEnzukaiTask = nil
        end

        if not Value then return end

        autoEnzukaiTask = task.spawn(function()
            while Value do
                local player = game.Players.LocalPlayer
                local section = workspace:FindFirstChild("Section2.5")
                local mindGame = section and section:FindFirstChild("MindGame")
                local boats = mindGame and mindGame:FindFirstChild("Boats")

                if boats then
                    for _, boat in ipairs(boats:GetChildren()) do
                        local assigned = boat:FindFirstChild("AssignedPlayer")
                        if assigned and assigned.Value == player then
                            local enzukai = boat:FindFirstChild("EnzukaiGame")
                            if enzukai then
                                local root = enzukai:FindFirstChild("RootPart")
                                if root then
                                    local attachment = root:FindFirstChild("PromptAttachment")
                                    local prompt = attachment and attachment:FindFirstChild("ProximityPrompt")
                                    
                                    if prompt and prompt.Parent and prompt.Enabled then
                                        pcall(function()
                                            fireproximityprompt(prompt)
                                        end)
                                    end
                                end
                            end
                            break
                        end
                    end
                end
                task.wait(0.1) 
            end
        end)
    end
})

local FatherStage = Window:CreateTab({
    Title = "Father Stage",
    Icon = "house"
})

local FatherMain = FatherStage:CreateSubTab({ Title = "Main", Icon = "house", Default = true })
local FatherTrain = FatherStage:CreateSubTab({ Title = "Train", Icon = "tram-front", Default = false })

FatherMain:Button({
    Title = "Safe Zone",
    Callback = function()
        task.spawn(function()
            local char = game.Players.LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
                hrp.CFrame = CFrame.new(1137.72, 28.66, -2401.24)
            end
        end)
    end
})

local antiIsamuConn = nil

FatherMain:Toggle({
    Title = "Anti Isamu",
    Default = false,
    Callback = function(Value)
        if antiIsamuConn then
            antiIsamuConn:Disconnect()
            antiIsamuConn = nil
        end

        if Value then
            task.spawn(function()
                local section3 = workspace:WaitForChild("Section3", 10)
                local isamu = section3 and section3:WaitForChild("IsamuAI", 10)
                local hitbox = isamu and isamu:WaitForChild("Hitbox", 10)

                if hitbox then
                    hitbox.CanTouch = false
                    -- Event-driven: Only fires if the game tries to turn it back on
                    antiIsamuConn = hitbox:GetPropertyChangedSignal("CanTouch"):Connect(function()
                        if hitbox.CanTouch then
                            hitbox.CanTouch = false
                        end
                    end)
                end
            end)
        end
    end
})

FatherMain:Divider("")

local autoWinEnabled = false
local autoWinTask = nil

FatherMain:Toggle({
    Title = "Auto Perfect Minigame",
    Default = false,
    Callback = function(state)
        autoWinEnabled = state
        
        if autoWinTask then
            task.cancel(autoWinTask)
            autoWinTask = nil
        end

        if not autoWinEnabled then return end

        local VirtualInputManager = game:GetService("VirtualInputManager")
        local VirtualUser = game:GetService("VirtualUser")
        local playerGui = game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui")
        local RunService = game:GetService("RunService")

        autoWinTask = task.spawn(function()
            while autoWinEnabled do
                local gui = playerGui:FindFirstChild("03_SkillCheck")
                
                if gui and gui.Enabled then
                    local handler = gui:FindFirstChild("Handler")
                    local holder = handler and handler:FindFirstChild("Holder")
                    local objects = holder and holder:FindFirstChild("Objects") 
                                 or handler and handler:FindFirstChild("Objects")
                                 or gui:FindFirstChild("Objects", true)
                    
                    if objects then
                        for _, obj in ipairs(objects:GetChildren()) do
                            if obj:IsA("Frame") and not obj:GetAttribute("Destroying") then
                                local x = obj:GetAttribute("X")
                                if x and x >= 4.0 and x <= 6.0 then
                                    pcall(function()
                                        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
                                        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
                                    end)
                                    
                                    pcall(function()
                                        VirtualUser:CaptureController()
                                        VirtualUser:Button1Down(Vector2.new(0.5, 0.5), workspace.CurrentCamera.CFrame)
                                        VirtualUser:Button1Up(Vector2.new(0.5, 0.5), workspace.CurrentCamera.CFrame)
                                    end)
                                    break
                                end
                            end
                        end
                    end
                end
                
                RunService.Heartbeat:Wait()
            end
        end)
    end
})

local autoCleanConn = nil
local lastCleanCheck = 0

FatherMain:Toggle({
    Title = "Auto Clean Dirt",
    Default = false,
    Callback = function(state)
        if autoCleanConn then
            autoCleanConn:Disconnect()
            autoCleanConn = nil
        end

        if not state then return end

        autoCleanConn = game:GetService("RunService").Heartbeat:Connect(function()
            -- Throttle to check only 0.2s (5 times a second) to prevent lag
            if tick() - lastCleanCheck < 0.2 then return end
            lastCleanCheck = tick()

            local char = game.Players.LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end

            local chores = workspace:FindFirstChild("Section3") and workspace.Section3:FindFirstChild("Chores")
            local sweeping = chores and chores:FindFirstChild("Sweeping")
            
            if sweeping then
                for _, dirt in ipairs(sweeping:GetChildren()) do
                    if dirt.Name == "Dirt" then
                        local part = dirt:IsA("BasePart") and dirt or dirt:FindFirstChildWhichIsA("BasePart", true)
                        if part and (hrp.Position - part.Position).Magnitude <= 15 then
                            local prompt = dirt:FindFirstChildWhichIsA("ProximityPrompt", true)
                            if prompt and prompt.Enabled then
                                pcall(function()
                                    fireproximityprompt(prompt)
                                end)
                            end
                        end
                    end
                end
            end
        end)
    end
})

FatherMain:Button({
    Title = "Pray",
    Callback = function()
        task.spawn(function()
            local chores = workspace:FindFirstChild("Section3") and workspace.Section3:FindFirstChild("Chores")
            local prayPillow = chores and chores:FindFirstChild("Pray") and chores.Pray:FindFirstChild("PrayPillow")
            
            local char = game.Players.LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            
            if prayPillow and hrp then
                local targetPart = prayPillow:IsA("BasePart") and prayPillow or prayPillow:FindFirstChildWhichIsA("BasePart", true)
                local prompt = prayPillow:FindFirstChildWhichIsA("ProximityPrompt", true)
                
                if targetPart then
                    hrp.AssemblyLinearVelocity = Vector3.zero
                    hrp.AssemblyAngularVelocity = Vector3.zero
                    hrp.CFrame = targetPart.CFrame + Vector3.new(0, 3, 0)
                    task.wait(0.3)
                    
                    if prompt and prompt.Enabled then
                        pcall(function()
                            fireproximityprompt(prompt)
                        end)
                    end
                end
            end
        end)
    end
})

FatherTrain:Button({
    Title = "Trigger Train",
    Callback = function()
        task.spawn(function()
            local char = game.Players.LocalPlayer.Character or game.Players.LocalPlayer.CharacterAdded:Wait()
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end

            local stage = workspace:FindFirstChild("Section3.5")
            local crowbarSpot = stage and stage:FindFirstChild("GrabCrowBarCutscene") and stage.GrabCrowBarCutscene:FindFirstChild("crowbar")
            local fence = stage and stage:FindFirstChild("GrabCrowBarCutscene") and stage.GrabCrowBarCutscene:FindFirstChild("WoodenFence")
            local trainTrigger = stage and stage:FindFirstChild("GhostTrain") and stage.GhostTrain:FindFirstChild("TrainTrigger")

            local function GetPart(obj)
                if not obj then return nil end
                if obj:IsA("BasePart") then return obj end
                return obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart", true)
            end

            local crowbarPart = GetPart(crowbarSpot)
            local fencePart = GetPart(fence)
            local triggerPart = GetPart(trainTrigger)

            if not crowbarPart or not fencePart or not triggerPart then return end

            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
            hrp.CFrame = crowbarPart.CFrame + Vector3.new(0, 5, 0)
            task.wait(0.3)

            local crowbar
            local timeout = tick() + 10
            repeat
                crowbar = game.Players.LocalPlayer.Backpack:FindFirstChild("Crowbar") or char:FindFirstChild("Crowbar")
                task.wait(0.1)
            until crowbar or tick() > timeout

            if not crowbar then return end

            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
            hrp.CFrame = fencePart.CFrame + Vector3.new(0, 5, 0)
            task.wait(0.3)

            if crowbar.Parent == game.Players.LocalPlayer.Backpack then
                char.Humanoid:EquipTool(crowbar)
            end
            task.wait(0.2)

            local equippedCrowbar = char:FindFirstChild("Crowbar")
            if equippedCrowbar then
                local activate = equippedCrowbar:FindFirstChildWhichIsA("RemoteEvent", true)
                local remoteFunction = equippedCrowbar:FindFirstChildWhichIsA("RemoteFunction", true)

                if activate then
                    pcall(function() activate:FireServer() end)
                elseif remoteFunction then
                    pcall(function() remoteFunction:InvokeServer() end)
                else
                    pcall(function() equippedCrowbar:Activate() end)
                end
            end

            task.wait(0.5)

            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
            hrp.CFrame = triggerPart.CFrame + Vector3.new(0, 5, 0)
        end)
    end
})

local LarvasTab = Window:CreateTab({
    Title = "Larvas Stage",
    Icon = "bug"
})

local LarvasMain = LarvasTab:CreateSubTab({ Title = "Larva Stage", Icon = "bug", Default = true })
local LarvasMud = LarvasTab:CreateSubTab({ Title = "Mud Stage", Icon = "droplet", Default = false })

LarvasMain:Button({
    Title = "Auto Collect",
    Callback = function()
        task.spawn(function()
            local Players = game:GetService("Players")
            local LocalPlayer = Players.LocalPlayer
            local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end

            local section4 = workspace:FindFirstChild("Section4")
            local hotPotato = section4 and section4:FindFirstChild("HotPotato")
            local givers = hotPotato and hotPotato:FindFirstChild("Givers")
            local dogWall = section4 and section4:FindFirstChild("DogWall")
            
            if not givers or not dogWall then return end

            local function GetPart(obj)
                if obj:IsA("BasePart") then return obj end
                return obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart", true)
            end

            local function GetPrompt(obj)
                return obj:FindFirstChildWhichIsA("ProximityPrompt", true)
            end

            while true do
                local dogPrompt = GetPrompt(dogWall)
                if not dogPrompt or not dogPrompt.Enabled then break end

                local giverFound = false

                for _, giver in ipairs(givers:GetChildren()) do
                    if giver:IsA("Model") then
                        local giverPart = GetPart(giver)
                        local giverPrompt = GetPrompt(giver)

                        if giverPart and giverPrompt and giverPrompt.Enabled then
                            giverFound = true

                            hrp.AssemblyLinearVelocity = Vector3.zero
                            hrp.AssemblyAngularVelocity = Vector3.zero
                            hrp.CFrame = giverPart.CFrame + Vector3.new(0, 3, 0)
                            task.wait(0.2)

                            pcall(function() fireproximityprompt(giverPrompt) end)
                            task.wait(0.2)

                            local currentDogPrompt = GetPrompt(dogWall)
                            if not currentDogPrompt or not currentDogPrompt.Enabled then break end

                            hrp.AssemblyLinearVelocity = Vector3.zero
                            hrp.AssemblyAngularVelocity = Vector3.zero
                            hrp.CFrame = CFrame.new(1930, 24, 4657)
                            task.wait(0.2)

                            pcall(function() fireproximityprompt(currentDogPrompt) end)
                            task.wait(0.2)
                            
                            if not GetPrompt(dogWall) then break end
                        end
                    end
                end

                if not giverFound then break end
                task.wait(0.1)
            end
        end)
    end
})

LarvasMain:Button({
    Title = "Enter Door",
    Callback = function()
        task.spawn(function()
            local char = game.Players.LocalPlayer.Character or game.Players.LocalPlayer.CharacterAdded:Wait()
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end

            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
            hrp.CFrame = CFrame.new(1930, 24, 4657)
            task.wait(0.3)

            local door = workspace:FindFirstChild("Section4") and workspace.Section4:FindFirstChild("Door")
            if door then
                local prompt = door:FindFirstChildWhichIsA("ProximityPrompt", true)
                if prompt and prompt.Enabled then
                    pcall(function()
                        fireproximityprompt(prompt)
                    end)
                end
            end
        end)
    end
})

local LarvasESP = LarvasTab:CreateSubTab({ Title = "ESP", Icon = "eye", Default = false })

local ESPConfig = { Givers = false, Boogeyman = false }
local activeHighlights = {}
local activeBillboards = {}
local activeTextLabels = {}
local espConnections = {}
local updateConnection = nil
local lastUpdate = 0

local function clearAllESP()
    for obj, hl in pairs(activeHighlights) do pcall(function() hl:Destroy() end) end
    for obj, bb in pairs(activeBillboards) do pcall(function() bb:Destroy() end) end
    table.clear(activeHighlights)
    table.clear(activeBillboards)
    table.clear(activeTextLabels)
    for _, conn in ipairs(espConnections) do pcall(function() conn:Disconnect() end) end
    table.clear(espConnections)
    if updateConnection then updateConnection:Disconnect() updateConnection = nil end
end

local function removeESP(obj)
    if activeHighlights[obj] then
        pcall(function() activeHighlights[obj]:Destroy() end)
        activeHighlights[obj] = nil
    end
    if activeBillboards[obj] then
        pcall(function() activeBillboards[obj]:Destroy() end)
        activeBillboards[obj] = nil
    end
    if activeTextLabels[obj] then
        activeTextLabels[obj] = nil
    end
end

local function applyESP(obj, name, color, withText)
    if not obj or activeHighlights[obj] or not (obj:IsA("Model") or obj:IsA("BasePart")) then return end
    
    local part = obj:IsA("BasePart") and obj or obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart", true)
    if not part then return end

    local hl = Instance.new("Highlight")
    hl.Name = "KazeESP"
    hl.FillColor = color
    hl.OutlineColor = Color3.fromRGB(255, 255, 255)
    hl.FillTransparency = 0.5
    hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Adornee = obj
    hl.Parent = obj
    activeHighlights[obj] = hl

    if withText then
        local bb = Instance.new("BillboardGui")
        bb.Name = "KazeESPTxt"
        bb.Size = UDim2.new(0, 200, 0, 50)
        bb.StudsOffset = Vector3.new(0, 3, 0)
        bb.AlwaysOnTop = true
        bb.Parent = part
        activeBillboards[obj] = bb

        local tl = Instance.new("TextLabel")
        tl.Size = UDim2.new(1, 0, 1, 0)
        tl.BackgroundTransparency = 1
        tl.TextStrokeTransparency = 0
        tl.TextColor3 = color
        tl.TextSize = 13
        tl.Font = Enum.Font.FredokaOne
        tl.Text = name
        tl.Parent = bb
        activeTextLabels[obj] = tl
    end
end

local function setupGivers()
    local section4 = workspace:FindFirstChild("Section4")
    local hotPotato = section4 and section4:FindFirstChild("HotPotato")
    local givers = hotPotato and hotPotato:FindFirstChild("Givers")
    if not givers then return end

    for _, giver in ipairs(givers:GetChildren()) do
        if giver:IsA("Model") and ESPConfig.Givers then
            applyESP(giver, "Giver", Color3.fromRGB(0, 255, 0), false)
        end
    end
    
    table.insert(espConnections, givers.ChildAdded:Connect(function(inst)
        if ESPConfig.Givers and inst:IsA("Model") then
            applyESP(inst, "Giver", Color3.fromRGB(0, 255, 0), false)
        end
    end))
end

local function setupBoogeyman()
    local section4 = workspace:FindFirstChild("Section4")
    local monster = section4 and section4:FindFirstChild("Monster")
    if not monster then return end

    local boogeyman = monster:FindFirstChild("BoogeymanAI")
    if boogeyman and ESPConfig.Boogeyman then
        applyESP(boogeyman, "Boogeyman", Color3.fromRGB(255, 0, 0), true)
    end
    
    table.insert(espConnections, monster.ChildAdded:Connect(function(inst)
        if ESPConfig.Boogeyman and inst.Name == "BoogeymanAI" then 
            applyESP(inst, "Boogeyman", Color3.fromRGB(255, 0, 0), true) 
        end
    end))
end

local function updateDistances()
    local char = game.Players.LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    for obj, tl in pairs(activeTextLabels) do
        if obj and obj.Parent and tl and tl.Parent then
            local part = obj:IsA("BasePart") and obj or obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart", true)
            if part then
                local dist = math.floor((hrp.Position - part.Position).Magnitude)
                local baseName = obj.Name
                tl.Text = baseName .. " [" .. dist .. "m]"
            end
        else
            removeESP(obj)
        end
    end
end

local function refreshAllESP()
    clearAllESP()
    if ESPConfig.Givers then setupGivers() end
    if ESPConfig.Boogeyman then setupBoogeyman() end

    if ESPConfig.Givers or ESPConfig.Boogeyman then
        updateConnection = game:GetService("RunService").Heartbeat:Connect(function()
            if tick() - lastUpdate > 0.2 then
                lastUpdate = tick()
                updateDistances()
            end
        end)
    end
end

LarvasESP:Toggle({
    Title = "ESP Larvas",
    Default = false,
    Callback = function(state)
        ESPConfig.Givers = state
        refreshAllESP()
    end
})

LarvasESP:Toggle({
    Title = "ESP Boogeyman",
    Default = false,
    Callback = function(state)
        ESPConfig.Boogeyman = state
        refreshAllESP()
    end
})

LarvasMud:Button({
    Title = "Auto Win",
    Callback = function()
        task.spawn(function()
            local teleportPart = workspace:FindFirstChild("Section4.5") and workspace["Section4.5"]:FindFirstChild("TeleportToSection5")
            local char = game.Players.LocalPlayer.Character or game.Players.LocalPlayer.CharacterAdded:Wait()
            local hrp = char:FindFirstChild("HumanoidRootPart")
            
            if teleportPart and hrp and firetouchinterest then
                firetouchinterest(hrp, teleportPart, 0)
                task.wait(0.1)
                firetouchinterest(hrp, teleportPart, 1)
            end
        end)
    end
})

local YureiStage = Window:CreateTab({
    Title = "Yurei Stage",
    Icon = "rose"
})

local YureiIspy = YureiStage:CreateSubTab({ Title = "Yurei", Icon = "rose", Default = true })

local SelectedHouse = nil
local HouseMap = {}

local RomanNumerals = {
    [1] = "House I", [2] = "House II", [3] = "House III", [4] = "House IV", [5] = "House V"
}

local function RefreshHouses()
    local section5 = workspace:FindFirstChild("Section5")
    local ispy = section5 and section5:FindFirstChild("ISPY")
    local housesFolder = ispy and ispy:FindFirstChild("Houses")

    HouseMap = {}
    local options = {}

    for i = 1, 5 do
        local label = RomanNumerals[i]
        table.insert(options, { Text = label, Icon = "house" })

        if housesFolder then
            local house = housesFolder:FindFirstChild("House" .. i)
            if house then
                HouseMap[label] = house
            end
        end
    end
    return options
end

local function GetHouseTarget(house)
    local playerObj = house:FindFirstChild("Player")
    local target = playerObj and playerObj:FindFirstChild("HumanoidRootPart") or playerObj
    if not target then return nil end
    if target:IsA("BasePart") then return target.CFrame end
    if target:IsA("Model") then return target:GetPivot() end
    local part = target:FindFirstChildWhichIsA("BasePart", true)
    return part and part.CFrame
end

YureiIspy:BoxDropdown({
    Title = "Houses",
    SearchBar = true,
    Options = RefreshHouses(),
    Default = "Select House",
    Callback = function(value)
        SelectedHouse = value
    end
})

YureiIspy:Button({
    Title = "Teleport",
    Callback = function()
        if not SelectedHouse or SelectedHouse == "Select House" then return end
        task.spawn(function()
            RefreshHouses()
            local house = HouseMap[SelectedHouse]
            if not house then return end
            local hrp = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            local targetCFrame = GetHouseTarget(house)
            if hrp and targetCFrame then
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
                hrp.CFrame = targetCFrame + Vector3.new(0, 3, 0)
            end
        end)
    end
})

YureiIspy:Button({
    Title = "Solve",
    Callback = function()
        if not SelectedHouse or SelectedHouse == "Select House" then return end
        task.spawn(function()
            RefreshHouses()
            local house = HouseMap[SelectedHouse]
            if not house then return end

            local hrp = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if not hrp then return end

            local prompt = house:FindFirstChildWhichIsA("ProximityPrompt", true)
            if not prompt then return end

            if (hrp.Position - prompt.Parent.Position).Magnitude > 10 then
                local targetCFrame = GetHouseTarget(house)
                if targetCFrame then
                    hrp.AssemblyLinearVelocity = Vector3.zero
                    hrp.AssemblyAngularVelocity = Vector3.zero
                    hrp.CFrame = targetCFrame + Vector3.new(0, 3, 0)
                    task.wait(0.2)
                end
            end

            local playerGui = game.Players.LocalPlayer:WaitForChild("PlayerGui")
            local section5Gui = playerGui:FindFirstChild("Section5")
            local textLabel = section5Gui and section5Gui:FindFirstChild("TextLabel")
            if not textLabel then return end

            local initialText = textLabel.Text
            prompt.Enabled = true
            pcall(function() fireproximityprompt(prompt) end)

            local startTime = tick()
            while (textLabel.Text == initialText or textLabel.Text == "") and tick() - startTime < 3 do
                game:GetService("RunService").Heartbeat:Wait()
            end

            local rawText = textLabel.Text
            if not rawText or rawText == "" then rawText = textLabel.LocalizedText end
            if not rawText or rawText == "" then return end

            local ReplicatedStorage = game:GetService("ReplicatedStorage")
            local PacketFunction = ReplicatedStorage:FindFirstChild("Packages") 
                and ReplicatedStorage.Packages:FindFirstChild("Packet") 
                and ReplicatedStorage.Packages.Packet:FindFirstChild("PacketFunction")

            if not PacketFunction then return end

            for item in string.gmatch(rawText, "([^,]+)") do
                item = item:match("^%s*(.-)%s*$")
                if item and item ~= "" then
                    item = item:gsub("%s+", "")
                    pcall(function()
                        PacketFunction:InvokeServer(0, {
                            ["__args"] = { [1] = item },
                            ["__tree"] = { [1] = "IspyService", [2] = "Clicked" },
                            ["__callType"] = 0
                        })
                    end)
                    task.wait(0.1)
                end
            end
        end)
    end
})

local YureiBoss = YureiStage:CreateSubTab({ Title = "Yurei Final", Icon = "rose", Default = false })

local AutoYureiEnabled = false
local yureiConnection = nil

YureiBoss:Toggle({
    Title = "Auto Yurei",
    Default = false,
    Callback = function(state)
        AutoYureiEnabled = state
        if yureiConnection then
            yureiConnection:Disconnect()
            yureiConnection = nil
        end

        if not AutoYureiEnabled then return end

        local lastActionTime = 0
        local katanaIndex = 1
        local SAFE_CFRAME = CFrame.new(3053.23, -52.22, -430.15)
        local FALLBACK_CFRAME = CFrame.new(3132, 17, -582)
        local MESH_SAFE_DISTANCE = 40
        local PATH_SAFE_DISTANCE = 35

        local function getCharacter()
            local char = game.Players.LocalPlayer.Character or game.Players.LocalPlayer.CharacterAdded:Wait()
            return char, char:FindFirstChild("HumanoidRootPart"), char:FindFirstChildOfClass("Humanoid")
        end

        local function getKatanas()
            local list = {}
            local backpack = game.Players.LocalPlayer:FindFirstChild("Backpack")
            local char = game.Players.LocalPlayer.Character
            for _, container in ipairs({backpack, char}) do
                if container then
                    for _, tool in ipairs(container:GetChildren()) do
                        if tool:IsA("Tool") and string.find(tool.Name, "Katana") then
                            table.insert(list, tool)
                        end
                    end
                end
            end
            return list
        end

        local function getYurei()
            local s5 = workspace:FindFirstChild("Section5")
            local boss = s5 and s5:FindFirstChild("Boss")
            local folder = boss and boss:FindFirstChild("MonsterFolder")
            if not folder then return nil end
            return folder:FindFirstChild("Yurei") or folder:FindFirstChild("YureiNM")
        end

        local function getYureiHitbox()
            local yurei = getYurei()
            if not yurei then return nil end
            return yurei:FindFirstChild("YureiHitbox", true) or yurei:FindFirstChildWhichIsA("BasePart", true)
        end

        local function getYureiPosition()
            local yurei = getYurei()
            if not yurei then return nil end
            if yurei:IsA("Model") then return yurei:GetBoundingBox().Position end
            local root = yurei:FindFirstChild("HumanoidRootPart") or yurei.PrimaryPart or yurei:FindFirstChildWhichIsA("BasePart", true)
            return root and root.Position
        end

        local function isSpecialAttackActive()
            local s5 = workspace:FindFirstChild("Section5")
            local boss = s5 and s5:FindFirstChild("Boss")
            local attack = boss and boss:FindFirstChild("SpecialAttack1")
            if not attack then return false end
            for _, obj in ipairs(attack:GetDescendants()) do
                if obj:IsA("BasePart") and obj:FindFirstChild("TouchInterest") then
                    return true
                end
            end
            return false
        end

        local function handleSafety(hrp)
            if isSpecialAttackActive() then
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
                hrp.CFrame = SAFE_CFRAME
                hrp.Anchored = true
                return true
            else
                hrp.Anchored = false
                return false
            end
        end

        local function isPathSafe(startPos, endPos, yureiPos)
            if not yureiPos then return true end
            local pathDir = (endPos - startPos)
            local pathLength = pathDir.Magnitude
            if pathLength < 0.1 then return true end
            pathDir = pathDir.Unit
            
            local toYurei = yureiPos - startPos
            local projectionLength = toYurei:Dot(pathDir)
            
            if projectionLength < 0 or projectionLength > pathLength then
                return true
            end
            
            local closestPoint = startPos + (pathDir * projectionLength)
            local distanceToYurei = (yureiPos - closestPoint).Magnitude
            
            return distanceToYurei > PATH_SAFE_DISTANCE
        end

        yureiConnection = game:GetService("RunService").Heartbeat:Connect(function()
            if not AutoYureiEnabled then return end
            if tick() - lastActionTime < 0.1 then return end
            lastActionTime = tick()

            local char, hrp, humanoid = getCharacter()
            if not hrp or not humanoid then return end

            if handleSafety(hrp) then return end

            local katanas = getKatanas()

            if #katanas < 3 then
                local s5 = workspace:FindFirstChild("Section5")
                local boss = s5 and s5:FindFirstChild("Boss")
                local folder = boss and boss:FindFirstChild("Katanas")
                
                local yureiPos = getYureiPosition()
                local foundKatana = false

                if folder then
                    local meshes = folder:GetChildren()
                    if #meshes > 0 then
                        if katanaIndex > #meshes then katanaIndex = 1 end
                        
                        local checked = 0
                        while checked < #meshes do
                            local candidate = meshes[katanaIndex]
                            katanaIndex += 1
                            if katanaIndex > #meshes then katanaIndex = 1 end
                            checked += 1

                            if candidate and candidate.Parent then
                                local part = candidate:IsA("BasePart") and candidate or candidate:FindFirstChildWhichIsA("BasePart", true)
                                if part and part.Transparency == 0 then
                                    local isSafe = true
                                    
                                    if yureiPos and (part.Position - yureiPos).Magnitude <= MESH_SAFE_DISTANCE then
                                        isSafe = false
                                    end
                                    
                                    if isSafe and not isPathSafe(hrp.Position, part.Position, yureiPos) then
                                        isSafe = false
                                    end

                                    if isSafe then
                                        local prompt = candidate:FindFirstChildWhichIsA("ProximityPrompt", true)
                                        if prompt and prompt.Enabled then
                                            foundKatana = true
                                            hrp.AssemblyLinearVelocity = Vector3.zero
                                            hrp.AssemblyAngularVelocity = Vector3.zero
                                            hrp.CFrame = part.CFrame
                                            
                                            task.wait(0.1)
                                            
                                            pcall(function() fireproximityprompt(prompt) end)
                                            break
                                        end
                                    end
                                end
                            end
                        end
                    end
                end

                if not foundKatana then
                    hrp.AssemblyLinearVelocity = Vector3.zero
                    hrp.AssemblyAngularVelocity = Vector3.zero
                    hrp.CFrame = FALLBACK_CFRAME
                end
            else
                local yurei = getYurei()
                local hitbox = getYureiHitbox()

                if yurei and hitbox then
                    for _, katana in ipairs(katanas) do
                        if not AutoYureiEnabled then break end
                        if handleSafety(hrp) then break end

                        if katana and katana.Parent then
                            humanoid:EquipTool(katana)
                            task.wait(0.05)

                            local remote = katana:FindFirstChildWhichIsA("RemoteEvent", true)
                            if not remote then
                                local equipped = char:FindFirstChild("Katana")
                                if equipped then remote = equipped:FindFirstChildWhichIsA("RemoteEvent", true) end
                            end

                            if remote then
                                local yureiPos = yurei:IsA("Model") and yurei:GetBoundingBox().Position or hitbox.Position
                                
                                local direction = hrp.Position - yureiPos
                                direction = direction.Magnitude < 0.01 and Vector3.new(0, 0, -1) or direction.Unit

                                local safePos = yureiPos + direction * 50
                                safePos = Vector3.new(safePos.X, hrp.Position.Y, safePos.Z)

                                local aimPos = Vector3.new(hitbox.Position.X, safePos.Y, hitbox.Position.Z)
                                local perfectAim = CFrame.lookAt(safePos, aimPos, Vector3.yAxis)

                                hrp.AssemblyLinearVelocity = Vector3.zero
                                hrp.AssemblyAngularVelocity = Vector3.zero
                                hrp.CFrame = perfectAim

                                pcall(function() remote:FireServer(perfectAim) end)
                            end
                        end
                    end
                end
            end
        end)
    end
})

YureiBoss:Button({
    Title = "Enter Tree Door",
    Callback = function()
        task.spawn(function()
            local portal = workspace:FindFirstChild("Section5") 
                and workspace.Section5:FindFirstChild("Boss") 
                and workspace.Section5.Boss:FindFirstChild("DeathAnimation") 
                and workspace.Section5.Boss.DeathAnimation:FindFirstChild("TreePortal") 
                and workspace.Section5.Boss.DeathAnimation.TreePortal:FindFirstChild("Part")
                
            local hrp = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            
            if portal and hrp then
                local prompt = portal:FindFirstChildWhichIsA("ProximityPrompt", true)
                if prompt and prompt.Enabled then
                    hrp.AssemblyLinearVelocity = Vector3.zero
                    hrp.AssemblyAngularVelocity = Vector3.zero
                    hrp.CFrame = portal.CFrame
                    task.wait(0.1)
                    pcall(function() 
                        fireproximityprompt(prompt) 
                    end)
                end
            end
        end)
    end
})

local YureiESP = YureiStage:CreateSubTab({ Title = "ESP", Icon = "eye", Default = false })

local ESPConfig = { Houses = false, Statues = false }
local activeHighlights = {}
local activeBillboards = {}
local activeTextLabels = {}
local espConnections = {}
local updateConnection = nil
local lastUpdate = 0

local function clearAllESP()
    for obj, hl in pairs(activeHighlights) do pcall(function() hl:Destroy() end) end
    for obj, bb in pairs(activeBillboards) do pcall(function() bb:Destroy() end) end
    table.clear(activeHighlights)
    table.clear(activeBillboards)
    table.clear(activeTextLabels)
    for _, conn in ipairs(espConnections) do pcall(function() conn:Disconnect() end) end
    table.clear(espConnections)
    if updateConnection then updateConnection:Disconnect() updateConnection = nil end
end

local function removeESP(obj)
    if activeHighlights[obj] then
        pcall(function() activeHighlights[obj]:Destroy() end)
        activeHighlights[obj] = nil
    end
    if activeBillboards[obj] then
        pcall(function() activeBillboards[obj]:Destroy() end)
        activeBillboards[obj] = nil
    end
    if activeTextLabels[obj] then
        activeTextLabels[obj] = nil
    end
end

local function applyESP(obj, name, color, withText)
    if not obj or activeHighlights[obj] or not (obj:IsA("Model") or obj:IsA("BasePart")) then return end
    
    local part = obj:IsA("BasePart") and obj or obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart", true)
    if not part then return end

    local hl = Instance.new("Highlight")
    hl.Name = "KazeESP"
    hl.FillColor = color
    hl.OutlineColor = Color3.fromRGB(255, 255, 255)
    hl.FillTransparency = 0.5
    hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Adornee = obj
    hl.Parent = obj
    activeHighlights[obj] = hl

    if withText then
        local bb = Instance.new("BillboardGui")
        bb.Name = "KazeESPTxt"
        bb.Size = UDim2.new(0, 200, 0, 50)
        bb.StudsOffset = Vector3.new(0, 3, 0)
        bb.AlwaysOnTop = true
        bb.Parent = part
        activeBillboards[obj] = bb

        local tl = Instance.new("TextLabel")
        tl.Size = UDim2.new(1, 0, 1, 0)
        tl.BackgroundTransparency = 1
        tl.TextStrokeTransparency = 0
        tl.TextColor3 = color
        tl.TextSize = 13
        tl.Font = Enum.Font.FredokaOne
        tl.Text = name
        tl.Parent = bb
        activeTextLabels[obj] = tl
    end
end

local function setupHouses()
    local section5 = workspace:FindFirstChild("Section5")
    local ispy = section5 and section5:FindFirstChild("ISPY")
    local housesFolder = ispy and ispy:FindFirstChild("Houses")
    if not housesFolder then return end

    for _, houseFolder in ipairs(housesFolder:GetChildren()) do
        if houseFolder:IsA("Folder") and string.find(houseFolder.Name, "House") then
            local build = houseFolder:FindFirstChild("Build")
            local houseModel = build and build:FindFirstChild("House")
            if houseModel and ESPConfig.Houses then
                applyESP(houseModel, "House", Color3.fromRGB(0, 255, 0), false)
            end
        end
    end
end

local function setupStatues()
    local section5 = workspace:FindFirstChild("Section5")
    local statuesFolder = section5 and section5:FindFirstChild("StatueMonsters")
    if not statuesFolder then return end

    for _, statue in ipairs(statuesFolder:GetChildren()) do
        if statue:IsA("Model") and ESPConfig.Statues then
            applyESP(statue, statue.Name, Color3.fromRGB(255, 0, 0), true)
        end
    end
    
    table.insert(espConnections, statuesFolder.ChildAdded:Connect(function(inst)
        if ESPConfig.Statues and inst:IsA("Model") then 
            applyESP(inst, inst.Name, Color3.fromRGB(255, 0, 0), true) 
        end
    end))
end

local function updateDistances()
    local char = game.Players.LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    for obj, tl in pairs(activeTextLabels) do
        if obj and obj.Parent and tl and tl.Parent then
            local part = obj:IsA("BasePart") and obj or obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart", true)
            if part then
                local dist = math.floor((hrp.Position - part.Position).Magnitude)
                local baseName = obj.Name
                tl.Text = baseName .. " [" .. dist .. "m]"
            end
        else
            removeESP(obj)
        end
    end
end

local function refreshAllESP()
    clearAllESP()
    if ESPConfig.Houses then setupHouses() end
    if ESPConfig.Statues then setupStatues() end

    if ESPConfig.Houses or ESPConfig.Statues then
        updateConnection = game:GetService("RunService").Heartbeat:Connect(function()
            if tick() - lastUpdate > 0.2 then
                lastUpdate = tick()
                updateDistances()
            end
        end)
    end
end

YureiESP:Toggle({
    Title = "ESP Houses",
    Default = false,
    Callback = function(state)
        ESPConfig.Houses = state
        refreshAllESP()
    end
})

YureiESP:Toggle({
    Title = "ESP Statues",
    Default = false,
    Callback = function(state)
        ESPConfig.Statues = state
        refreshAllESP()
    end
})

local Chase = YureiStage:CreateSubTab({ Title = "Chase", Icon = "footprints", Default = false })

Chase:Button({
    Title = "Start Cutscene",
    Callback = function()
        task.spawn(function()
            local char = game.Players.LocalPlayer.Character or game.Players.LocalPlayer.CharacterAdded:Wait()
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end

            local section6 = workspace:FindFirstChild("Section6")
            local trigger = section6 and section6:FindFirstChild("TriggerCutscene")
            
            if trigger then
                local targetCFrame = trigger:IsA("BasePart") and trigger.CFrame or trigger:GetPivot()
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
                hrp.CFrame = targetCFrame
                task.wait(0.1)

                if firetouchinterest then
                    firetouchinterest(hrp, trigger, 0)
                    task.wait(0.1)
                    firetouchinterest(hrp, trigger, 1)
                end
            end
        end)
    end
})

Chase:Button({
    Title = "Auto Win",
    Callback = function()
        task.spawn(function()
            local char = game.Players.LocalPlayer.Character or game.Players.LocalPlayer.CharacterAdded:Wait()
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end

            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
            hrp.CFrame = CFrame.new(-1708, 88, 7797)
            task.wait(0.2)

            local section6 = workspace:FindFirstChild("Section6")
            local chase = section6 and section6:FindFirstChild("Chase")
            local endPart = chase and chase:FindFirstChild("END")
            
            if endPart then
                if firetouchinterest then
                    firetouchinterest(hrp, endPart, 0)
                    task.wait(0.5)
                    firetouchinterest(hrp, endPart, 1)
                end
            end
        end)
    end
})
