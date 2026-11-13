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



local SamuraiTab = Window:CreateTab({ Title = "Samurai", Icon = "swords" })

SamuraiTab:Button({
    Title = "Trigger Cutscene",
    Description = "",
    Callback = function()
        task.spawn(function()
            local char = game:GetService("Players").LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            
            local section0 = workspace:FindFirstChild("Section0")
            local cutscene = section0 and section0:FindFirstChild("Cutscene")
            local trigger = cutscene and cutscene:FindFirstChild("Trigger")

            if hrp and trigger then
                pcall(function()
                    firetouchinterest(hrp, trigger, 0)
                    task.wait(0.1)
                    firetouchinterest(hrp, trigger, 1)
                end)
            end
        end)
    end
})

local KawasakiTab = Window:CreateTab({ Title = "Kawasaki Ward", Icon = "hospital" })

local KawasakiMain = KawasakiTab:CreateSubTab({ Title = "Main", Icon = "gamepad-2", Default = true })
local KawasakiESP = KawasakiTab:CreateSubTab({ Title = "ESP", Icon = "eye" })

KawasakiMain:Button({
    Title = "Remove Glass",
    Description = "",
    Callback = function()
        task.spawn(function()
            local s1 = workspace:FindFirstChild("Section1")
            local sneakSeq = s1 and s1:FindFirstChild("EnzukaiSneakSequence")
            local activators = sneakSeq and sneakSeq:FindFirstChild("Activators")
            
            if activators then
                activators:Destroy()
            end
        end)
    end
})KawasakiMain:Button({    Title = "Enter Office Door",    Description = "",    Callback = function()        task.spawn(function()            local char = game:GetService("Players").LocalPlayer.Character            local hrp = char and char:FindFirstChild("HumanoidRootPart")                        local s1 = workspace:FindFirstChild("Section1")            local officeTele = s1 and s1:FindFirstChild("OfficeTeleA")            if hrp and officeTele then                pcall(function()                    firetouchinterest(hrp, officeTele, 0)                    task.wait(0.1)                    firetouchinterest(hrp, officeTele, 1)                end)            end        end)    end})

local espGlassEnabled = false
local glassHighlights = {}
local glassConnections = {}

local function applyGlassESP(obj)
    if not obj or glassHighlights[obj] or not espGlassEnabled then return end
    if not (obj:IsA("Model") or obj:IsA("BasePart")) then return end

    local hl = Instance.new("Highlight")
    hl.Name = "GlassESP"
    hl.Adornee = obj
    hl.FillColor = Color3.fromRGB(0, 255, 255)
    hl.OutlineColor = Color3.fromRGB(255, 255, 255)
    hl.FillTransparency = 0.5
    hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = obj
    glassHighlights[obj] = hl
end

local function clearGlassESP()
    for _, conn in ipairs(glassConnections) do pcall(function() conn:Disconnect() end) end
    table.clear(glassConnections)
    for obj, hl in pairs(glassHighlights) do
        pcall(function() hl:Destroy() end)
    end
    table.clear(glassHighlights)
end

KawasakiESP:Toggle({
    Title = "ESP Glass",
    Default = false,
    Callback = function(state)
        espGlassEnabled = state
        clearGlassESP()
        if not espGlassEnabled then return end

        task.spawn(function()
            local s1 = workspace:FindFirstChild("Section1")
            local sneakSeq = s1 and s1:FindFirstChild("EnzukaiSneakSequence")
            local folder = sneakSeq and sneakSeq:FindFirstChild("Activators")
            
            if folder then
                for _, child in ipairs(folder:GetChildren()) do
                    applyGlassESP(child)
                end
                table.insert(glassConnections, folder.ChildAdded:Connect(function(inst)
                    if espGlassEnabled then applyGlassESP(inst) end
                end))
            end
        end)
    end
})

local espEnzukaiEnabled = false
local enzukaiHighlights = {}
local enzukaiBillboards = {}
local enzukaiConnections = {}

local function applyEnzukaiESP(obj)
    if not obj or enzukaiHighlights[obj] or not espEnzukaiEnabled then return end
    if not (obj:IsA("Model") or obj:IsA("BasePart")) then return end

    local hl = Instance.new("Highlight")
    hl.Name = "EnzukaiESP"
    hl.Adornee = obj
    hl.FillColor = Color3.fromRGB(255, 0, 0)
    hl.OutlineColor = Color3.fromRGB(0, 0, 0)
    hl.FillTransparency = 0.5
    hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = obj
    enzukaiHighlights[obj] = hl

    local bb = Instance.new("BillboardGui")
    bb.Name = "EnzukaiName"
    bb.Size = UDim2.new(0, 200, 0, 50)
    bb.StudsOffset = Vector3.new(0, 3, 0)
    bb.AlwaysOnTop = true
    bb.Parent = obj

    local tl = Instance.new("TextLabel")
    tl.Size = UDim2.new(1, 0, 1, 0)
    tl.BackgroundTransparency = 1
    tl.Text = obj.Name
    tl.TextColor3 = Color3.fromRGB(255, 0, 0)
    tl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    tl.TextStrokeTransparency = 0
    tl.TextSize = 13
    tl.Font = Enum.Font.FredokaOne
    tl.Parent = bb
    enzukaiBillboards[obj] = bb
end

local function clearEnzukaiESP()
    for _, conn in ipairs(enzukaiConnections) do pcall(function() conn:Disconnect() end) end
    table.clear(enzukaiConnections)

    for obj, hl in pairs(enzukaiHighlights) do
        pcall(function() hl:Destroy() end)
        local bb = obj:FindFirstChild("EnzukaiName")
        if bb then pcall(function() bb:Destroy() end) end
    end
    table.clear(enzukaiHighlights)
    table.clear(enzukaiBillboards)
end

KawasakiESP:Toggle({
    Title = "ESP Enzukai",
    Default = false,
    Callback = function(state)
        espEnzukaiEnabled = state
        clearEnzukaiESP()
        if not espEnzukaiEnabled then return end

        task.spawn(function()
            local s1 = workspace:FindFirstChild("Section1")
            local sneakSeq = s1 and s1:FindFirstChild("EnzukaiSneakSequence")
            local monster = sneakSeq and sneakSeq:FindFirstChild("Monster")
            
            if monster then
                if monster:IsA("Model") or monster:IsA("BasePart") then
                    applyEnzukaiESP(monster)
                else
                    for _, child in ipairs(monster:GetChildren()) do
                        applyEnzukaiESP(child)
                    end
                    table.insert(enzukaiConnections, monster.ChildAdded:Connect(function(inst)
                        if espEnzukaiEnabled then applyEnzukaiESP(inst) end
                    end))
                end
            end
        end)
    end
})

local OfficeTab = Window:CreateTab({ Title = "Office", Icon = "briefcase" })

local OfficeMain = OfficeTab:CreateSubTab({ Title = "Main", Icon = "gamepad-2", Default = true })

OfficeMain:Button({
    Title = "Talk to the boss",
    Callback = function()
        task.spawn(function()
            local char = game:GetService("Players").LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")

            if not char or not hrp then return end

            -- 1. Teleport to the specific position
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
            char:PivotTo(CFrame.new(4450, 44, 1659))
            
            -- 2. Wait for the server to register the new position
            task.wait(0.3)

            -- 3. Find the NPC and the prompt
            local s1 = workspace:FindFirstChild("Section1")
            local playerObj = s1 and s1:FindFirstChild("PlayerObjective")
            local npc = playerObj and playerObj:FindFirstChild("QuestGiverNPC")

            if npc then
                local prompt = npc:FindFirstChildWhichIsA("ProximityPrompt", true)
                
                if prompt then
                    prompt.Enabled = true
                    pcall(function()
                        if fireproximityprompt then
                            fireproximityprompt(prompt, 0)
                        else
                            prompt:InputHoldBegin()
                            task.wait(0.05)
                            prompt:InputHoldEnd()
                        end
                    end)
                end
            end
        end)
    end
})

OfficeMain:Button({
    Title = "Auto Passcode",
    Callback = function()
        task.spawn(function()
            local char = game.Players.LocalPlayer.Character or game.Players.LocalPlayer.CharacterAdded:Wait()
            local root = char:WaitForChild("HumanoidRootPart")

            -- 1. TELEPORT TO POSITION
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
            char:PivotTo(CFrame.new(4472, 44, 1636))
            task.wait(0.3)

            local section = workspace:FindFirstChild("Section1")
            local obj = section and section:FindFirstChild("PlayerObjective")
            local keypad = obj and obj:FindFirstChild("CodeDoor") and obj.CodeDoor:FindFirstChild("Keypad")

            -- 2. FIRE PROXIMITY PROMPT
            if keypad then
                local prompt = keypad:FindFirstChildWhichIsA("ProximityPrompt", true)
                if prompt then
                    prompt.Enabled = true
                    pcall(function()
                        if fireproximityprompt then
                            fireproximityprompt(prompt)
                        else
                            prompt:InputHoldBegin()
                            task.wait(0.05)
                            prompt:InputHoldEnd()
                        end
                    end)
                end
            end

            task.wait(0.5) -- Wait for the UI to load

            -- 3. READ CODES AND FIRE REMOTE
            if not obj then return end
            local folder = obj:FindFirstChild("CodeNumbers")
            local remote = obj:FindFirstChild("CodeDoor") and obj.CodeDoor:FindFirstChild("Remote")
            if not folder or not remote then return end

            local codes = {}
            for _, part in ipairs(folder:GetChildren()) do
                local gui = part:FindFirstChildWhichIsA("SurfaceGui", true)
                local textObj = gui and (gui:FindFirstChildWhichIsA("TextLabel", true) or gui:FindFirstChildWhichIsA("TextBox", true))
                
                local textValue = nil
                if textObj then
                    -- Check ContentText first as you requested
                    if textObj.ContentText and textObj.ContentText ~= "" then
                        textValue = textObj.ContentText
                    else
                        textValue = textObj.Text
                    end
                end
                
                local value = textValue and tonumber(textValue)
                
                if value then
                    table.insert(codes, {Floor = tonumber(part.Name:match("%d+")) or 0, Value = value})
                end
            end

            -- Sort from 6th floor to 1st floor
            table.sort(codes, function(a, b) return a.Floor > b.Floor end)

            local result = {}
            for i = 1, 6 do
                result[i] = codes[i] and codes[i].Value or 0
            end

            -- Fire the remote
            pcall(function()
                remote:FireServer(1, result)
            end)
        end)
    end
})

OfficeMain:Button({
    Title = "Enter Rooftop",
    Callback = function()
        task.spawn(function()
            local player = game:GetService("Players").LocalPlayer
            local char = player.Character or player.CharacterAdded:Wait()
            local hrp = char:WaitForChild("HumanoidRootPart")
            local backpack = player:WaitForChild("Backpack")

            local function teleport(x, y, z)
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
                char:PivotTo(CFrame.new(x, y, z))
                task.wait(0.3)
            end

            local function firePrompt(obj)
                if not obj then return end
                local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
                if prompt then
                    prompt.Enabled = true
                    pcall(function()
                        if fireproximityprompt then
                            fireproximityprompt(prompt)
                        else
                            prompt:InputHoldBegin()
                            task.wait(0.05)
                            prompt:InputHoldEnd()
                        end
                    end)
                end
            end

            local s1 = workspace:FindFirstChild("Section1")
            local playerObj = s1 and s1:FindFirstChild("PlayerObjective")
            local codeDoor = playerObj and playerObj:FindFirstChild("CodeDoor")

            -- 1. Teleport to ShovelGiver
            teleport(4468, 44, 1627)
            
            -- 2. Fire ShovelGiver Prompt
            local shovelGiver = codeDoor and codeDoor:FindFirstChild("ShovelGiver")
            firePrompt(shovelGiver)
            
            -- 3. Wait for the shovel to arrive in the backpack and equip it
            local shovel = nil
            local startWait = tick()
            repeat
                shovel = backpack:FindFirstChild("Mimic@Tool_Shovel")
                if not shovel then task.wait(0.1) end
            until shovel or (tick() - startWait > 2)

            if shovel and char:FindFirstChildOfClass("Humanoid") then
                char.Humanoid:EquipTool(shovel)
                task.wait(0.3)
            end

            -- 4. Teleport to DirtDigObjective
            teleport(4452, 44, 1639)
            
            -- 5. Fire the dig prompt 5 times
            local dirtDig = playerObj and playerObj:FindFirstChild("DirtDigObjective")
            if dirtDig then
                for i = 1, 5 do
                    firePrompt(dirtDig)
                    task.wait(0.3) -- Give the server time to register the dig
                end
            end

            -- 6. Teleport to TeleportDoor
            teleport(4434, 44, 1638)
            
            -- 7. Fire TeleportDoor Prompt
            local teleDoor = playerObj and playerObj:FindFirstChild("TeleportDoor")
            firePrompt(teleDoor)
            
        end)
    end
})

OfficeMain:Section("Rooftop")

OfficeMain:Button({
    Title = "Exit Rooftop",
    Callback = function()
        task.spawn(function()
            local player = game:GetService("Players").LocalPlayer
            local char = player.Character or player.CharacterAdded:Wait()
            local hrp = char:WaitForChild("HumanoidRootPart")

            local function teleport(x, y, z)
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
                char:PivotTo(CFrame.new(x, y, z))
                task.wait(0.3)
            end

            local function firePrompt(obj)
                if not obj then return end
                local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
                if prompt then
                    prompt.Enabled = true
                    pcall(function()
                        if fireproximityprompt then
                            fireproximityprompt(prompt)
                        else
                            prompt:InputHoldBegin()
                            task.wait(0.05)
                            prompt:InputHoldEnd()
                        end
                    end)
                end
            end

            -- 1. Teleport to PieceA and fire prompt
            teleport(4951, 27, 1224)
            local pieceA = workspace:FindFirstChild("WHITE_FLAME_LANTERN") and workspace.WHITE_FLAME_LANTERN:FindFirstChild("PieceA")
            firePrompt(pieceA)

            task.wait(0.5) -- Give the server time to register

            -- 2. Teleport to Ladder and fire prompt
            teleport(4975, 27, 1220)
            local s1 = workspace:FindFirstChild("Section1")
            local playerObj = s1 and s1:FindFirstChild("PlayerObjective")
            local ladderPrompt = playerObj and playerObj:FindFirstChild("LADDERPROMPT")
            firePrompt(ladderPrompt)
            
        end)
    end
})

local MallTab = Window:CreateTab({ Title = "Mall", Icon = "shopping-bag" })
local MallMain = MallTab:CreateSubTab({ Title = "Main", Icon = "gamepad-2", Default = true })

MallMain:Button({
    Title = "Walkie Talkie",
    Callback = function()
        task.spawn(function()
            local Character = game:GetService("Players").LocalPlayer.Character or game:GetService("Players").LocalPlayer.CharacterAdded:Wait()
            local HRP = Character:FindFirstChild("HumanoidRootPart")
            if not HRP then return end

            local section = workspace:FindFirstChild("Section2")
            local folder = section and section:FindFirstChild("WalkieTalkis")
            if not folder then return end

            local children = folder:GetChildren()
            local targets = {
                folder:FindFirstChild("WalkieTalkie"),
                children[6],
                children[7],
                children[8]
            }

            for _, target in ipairs(targets) do
                -- Make sure target exists and is a BasePart
                if target and target:IsA("BasePart") then
                    
                    -- Fast Teleport (resets velocity to prevent snapping)
                    HRP.AssemblyLinearVelocity = Vector3.zero
                    HRP.AssemblyAngularVelocity = Vector3.zero
                    Character:PivotTo(target.CFrame + Vector3.new(0, 3, 0))
                    task.wait(0.2) -- Slightly faster wait for instant feel

                    -- Fast Prompt Finder
                    local prompt = target:FindFirstChildWhichIsA("ProximityPrompt", true)
                    
                    if prompt and prompt.Enabled then
                        -- Check distance to prompt (to ensure the server accepts it)
                        local promptPart = prompt.Parent
                        if promptPart and promptPart:IsA("BasePart") then
                            if (promptPart.Position - HRP.Position).Magnitude <= 10 then
                                
                                -- Fire the prompt instantly
                                prompt.HoldDuration = 0
                                prompt.RequiresLineOfSight = false
                                pcall(function()
                                    if fireproximityprompt then
                                        fireproximityprompt(prompt)
                                    else
                                        prompt:InputHoldBegin()
                                        task.wait(0.05)
                                        prompt:InputHoldEnd()
                                    end
                                end)
                            end
                        end
                    end
                    task.wait(0.3)
                end
            end
        end)
    end
})

MallMain:Button({
    Title = "Trigger Start",
    Callback = function()
        task.spawn(function()
            local player = game:GetService("Players").LocalPlayer
            local char = player.Character or player.CharacterAdded:Wait()
            local hrp = char and char:FindFirstChild("HumanoidRootPart")

            local s2 = workspace:FindFirstChild("Section2")
            local floor1 = s2 and s2:FindFirstChild("Floor1")
            local trigger = floor1 and floor1:FindFirstChild("TRIGGER")

            if hrp and trigger then
                pcall(function()
                    firetouchinterest(hrp, trigger, 0)
                    task.wait(0.1)
                    firetouchinterest(hrp, trigger, 1)
                end)
            end
        end)
    end
})


MallMain:Button({
    Title = "Blind Kyogi",
    Callback = function()
        local player = game:GetService("Players").LocalPlayer
        local safePos = Vector3.new(-1158, -151, -1010)
        
        -- 1. Cache the main folders so we don't search the workspace repeatedly
        local s2 = workspace:FindFirstChild("Section2")
        local floor1 = s2 and s2:FindFirstChild("Floor1")
        local timedTrial = floor1 and floor1:FindFirstChild("TimedTrial")
        local tenome = floor1 and floor1:FindFirstChild("Monster") and floor1.Monster:FindFirstChild("Tenome")
        
        if not timedTrial then return end

        -- 2. Helper Functions
        local function GetValidPart(Object)
            if Object:IsA("BasePart") then return Object end
            for _, Descendant in ipairs(Object:GetDescendants()) do
                if Descendant:IsA("BasePart") then return Descendant end
            end
        end

        local function SafeTeleport(Position)
            local Character = player.Character or player.CharacterAdded:Wait()
            local Root = Character:FindFirstChild("HumanoidRootPart")
            if Root then 
                Root.AssemblyLinearVelocity = Vector3.zero
                Root.AssemblyAngularVelocity = Vector3.zero
                Root.CFrame = CFrame.new(Position) 
            end
        end

        local function IsTenomeTooClose()
            local Character = player.Character
            local Root = Character and Character:FindFirstChild("HumanoidRootPart")
            if not Root or not tenome then return false end
            
            local TenomePart = GetValidPart(tenome)
            if TenomePart then
                return (Root.Position - TenomePart.Position).Magnitude <= 30
            end
            return false
        end

        local function TeleportAndPrompt(Folder)
            local Character = player.Character or player.CharacterAdded:Wait()
            local Root = Character:FindFirstChild("HumanoidRootPart")
            if not Root then return end

            for _, Item in ipairs(Folder:GetChildren()) do
                if IsTenomeTooClose() then
                    SafeTeleport(safePos)
                    return
                end

                -- Skip the Tenome model itself
                if tenome and (Item == tenome or Item:IsAncestorOf(tenome) or tenome:IsAncestorOf(Item)) then
                    continue
                end

                local Part = GetValidPart(Item)
                if Part then
                    Root.CFrame = Part.CFrame + Vector3.new(0, 3, 0)
                    task.wait(0.25)
                    
                    if IsTenomeTooClose() then
                        SafeTeleport(safePos)
                        return
                    end

                    for _, Obj in ipairs(Item:GetDescendants()) do
                        if Obj:IsA("ProximityPrompt") and Obj.Enabled then
                            Obj.HoldDuration = 0
                            Obj.RequiresLineOfSight = false
                            
                            pcall(function()
                                if fireproximityprompt then
                                    fireproximityprompt(Obj)
                                else
                                    Obj:InputHoldBegin()
                                    task.wait(0.05)
                                    Obj:InputHoldEnd()
                                end
                            end)
                            
                            task.wait(0.25)
                            break
                        end
                    end
                    SafeTeleport(safePos)
                    task.wait(0.50)
                end
            end
        end

        -- 3. Start the Execution
        task.spawn(function()
            local punchObj = timedTrial:FindFirstChild("PlayerPunch")
            local originalAnimId = nil
            local animatorConnection = nil
            
            local animator = player.Character and player.Character:FindFirstChildOfClass("Humanoid") and player.Character.Humanoid:FindFirstChildOfClass("Animator")

            -- Setup Animation Blocker
            if punchObj and punchObj:IsA("Animation") then
                originalAnimId = punchObj.AnimationId
                punchObj.AnimationId = "rbxassetid://0" -- Break the animation ID
                
                -- Event-driven block: Only runs exactly when the game tries to play an animation
                if animator then
                    animatorConnection = animator.AnimationPlayed:Connect(function(track)
                        if track.Animation and track.Animation.AnimationId == originalAnimId then
                            track:Stop(0)
                        elseif track.Name:lower():find("punch") then
                            track:Stop(0)
                        end
                    end)
                end
            end

            -- Execute the Teleport & Prompt Loops
            for Index = 1, 3 do
                if IsTenomeTooClose() then break end
                local Folder = timedTrial:FindFirstChild(tostring(Index))
                if Folder then TeleportAndPrompt(Folder) end
            end

            -- Restore Everything
            if animatorConnection then
                animatorConnection:Disconnect()
            end

            if punchObj and punchObj:IsA("Animation") and originalAnimId then
                punchObj.AnimationId = originalAnimId
            end
        end)
    end
})

MallMain:Button({
    Title = "Collect & Insert Coins",
    Callback = function()
        task.spawn(function()
            local player = game:GetService("Players").LocalPlayer
            local char = player.Character or player.CharacterAdded:Wait()
            local root = char:WaitForChild("HumanoidRootPart")
            
            -- Cache paths to prevent repeated workspace searches
            local section = workspace:FindFirstChild("Section2")
            local floor2 = section and section:FindFirstChild("Floor2")
            local coinFolder = floor2 and floor2:FindFirstChild("Coins")
            local carousel = floor2 and floor2:FindFirstChild("Carousel")
            local coinSlot = carousel and carousel:FindFirstChild("CoinSlot")

            if not coinFolder then return end

            local function TeleportAndFire(object)
                if not object then return end
                
                -- Fast part finder
                local part = object:IsA("BasePart") and object or object:FindFirstChildWhichIsA("BasePart", true)
                if not part or part.Transparency >= 1 then return false end

                -- Teleport
                root.AssemblyLinearVelocity = Vector3.zero
                root.AssemblyAngularVelocity = Vector3.zero
                root.CFrame = part.CFrame + Vector3.new(0, 3, 0)
                task.wait(0.2)

                -- Fast prompt finder
                local prompt = object:FindFirstChildWhichIsA("ProximityPrompt", true)
                if prompt and prompt.Enabled then
                    prompt.HoldDuration = 0
                    prompt.RequiresLineOfSight = false
                    pcall(function()
                        if fireproximityprompt then
                            fireproximityprompt(prompt)
                        else
                            prompt:InputHoldBegin()
                            task.wait(0.05)
                            prompt:InputHoldEnd()
                        end
                    end)
                end
                task.wait(0.2)
                return true
            end

            -- 1. Gather valid coins
            local candidates = {}
            for _, obj in ipairs(coinFolder:GetChildren()) do
                local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart", true)
                if part and part.Transparency < 1 then
                    table.insert(candidates, obj)
                end
            end

            -- 2. Pick 5 random coins and collect them
            local count = 0
            while count < 5 and #candidates > 0 do
                local randomIndex = math.random(1, #candidates)
                local choice = table.remove(candidates, randomIndex)
                
                if TeleportAndFire(choice) then 
                    count = count + 1 
                end
            end

            -- 3. Insert into the coin slot
            if coinSlot then 
                TeleportAndFire(coinSlot) 
            end
        end)
    end
})

MallMain:Button({
    Title = "Auto Speaker",
    Callback = function()
        task.spawn(function()
            local player = game:GetService("Players").LocalPlayer
            local char = player.Character or player.CharacterAdded:Wait()
            local hrp = char:FindFirstChild("HumanoidRootPart")

            local section2 = workspace:FindFirstChild("Section2")
            local speaker = section2 and section2:FindFirstChild("Speaker")
            if not speaker then return end

            local function firePrompt(obj)
                if not obj then return end
                local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
                if prompt then
                    prompt.Enabled = true
                    prompt.HoldDuration = 0
                    prompt.RequiresLineOfSight = false
                    pcall(function()
                        if fireproximityprompt then
                            fireproximityprompt(prompt)
                        else
                            prompt:InputHoldBegin()
                            task.wait(0.05)
                            prompt:InputHoldEnd()
                        end
                    end)
                end
            end

            local function teleport(pos)
                if hrp then
                    hrp.AssemblyLinearVelocity = Vector3.zero
                    hrp.AssemblyAngularVelocity = Vector3.zero
                    char:PivotTo(CFrame.new(pos))
                    task.wait(0.3)
                end
            end

            -- 1. Teleport to the Speaker and fire prompt
            local speakerPart = speaker:IsA("BasePart") and speaker or speaker:FindFirstChildWhichIsA("BasePart", true)
            if speakerPart then
                teleport(speakerPart.Position + Vector3.new(0, 3, 0))
                firePrompt(speaker)
            end

            -- 2. Teleport to the position -1360, -120, -947
            teleport(Vector3.new(-1360, -120, -947))

            -- 3. Fire the Signal Remote
            local signal = speaker:FindFirstChild("Signal")
            if signal and signal:IsA("RemoteEvent") then
                pcall(function()
                    signal:FireServer()
                end)
            end
            task.wait(0.3)

            -- 4. Fire the Speaker Prompt again
            firePrompt(speaker)
        end)
    end
})

MallMain:Button({
    Title = "Exit Mall",
    Callback = function()
        task.spawn(function()
            local player = game:GetService("Players").LocalPlayer
            local char = player.Character or player.CharacterAdded:Wait()
            local hrp = char:FindFirstChild("HumanoidRootPart")

            local function teleport(pos)
                if hrp then
                    hrp.AssemblyLinearVelocity = Vector3.zero
                    hrp.AssemblyAngularVelocity = Vector3.zero
                    char:PivotTo(CFrame.new(pos))
                    task.wait(0.3)
                end
            end

            local function firePrompt(obj)
                if not obj then return end
                local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
                if prompt then
                    prompt.Enabled = true
                    prompt.HoldDuration = 0
                    prompt.RequiresLineOfSight = false
                    pcall(function()
                        if fireproximityprompt then
                            fireproximityprompt(prompt)
                        else
                            prompt:InputHoldBegin()
                            task.wait(0.05)
                            prompt:InputHoldEnd()
                        end
                    end)
                end
            end

            -- 1. Teleport to PieceC and fire prompt
            local lantern = workspace:FindFirstChild("WHITE_FLAME_LANTERN")
            local pieceC = lantern and lantern:FindFirstChild("PieceC")

            if pieceC then
                local targetPart = pieceC:IsA("BasePart") and pieceC or pieceC:FindFirstChildWhichIsA("BasePart", true)
                if targetPart then
                    teleport(targetPart.Position + Vector3.new(0, 3, 0))
                    firePrompt(pieceC)
                    task.wait(0.5)
                end
            end

            -- 2. Fire TouchInterest on Section2.Exit
            local s2 = workspace:FindFirstChild("Section2")
            local exitPart = s2 and s2:FindFirstChild("Exit")
            
            if exitPart and exitPart:IsA("BasePart") and hrp then
                pcall(function()
                    firetouchinterest(hrp, exitPart, 0)
                    task.wait(0.1)
                    firetouchinterest(hrp, exitPart, 1)
                end)
            end
        end)
    end
})

local MallESP = MallTab:CreateSubTab({ Title = "ESP", Icon = "eye" })

-- ==========================================
-- 1. ESP WALKIE TALKIE
-- ==========================================
local espWalkieEnabled = false
local walkieHighlights = {}
local walkieConnections = {}

local function applyWalkieESP(obj)
    if not obj or walkieHighlights[obj] or not espWalkieEnabled then return end
    if not (obj:IsA("Model") or obj:IsA("BasePart")) then return end

    local hl = Instance.new("Highlight")
    hl.Name = "WalkieESP"
    hl.Adornee = obj
    hl.FillColor = Color3.fromRGB(0, 255, 0)
    hl.OutlineColor = Color3.fromRGB(0, 255, 0)
    hl.FillTransparency = 0.5
    hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = obj
    walkieHighlights[obj] = hl
end

local function clearWalkieESP()
    for _, conn in ipairs(walkieConnections) do pcall(function() conn:Disconnect() end) end
    table.clear(walkieConnections)
    for obj, hl in pairs(walkieHighlights) do pcall(function() hl:Destroy() end) end
    table.clear(walkieHighlights)
end

MallESP:Toggle({
    Title = "ESP Walkie Talkie",
    Default = false,
    Callback = function(state)
        espWalkieEnabled = state
        clearWalkieESP()
        if not espWalkieEnabled then return end

        task.spawn(function()
            local s2 = workspace:FindFirstChild("Section2")
            local folder = s2 and s2:FindFirstChild("WalkieTalkis")
            
            if folder then
                for _, child in ipairs(folder:GetChildren()) do
                    applyWalkieESP(child)
                end
                table.insert(walkieConnections, folder.ChildAdded:Connect(function(inst)
                    if espWalkieEnabled then applyWalkieESP(inst) end
                end))
            end
        end)
    end
})

-- ==========================================
-- 2. ESP EYES (TimedTrial)
-- ==========================================
local espEyesEnabled = false
local eyesHighlights = {}
local eyesConnections = {}

local function applyEyesESP(obj)
    if not obj or eyesHighlights[obj] or not espEyesEnabled then return end
    if not (obj:IsA("Model") or obj:IsA("BasePart")) then return end

    local hl = Instance.new("Highlight")
    hl.Name = "EyesESP"
    hl.Adornee = obj
    hl.FillColor = Color3.fromRGB(255, 0, 0)
    hl.OutlineColor = Color3.fromRGB(255, 0, 0)
    hl.FillTransparency = 0.5
    hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = obj
    eyesHighlights[obj] = hl
end

local function clearEyesESP()
    for _, conn in ipairs(eyesConnections) do pcall(function() conn:Disconnect() end) end
    table.clear(eyesConnections)
    for obj, hl in pairs(eyesHighlights) do pcall(function() hl:Destroy() end) end
    table.clear(eyesHighlights)
end

local function setupEyesFolder(folder)
    if not folder then return end
    for _, child in ipairs(folder:GetChildren()) do
        applyEyesESP(child)
    end
    table.insert(eyesConnections, folder.ChildAdded:Connect(function(inst)
        if espEyesEnabled then applyEyesESP(inst) end
    end))
end

MallESP:Toggle({
    Title = "ESP Eyes",
    Default = false,
    Callback = function(state)
        espEyesEnabled = state
        clearEyesESP()
        if not espEyesEnabled then return end

        task.spawn(function()
            local s2 = workspace:FindFirstChild("Section2")
            local floor1 = s2 and s2:FindFirstChild("Floor1")
            local timedTrial = floor1 and floor1:FindFirstChild("TimedTrial")
            
            if timedTrial then
                setupEyesFolder(timedTrial:FindFirstChild("1"))
                setupEyesFolder(timedTrial:FindFirstChild("2"))
                setupEyesFolder(timedTrial:FindFirstChild("3"))
            end
        end)
    end
})

-- ==========================================
-- 3. ESP COINS
-- ==========================================
local espCoinsEnabled = false
local coinHighlights = {}
local coinConnections = {}

local function applyCoinESP(obj)
    if not obj or coinHighlights[obj] or not espCoinsEnabled then return end
    if not (obj:IsA("Model") or obj:IsA("BasePart")) then return end

    local hl = Instance.new("Highlight")
    hl.Name = "CoinESP"
    hl.Adornee = obj
    hl.FillColor = Color3.fromRGB(255, 215, 0)
    hl.OutlineColor = Color3.fromRGB(255, 215, 0)
    hl.FillTransparency = 0.5
    hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = obj
    coinHighlights[obj] = hl
end

local function clearCoinESP()
    for _, conn in ipairs(coinConnections) do pcall(function() conn:Disconnect() end) end
    table.clear(coinConnections)
    for obj, hl in pairs(coinHighlights) do pcall(function() hl:Destroy() end) end
    table.clear(coinHighlights)
end

MallESP:Toggle({
    Title = "ESP Coins",
    Default = false,
    Callback = function(state)
        espCoinsEnabled = state
        clearCoinESP()
        if not espCoinsEnabled then return end

        task.spawn(function()
            local s2 = workspace:FindFirstChild("Section2")
            local floor2 = s2 and s2:FindFirstChild("Floor2")
            local folder = floor2 and floor2:FindFirstChild("Coins")
            
            if folder then
                for _, child in ipairs(folder:GetChildren()) do
                    applyCoinESP(child)
                end
                table.insert(coinConnections, folder.ChildAdded:Connect(function(inst)
                    if espCoinsEnabled then applyCoinESP(inst) end
                end))
            end
        end)
    end
})

-- ==========================================
-- 4. ESP SPEAKER
-- ==========================================
local espSpeakerEnabled = false
local speakerHighlights = {}
local speakerBillboards = {}

local function applySpeakerESP(obj)
    if not obj or speakerHighlights[obj] or not espSpeakerEnabled then return end
    if not (obj:IsA("Model") or obj:IsA("BasePart")) then return end

    local hl = Instance.new("Highlight")
    hl.Name = "SpeakerESP"
    hl.Adornee = obj
    hl.FillColor = Color3.fromRGB(0, 255, 255)
    hl.OutlineColor = Color3.fromRGB(0, 255, 255)
    hl.FillTransparency = 0.5
    hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = obj
    speakerHighlights[obj] = hl

    local bb = Instance.new("BillboardGui")
    bb.Name = "SpeakerName"
    bb.Size = UDim2.new(0, 200, 0, 50)
    bb.StudsOffset = Vector3.new(0, 3, 0)
    bb.AlwaysOnTop = true
    bb.Parent = obj

    local tl = Instance.new("TextLabel")
    tl.Size = UDim2.new(1, 0, 1, 0)
    tl.BackgroundTransparency = 1
    tl.Text = obj.Name
    tl.TextColor3 = Color3.fromRGB(0, 255, 255)
    tl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    tl.TextStrokeTransparency = 0
    tl.TextSize = 13
    tl.Font = Enum.Font.FredokaOne
    tl.Parent = bb
    speakerBillboards[obj] = bb
end

local function clearSpeakerESP()
    for obj, hl in pairs(speakerHighlights) do pcall(function() hl:Destroy() end) end
    for obj, bb in pairs(speakerBillboards) do pcall(function() bb:Destroy() end) end
    table.clear(speakerHighlights)
    table.clear(speakerBillboards)
end

MallESP:Toggle({
    Title = "ESP Speaker",
    Default = false,
    Callback = function(state)
        espSpeakerEnabled = state
        clearSpeakerESP()
        if not espSpeakerEnabled then return end

        task.spawn(function()
            local s2 = workspace:FindFirstChild("Section2")
            local folder = s2 and s2:FindFirstChild("Speaker")
            
            if folder then
                applySpeakerESP(folder)
            end
        end)
    end
})

-- ==========================================
-- 5. MONSTER SECTION
-- ==========================================
MallESP:Section("Monster")

local espMallMonsterEnabled = false
local monsterHighlights = {}
local monsterBillboards = {}
local monsterConnections = {}

local function applyMonsterESP(obj)
    if not obj or monsterHighlights[obj] or not espMallMonsterEnabled then return end
    if not (obj:IsA("Model") or obj:IsA("BasePart")) then return end

    local hl = Instance.new("Highlight")
    hl.Name = "MonsterESP"
    hl.Adornee = obj
    hl.FillColor = Color3.fromRGB(255, 0, 0)
    hl.OutlineColor = Color3.fromRGB(0, 0, 0)
    hl.FillTransparency = 0.5
    hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = obj
    monsterHighlights[obj] = hl

    local bb = Instance.new("BillboardGui")
    bb.Name = "MonsterName"
    bb.Size = UDim2.new(0, 200, 0, 50)
    bb.StudsOffset = Vector3.new(0, 3, 0)
    bb.AlwaysOnTop = true
    bb.Parent = obj

    local tl = Instance.new("TextLabel")
    tl.Size = UDim2.new(1, 0, 1, 0)
    tl.BackgroundTransparency = 1
    tl.Text = obj.Name
    tl.TextColor3 = Color3.fromRGB(255, 0, 0)
    tl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    tl.TextStrokeTransparency = 0
    tl.TextSize = 13
    tl.Font = Enum.Font.FredokaOne
    tl.Parent = bb
    monsterBillboards[obj] = bb
end

local function clearMonsterESP()
    for _, conn in ipairs(monsterConnections) do pcall(function() conn:Disconnect() end) end
    table.clear(monsterConnections)

    for obj, hl in pairs(monsterHighlights) do pcall(function() hl:Destroy() end) end
    for obj, bb in pairs(monsterBillboards) do pcall(function() bb:Destroy() end) end
    table.clear(monsterHighlights)
    table.clear(monsterBillboards)
end

local function setupMonsterFolder(folder)
    if not folder then return end
    for _, child in ipairs(folder:GetChildren()) do
        applyMonsterESP(child)
    end
    table.insert(monsterConnections, folder.ChildAdded:Connect(function(inst)
        if espMallMonsterEnabled then applyMonsterESP(inst) end
    end))
end

MallESP:Toggle({
    Title = "ESP Monsters",
    Default = false,
    Callback = function(state)
        espMallMonsterEnabled = state
        clearMonsterESP()
        if not espMallMonsterEnabled then return end

        task.spawn(function()
            local s2 = workspace:FindFirstChild("Section2")
            if not s2 then return end

            local floor1 = s2:FindFirstChild("Floor1")
            if floor1 then setupMonsterFolder(floor1:FindFirstChild("Monster")) end

            local floor2 = s2:FindFirstChild("Floor2")
            if floor2 then setupMonsterFolder(floor2:FindFirstChild("Monster")) end

            local floor3 = s2:FindFirstChild("Floor3")
            if floor3 then setupMonsterFolder(floor3:FindFirstChild("Monster")) end
        end)
    end
})

local MallChase = MallTab:CreateSubTab({ Title = "Chase", Icon = "footprints" })

MallChase:Button({
    Title = "Auto Escape First Chase",
    Callback = function()
        task.spawn(function()
            local player = game:GetService("Players").LocalPlayer
            local char = player.Character or player.CharacterAdded:Wait()
            local hrp = char:WaitForChild("HumanoidRootPart")
            local tweenService = game:GetService("TweenService")

            local waypoints = {
                Vector3.new(-2925, -152, 22),
                Vector3.new(-3008, -156, 100),
                Vector3.new(-3009, -157, -0),
                Vector3.new(-3076, -161, -1),
                Vector3.new(-3077, -160, 52),
                Vector3.new(-3114, -162, 51),
                Vector3.new(-3150, -164, 64),
                Vector3.new(-3157, -165, 6),
                Vector3.new(-3287, -173, 10),
                Vector3.new(-3340, -175, 10),
                Vector3.new(-3456, -183, -47),
                Vector3.new(-3421, -182, -147),
                Vector3.new(-3393, -182, -219),
                Vector3.new(-3311, -180, -388),
                Vector3.new(-3363, -183, -412),
                Vector3.new(-3337, -183, -474),
                Vector3.new(-3402, -187, -513),
                Vector3.new(-3386, -187, -553),
                Vector3.new(-3444, -190, -579),
                Vector3.new(-3469, -191, -530),
                Vector3.new(-3538, -195, -562),
                Vector3.new(-3574, -197, -520),
                Vector3.new(-3628, -201, -628),
                Vector3.new(-3712, -208, -781),
                Vector3.new(-3694, -208, -833),
                Vector3.new(-3589, -206, -1061),
                Vector3.new(-3451, -197, -998),
                Vector3.new(-3269, -186, -916)
            }

            for i, pos in ipairs(waypoints) do
                if not char or not char.Parent then break end
                
                local currentPos = hrp.Position
                local distance = (pos - currentPos).Magnitude
                
                -- Adjust speed (studs per second). 45 is a fast run.
                local speed = 45
                local timeToTravel = distance / speed

                -- Tween to the next position
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
                
                local tweenInfo = TweenInfo.new(timeToTravel, Enum.EasingStyle.Linear)
                local tween = tweenService:Create(hrp, tweenInfo, {CFrame = CFrame.new(pos)})
                
                tween:Play()
                tween.Completed:Wait()
                
                task.wait(0.05)
            end
        end)
    end
})

MallChase:Button({
    Title = "Auto Escape Second Chase",
    Callback = function()
        task.spawn(function()
            local player = game:GetService("Players").LocalPlayer
            local char = player.Character or player.CharacterAdded:Wait()
            local hrp = char:WaitForChild("HumanoidRootPart")

            if not hrp then return end

            -- 1. Teleport to the Elevator
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
            char:PivotTo(CFrame.new(-3910, -255, -1103))
            task.wait(0.3)

            -- 2. Find the Objects
            local s25 = workspace:FindFirstChild("Section2.5")
            if not s25 then return end

            local elevator = s25:FindFirstChild("Elevator")
            local qteMonsters = elevator and elevator:FindFirstChild("QTEMonsters")
            
            local chaseSeq = s25:FindFirstChild("ChaseSequence")
            local secondChase = chaseSeq and chaseSeq:FindFirstChild("SecondChaseStuff")
            local elevatorHit = secondChase and secondChase:FindFirstChild("ElevatorHit")

            if not elevatorHit then return end

            -- 3. Check distance between QTEMonsters and ElevatorHit
            local function getPosition(obj)
                if not obj then return nil end
                if obj:IsA("BasePart") then return obj.Position end
                if obj:IsA("Model") then return obj:GetPivot().Position end
                local p = obj:FindFirstChildWhichIsA("BasePart", true)
                return p and p.Position
            end

            local monsterPos = getPosition(qteMonsters)
            local hitPos = getPosition(elevatorHit)
            
            local isTooFar = false
            if monsterPos and hitPos then
                local distance = (monsterPos - hitPos).Magnitude
                if distance > 10 then -- "Isn't near"
                    isTooFar = true
                end
            elseif not monsterPos then
                -- If the monsters folder doesn't exist or is empty, trigger it anyway to be safe
                isTooFar = true
            end

            -- 4. If far, fire the TouchInterest
            if isTooFar and elevatorHit:IsA("BasePart") then
                pcall(function()
                    firetouchinterest(hrp, elevatorHit, 0)
                    task.wait(0.1)
                    firetouchinterest(hrp, elevatorHit, 1)
                end)
            end
        end)
    end
})

local MallParking = MallTab:CreateSubTab({ Title = "Parking", Icon = "car", Default = false })

-- ==========================================
-- AUTO REPAIR VEHICLE (No Lag)
-- ==========================================
MallParking:Button({
    Title = "Auto Repair Vehicle",
    Callback = function()
        task.spawn(function()
            local player = game:GetService("Players").LocalPlayer
            local char = player.Character or player.CharacterAdded:Wait()
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end

            local s25 = workspace:FindFirstChild("Section2.5")
            local chihiro = s25 and s25:FindFirstChild("ChihiroMinigame")
            local minigamePath = chihiro and chihiro:FindFirstChild("CarFixObjective")
            if not minigamePath then return end

            local carPartsFolder = minigamePath:FindFirstChild("CarParts")
            local vehicle = minigamePath:FindFirstChild("Vehicle")
            local vehicleBuilder = vehicle and vehicle:FindFirstChild("Builder")
            if not carPartsFolder or not vehicleBuilder then return end

            local wheelSlots = {
                vehicleBuilder:FindFirstChild("FL"),
                vehicleBuilder:FindFirstChild("FR"),
                vehicleBuilder:FindFirstChild("RL"),
                vehicleBuilder:FindFirstChild("RR")
            }
            local mainPart = vehicleBuilder:FindFirstChild("Main")

            local validPartNames = {
                ["Car Wheel"] = true, ["GasCan"] = true, ["Gas Can"] = true,
                ["V8 Engine"] = true, ["Steering Wheel"] = true
            }

            local function triggerPrompt(parentObject)
                local prompt = parentObject:FindFirstChildWhichIsA("ProximityPrompt", true)
                if prompt then
                    prompt.HoldDuration = 0
                    prompt.RequiresLineOfSight = false
                    pcall(function()
                        if fireproximityprompt then
                            fireproximityprompt(prompt)
                        else
                            prompt:InputHoldBegin()
                            task.wait(0.05)
                            prompt:InputHoldEnd()
                        end
                    end)
                end
            end

            local function teleportTo(targetObject)
                local targetCFrame
                if targetObject:IsA("BasePart") then targetCFrame = targetObject.CFrame
                elseif targetObject:IsA("Attachment") then targetCFrame = targetObject.WorldCFrame
                elseif targetObject:IsA("Model") then targetCFrame = targetObject:GetPivot() end

                if targetCFrame and hrp then
                    hrp.AssemblyLinearVelocity = Vector3.zero
                    hrp.AssemblyAngularVelocity = Vector3.zero
                    char:PivotTo(targetCFrame + Vector3.new(0, 3, 0))
                    task.wait(0.2)
                end
            end

            local availableParts = {}
            for _, object in ipairs(carPartsFolder:GetChildren()) do
                if object:IsA("BasePart") or object:IsA("Model") then
                    table.insert(availableParts, object)
                end
            end

            local currentWheelIndex = 1

            for i = 1, #availableParts, 3 do
                local batchCollectedNames = {}
                for j = i, math.min(i + 2, #availableParts) do
                    local part = availableParts[j]
                    if part and part.Parent then
                        teleportTo(part)
                        triggerPrompt(part)
                        table.insert(batchCollectedNames, part.Name)
                        task.wait(0.3)
                    end
                end

                for _, itemName in ipairs(batchCollectedNames) do
                    local backpack = player:FindFirstChild("Backpack")
                    local tool = backpack and backpack:FindFirstChild(itemName)
                    if not tool and char then tool = char:FindFirstChild(itemName) end

                    if tool and tool:IsA("Tool") and validPartNames[tool.Name] then
                        if tool.Parent == backpack then
                            char.Humanoid:EquipTool(tool)
                            task.wait(0.3)
                        end

                        if tool.Name == "Car Wheel" then
                            if currentWheelIndex <= #wheelSlots then
                                local targetSlot = wheelSlots[currentWheelIndex]
                                teleportTo(targetSlot)
                                triggerPrompt(targetSlot)
                                currentWheelIndex += 1
                            end
                        else
                            teleportTo(mainPart)
                            triggerPrompt(mainPart)
                        end
                        task.wait(0.3)
                    end
                end
            end
        end)
    end
})

MallParking:Section("Chihiro Minigame")

-- ==========================================
-- FIX CHIHIRO MINIGAME
-- ==========================================
MallParking:Button({
    Title = "Fix Chihiro Minigame",
    Callback = function()
        local PlayerGui = game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui")
        local gui = PlayerGui and PlayerGui:FindFirstChild("S2.5")
        if gui then
            local scriptObj = gui:FindFirstChild("LocalScript")
            if scriptObj and scriptObj:IsA("LocalScript") then
                scriptObj.Enabled = false
                task.wait(0.2)
                scriptObj.Enabled = true
            end
        end
    end
})

-- ==========================================
-- ANSWER & CHAT LOGIC (No Lag)
-- ==========================================
local answerMap = {  
    ["i was once a curious girl, now i wear a white dress and a pink hat, forever smiling. who am i?"] = "Hiachi Masashige",  
    ["i sit quietly, made of stone, and show the way to a sacred throne. what am i?"] = "Torii Gate",  
    ["flames consume at my decree, yokai kneel and follow me. jealous hearts, i twist and pry, for my father, worlds will die. speak my name, who am i?"] = "Enzukai",  
    ["i guard the shrine in silence, standing still with fierce eyes. what am i?"] = "A Komainu",  
    ["what is our cult name?"] = "Kiiroibara Cult",  
    ["i am pathetic, regretful, and i'm the reason my brother died. who am i?"] = "Me",  
    ["i bloom in spring, soft and sweet, pink and white, on branches i greet. i am kintoru's favorite. what am i?"] = "Cherry Blossom",  
    ["i have no voice, yet i tell stories in ink. i'm soft in your hand, but i carve into time. what am i?"] = "A Brush",  
    ["four i shaped in shadows dire— flames of envy, a burning pyre. chains of control, unyielding, tight, one reborn, one filled with spite, who forged them all? speak my fate."] = "Evil God"  
}  

local function getCorrectAnswer()
    local PlayerGui = game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui")
    local SectionGui = PlayerGui and PlayerGui:FindFirstChild("S2.5")
    if not SectionGui then return nil end

    local QuestionLabel = SectionGui:FindFirstChild("Questions") and SectionGui.Questions:FindFirstChild("Question")
    if not QuestionLabel then return nil end

    local questionText = QuestionLabel.Text:lower():gsub("%s+", " "):gsub("^%s*(.-)%s*$", "%1")
    return answerMap[questionText], QuestionLabel.Text
end

MallParking:Button({
    Title = "Answer",
    Callback = function()
        local correctAnswer, rawQuestion = getCorrectAnswer()
        if not correctAnswer then
            Window:Notify({ Title = "No Match Found", Content = "Question not recognized.", Duration = 5 })
            return
        end

        local PlayerGui = game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui")
        local SectionGui = PlayerGui and PlayerGui:FindFirstChild("S2.5")
        local Selectors = SectionGui and SectionGui:FindFirstChild("Selectors")
        
        if not Selectors then return end

        local chosenIndex = nil
        for index, selector in ipairs(Selectors:GetChildren()) do
            local label = selector:FindFirstChild("Label", true)
            if label and label:IsA("TextLabel") then
                local answerText = label.Text:lower():gsub("%s+", " "):gsub("^%s*(.-)%s*$", "%1")
                local expected = correctAnswer:lower():gsub("%s+", " "):gsub("^%s*(.-)%s*$", "%1")
                if answerText == expected then
                    chosenIndex = index
                    break
                end
            end
        end

        if chosenIndex then
            local s25 = workspace:FindFirstChild("Section2.5")
            local chihiro = s25 and s25:FindFirstChild("ChihiroMinigame")
            local trivia = chihiro and chihiro:FindFirstChild("Trivia")
            local signal = trivia and trivia:FindFirstChild("Signal")

            if signal then
                signal:FireServer(1, chosenIndex)
                Window:Notify({ Title = "Correct Answer Found", Content = "Answer: " .. correctAnswer, Duration = 5 })
            end
        else
            Window:Notify({ Title = "Answer Not Found", Content = "Correct answer not in choices.", Duration = 5 })
        end
    end
})

MallParking:Button({
    Title = "Answer & Chat",
    Callback = function()
        local correctAnswer, rawQuestion = getCorrectAnswer()
        if not correctAnswer then
            Window:Notify({ Title = "No Match Found", Content = "Question not recognized.", Duration = 5 })
            return
        end

        -- Click answer
        local PlayerGui = game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui")
        local SectionGui = PlayerGui and PlayerGui:FindFirstChild("S2.5")
        local Selectors = SectionGui and SectionGui:FindFirstChild("Selectors")
        
        if Selectors then
            for index, selector in ipairs(Selectors:GetChildren()) do
                local label = selector:FindFirstChild("Label", true)
                if label and label:IsA("TextLabel") then
                    local answerText = label.Text:lower():gsub("%s+", " "):gsub("^%s*(.-)%s*$", "%1")
                    local expected = correctAnswer:lower():gsub("%s+", " "):gsub("^%s*(.-)%s*$", "%1")
                    if answerText == expected then
                        local s25 = workspace:FindFirstChild("Section2.5")
                        local chihiro = s25 and s25:FindFirstChild("ChihiroMinigame")
                        local trivia = chihiro and chihiro:FindFirstChild("Trivia")
                        local signal = trivia and trivia:FindFirstChild("Signal")
                        if signal then
                            signal:FireServer(1, index)
                        end
                        break
                    end
                end
            end
        end

        -- Chat answer
        task.wait(0.2)
        local TextChatService = game:GetService("TextChatService")
        if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
            local textChannels = TextChatService:FindFirstChild("TextChannels")
            local generalChannel = textChannels and textChannels:FindFirstChild("RBXGeneral")
            if generalChannel then
                generalChannel:SendAsync(correctAnswer)
            end
        else
            -- Legacy chat fallback
            local chatBar = PlayerGui:FindFirstChild("Chat")
            if chatBar then
                local chatBarFrame = chatBar:FindFirstChild("Frame")
                local chatBox = chatBarFrame and chatBarFrame:FindFirstChild("ChatBar")
                if chatBox then
                    chatBox.Text = correctAnswer
                    local VirtualInputManager = game:GetService("VirtualInputManager")
                    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
                    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
                end
            end
        end

        Window:Notify({ Title = "Answer & Chat", Content = "Sent: " .. correctAnswer, Duration = 5 })
    end
})

local TempleTab = Window:CreateTab({ Title = "Temple", Icon = "landmark" })
local TempleMain = TempleTab:CreateSubTab({ Title = "Main", Icon = "gamepad-2", Default = true })

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local function GetPath(...)
    local current = workspace
    for _, name in ipairs({...}) do
        if not current then return nil end
        current = current:FindFirstChild(name)
    end
    return current
end

local function GetValidPart(model)
    if not model then return nil end
    if model:IsA("BasePart") then return model end
    if model:IsA("Model") then
        if model.PrimaryPart then return model.PrimaryPart end
        for _, v in ipairs(model:GetDescendants()) do
            if v:IsA("BasePart") then return v end
        end
    end
    return nil
end

local function GetHRP()
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    return char:WaitForChild("HumanoidRootPart", 5)
end

-- ==================== BLESS INK ====================
TempleMain:Button({
    Title = "Bless Ink",
    Callback = function()
        task.spawn(function()
            local function firePromptIn(target)
                if not target then return end
                local part = GetValidPart(target)
                if not part then return end
                
                local HRP = GetHRP()
                local char = LocalPlayer.Character
                HRP.AssemblyLinearVelocity = Vector3.zero
                HRP.AssemblyAngularVelocity = Vector3.zero
                char:PivotTo(part.CFrame + Vector3.new(0, 3, 0))
                task.wait(0.2)
                
                local prompt = target:FindFirstChildWhichIsA("ProximityPrompt", true)
                if prompt and prompt.Enabled then
                    prompt.HoldDuration = 0
                    prompt.RequiresLineOfSight = false
                    pcall(function()
                        if fireproximityprompt then
                            fireproximityprompt(prompt)
                        else
                            prompt:InputHoldBegin()
                            task.wait(0.05)
                            prompt:InputHoldEnd()
                        end
                    end)
                end
                task.wait(0.3)
            end

            local paintPuzzle = GetPath("Section3", "PaintPuzzle")
            if not paintPuzzle then return end

            -- 1. Teleport to PaintStation_A and fire its prompt
            local stationA = paintPuzzle:FindFirstChild("PaintStation_A")
            if stationA then
                firePromptIn(stationA)
            end

            -- 2. Start the Bless Ink sequence
            local ingredients = paintPuzzle:FindFirstChild("Ingredients")
            if not ingredients then return end

            firePromptIn(ingredients:FindFirstChild("Orchid"))
            firePromptIn(ingredients:FindFirstChild("Water"))
            firePromptIn(ingredients:FindFirstChild("PlaceInkHere"))
        end)
    end
})

-- ==================== TELEPORT CYCLE ====================
local currentPaintIndex = 1
local paintStations = { "PaintStation_A", "PaintStation_B", "PaintStation_C", "PaintStation_D" }

TempleMain:Button({
    Title = "Teleport to Paint",
    Callback = function()
        task.spawn(function()
            local paintPuzzle = GetPath("Section3", "PaintPuzzle")
            if not paintPuzzle then return end

            local targetName = paintStations[currentPaintIndex]
            local target = paintPuzzle:FindFirstChild(targetName)
            
            if target then
                local HRP = GetHRP()
                local part = GetValidPart(target)
                if HRP and part then
                    HRP.AssemblyLinearVelocity = Vector3.zero
                    HRP.AssemblyAngularVelocity = Vector3.zero
                    LocalPlayer.Character:PivotTo(part.CFrame + Vector3.new(0, 3, 0))
                end
            end

            currentPaintIndex = currentPaintIndex + 1
            if currentPaintIndex > #paintStations then
                currentPaintIndex = 1
            end
        end)
    end
})

-- ==================== AUTO DRAW ====================
local StationPoints = {
    PaintStation_A = {Vector2.new(29,44),Vector2.new(34,44),Vector2.new(39,45),Vector2.new(43,46),Vector2.new(47,46),Vector2.new(51,46),Vector2.new(56,46),Vector2.new(61,45),Vector2.new(66,44),Vector2.new(71,44),Vector2.new(75,44),Vector2.new(79,43),Vector2.new(83,43),Vector2.new(87,43),Vector2.new(91,43),Vector2.new(95,43),Vector2.new(99,44),Vector2.new(104,44),Vector2.new(108,44),Vector2.new(112,44),Vector2.new(116,44),Vector2.new(120,44),Vector2.new(124,45),Vector2.new(128,45),Vector2.new(131,49),Vector2.new(133,53),Vector2.new(134,57),Vector2.new(58,72),Vector2.new(58,68),Vector2.new(58,64),Vector2.new(59,59),Vector2.new(59,55),Vector2.new(59,50),Vector2.new(59,39),Vector2.new(60,34),Vector2.new(31,104),Vector2.new(35,104),Vector2.new(39,104),Vector2.new(44,104),Vector2.new(49,104),Vector2.new(53,104),Vector2.new(57,104),Vector2.new(61,104),Vector2.new(65,104),Vector2.new(69,104),Vector2.new(73,105),Vector2.new(74,109),Vector2.new(73,113),Vector2.new(73,117),Vector2.new(73,121),Vector2.new(73,125),Vector2.new(73,100),Vector2.new(73,96),Vector2.new(74,92),Vector2.new(74,88),Vector2.new(74,84),Vector2.new(45,86),Vector2.new(45,90),Vector2.new(46,95),Vector2.new(45,99),Vector2.new(45,109),Vector2.new(46,113),Vector2.new(45,117),Vector2.new(45,121),Vector2.new(82,70),Vector2.new(86,67),Vector2.new(90,64),Vector2.new(94,62),Vector2.new(98,61),Vector2.new(81,104),Vector2.new(86,103),Vector2.new(90,103),Vector2.new(94,103),Vector2.new(98,103),Vector2.new(102,102),Vector2.new(106,103),Vector2.new(110,103),Vector2.new(114,103),Vector2.new(118,103),Vector2.new(122,103),Vector2.new(125,107),Vector2.new(126,111),Vector2.new(128,116),Vector2.new(129,120),Vector2.new(130,124),Vector2.new(130,112),Vector2.new(129,106),Vector2.new(129,102),Vector2.new(127,97),Vector2.new(126,93),Vector2.new(125,89),Vector2.new(123,85),Vector2.new(121,81),Vector2.new(100,88),Vector2.new(100,92),Vector2.new(100,97),Vector2.new(98,107),Vector2.new(97,112),Vector2.new(97,116),Vector2.new(101,118)},
    PaintStation_B = {Vector2.new(28,109),Vector2.new(32,109),Vector2.new(36,111),Vector2.new(40,113),Vector2.new(44,116),Vector2.new(48,119),Vector2.new(51,123),Vector2.new(53,127),Vector2.new(35,105),Vector2.new(39,102),Vector2.new(42,98),Vector2.new(46,96),Vector2.new(64,119),Vector2.new(64,115),Vector2.new(63,111),Vector2.new(63,107),Vector2.new(63,103),Vector2.new(63,99),Vector2.new(68,110),Vector2.new(72,110),Vector2.new(76,110),Vector2.new(80,110),Vector2.new(84,110),Vector2.new(82,114),Vector2.new(82,118),Vector2.new(82,122),Vector2.new(83,126),Vector2.new(84,105),Vector2.new(83,101),Vector2.new(83,97),Vector2.new(99,125),Vector2.new(103,125),Vector2.new(107,125),Vector2.new(111,123),Vector2.new(90,109),Vector2.new(94,109),Vector2.new(98,109),Vector2.new(102,109),Vector2.new(106,109),Vector2.new(110,109),Vector2.new(114,109),Vector2.new(118,109),Vector2.new(122,109),Vector2.new(126,109),Vector2.new(130,109),Vector2.new(130,113),Vector2.new(131,117),Vector2.new(133,121),Vector2.new(133,125),Vector2.new(129,105),Vector2.new(128,100),Vector2.new(127,96),Vector2.new(125,92),Vector2.new(113,98),Vector2.new(109,96),Vector2.new(105,96),Vector2.new(101,95),Vector2.new(138,90),Vector2.new(136,86),Vector2.new(134,82),Vector2.new(132,78),Vector2.new(131,74),Vector2.new(129,70),Vector2.new(126,49),Vector2.new(128,45),Vector2.new(130,41),Vector2.new(131,36),Vector2.new(133,32),Vector2.new(135,38),Vector2.new(137,34),Vector2.new(133,27),Vector2.new(26,59),Vector2.new(30,59),Vector2.new(35,59),Vector2.new(40,59),Vector2.new(40,64),Vector2.new(39,70),Vector2.new(38,74),Vector2.new(38,78),Vector2.new(43,80),Vector2.new(46,84),Vector2.new(42,84),Vector2.new(38,55),Vector2.new(38,49),Vector2.new(37,45),Vector2.new(36,40),Vector2.new(36,36),Vector2.new(49,59),Vector2.new(53,59),Vector2.new(57,59),Vector2.new(57,63),Vector2.new(57,67),Vector2.new(56,71),Vector2.new(56,75),Vector2.new(60,76),Vector2.new(64,77),Vector2.new(68,77),Vector2.new(72,77),Vector2.new(76,78),Vector2.new(80,78),Vector2.new(85,79),Vector2.new(89,79),Vector2.new(93,79),Vector2.new(97,79),Vector2.new(100,75),Vector2.new(99,71),Vector2.new(99,67),Vector2.new(99,63),Vector2.new(100,58),Vector2.new(100,54),Vector2.new(100,50),Vector2.new(100,46),Vector2.new(99,42),Vector2.new(95,39),Vector2.new(91,38),Vector2.new(87,38),Vector2.new(83,38),Vector2.new(79,39),Vector2.new(75,39),Vector2.new(71,39),Vector2.new(67,40),Vector2.new(63,41),Vector2.new(59,45),Vector2.new(59,49),Vector2.new(71,70),Vector2.new(70,66),Vector2.new(71,62),Vector2.new(70,57),Vector2.new(70,53),Vector2.new(70,49),Vector2.new(84,72),Vector2.new(84,67),Vector2.new(84,63),Vector2.new(84,55),Vector2.new(84,51),Vector2.new(85,47),Vector2.new(114,86),Vector2.new(114,82),Vector2.new(115,77),Vector2.new(115,73),Vector2.new(115,68),Vector2.new(115,62),Vector2.new(115,58),Vector2.new(115,54),Vector2.new(115,50),Vector2.new(115,46),Vector2.new(116,42),Vector2.new(115,38),Vector2.new(118,34)},
    PaintStation_C = {Vector2.new(37,123),Vector2.new(37,119),Vector2.new(38,115),Vector2.new(38,111),Vector2.new(34,110),Vector2.new(35,105),Vector2.new(38,100),Vector2.new(39,95),Vector2.new(41,91),Vector2.new(61,92),Vector2.new(62,96),Vector2.new(62,100),Vector2.new(62,104),Vector2.new(61,108),Vector2.new(61,112),Vector2.new(62,116),Vector2.new(61,120),Vector2.new(62,124),Vector2.new(67,107),Vector2.new(71,107),Vector2.new(75,107),Vector2.new(79,107),Vector2.new(83,107),Vector2.new(87,107),Vector2.new(91,107),Vector2.new(95,107),Vector2.new(99,108),Vector2.new(103,108),Vector2.new(107,108),Vector2.new(111,108),Vector2.new(115,108),Vector2.new(119,108),Vector2.new(123,108),Vector2.new(127,108),Vector2.new(131,108),Vector2.new(135,108),Vector2.new(139,108),Vector2.new(81,122),Vector2.new(85,122),Vector2.new(89,122),Vector2.new(93,122),Vector2.new(98,123),Vector2.new(102,123),Vector2.new(106,123),Vector2.new(110,123),Vector2.new(115,124),Vector2.new(119,125),Vector2.new(81,93),Vector2.new(85,94),Vector2.new(89,94),Vector2.new(93,94),Vector2.new(97,94),Vector2.new(101,94),Vector2.new(105,94),Vector2.new(109,94),Vector2.new(32,47),Vector2.new(37,43),Vector2.new(42,41),Vector2.new(45,34),Vector2.new(47,30),Vector2.new(57,80),Vector2.new(57,73),Vector2.new(57,68),Vector2.new(57,61),Vector2.new(57,56),Vector2.new(58,50),Vector2.new(58,46),Vector2.new(58,40),Vector2.new(58,36),Vector2.new(58,32),Vector2.new(31,67),Vector2.new(35,68),Vector2.new(40,68),Vector2.new(44,68),Vector2.new(48,69),Vector2.new(53,68),Vector2.new(62,67),Vector2.new(67,67),Vector2.new(72,67),Vector2.new(77,68),Vector2.new(81,68),Vector2.new(85,69),Vector2.new(90,70),Vector2.new(95,71),Vector2.new(99,72),Vector2.new(104,74),Vector2.new(108,76),Vector2.new(112,77),Vector2.new(116,79),Vector2.new(121,81),Vector2.new(125,83),Vector2.new(129,85),Vector2.new(133,86),Vector2.new(84,62),Vector2.new(89,62),Vector2.new(93,61),Vector2.new(98,60),Vector2.new(102,58),Vector2.new(106,53),Vector2.new(110,51),Vector2.new(114,49),Vector2.new(118,45),Vector2.new(123,41),Vector2.new(128,37),Vector2.new(131,33),Vector2.new(134,29),Vector2.new(74,38),Vector2.new(78,38),Vector2.new(83,38),Vector2.new(89,40),Vector2.new(94,41),Vector2.new(99,43),Vector2.new(103,44),Vector2.new(108,46),Vector2.new(118,51),Vector2.new(123,53),Vector2.new(127,57),Vector2.new(131,62),Vector2.new(132,66),Vector2.new(135,70)},
    PaintStation_D = {Vector2.new(97,65),Vector2.new(100,71),Vector2.new(104,79),Vector2.new(101,74),Vector2.new(108,85),Vector2.new(112,88),Vector2.new(109,80),Vector2.new(103,67),Vector2.new(106,75),Vector2.new(98,53),Vector2.new(101,63),Vector2.new(99,58),Vector2.new(94,47),Vector2.new(98,47),Vector2.new(103,53),Vector2.new(101,123),Vector2.new(105,123),Vector2.new(109,123),Vector2.new(114,123),Vector2.new(118,123),Vector2.new(122,123),Vector2.new(101,94),Vector2.new(107,92),Vector2.new(111,93),Vector2.new(82,127),Vector2.new(80,120),Vector2.new(81,115),Vector2.new(81,111),Vector2.new(81,106),Vector2.new(79,101),Vector2.new(79,97),Vector2.new(66,93),Vector2.new(70,92),Vector2.new(74,92),Vector2.new(78,90),Vector2.new(83,88),Vector2.new(29,110),Vector2.new(33,110),Vector2.new(37,111),Vector2.new(42,112),Vector2.new(47,115),Vector2.new(49,119),Vector2.new(48,124),Vector2.new(44,125),Vector2.new(53,119),Vector2.new(57,115),Vector2.new(61,111),Vector2.new(40,94),Vector2.new(45,97),Vector2.new(50,99),Vector2.new(54,101),Vector2.new(58,103),Vector2.new(62,106),Vector2.new(66,109),Vector2.new(69,113),Vector2.new(73,115),Vector2.new(87,109),Vector2.new(93,109),Vector2.new(100,109),Vector2.new(105,110),Vector2.new(109,110),Vector2.new(113,110),Vector2.new(117,110),Vector2.new(121,110),Vector2.new(126,110),Vector2.new(131,110),Vector2.new(45,80),Vector2.new(45,75),Vector2.new(46,70),Vector2.new(46,64),Vector2.new(46,60),Vector2.new(46,56),Vector2.new(46,51),Vector2.new(46,47),Vector2.new(47,43),Vector2.new(47,38),Vector2.new(46,34),Vector2.new(44,30),Vector2.new(25,58),Vector2.new(31,58),Vector2.new(38,59),Vector2.new(34,58),Vector2.new(41,59),Vector2.new(51,58),Vector2.new(55,59),Vector2.new(59,58),Vector2.new(63,58),Vector2.new(67,58),Vector2.new(71,58),Vector2.new(71,79),Vector2.new(71,75),Vector2.new(72,70),Vector2.new(72,64),Vector2.new(70,54),Vector2.new(71,50),Vector2.new(71,46),Vector2.new(71,41),Vector2.new(71,36),Vector2.new(71,32),Vector2.new(132,75),Vector2.new(128,75),Vector2.new(123,75),Vector2.new(119,76),Vector2.new(115,77),Vector2.new(111,76),Vector2.new(93,78),Vector2.new(93,72),Vector2.new(96,42),Vector2.new(96,38),Vector2.new(96,34),Vector2.new(100,34),Vector2.new(105,34),Vector2.new(111,34),Vector2.new(117,34),Vector2.new(122,35),Vector2.new(127,35),Vector2.new(131,35),Vector2.new(135,35),Vector2.new(126,40),Vector2.new(126,46),Vector2.new(126,51),Vector2.new(127,55),Vector2.new(126,59),Vector2.new(128,63),Vector2.new(128,67),Vector2.new(128,71)}
}

local function getNearestStation()
    local HRP = GetHRP()
    if not HRP then return nil end

    local paintPuzzle = GetPath("Section3", "PaintPuzzle")
    if not paintPuzzle then return nil end

    local playerPos = HRP.Position
    local nearestStation = nil
    local shortestDistance = math.huge

    for name, points in pairs(StationPoints) do
        local stationModel = paintPuzzle:FindFirstChild(name)
        if stationModel and stationModel:FindFirstChild("Pad") then
            local pad = stationModel.Pad
            local padPos = pad:GetPivot().Position
            local distance = (playerPos - padPos).Magnitude
            if distance < shortestDistance then
                shortestDistance = distance
                local remote = pad:FindFirstChild("Controls") and pad.Controls:FindFirstChild("Draw")
                if remote then
                    nearestStation = { Remote = remote, Points = points }
                end
            end
        end
    end
    return nearestStation
end

TempleMain:Button({
    Title = "Auto Draw",
    Callback = function()
        task.spawn(function()
            local nearestStation = getNearestStation()
            if nearestStation and nearestStation.Remote then
                for _, point in ipairs(nearestStation.Points) do
                    pcall(function()
                        nearestStation.Remote:FireServer(CFrame.new(), point, 0)
                    end)
                end
            else
                warn("Could not find a valid PaintStation nearby!")
            end
        end)
    end
})

-- ==================== SUBMIT DRAWING ====================
local currentPillarIndex = 1
local totalPillars = 4

TempleMain:Button({
    Title = "Submit Drawing",
    Callback = function()
        task.spawn(function()
            local HRP = GetHRP()
            if not HRP then return end

            local folder = GetPath("Section3", "MagicPillars")
            if not folder then return end

            local pillars = {}
            for _, v in ipairs(folder:GetChildren()) do
                if v:IsA("Model") and v.Name == "Pillar" then
                    table.insert(pillars, v)
                end
            end

            table.sort(pillars, function(a, b)
                return a:GetFullName() < b:GetFullName()
            end)

            local targetPillar = pillars[currentPillarIndex]
            if targetPillar then
                local basePart = targetPillar:FindFirstChildWhichIsA("BasePart")
                if basePart then
                    HRP.AssemblyLinearVelocity = Vector3.zero
                    HRP.AssemblyAngularVelocity = Vector3.zero
                    LocalPlayer.Character:PivotTo(basePart.CFrame + Vector3.new(0, 3, 0))
                end
            end

            currentPillarIndex += 1
            if currentPillarIndex > totalPillars then
                currentPillarIndex = 1
            end
        end)
    end
})

-- ==================== COLLECT BOW & EXIT ====================
TempleMain:Button({
    Title = "Collect Bow & Exit",
    Callback = function()
        task.spawn(function()
            local function triggerPrompt(parentObject)
                if not parentObject then return end
                local prompt = parentObject:FindFirstChildWhichIsA("ProximityPrompt", true)
                if prompt then
                    prompt.HoldDuration = 0
                    prompt.RequiresLineOfSight = false
                    pcall(function()
                        if fireproximityprompt then
                            fireproximityprompt(prompt)
                        else
                            prompt:InputHoldBegin()
                            task.wait(0.05)
                            prompt:InputHoldEnd()
                        end
                    end)
                end
            end

            local function pivotTeleport(targetObject)
                local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
                local HRP = char and char:FindFirstChild("HumanoidRootPart")
                if targetObject and HRP then
                    local targetCFrame = targetObject:GetPivot()
                    HRP.AssemblyLinearVelocity = Vector3.zero
                    HRP.AssemblyAngularVelocity = Vector3.zero
                    char:PivotTo(targetCFrame + Vector3.new(0, 3, 0))
                    task.wait(0.3)
                end
            end

            -- Collect Magic Bow
            local magicBow = GetPath("Section3", "BowPuzzle", "MagicBow")
            if magicBow then
                pivotTeleport(magicBow)
                triggerPrompt(magicBow)
            end

            task.wait(5)

            -- Exit (GameStart)
            local gameStart = GetPath("Section3", "Monster", "GameStart")
            if gameStart then
                pivotTeleport(gameStart)
            end
        end)
    end
})

local TempleESP = TempleTab:CreateSubTab({ Title = "ESP", Icon = "eye" })

local espStationsEnabled = false
local stationHighlights = {}

local function applyStationESP(obj)
    if not obj or stationHighlights[obj] or not espStationsEnabled then return end
    local hl = Instance.new("Highlight")
    hl.Adornee = obj
    hl.FillColor = Color3.fromRGB(0, 255, 0)
    hl.OutlineColor = Color3.fromRGB(0, 255, 0)
    hl.FillTransparency = 0.5
    hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = obj
    stationHighlights[obj] = hl
end

local function clearStationESP()
    for obj, hl in pairs(stationHighlights) do pcall(function() hl:Destroy() end) end
    table.clear(stationHighlights)
end

TempleESP:Toggle({
    Title = "Paint Stations",
    Default = false,
    Callback = function(state)
        espStationsEnabled = state
        clearStationESP()
        if not espStationsEnabled then return end
        
        task.spawn(function()
            local paintPuzzle = workspace:FindFirstChild("Section3") and workspace.Section3:FindFirstChild("PaintPuzzle")
            if not paintPuzzle then return end
            
            local pads = {
                paintPuzzle:FindFirstChild("PaintStation_A") and paintPuzzle.PaintStation_A:FindFirstChild("Pad"),
                paintPuzzle:FindFirstChild("PaintStation_B") and paintPuzzle.PaintStation_B:FindFirstChild("Pad"),
                paintPuzzle:FindFirstChild("PaintStation_C") and paintPuzzle.PaintStation_C:FindFirstChild("Pad"),
                paintPuzzle:FindFirstChild("PaintStation_D") and paintPuzzle.PaintStation_D:FindFirstChild("Pad")
            }
            
            for _, pad in ipairs(pads) do
                if pad then applyStationESP(pad) end
            end
        end)
    end
})

local espIngredientsEnabled = false
local ingredientHighlights = {}
local ingredientConnection = nil

local function applyIngredientESP(obj)
    if not obj or ingredientHighlights[obj] or not espIngredientsEnabled then return end
    if not (obj:IsA("Model") or obj:IsA("BasePart")) then return end

    local color = nil
    local name = obj.Name
    
    if name:find("Orchid") then
        color = Color3.fromRGB(255, 255, 0)
    elseif name:find("Water") then
        color = Color3.fromRGB(0, 0, 255)
    elseif name:find("PlaceInkHere") then
        color = Color3.fromRGB(170, 0, 255)
    end

    if color then
        local hl = Instance.new("Highlight")
        hl.Adornee = obj
        hl.FillColor = color
        hl.OutlineColor = color
        hl.FillTransparency = 0.5
        hl.OutlineTransparency = 0
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Parent = obj
        ingredientHighlights[obj] = hl
    end
end

local function clearIngredientESP()
    if ingredientConnection then
        ingredientConnection:Disconnect()
        ingredientConnection = nil
    end
    for obj, hl in pairs(ingredientHighlights) do 
        pcall(function() hl:Destroy() end) 
    end
    table.clear(ingredientHighlights)
end

TempleESP:Toggle({
    Title = "Ingredients",
    Default = false,
    Callback = function(state)
        espIngredientsEnabled = state
        clearIngredientESP()
        
        if not espIngredientsEnabled then return end
        
        task.spawn(function()
            local paintPuzzle = workspace:FindFirstChild("Section3") and workspace.Section3:FindFirstChild("PaintPuzzle")
            local ingredients = paintPuzzle and paintPuzzle:FindFirstChild("Ingredients")
            if not ingredients then return end
            
            for _, obj in ipairs(ingredients:GetChildren()) do
                applyIngredientESP(obj)
            end
            
            ingredientConnection = ingredients.ChildAdded:Connect(function(obj)
                if espIngredientsEnabled then
                    applyIngredientESP(obj)
                end
            end)
        end)
    end
})

TempleESP:Section("Monster")

local espMonsterEnabled = false
local monsterHighlights = {}
local monsterBillboards = {}
local monsterConnections = {}

local function applyMonsterESP(obj)
    if not obj or obj.Name ~= "Senzai" or monsterHighlights[obj] or not espMonsterEnabled then return end
    if not obj:IsA("Model") then return end

    local hl = Instance.new("Highlight")
    hl.Adornee = obj
    hl.FillColor = Color3.fromRGB(255, 0, 0)
    hl.OutlineColor = Color3.fromRGB(0, 0, 0)
    hl.FillTransparency = 0.5
    hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = obj
    monsterHighlights[obj] = hl

    local bb = Instance.new("BillboardGui")
    bb.Size = UDim2.new(0, 200, 0, 50)
    bb.StudsOffset = Vector3.new(0, 3, 0)
    bb.AlwaysOnTop = true
    bb.Parent = obj

    local tl = Instance.new("TextLabel")
    tl.Size = UDim2.new(1, 0, 1, 0)
    tl.BackgroundTransparency = 1
    tl.Text = obj.Name
    tl.TextColor3 = Color3.fromRGB(255, 0, 0)
    tl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    tl.TextStrokeTransparency = 0
    tl.TextSize = 13
    tl.Font = Enum.Font.FredokaOne
    tl.Parent = bb
    monsterBillboards[obj] = bb
end

local function clearMonsterESP()
    for _, conn in ipairs(monsterConnections) do pcall(function() conn:Disconnect() end) end
    table.clear(monsterConnections)
    for obj, hl in pairs(monsterHighlights) do pcall(function() hl:Destroy() end) end
    for obj, bb in pairs(monsterBillboards) do pcall(function() bb:Destroy() end) end
    table.clear(monsterHighlights)
    table.clear(monsterBillboards)
end

local function setupMonsterFolder(folder)
    if not folder then return end
    for _, child in ipairs(folder:GetChildren()) do
        if child.Name == "Senzai" then
            applyMonsterESP(child)
        end
    end
    table.insert(monsterConnections, folder.ChildAdded:Connect(function(inst)
        if espMonsterEnabled and inst.Name == "Senzai" then 
            applyMonsterESP(inst) 
        end
    end))
end

TempleESP:Toggle({
    Title = "Senzai",
    Default = false,
    Callback = function(state)
        espMonsterEnabled = state
        clearMonsterESP()
        if not espMonsterEnabled then return end

        task.spawn(function()
            local s3 = workspace:FindFirstChild("Section3")
            local monsterFolder = s3 and s3:FindFirstChild("Monster")
            if monsterFolder then
                setupMonsterFolder(monsterFolder)
            end
        end)
    end
})

local StreetTokyoTab = Window:CreateTab({ Title = "StreetTokyo", Icon = "building" })
local StreetTokyoMain = StreetTokyoTab:CreateSubTab({ Title = "Main", Icon = "gamepad-2", Default = true })
local StreetTokyoESP = StreetTokyoTab:CreateSubTab({ Title = "ESP", Icon = "eye" })

-- ==========================================
-- 1. RESCUE SURVIVOR
-- ==========================================
StreetTokyoMain:Button({
    Title = "Rescue Survivor",
    Callback = function()
        task.spawn(function()
            local player = game:GetService("Players").LocalPlayer
            local Character = player.Character or player.CharacterAdded:Wait()
            local HRP = Character:FindFirstChild("HumanoidRootPart")
            if not HRP then return end

            local s4 = workspace:FindFirstChild("Section4")
            local rescue = s4 and s4:FindFirstChild("Rescue")
            local npcFolder = rescue and rescue:FindFirstChild("NPCs")
            if not npcFolder then return end

            local poses = {}
            for _, obj in ipairs(npcFolder:GetChildren()) do
                if #poses >= 3 then break end
                if obj:IsA("Model") and obj.Name:lower():find("pose") then
                    table.insert(poses, obj)
                end
            end

            local function getPrimaryPart(model)
                if not model then return nil end
                if model:IsA("Model") then
                    return model.PrimaryPart or model:FindFirstChild("HumanoidRootPart") or model:FindFirstChildWhichIsA("BasePart")
                elseif model:IsA("BasePart") then
                    return model
                end
                return nil
            end

            for _, pose in ipairs(poses) do
                local targetPart = getPrimaryPart(pose)
                if targetPart then
                    HRP.AssemblyLinearVelocity = Vector3.zero
                    HRP.AssemblyAngularVelocity = Vector3.zero
                    Character:PivotTo(targetPart.CFrame + Vector3.new(0, 3, 0))
                    task.wait(0.2)
                    
                    local prompt = pose:FindFirstChildWhichIsA("ProximityPrompt", true)
                    if prompt and prompt.Enabled then
                        prompt.HoldDuration = 0
                        prompt.RequiresLineOfSight = false
                        pcall(function()
                            if fireproximityprompt then
                                fireproximityprompt(prompt)
                            else
                                prompt:InputHoldBegin()
                                task.wait(0.05)
                                prompt:InputHoldEnd()
                            end
                        end)
                    end
                    task.wait(0.2)
                end
            end

            local rescuePoint = rescue and rescue:FindFirstChild("RescuePoint")
            if rescuePoint and rescuePoint:IsA("BasePart") then
                HRP.AssemblyLinearVelocity = Vector3.zero
                HRP.AssemblyAngularVelocity = Vector3.zero
                Character:PivotTo(rescuePoint.CFrame + Vector3.new(0, 3, 0))
            end
        end)
    end
})

-- ==========================================
-- 2. AUTO ENZUKAI (SECTION 4 PLANE)
-- ==========================================
do
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local Workspace = game:GetService("Workspace")
    local LocalPlayer = Players.LocalPlayer

    local isToggled = false
    local mainTask = nil
    local floatConnection = nil
    local currentHoverCFrame = nil
    local isFlightActive = false
    local noclipConnection = nil

    local function getPerfectAimDirection(bow, targetPart, fallbackRoot, arrowSpeed)
        if not targetPart or not targetPart.Parent then return Vector3.new(0, 1, 0) end
        local originPart = bow and (bow:FindFirstChild("Handle") or bow:FindFirstChild("Muzzle"))
        local originPos = originPart and originPart.Position or (fallbackRoot and fallbackRoot.Position)
        if not originPos then return Vector3.new(0, 1, 0) end

        local speed = arrowSpeed or 300
        local targetPos = targetPart.Position
        local velocity = targetPart:IsA("BasePart") and targetPart.AssemblyLinearVelocity or Vector3.zero
        local distance = (targetPos - originPos).Magnitude
        local flightTime = distance / speed

        local predicted = targetPos + velocity * flightTime
        local gravity = Workspace.Gravity
        local compensated = predicted + Vector3.new(0, 0.5 * gravity * flightTime ^ 2, 0)
        
        if Workspace.CurrentCamera then
            Workspace.CurrentCamera.CFrame = CFrame.lookAt(Workspace.CurrentCamera.CFrame.Position, compensated)
        end
        
        return (compensated - originPos).Unit
    end

    local function enableFloat(rootPart)
        if floatConnection then return end
        floatConnection = RunService.PreRender:Connect(function()
            if isToggled and rootPart and rootPart.Parent then
                rootPart.AssemblyLinearVelocity = Vector3.zero
                rootPart.AssemblyAngularVelocity = Vector3.zero
                if currentHoverCFrame then rootPart.CFrame = currentHoverCFrame end
            end
        end)
    end

    local function disableFloat()
        if floatConnection then floatConnection:Disconnect() floatConnection = nil end
        currentHoverCFrame = nil
    end

    local function enableNoclip()
        if noclipConnection then return end
        noclipConnection = RunService.Stepped:Connect(function()
            local char = LocalPlayer.Character
            if char then
                for _, p in ipairs(char:GetDescendants()) do
                    if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end
                end
            end
        end)
    end

    local function disableNoclip()
        if noclipConnection then noclipConnection:Disconnect() noclipConnection = nil end
    end

    -- More flexible find
    local function findActiveWeakPoint()
        local s4 = Workspace:FindFirstChild("Section4")
        local folder = s4 and s4:FindFirstChild("WeakPoints") and s4.WeakPoints:FindFirstChild("Points")
        if not folder then return nil end
        
        for _, model in ipairs(folder:GetChildren()) do
            local icon = model:FindFirstChild("Icon") or model:FindFirstChild("Icon", true)
            local billboard = icon and (icon:IsA("BillboardGui") and icon or icon:FindFirstChildWhichIsA("BillboardGui", true))
            
            if billboard and billboard.Enabled then
                return model, billboard
            end
            task.wait(0.01)
        end
        return nil
    end

    local function getBoss()
        local s4 = Workspace:FindFirstChild("Section4")
        local boss = s4 and s4:FindFirstChild("BossMonster") and s4.BossMonster:FindFirstChild("EnzukaiRyu")
        if not boss then return nil end
        local plane = boss:FindFirstChild("Plane.009") or boss:FindFirstChild("Plane.015") or boss:FindFirstChild("Plane.014")
        local hitbox = boss:FindFirstChild("Hitbox") or plane
        local hitEvent = boss:FindFirstChild("HitEvent")
        local hrp = boss:FindFirstChild("HumanoidRootPart")
        return plane, hitbox, hitEvent, hrp and hrp:FindFirstChild("FlightSFX")
    end

    local function equipSpiritBow(character, humanoid)
        local bowInChar = character:FindFirstChild("SpiritBow")
        if bowInChar then return bowInChar end
        local backpack = LocalPlayer:FindFirstChild("Backpack")
        local bowInBackpack = backpack and backpack:FindFirstChild("SpiritBow")
        if bowInBackpack and humanoid then
            humanoid:EquipTool(bowInBackpack)
            task.wait(0.1)
            return character:FindFirstChild("SpiritBow")
        end
        return nil
    end

    local function getClearShotPos(originCFrame, targetPart)
        if not targetPart then return originCFrame.Position end
        local rp = RaycastParams.new()
        rp.FilterType = Enum.RaycastFilterType.Exclude
        rp.FilterDescendantsInstances = { LocalPlayer.Character, Workspace.CurrentCamera }
        rp.IgnoreWater = true
        
        local targetPos = targetPart.Position
        local offsets = {
            originCFrame * CFrame.new(0, 30, 25),
            originCFrame * CFrame.new(25, 30, 0),
            originCFrame * CFrame.new(-25, 30, 0),
            originCFrame * CFrame.new(0, 30, -25),
            originCFrame * CFrame.new(0, 45, 0)
        }
        
        for _, testCF in ipairs(offsets) do
            local hit = Workspace:Raycast(testCF.Position, targetPos - testCF.Position, rp)
            if not hit or hit.Instance:IsDescendantOf(targetPart.Parent) then
                return testCF.Position
            end
        end
        return offsets[1].Position
    end

    local function runCombinedAutomation()
        local hitConn = nil
        local _, _, hitEvent = getBoss()
        if hitEvent and hitEvent:IsA("RemoteEvent") then
            hitConn = hitEvent.OnClientEvent:Connect(function() isFlightActive = true end)
        end

        while isToggled do
            local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
            local hum = char:FindFirstChildOfClass("Humanoid")
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if not hrp or not hum then task.wait(0.5) continue end

            -- FLIGHT PHASE
            if isFlightActive then
                disableFloat()
                disableNoclip()
                hrp.CFrame = CFrame.new(30, 126, -2868)
                task.wait(1)
                
                local _, _, _, sfx = getBoss()
                local flightStart = tick()
                while isToggled and sfx and sfx.IsPlaying and (tick() - flightStart) < 15 do
                    task.wait(0.5)
                end
                
                isFlightActive = false
                
                -- WAIT FOR WEAK POINT TO APPEAR (prevents going to boss prematurely)
                local waitStart = tick()
                while isToggled and (tick() - waitStart) < 10 do
                    if findActiveWeakPoint() then 
                        task.wait(0.5)
                        break 
                    end
                    task.wait(0.3)
                end
                continue
            end

            local model, icon = findActiveWeakPoint()
            local plane, hitbox, _, sfx = getBoss()

            if model and icon then
                -- WEAK POINT PHASE
                local bow = equipSpiritBow(char, hum)
                if bow and bow:FindFirstChild("RemoteEvent") then
                    enableFloat(hrp)
                    local shotSomething = false
                    for _, name in ipairs({"EyeA", "EyeB", "EyeC", "EyeD", "EyeE", "HitboxA", "HitboxB", "HitboxC", "HitboxD", "HitboxE"}) do
                        local eye = model:FindFirstChild(name, true)
                        if isToggled and eye and eye:IsA("BasePart") and eye.Transparency < 1 then
                            shotSomething = true
                            while isToggled and eye.Transparency < 1 and icon.Enabled do
                                local shotPos = getClearShotPos(eye.CFrame, eye)
                                currentHoverCFrame = CFrame.lookAt(shotPos, eye.Position)
                                hrp.CFrame = currentHoverCFrame
                                
                                pcall(function() bow.RemoteEvent:FireServer(0, true) end)
                                task.wait(0.8)
                                if eye and eye.Parent then
                                    pcall(function() bow.RemoteEvent:FireServer(0, false, getPerfectAimDirection(bow, eye, hrp, 300)) end)
                                end
                                task.wait(0.2)
                            end
                        end
                    end
                    if not shotSomething then
                        task.wait(0.5)
                    end
                end
            elseif hitbox and hitbox:IsA("BasePart") and not isFlightActive then
                -- BOSS PHASE
                local bow = equipSpiritBow(char, hum)
                if bow and bow:FindFirstChild("RemoteEvent") then
                    enableFloat(hrp)
                    enableNoclip() 
                    while isToggled and not isFlightActive do
                        -- BREAK if weak point appeared (prioritize weak point)
                        if findActiveWeakPoint() then break end
                        
                        local cp, ch, _, cs = getBoss()
                        if cs and cs:IsA("Sound") and cs.IsPlaying then isFlightActive = true break end
                        if not cp then break end

                        local targetPart = ch or cp
                        local shotPos = cp.Position - Vector3.new(0, 40, 0)
                        
                        currentHoverCFrame = CFrame.lookAt(shotPos, targetPart.Position)
                        hrp.CFrame = currentHoverCFrame
                        
                        pcall(function() bow.RemoteEvent:FireServer(0, true) end)
                        task.wait(0.8) 

                        if cp and cp:IsA("BasePart") and ch then
                            local newShotPos = cp.Position - Vector3.new(0, 40, 0)
                            currentHoverCFrame = CFrame.lookAt(newShotPos, ch.Position)
                            hrp.CFrame = currentHoverCFrame
                        end
                        
                        if cs and cs:IsA("Sound") and cs.IsPlaying then isFlightActive = true break end

                        if not isToggled or isFlightActive then break end
                        if ch then 
                            pcall(function() bow.RemoteEvent:FireServer(0, false, getPerfectAimDirection(bow, ch, hrp, 300)) end) 
                        end
                        task.wait(0.2)
                    end
                    disableNoclip()
                end
            else
                disableFloat()
                task.wait(1) 
            end
        end

        if hitConn then hitConn:Disconnect() end
        disableFloat()
        disableNoclip()
    end

    StreetTokyoMain:Toggle({
        Title = "Auto Enzukai",
        Default = false,
        Callback = function(state)
            isToggled = state
            isFlightActive = false
            if isToggled then
                if mainTask then task.cancel(mainTask) end
                mainTask = task.spawn(function()
                    local ok, err = pcall(runCombinedAutomation)
                    if not ok then warn("[Auto Enzukai] Error:", err) end
                end)
            else
                disableFloat()
                disableNoclip()
                if mainTask then task.cancel(mainTask) mainTask = nil end
            end
        end
    })
end

-- ==========================================
-- 3. AUTO 3 MONSTERS (Fixed: Teleport to prompt)
-- ==========================================
do
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local Workspace = game:GetService("Workspace")
    local LocalPlayer = Players.LocalPlayer

    local isToggled = false
    local mainTask = nil
    local floatConnection = nil
    local noclipConnection = nil
    local currentHoverCFrame = nil

    local function getPerfectAimDirection(bow, targetPart, fallbackRoot, arrowSpeed)
        if not targetPart or not targetPart.Parent then return Vector3.new(0, 1, 0) end
        local originPart = bow and (bow:FindFirstChild("Handle") or bow:FindFirstChild("Muzzle"))
        local originPos = originPart and originPart.Position or (fallbackRoot and fallbackRoot.Position)
        if not originPos then return Vector3.new(0, 1, 0) end

        local speed = arrowSpeed or 300
        local targetPos = targetPart.Position
        local velocity = targetPart:IsA("BasePart") and targetPart.AssemblyLinearVelocity or Vector3.zero
        local distance = (targetPos - originPos).Magnitude
        local flightTime = distance / speed

        local predicted = targetPos + velocity * flightTime
        local gravity = Workspace.Gravity
        local compensated = predicted + Vector3.new(0, 0.5 * gravity * flightTime ^ 2, 0)
        
        if Workspace.CurrentCamera then
            Workspace.CurrentCamera.CFrame = CFrame.lookAt(Workspace.CurrentCamera.CFrame.Position, compensated)
        end
        
        return (compensated - originPos).Unit
    end

    local function enableNoclip()
        if noclipConnection then return end
        noclipConnection = RunService.Stepped:Connect(function()
            local char = LocalPlayer.Character
            if char then
                for _, p in ipairs(char:GetChildren()) do
                    if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false 
                    elseif p:IsA("Accessory") then
                        local h = p:FindFirstChild("Handle")
                        if h and h:IsA("BasePart") and h.CanCollide then h.CanCollide = false end
                    end
                end
            end
        end)
    end

    local function disableNoclip()
        if noclipConnection then noclipConnection:Disconnect() noclipConnection = nil end
    end

    local function equipSpiritBow(character, humanoid)
        local bow = character:FindFirstChild("SpiritBow")
        if bow then return bow end
        local backpack = LocalPlayer:FindFirstChild("Backpack")
        local backpackBow = backpack and backpack:FindFirstChild("SpiritBow")
        if backpackBow and humanoid then
            humanoid:EquipTool(backpackBow)
            task.wait(0.1)
            return character:FindFirstChild("SpiritBow")
        end
        return bow
    end

    local function enableFloat(rootPart)
        if floatConnection then return end
        floatConnection = RunService.Heartbeat:Connect(function()
            if isToggled and rootPart and rootPart.Parent then
                rootPart.AssemblyLinearVelocity = Vector3.zero
                rootPart.AssemblyAngularVelocity = Vector3.zero
                if currentHoverCFrame then rootPart.CFrame = currentHoverCFrame end
            end
        end)
    end

    local function disableFloat()
        if floatConnection then floatConnection:Disconnect() floatConnection = nil end
        currentHoverCFrame = nil
    end

    local function isBossHealthZero()
        local gui = LocalPlayer:FindFirstChild("PlayerGui")
        local s4 = gui and gui:FindFirstChild("S4")
        local health = s4 and s4:FindFirstChild("Health")
        local front = health and health:FindFirstChild("Front")
        return front and front.AbsoluteSize.X <= 0
    end

    local monsterTargets = {
        { folder = "Monster2", name = "Rin2" },
        { folder = "Monster3", name = "Tenome2" },
        { folder = "Monster4", name = "Tsukiya2" }
    }

    local function getMonster(targetInfo)
        local s4 = Workspace:FindFirstChild("Section4")
        local mf = s4 and s4:FindFirstChild(targetInfo.folder)
        local model = mf and mf:FindFirstChild(targetInfo.name)
        if not model then return nil end
        local hrp = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
        local hitbox = model:FindFirstChild("Hitbox") or hrp
        return model, hrp, hitbox
    end

    local function runSequence()
        while isToggled do
            local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
            local hum = char:FindFirstChildOfClass("Humanoid")
            local root = char:FindFirstChild("HumanoidRootPart")
            if not root or not hum then task.wait(0.5) continue end

            enableFloat(root)
            local waitCF = CFrame.new(30, 126, -2868)

            while isToggled and not isBossHealthZero() do
                currentHoverCFrame = waitCF
                task.wait(0.5)
            end

            if not isToggled then break end
            task.wait(0.5)

            for _, target in ipairs(monsterTargets) do
                if not isToggled then break end

                local model, hrp, hitbox = getMonster(target)
                if model and hrp and hitbox then
                    local standPos = (hrp.CFrame * CFrame.new(0, 0, -50)).Position
                    currentHoverCFrame = CFrame.lookAt(standPos, hitbox.Position)

                    local bow = equipSpiritBow(char, hum)
                    local remote = bow and bow:FindFirstChild("RemoteEvent")

                    local startTime = tick()
                    
                    while isToggled and model.Parent and (tick() - startTime) < 40 do
                        local prompt = hrp:FindFirstChildWhichIsA("ProximityPrompt", true) or model:FindFirstChildWhichIsA("ProximityPrompt", true)

                        if prompt and prompt.Enabled then
                            -- Teleport near prompt before firing
                            local promptPart = prompt.Parent
                            if promptPart and promptPart:IsA("BasePart") then
                                currentHoverCFrame = promptPart.CFrame + Vector3.new(0, 3, 0)
                            else
                                currentHoverCFrame = hrp.CFrame + Vector3.new(0, 3, 0)
                            end
                            root.CFrame = currentHoverCFrame
                            task.wait(0.3)
                            
                            if fireproximityprompt then 
                                pcall(function() fireproximityprompt(prompt) end)
                            end
                            task.wait(0.5) 
                        elseif remote then
                            local keepPos = (hrp.CFrame * CFrame.new(0, 0, -50)).Position
                            currentHoverCFrame = CFrame.lookAt(keepPos, hitbox.Position)
                            root.CFrame = currentHoverCFrame
                            
                            remote:FireServer(0, true)
                            task.wait(0.8)
                            if model.Parent then
                                remote:FireServer(0, false, getPerfectAimDirection(bow, hitbox, root, 300))
                            end
                            task.wait(0.2)
                        else
                            task.wait(0.2)
                        end
                    end
                end
            end
            break
        end

        disableFloat()
        disableNoclip()
        isToggled = false
    end

    StreetTokyoMain:Toggle({
        Title = "Auto 3 Monsters",
        Default = false,
        Callback = function(state)
            isToggled = state
            if isToggled then
                if mainTask then task.cancel(mainTask) end
                enableNoclip()
                mainTask = task.spawn(function()
                    local ok, err = pcall(runSequence)
                    if not ok then warn("[Auto 3 Monsters] Error:", err) end
                end)
            else
                disableFloat()
                disableNoclip()
                if mainTask then task.cancel(mainTask) mainTask = nil end
            end
        end
    })
end

-- ==========================================
-- 4. AUTO ENZUKAI RYUJIN (SECTION 5 FINAL FORM)
-- ==========================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local DODGE_WAIT_TIME = 4.5
local HEAD_X_THRESHOLD = -200
local isToggled = false
local isDodging = false
local dodgeArmed = true
local mainTask = nil
local floatConnection = nil
local noclipConnection = nil
local positionTrackerConnection = nil
local currentHoverCFrame = nil

local cachedSection5, cachedFinalForm, cachedRyujin, cachedHeadHitBox, cachedSpawnPoint

local function updateCachedObjects(force)
	if force or not cachedSection5 or not cachedSection5.Parent then cachedSection5 = Workspace:FindFirstChild("Section5") end
	if not cachedSection5 then return false end

	if force or not cachedSpawnPoint or not cachedSpawnPoint.Parent then cachedSpawnPoint = cachedSection5:FindFirstChild("TeleportAndSetSpawn", true) end
	if force or not cachedFinalForm or not cachedFinalForm.Parent then cachedFinalForm = cachedSection5:FindFirstChild("FinalForm", true) end
	if not cachedFinalForm then return false end

	if force or not cachedRyujin or not cachedRyujin.Parent then cachedRyujin = cachedFinalForm:FindFirstChild("EnzukaiRyujin", true) end
	if not cachedRyujin then return false end

	if force or not cachedHeadHitBox or not cachedHeadHitBox.Parent then
		cachedHeadHitBox = cachedRyujin:FindFirstChild("HeadHitBox", true) or cachedRyujin:FindFirstChild("Hitbox", true)
		if not cachedHeadHitBox and cachedRyujin:IsA("Model") then cachedHeadHitBox = cachedRyujin.PrimaryPart end
	end
	return true
end

local function clearCache()
	cachedSection5, cachedFinalForm, cachedRyujin, cachedHeadHitBox, cachedSpawnPoint = nil, nil, nil, nil, nil
end

local function getPerfectAimDirection(bow, targetPart, fallbackRoot, arrowSpeed)
	if not targetPart or not targetPart.Parent then return Vector3.new(0, 1, 0) end
	local originPart = bow and (bow:FindFirstChild("Handle") or bow:FindFirstChild("Muzzle"))
	local originPos = originPart and originPart:IsA("BasePart") and originPart.Position or (fallbackRoot and fallbackRoot:IsA("BasePart") and fallbackRoot.Position)
	if not originPos then return Vector3.new(0, 1, 0) end

	local speed = arrowSpeed or 300
	local targetPos = targetPart.Position
	local velocity = targetPart:IsA("BasePart") and targetPart.AssemblyLinearVelocity or Vector3.zero
	local distance = (targetPos - originPos).Magnitude
	local flightTime = distance / speed

	local predicted = targetPos + velocity * flightTime
	local gravity = Workspace.Gravity
	local compensated = predicted + Vector3.new(0, 0.5 * gravity * flightTime ^ 2, 0)
	local direction = compensated - originPos

	return direction.Magnitude > 0 and direction.Unit or Vector3.new(0, 1, 0)
end

local function equipSpiritBow(character, humanoid)
	local bow = character:FindFirstChild("SpiritBow")
	if bow then return bow end
	local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
	local backpackBow = backpack and backpack:FindFirstChild("SpiritBow")
	if backpackBow then
		pcall(function() humanoid:EquipTool(backpackBow) end)
		task.wait(0.1)
		return character:FindFirstChild("SpiritBow")
	end
	return nil
end

local function enableFloat(rootPart)
	if floatConnection then return end
	floatConnection = RunService.PreRender:Connect(function()
		if not isToggled or not rootPart or not rootPart.Parent then return end
		rootPart.AssemblyLinearVelocity = Vector3.zero
		rootPart.AssemblyAngularVelocity = Vector3.zero
		if currentHoverCFrame then
			rootPart.CFrame = currentHoverCFrame
		end
	end)
end

local function disableFloat()
	if floatConnection then floatConnection:Disconnect() floatConnection = nil end
	currentHoverCFrame = nil
end

local function enableNoclip()
	if noclipConnection then return end
	noclipConnection = RunService.Stepped:Connect(function()
		local char = LocalPlayer.Character
		if char then
			for _, p in ipairs(char:GetChildren()) do
				if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end
				if p:IsA("Accessory") then
					local h = p:FindFirstChild("Handle")
					if h and h:IsA("BasePart") and h.CanCollide then h.CanCollide = false end
				end
			end
		end
	end)
end

local function disableNoclip()
	if noclipConnection then noclipConnection:Disconnect() noclipConnection = nil end
end

local function findActiveWeakPoint()
	updateCachedObjects()
	if not cachedSection5 then return nil end
	local points = cachedSection5:FindFirstChild("WeakPoints") and cachedSection5.WeakPoints:FindFirstChild("Points")
	if not points then return nil end

	for _, pointModel in ipairs(points:GetChildren()) do
		local iconGui = pointModel:FindFirstChild("Icon", true)
		if iconGui and iconGui:IsA("BillboardGui") and iconGui.Enabled then
			local imageLabel = iconGui:FindFirstChildWhichIsA("ImageLabel", true)
			if imageLabel and imageLabel.Visible then return pointModel, iconGui end
		end
	end
	return nil
end

local function getTeleportSpawnCFrame()
	updateCachedObjects()
	if not cachedSpawnPoint then return nil end
	if cachedSpawnPoint:IsA("BasePart") then return cachedSpawnPoint.CFrame end
	if cachedSpawnPoint:IsA("Model") then return cachedSpawnPoint:GetPivot() end
	return nil
end

local function performDodge()
	if not isToggled or isDodging or not dodgeArmed then return end
	isDodging, dodgeArmed = true, false

	local char = LocalPlayer.Character
	local rootPart = char and char:FindFirstChild("HumanoidRootPart")
	local spawnCFrame = getTeleportSpawnCFrame()

	if rootPart and spawnCFrame then
		currentHoverCFrame = spawnCFrame
		rootPart.CFrame = spawnCFrame
		rootPart.AssemblyLinearVelocity = Vector3.zero
		rootPart.AssemblyAngularVelocity = Vector3.zero
		task.wait(DODGE_WAIT_TIME)
	end
	isDodging = false
end

local function startPositionTracker()
	if positionTrackerConnection then positionTrackerConnection:Disconnect() end
	positionTrackerConnection = RunService.Heartbeat:Connect(function()
		if not isToggled then return end
		updateCachedObjects()
		local hitbox = cachedHeadHitBox
		if not hitbox or not hitbox.Parent then
			updateCachedObjects(true)
			hitbox = cachedHeadHitBox
		end
		if not hitbox or not hitbox:IsA("BasePart") then return end

		local x = hitbox.Position.X
		if x > HEAD_X_THRESHOLD + 20 then dodgeArmed = true end
		if x <= HEAD_X_THRESHOLD and dodgeArmed and not isDodging then task.spawn(performDodge) end
	end)
end

local function stopPositionTracker()
	if positionTrackerConnection then positionTrackerConnection:Disconnect() positionTrackerConnection = nil end
end

local function runWeakPointPhase(character, humanoid, rootPart, activeModel, iconGui)
	local bow = equipSpiritBow(character, humanoid)
	if not bow then return end
	local remote = bow:FindFirstChild("RemoteEvent")
	if not remote then return end

	enableFloat(rootPart)
	local offsets = { CFrame.new(0, 30, 25), CFrame.new(25, 30, 0), CFrame.new(-25, 30, 0), CFrame.new(0, 30, -25) }

	for _, eyeName in ipairs({"EyeA", "EyeB", "EyeC", "EyeD", "EyeE"}) do
		if not isToggled or isDodging then break end
		local eye = activeModel:FindFirstChild(eyeName, true)

		if eye and eye:IsA("BasePart") then
			local offsetIndex = 1
			while isToggled and not isDodging and eye.Parent and eye.Transparency == 0 and iconGui and iconGui.Parent and iconGui.Enabled do
				local offset = offsets[offsetIndex]
				currentHoverCFrame = CFrame.lookAt((eye.CFrame * offset).Position, eye.Position)
				
				pcall(function() remote:FireServer(0, true) end)
				
				local elapsed = 0
				-- Pinalitan ang 1.5 ng 0.8
				while elapsed < 0.8 and isToggled and not isDodging do
					currentHoverCFrame = CFrame.lookAt((eye.CFrame * offset).Position, eye.Position)
					task.wait(0.05)
					elapsed += 0.05
				end

				if not isToggled or isDodging then break end
				if eye.Parent and eye.Transparency == 0 then
					pcall(function() remote:FireServer(0, false, getPerfectAimDirection(bow, eye, rootPart, 300)) end)
				end
				task.wait(0.2)
				offsetIndex = (offsetIndex % #offsets) + 1
			end
		end
	end
end

local function runBossPhase(character, humanoid, rootPart)
	updateCachedObjects()
	local headHitBox = cachedHeadHitBox
	if not headHitBox or not headHitBox.Parent then return end

	local bow = equipSpiritBow(character, humanoid)
	if not bow then return end
	local remote = bow:FindFirstChild("RemoteEvent")
	if not remote then return end

	enableFloat(rootPart)
	while isToggled and not isDodging and headHitBox and headHitBox.Parent do
		if findActiveWeakPoint() then break end
		
		currentHoverCFrame = CFrame.lookAt((headHitBox.CFrame * CFrame.new(15, 0, 0)).Position, headHitBox.Position)
		
		pcall(function() remote:FireServer(0, true) end)
		
		local elapsed = 0
		-- Pinalitan ang 1.5 ng 0.8
		while elapsed < 0.8 and isToggled and not isDodging and not findActiveWeakPoint() do
			if not headHitBox or not headHitBox.Parent then break end
			currentHoverCFrame = CFrame.lookAt((headHitBox.CFrame * CFrame.new(15, 0, 0)).Position, headHitBox.Position)
			task.wait(0.05)
			elapsed += 0.05
		end

		if not isToggled or isDodging or findActiveWeakPoint() then break end
		if headHitBox and headHitBox.Parent then
			pcall(function() remote:FireServer(0, false, getPerfectAimDirection(bow, headHitBox, rootPart, 300)) end)
		end
		task.wait(0.2)
	end
end

local function runSection5Automation()
	startPositionTracker()
	while isToggled do
		if isDodging then task.wait(0.1) continue end
		local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		local rootPart = character:FindFirstChild("HumanoidRootPart")
		if not humanoid or not rootPart or humanoid.Health <= 0 then task.wait(0.5) continue end

		updateCachedObjects()
		local activeModel, iconGui = findActiveWeakPoint()

		if activeModel and iconGui then
			runWeakPointPhase(character, humanoid, rootPart, activeModel, iconGui)
		else
			runBossPhase(character, humanoid, rootPart)
		end
		task.wait(0.1)
	end
	stopPositionTracker()
	disableFloat()
end

local function stopAutomation()
	isToggled = false
	isDodging = false
	dodgeArmed = true
	stopPositionTracker()
	disableFloat()
	disableNoclip()
	if mainTask then pcall(function() task.cancel(mainTask) end) mainTask = nil end
end

LocalPlayer.CharacterAdded:Connect(function()
	clearCache()
	if isToggled then task.wait(0.5) updateCachedObjects(true) end
end)

local function toggleAutomation(state)
	if state then
		if isToggled then return end
		isToggled = true
		isDodging = false
		dodgeArmed = true
		clearCache()
		enableNoclip()
		mainTask = task.spawn(function()
			local ok, err = pcall(runSection5Automation)
			if not ok and isToggled then warn("[Auto Enzukai] Error:", err) end
		end)
	else
		stopAutomation()
	end
end

StreetTokyoMain:Toggle({
	Title = "Auto Enzukai Ryujin",
	Description = "Final Form",
	Default = false,
	Callback = toggleAutomation
})

-- ==========================================
-- ESP BOSS
-- ==========================================
local espBossEnabled = false
local bossHighlights = {}
local bossBillboards = {}

StreetTokyoESP:Toggle({
    Title = "ESP Boss",
    Default = false,
    Callback = function(state)
        espBossEnabled = state
        
        for _, hl in pairs(bossHighlights) do pcall(function() hl:Destroy() end) end
        for _, bb in pairs(bossBillboards) do pcall(function() bb:Destroy() end) end
        table.clear(bossHighlights)
        table.clear(bossBillboards)
        
        if not espBossEnabled then return end
        
        local function applyBossESP(model)
            if not model or bossHighlights[model] or not model:IsA("Model") then return end
            
            local hl = Instance.new("Highlight")
            hl.Name = "BossESP"
            hl.FillColor = Color3.fromRGB(255, 0, 0)
            hl.OutlineColor = Color3.fromRGB(0, 0, 0)
            hl.FillTransparency = 0.5
            hl.OutlineTransparency = 0
            hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            hl.Adornee = model
            hl.Parent = model
            bossHighlights[model] = hl
            
            local bb = Instance.new("BillboardGui")
            bb.Name = "BossName"
            bb.Size = UDim2.new(0, 200, 0, 50)
            bb.StudsOffset = Vector3.new(0, 3, 0)
            bb.AlwaysOnTop = true
            bb.Parent = model
            
            local tl = Instance.new("TextLabel")
            tl.Size = UDim2.new(1, 0, 1, 0)
            tl.BackgroundTransparency = 1
            tl.Text = model.Name
            tl.TextColor3 = Color3.fromRGB(255, 0, 0)
            tl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
            tl.TextStrokeTransparency = 0
            tl.TextSize = 13
            tl.Font = Enum.Font.FredokaOne
            tl.Parent = bb
            bossBillboards[model] = bb
        end
        
        task.spawn(function()
            local s4 = workspace:FindFirstChild("Section4")
            local bossMonster = s4 and s4:FindFirstChild("BossMonster")
            local boss = bossMonster and bossMonster:FindFirstChild("EnzukaiRyu")
            
            if boss then applyBossESP(boss) end
            
            if bossMonster then
                bossMonster.ChildAdded:Connect(function(inst)
                    if espBossEnabled and inst.Name == "EnzukaiRyu" then applyBossESP(inst) end
                end)
            end
        end)
    end
})

-- ==========================================
-- ESP MONSTERS
-- ==========================================
local espMonstersEnabled = false
local monsterHighlights = {}
local monsterBillboards = {}
local monsterConnections = {}

StreetTokyoESP:Toggle({
    Title = "ESP Monsters",
    Default = false,
    Callback = function(state)
        espMonstersEnabled = state
        
        for _, hl in pairs(monsterHighlights) do pcall(function() hl:Destroy() end) end
        for _, bb in pairs(monsterBillboards) do pcall(function() bb:Destroy() end) end
        for _, conn in ipairs(monsterConnections) do pcall(function() conn:Disconnect() end) end
        table.clear(monsterHighlights)
        table.clear(monsterBillboards)
        table.clear(monsterConnections)
        
        if not espMonstersEnabled then return end
        
        local function applyMonsterESP(model)
            if not model or monsterHighlights[model] or not model:IsA("Model") then return end
            
            local hl = Instance.new("Highlight")
            hl.Name = "MonsterESP"
            hl.FillColor = Color3.fromRGB(255, 0, 0)
            hl.OutlineColor = Color3.fromRGB(0, 0, 0)
            hl.FillTransparency = 0.5
            hl.OutlineTransparency = 0
            hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            hl.Adornee = model
            hl.Parent = model
            monsterHighlights[model] = hl
            
            local bb = Instance.new("BillboardGui")
            bb.Name = "MonsterName"
            bb.Size = UDim2.new(0, 200, 0, 50)
            bb.StudsOffset = Vector3.new(0, 3, 0)
            bb.AlwaysOnTop = true
            bb.Parent = model
            
            local tl = Instance.new("TextLabel")
            tl.Size = UDim2.new(1, 0, 1, 0)
            tl.BackgroundTransparency = 1
            tl.Text = model.Name
            tl.TextColor3 = Color3.fromRGB(255, 0, 0)
            tl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
            tl.TextStrokeTransparency = 0
            tl.TextSize = 13
            tl.Font = Enum.Font.FredokaOne
            tl.Parent = bb
            monsterBillboards[model] = bb
        end
        
        task.spawn(function()
            local s4 = workspace:FindFirstChild("Section4")
            if not s4 then return end
            
            local monsterPaths = {
                { folder = "Monster2", name = "Rin2" },
                { folder = "Monster3", name = "Tenome2" },
                { folder = "Monster4", name = "Tsukiya2" }
            }
            
            -- Check specific folders
            for _, path in ipairs(monsterPaths) do
                local folder = s4:FindFirstChild(path.folder)
                local model = folder and folder:FindFirstChild(path.name)
                if model then applyMonsterESP(model) end
                
                if folder then
                    table.insert(monsterConnections, folder.ChildAdded:Connect(function(inst)
                        if espMonstersEnabled and inst.Name == path.name then applyMonsterESP(inst) end
                    end))
                end
            end
            
            -- Check for MonsterEnzukaiRyu directly in Section4
            local enzukaiMonster = s4:FindFirstChild("MonsterEnzukaiRyu")
            if enzukaiMonster then applyMonsterESP(enzukaiMonster) end
            
            table.insert(monsterConnections, s4.ChildAdded:Connect(function(inst)
                if espMonstersEnabled and inst.Name == "MonsterEnzukaiRyu" then applyMonsterESP(inst) end
            end))
        end)
    end
})

-- ==========================================
-- ESP NPCs (GREEN, NO TEXT)
-- ==========================================
local espNpcEnabled = false
local npcHighlights = {}
local npcConnections = {}

StreetTokyoESP:Toggle({
    Title = "ESP NPCs",
    Default = false,
    Callback = function(state)
        espNpcEnabled = state
        
        for _, hl in pairs(npcHighlights) do pcall(function() hl:Destroy() end) end
        for _, conn in ipairs(npcConnections) do pcall(function() conn:Disconnect() end) end
        table.clear(npcHighlights)
        table.clear(npcConnections)
        
        if not espNpcEnabled then return end
        
        local function applyNpcESP(obj)
            if not obj or npcHighlights[obj] or not (obj:IsA("Model") or obj:IsA("BasePart")) then return end
            
            local hl = Instance.new("Highlight")
            hl.Name = "NpcESP"
            hl.FillColor = Color3.fromRGB(0, 255, 0)
            hl.OutlineColor = Color3.fromRGB(0, 255, 0)
            hl.FillTransparency = 0.5
            hl.OutlineTransparency = 0
            hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            hl.Adornee = obj
            hl.Parent = obj
            npcHighlights[obj] = hl
        end
        
        task.spawn(function()
            local s4 = workspace:FindFirstChild("Section4")
            local rescue = s4 and s4:FindFirstChild("Rescue")
            local npcs = rescue and rescue:FindFirstChild("NPCs")
            
            if npcs then
                for _, child in ipairs(npcs:GetChildren()) do
                    applyNpcESP(child)
                end
                table.insert(npcConnections, npcs.ChildAdded:Connect(function(inst)
                    if espNpcEnabled then applyNpcESP(inst) end
                end))
            end
        end)
    end
})
