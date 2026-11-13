local KazeUI = KazeUI or loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/KazeHub/UI/refs/heads/main/UILibrary.lua.txt"
))()

local Window = KazeUI:CreateWindow({
    Title = "THE MIMIC",
    Author = "KAZE",
    Version = "RAGE I",
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

local GameTab = Window:CreateTab({ Title = "Game", Icon = "gamepad-2" })
local GameFPS = GameTab:CreateSubTab({ Title = "FPS Boost", Icon = "zap", Default = true })

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

local GameYen = GameTab:CreateSubTab({ Title = "Yen", Icon = "coins", Default = false })

local isAutoPromptToggled = false
local autoPromptTask = nil
local PROXIMITY_RANGE = 15

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
                local char = game:GetService("Players").LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                local yenFolder = workspace:FindFirstChild("Yen")
                
                if hrp and yenFolder then
                    for _, item in ipairs(yenFolder:GetChildren()) do
                        if not isAutoPromptToggled then break end
                        
                        local targetPart = item:IsA("BasePart") and item or (item:IsA("Model") and (item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart", true)))
                        
                        if targetPart and (targetPart.Position - hrp.Position).Magnitude <= PROXIMITY_RANGE then
                            local prompt = item:FindFirstChildWhichIsA("ProximityPrompt", true)
                            if prompt then
                                prompt.HoldDuration = 0
                                prompt.RequiresLineOfSight = false
                                pcall(function()
                                    if fireproximityprompt then 
                                        fireproximityprompt(prompt, 0) 
                                    end
                                end)
                            end
                        end
                    end
                end
                task.wait(0.05)
            end
        end)
    end
})

local isEspToggled = false
local yenEspHolders = {}
local yenEspConnection = nil

GameYen:Toggle({
    Title = "ESP Yen",
    Default = false,
    Callback = function(state)
        isEspToggled = state
        
        if yenEspConnection then
            yenEspConnection:Disconnect()
            yenEspConnection = nil
        end
        
        for item, data in pairs(yenEspHolders) do
            pcall(function()
                if data.Highlight then data.Highlight:Destroy() end
                if data.Billboard then data.Billboard:Destroy() end
            end)
        end
        table.clear(yenEspHolders)
        
        if not isEspToggled then return end

        local function addYenEspToItem(item)
            if not item or yenEspHolders[item] then return end
            local targetPart = item:IsA("BasePart") and item or (item:IsA("Model") and (item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart", true))) or item:FindFirstChildWhichIsA("BasePart", true)
            if not targetPart then return end

            pcall(function()
                local hl = Instance.new("Highlight")
                hl.FillColor = Color3.fromRGB(255, 215, 0)
                hl.OutlineColor = Color3.fromRGB(0, 0, 0)
                hl.FillTransparency = 0.4
                hl.OutlineTransparency = 0
                hl.Adornee = item
                hl.Parent = item

                local bb = Instance.new("BillboardGui")
                bb.Adornee = targetPart
                bb.Size = UDim2.new(0, 80, 0, 24)
                bb.StudsOffset = Vector3.new(0, 2, 0)
                bb.AlwaysOnTop = true
                bb.Parent = targetPart

                local tl = Instance.new("TextLabel")
                tl.Size = UDim2.new(1, 0, 1, 0)
                tl.BackgroundTransparency = 1
                tl.TextColor3 = Color3.fromRGB(255, 215, 0)
                tl.TextSize = 12
                tl.Font = Enum.Font.SourceSansBold
                tl.Text = "Yen"
                tl.Parent = bb

                local stroke = Instance.new("UIStroke")
                stroke.Color = Color3.fromRGB(0, 0, 0)
                stroke.Thickness = 1.5
                stroke.Parent = tl

                yenEspHolders[item] = { Highlight = hl, Billboard = bb, TextLabel = tl, Part = targetPart }
            end)
        end

        local yenFolder = workspace:FindFirstChild("Yen")
        if yenFolder then
            for _, item in ipairs(yenFolder:GetChildren()) do
                addYenEspToItem(item)
            end
            yenFolder.ChildAdded:Connect(function(item) if isEspToggled then addYenEspToItem(item) end end)
        end

        yenEspConnection = task.spawn(function()
            while isEspToggled do
                local char = game:GetService("Players").LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                
                for item, data in pairs(yenEspHolders) do
                    if item and item.Parent and data.Part and data.Part.Parent and data.TextLabel then
                        if hrp then
                            local dist = math.floor((data.Part.Position - hrp.Position).Magnitude)
                            data.TextLabel.Text = string.format("Yen [%sm]", dist)
                        else
                            data.TextLabel.Text = "Yen"
                        end
                    else
                        pcall(function()
                            if data.Highlight then data.Highlight:Destroy() end
                            if data.Billboard then data.Billboard:Destroy() end
                        end)
                        yenEspHolders[item] = nil
                    end
                end
                task.wait(0.2)
            end
        end)
    end
})

GameYen:Button({
    Title = "Yen Collect",
    Description = "When it's stairs stage, on the Auto Shoot HogoGuntai so you won't die",
    Callback = function()
        task.spawn(function()
            local char = game:GetService("Players").LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local mimicFolder = workspace:FindFirstChild("MimicCurrencySpawns")
            local yenFolder = mimicFolder and mimicFolder:FindFirstChild("Yen")
            if not hrp or not yenFolder then return end

            local RS = game:GetService("RunService")
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
                    RS.Heartbeat:Wait()

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
                    RS.Heartbeat:Wait()
                else
                    RS.Heartbeat:Wait()
                end
            end

            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
            char:PivotTo(originalCFrame)
        end)
    end
})

local GameEgao = GameTab:CreateSubTab({ Title = "Egao", Icon = "ghost", Default = false })

GameEgao:Button({
    Title = "School Location",
    Callback = function()
        task.spawn(function()
            local char = game:GetService("Players").LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
                char:PivotTo(CFrame.new(-26.5377808, 22.3487396, -50.0676498))
            end
        end)
    end
})

GameEgao:Button({
    Title = "Forest Location",
    Callback = function()
        task.spawn(function()
            local char = game:GetService("Players").LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
                char:PivotTo(CFrame.new(-3528.81519, 53.2901878, 274.508606))
            end
        end)
    end
})

GameEgao:Button({
    Title = "IJO Location",
    Callback = function()
        task.spawn(function()
            local char = game:GetService("Players").LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
                char:PivotTo(CFrame.new(-3377.18066, -290.173523, 4633.80371))
            end
        end)
    end
})

local lookingActive = false
local lookConnection = nil

GameEgao:Toggle({
    Title = "Look Egao",
    Default = false,
    Callback = function(state)
        lookingActive = state
        
        if lookConnection then
            lookConnection:Disconnect()
            lookConnection = nil
        end
        
        if not lookingActive then return end

        local RunService = game:GetService("RunService")
        local camera = workspace.CurrentCamera
        local notified = false

        lookConnection = RunService.Heartbeat:Connect(function()
            if not lookingActive then return end
            
            local egaoRig = workspace:FindFirstChild("EgaoEventRig")
            local char = game:GetService("Players").LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            
            if egaoRig then
                if not notified then
                    notified = true
                    pcall(function() 
                        Window:Notify({ Title = "Egao Encounter", Content = "Egao is here!", Duration = 3 }) 
                    end)
                end
                
                local targetPart = egaoRig:IsA("Model") and (egaoRig.PrimaryPart or egaoRig:FindFirstChildWhichIsA("BasePart", true)) or egaoRig
                
                if targetPart and hrp then
                    camera.CFrame = CFrame.new(camera.CFrame.Position, targetPart.Position)
                    hrp.CFrame = CFrame.lookAt(hrp.Position, Vector3.new(targetPart.Position.X, hrp.Position.Y, targetPart.Position.Z))
                end
            else
                notified = false
            end
        end)
    end
})

local CityTab = Window:CreateTab({ Title = "City", Icon = "Building-2" })
local CityMain = CityTab:CreateSubTab({ Title = "Main", Icon = "gamepad-2", Default = true })

local function mahanapAngAktibongTarget()
    local section1 = workspace:FindFirstChild("Section1") or workspace:FindFirstChild("Section2")
    if not section1 then return nil end

    for _, object in ipairs(section1:GetDescendants()) do
        if object:IsA("Model") and (object.Name == "Gata" or object.Name == "Gata2") then
            local rootPart = object:FindFirstChild("HumanoidRootPart")
            local humanoid = object:FindFirstChildOfClass("Humanoid")
            
            if rootPart and (not humanoid or humanoid.Health > 0) then
                local iconFolder = rootPart:FindFirstChild("Icon")
                local imageLabel = iconFolder and iconFolder:FindFirstChildOfClass("ImageLabel")
                
                if imageLabel and imageLabel.Visible == true then
                    return object
                end
            end
        end
    end
    return nil
end

CityMain:Button({
    Title = "Kill All Gatas",
    Callback = function()
        task.spawn(function()
            local plr = game:GetService("Players").LocalPlayer
            local character = plr.Character or plr.CharacterAdded:Wait()
            local myRoot = character and character:FindFirstChild("HumanoidRootPart")
            if not myRoot then return end
            
            while true do
                local targetGata = mahanapAngAktibongTarget()
                if not targetGata then break end
                
                local targetRoot = targetGata:FindFirstChild("HumanoidRootPart")
                local humanoid = targetGata:FindFirstChildOfClass("Humanoid")
                local hitRemote = targetGata:FindFirstChild("RemoteEvent") or targetGata:FindFirstChildOfClass("RemoteEvent")
                
                local targetIconFolder = targetRoot and targetRoot:FindFirstChild("Icon")
                local targetImageLabel = targetIconFolder and targetIconFolder:FindFirstChildOfClass("ImageLabel")
                
                while targetGata and targetGata.Parent and targetRoot and (not humanoid or humanoid.Health > 0) and targetImageLabel and targetImageLabel.Visible == true do
                    character = plr.Character
                    if not character or not character.Parent then break end
                    myRoot = character:FindFirstChild("HumanoidRootPart")
                    if not myRoot then break end
                    
                    local gataPivot = targetGata:GetPivot()
                    character:PivotTo(gataPivot * CFrame.new(0, 15, 0))
                    
                    for _ = 1, 25 do
                        task.spawn(function()
                            if hitRemote then
                                pcall(function()
                                    hitRemote:FireServer()
                                end)
                            end
                        end)
                    end
                    
                    task.wait(0.1)
                end
                
                task.wait(0.1)
            end
        end)
    end
})

CityMain:Button({
    Title = "Report Dead Civilians",
    Callback = function()
        task.spawn(function()
            local plr = game:GetService("Players").LocalPlayer
            local character = plr.Character or plr.CharacterAdded:Wait()
            if not character then return end

            local section1 = workspace:FindFirstChild("Section1") or workspace:FindFirstChild("Section2")
            local deadCiviliansFolder = section1 and section1:FindFirstChild("DeadCivilians")
            if not deadCiviliansFolder then return end

            for _, prompt in ipairs(deadCiviliansFolder:GetDescendants()) do
                character = plr.Character
                if not character or not character.Parent then break end
                
                if prompt:IsA("ProximityPrompt") then
                    local targetPart = prompt.Parent
                    if targetPart and targetPart:IsA("BasePart") then
                        local civPos = targetPart.Position
                        local targetCFrame = CFrame.lookAt(civPos + Vector3.new(0, 1, 3), civPos)

                        local hrp = character:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            hrp.AssemblyLinearVelocity = Vector3.zero
                            hrp.AssemblyAngularVelocity = Vector3.zero
                            character:PivotTo(targetCFrame)
                            task.wait(0.15)
                        end

                        if prompt.Enabled then
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
                    end
                end
            end
        end)
    end
})

CityMain:Button({
    Title = "Find Mika",
    Callback = function()
        task.spawn(function()
            local plr = game:GetService("Players").LocalPlayer
            local character = plr.Character or plr.CharacterAdded:Wait()
            local hrp = character and character:FindFirstChild("HumanoidRootPart")
            if not character or not hrp then return end

            local section = workspace:FindFirstChild("Section1") or workspace:FindFirstChild("Section2")
            local trigger = section and section:FindFirstChild("Monster") and section.Monster:FindFirstChild("Trigger")

            if trigger then
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
                character:PivotTo(trigger.CFrame + Vector3.new(0, 3, 0))
            end
        end)
    end
})

CityMain:Button({
    Title = "Talk To Hedio",
    Callback = function()
        task.spawn(function()
            local plr = game:GetService("Players").LocalPlayer
            local character = plr.Character or plr.CharacterAdded:Wait()
            local hrp = character and character:FindFirstChild("HumanoidRootPart")
            if not character or not hrp then return end

            local section = workspace:FindFirstChild("Section1") or workspace:FindFirstChild("Section2")
            local hideoScene = section and section:FindFirstChild("HideoScene")
            
            if not hideoScene then return end

            local hideo2 = hideoScene:FindFirstChild("Hideo2") or hideoScene:FindFirstChild("Light")
            if not hideo2 then return end

            local targetPart = hideo2:IsA("BasePart") and hideo2 or hideo2:FindFirstChildWhichIsA("BasePart", true)
            
            if targetPart then
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
                character:PivotTo(targetPart.CFrame + Vector3.new(0, 2, 0))
                task.wait(0.3)
            end

            local hideoHrp = hideoScene:FindFirstChild("Hideo2") and hideoScene.Hideo2:FindFirstChild("HumanoidRootPart")
            local searchRoot = hideoHrp or hideoScene
            
            local prompt = searchRoot:FindFirstChildWhichIsA("ProximityPrompt", true)
            
            if prompt then
                prompt.Enabled = true
                prompt.HoldDuration = 0
                prompt.RequiresLineOfSight = false
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
        end)
    end
})

CityMain:Button({
    Title = "Auto School",
    Callback = function()
        task.spawn(function()
            local plr = game:GetService("Players").LocalPlayer
            local char = plr.Character or plr.CharacterAdded:Wait()
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not char or not hrp then return end

            local RS = game:GetService("ReplicatedStorage")
            local packet = RS:FindFirstChild("modules") and RS.modules:FindFirstChild("Packet")
            local reliable = packet and packet:FindFirstChild("Reliable")

            if reliable then
                pcall(function()
                    reliable:FireServer("Section1/BoltCutterPickedUp")
                end)
            end
            task.wait(0.5)

            local function teleport(x, y, z)
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
                char:PivotTo(CFrame.new(x, y, z))
                task.wait(0.3)
            end

            teleport(124.98, 8.92, 274.03)

            local s1 = workspace:FindFirstChild("Section1")
            local gatePart = s1 and s1:FindFirstChild("SchoolGatePart")
            local gate = gatePart and gatePart:FindFirstChild("Gate")
            local chain = gate and gate:FindFirstChild("Chain")

            if chain then
                for i = 1, 4 do
                    local breakPart = chain:FindFirstChild("Break" .. i)
                    if breakPart then
                        local prompt = breakPart:FindFirstChildWhichIsA("ProximityPrompt", true) 
                                    or chain:FindFirstChildWhichIsA("ProximityPrompt", true)
                        if prompt then
                            prompt.Enabled = true
                            prompt.HoldDuration = 0
                            prompt.RequiresLineOfSight = false
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
                    task.wait(0.1)
                end
            end

            teleport(174.81, 9.24, 331.58)

            local s2 = workspace:FindFirstChild("Section2")
            local school = s2 and s2:FindFirstChild("School")
            local doors = school and school:FindFirstChild("Doors")
            local mainDoors = doors and doors:FindFirstChild("MainDoors")
            local entireDoor = mainDoors and mainDoors:FindFirstChild("EntireDoor")
            local door = entireDoor and entireDoor:FindFirstChild("Door")
            local proxPart = door and door:FindFirstChild("PROXPART")

            if proxPart then
                local prompt = proxPart:FindFirstChildWhichIsA("ProximityPrompt", true)
                if prompt then
                    prompt.Enabled = true
                    prompt.HoldDuration = 0
                    prompt.RequiresLineOfSight = false
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

local CityESP = CityTab:CreateSubTab({ Title = "ESP", Icon = "eye" })

local espGruntsEnabled = false
local gruntsHighlights = {}

CityESP:Toggle({
    Title = "Gata",
    Default = false,
    Callback = function(state)
        espGruntsEnabled = state
        for _, hl in pairs(gruntsHighlights) do hl:Destroy() end
        table.clear(gruntsHighlights)
        if not espGruntsEnabled then return end
        
        local function apply(model)
            if gruntsHighlights[model] or not model:IsA("Model") then return end
            local hl = Instance.new("Highlight")
            hl.FillColor = Color3.fromRGB(255, 0, 0); hl.OutlineColor = Color3.fromRGB(0, 0, 0)
            hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop; hl.Adornee = model; hl.Parent = model
            gruntsHighlights[model] = hl
            
            local bb = Instance.new("BillboardGui")
            bb.Size = UDim2.new(0, 200, 0, 50); bb.StudsOffset = Vector3.new(0, 3, 0); bb.AlwaysOnTop = true; bb.Parent = model
            local tl = Instance.new("TextLabel")
            tl.Size = UDim2.new(1, 0, 1, 0); tl.BackgroundTransparency = 1; tl.Text = model.Name
            tl.TextColor3 = Color3.fromRGB(255, 0, 0); tl.TextStrokeTransparency = 0; tl.TextSize = 13
            tl.Font = Enum.Font.FredokaOne; tl.Parent = bb
        end

        local folder = workspace:FindFirstChild("Section1") and workspace.Section1:FindFirstChild("Grunts")
        if folder then
            for _, m in ipairs(folder:GetChildren()) do apply(m) end
            folder.ChildAdded:Connect(function(m) if espGruntsEnabled then apply(m) end end)
        end
    end
})

local espDeadCivEnabled = false
local deadCivHighlights = {}

CityESP:Toggle({
    Title = "Dead Civilians",
    Default = false,
    Callback = function(state)
        espDeadCivEnabled = state
        for _, hl in pairs(deadCivHighlights) do hl:Destroy() end
        table.clear(deadCivHighlights)
        if not espDeadCivEnabled then return end
        
        local function apply(part)
            if deadCivHighlights[part] or not (part:IsA("BasePart") or part:IsA("Model")) then return end
            local hl = Instance.new("Highlight")
            hl.FillColor = Color3.fromRGB(0, 255, 0); hl.OutlineColor = Color3.fromRGB(0, 255, 0)
            hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop; hl.Adornee = part; hl.Parent = part
            deadCivHighlights[part] = hl
        end

        local folder = workspace:FindFirstChild("Section1") and workspace.Section1:FindFirstChild("DeadCivilians")
        if folder then
            for _, m in ipairs(folder:GetChildren()) do apply(m) end
            folder.ChildAdded:Connect(function(m) if espDeadCivEnabled then apply(m) end end)
        end
    end
})

local SchoolTab = Window:CreateTab({ Title = "School", Icon = "school" })
local SchoolMain = SchoolTab:CreateSubTab({ Title = "Main", Icon = "gamepad-2", Default = true })

SchoolMain:Button({
    Title = "Heal Hideo",
    Description = "",
    Callback = function()
        task.spawn(function()
            local RS = game:GetService("ReplicatedStorage")
            local packet = RS:FindFirstChild("modules") and RS.modules:FindFirstChild("Packet")
            local reliable = packet and packet:FindFirstChild("Reliable")
            
            if reliable then
                pcall(function() 
                    reliable:FireServer("Section2/BandagePickedUp") 
                end)
                
                task.wait(0.1)
                
                pcall(function() 
                    reliable:FireServer("Section2/HideoHealed") 
                end)
            end
        end)
    end
})

SchoolMain:Button({
    Title = "Read Diary",
    Callback = function()
        task.spawn(function()
            local char = game:GetService("Players").LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end

            local s2 = workspace:FindFirstChild("Section2")
            local mainObj = s2 and s2:FindFirstChild("MAINOBJECTIVE")
            local locker = mainObj and mainObj:FindFirstChild("Locker")
            local diary = mainObj and mainObj:FindFirstChild("Diary")

            local function fireObj(obj)
                if not obj then return end
                pcall(function()
                    hrp.AssemblyLinearVelocity = Vector3.zero
                    hrp.AssemblyAngularVelocity = Vector3.zero
                    char:PivotTo(obj:GetPivot() + Vector3.new(0, 2, 0))
                    task.wait(0.2)
                    
                    local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
                    if prompt then
                        prompt.HoldDuration = 0
                        prompt.RequiresLineOfSight = false
                        if fireproximityprompt then 
                            fireproximityprompt(prompt, 0) 
                        end
                    end
                    task.wait(0.2)
                end)
            end

            fireObj(locker)
            fireObj(diary)
        end)
    end
})

SchoolMain:Button({
    Title = "Kill Spiders",
    Callback = function()
        task.spawn(function()
            local char = game:GetService("Players").LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end

            local RS = game:GetService("ReplicatedStorage")
            local reliable = RS:FindFirstChild("modules") and RS.modules:FindFirstChild("Packet") and RS.modules.Packet:FindFirstChild("Reliable")
            
            local s2 = workspace:FindFirstChild("Section2")
            local spiders = s2 and s2:FindFirstChild("MAINOBJECTIVE2") and s2.MAINOBJECTIVE2:FindFirstChild("Spiders")
            if not spiders or not reliable then return end

            local isDead = false
            local conn = reliable.OnClientEvent:Connect(function(packet)
                if packet == "Section2/SpiderAmbienceStop" then isDead = true end
            end)

            for _, spider in ipairs(spiders:GetChildren()) do
                if not char.Parent then break end
                
                local hitbox = spider:FindFirstChild("Hitbox")
                local remote = hitbox and hitbox:FindFirstChild("RemoteEvent")
                
                if hitbox and remote then
                    isDead = false
                    hrp.AssemblyLinearVelocity = Vector3.zero
                    char:PivotTo(hitbox.CFrame + Vector3.new(0, 3, 0))
                    task.wait(0.1)
                    
                    for _ = 1, 50 do
                        if isDead or not spider.Parent then break end
                        remote:FireServer()
                        task.wait(0.02)
                    end
                    task.wait(0.1)
                end
            end

            if conn then conn:Disconnect() end
        end)
    end
})

SchoolMain:Button({
    Title = "Exit School",
    Callback = function()
        task.spawn(function()
            local char = game:GetService("Players").LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end

            local s2 = workspace:FindFirstChild("Section2")
            local door = s2 and s2:FindFirstChild("School") and s2.School:FindFirstChild("Doors") and s2.School.Doors:FindFirstChild("ExitDoor") and s2.School.Doors.ExitDoor:FindFirstChild("ProxPart")

            if door then
                hrp.CFrame = door.CFrame + Vector3.new(0, 2, 0)
                task.wait(0.1)
                local prompt = door:FindFirstChildWhichIsA("ProximityPrompt", true)
                if prompt and fireproximityprompt then 
                    fireproximityprompt(prompt, 0) 
                end
            end
        end)
    end
})

local SchoolESP = SchoolTab:CreateSubTab({ Title = "ESP", Icon = "eye" })

local espMonstersEnabled = false
local monsterHighlights = {}
local monsterBillboards = {}

SchoolESP:Toggle({
    Title = "Monsters",
    Default = false,
    Callback = function(state)
        espMonstersEnabled = state
        for _, hl in pairs(monsterHighlights) do hl:Destroy() end
        for _, bb in pairs(monsterBillboards) do bb:Destroy() end
        table.clear(monsterHighlights) table.clear(monsterBillboards)
        if not espMonstersEnabled then return end
        
        local function apply(model)
            if monsterHighlights[model] or not model then return end
            local hl = Instance.new("Highlight")
            hl.FillColor = Color3.fromRGB(255, 0, 0)
            hl.OutlineColor = Color3.fromRGB(0, 0, 0)
            hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            hl.Adornee = model
            hl.Parent = model
            monsterHighlights[model] = hl
            
            local bb = Instance.new("BillboardGui")
            bb.Size = UDim2.new(0, 200, 0, 50)
            bb.StudsOffset = Vector3.new(0, 3, 0)
            bb.AlwaysOnTop = true
            bb.Parent = model
            
            local tl = Instance.new("TextLabel")
            tl.Size = UDim2.new(1, 0, 1, 0)
            tl.BackgroundTransparency = 1
            tl.Text = model.Name
            tl.TextColor3 = Color3.fromRGB(255, 0, 0)
            tl.TextStrokeTransparency = 0
            tl.TextSize = 13
            tl.Font = Enum.Font.FredokaOne
            tl.Parent = bb
            monsterBillboards[model] = bb
        end
        
        local s2 = workspace:FindFirstChild("Section2")
        if s2 then
            local mf = s2:FindFirstChild("Monster")
            local akari = mf and mf:FindFirstChild("AkariNM")
            if akari then apply(akari) end
            
            local rf = s2:FindFirstChild("Rage")
            local akariR = rf and rf:FindFirstChild("AkariRageNM")
            if akariR then apply(akariR) end
        end
        
        workspace.DescendantAdded:Connect(function(inst) 
            if espMonstersEnabled and (inst.Name == "AkariNM" or inst.Name == "AkariRageNM") then 
                apply(inst) 
            end 
        end)
    end
})

local espSpidersEnabled = false
local spiderHighlights = {}

SchoolESP:Toggle({
    Title = "Spiders",
    Default = false,
    Callback = function(state)
        espSpidersEnabled = state
        for _, hl in pairs(spiderHighlights) do hl:Destroy() end
        table.clear(spiderHighlights)
        if not espSpidersEnabled then return end
        
        local function apply(spider)
            if spiderHighlights[spider] then return end
            local hl = Instance.new("Highlight")
            hl.FillColor = Color3.fromRGB(255, 100, 0)
            hl.OutlineColor = Color3.fromRGB(255, 100, 0)
            hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            hl.Adornee = spider
            hl.Parent = spider
            spiderHighlights[spider] = hl
        end
        
        local s2 = workspace:FindFirstChild("Section2")
        local folder = s2 and s2:FindFirstChild("MAINOBJECTIVE2") and s2.MAINOBJECTIVE2:FindFirstChild("Spiders")
        if folder then
            for _, m in ipairs(folder:GetChildren()) do apply(m) end
            folder.ChildAdded:Connect(function(m) 
                if espSpidersEnabled then apply(m) end 
            end)
        end
    end
})

local espGruntsSchoolEnabled = false
local gruntSchoolHL = {}

SchoolESP:Toggle({
    Title = "Gata",
    Default = false,
    Callback = function(state)
        espGruntsSchoolEnabled = state
        for _, hl in pairs(gruntSchoolHL) do hl:Destroy() end
        table.clear(gruntSchoolHL)
        if not espGruntsSchoolEnabled then return end
        
        local function apply(model)
            if gruntSchoolHL[model] or not model:IsA("Model") then return end
            local hl = Instance.new("Highlight")
            hl.FillColor = Color3.fromRGB(255, 0, 0)
            hl.OutlineColor = Color3.fromRGB(0, 0, 0)
            hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            hl.Adornee = model
            hl.Parent = model
            gruntSchoolHL[model] = hl
            
            local bb = Instance.new("BillboardGui")
            bb.Size = UDim2.new(0, 200, 0, 50)
            bb.StudsOffset = Vector3.new(0, 3, 0)
            bb.AlwaysOnTop = true
            bb.Parent = model
            
            local tl = Instance.new("TextLabel")
            tl.Size = UDim2.new(1, 0, 1, 0)
            tl.BackgroundTransparency = 1
            tl.Text = model.Name
            tl.TextColor3 = Color3.fromRGB(255, 0, 0)
            tl.TextStrokeTransparency = 0
            tl.TextSize = 13
            tl.Font = Enum.Font.FredokaOne
            tl.Parent = bb
        end
        
        local s2 = workspace:FindFirstChild("Section2")
        local folder = s2 and s2:FindFirstChild("Grunts")
        if folder then
            for _, m in ipairs(folder:GetChildren()) do apply(m) end
            folder.ChildAdded:Connect(function(m) 
                if espGruntsSchoolEnabled then apply(m) end 
            end)
        end
    end
})

local ForestTab = Window:CreateTab({ Title = "Forest", Icon = "trees" })
local ForestMain = ForestTab:CreateSubTab({ Title = "Main", Icon = "gamepad-2", Default = true })

ForestMain:Button({
    Title = "Start",
    Callback = function()
        task.spawn(function()
            local char = game:GetService("Players").LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end

            local s3 = workspace:FindFirstChild("Section3")
            local obj = s3 and s3:FindFirstChild("OBJECTIVE")
            local trigger = obj and obj:FindFirstChild("Trigger2")

            if trigger then
                pcall(function()
                    firetouchinterest(hrp, trigger, 0)
                    task.wait(0.1)
                    firetouchinterest(hrp, trigger, 1)
                end)
            end
        end)
    end
})

ForestMain:Button({
    Title = "Fix Generator",
    Callback = function()
        task.spawn(function()
            local char = game:GetService("Players").LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end

            local RS = game:GetService("ReplicatedStorage")
            local reliable = RS:FindFirstChild("modules") and RS.modules:FindFirstChild("Packet") and RS.modules.Packet:FindFirstChild("Reliable")
            if not reliable then return end
            
            local s3 = workspace:FindFirstChild("Section3")
            local circuits = s3 and s3:FindFirstChild("OBJECTIVE") and s3.OBJECTIVE:FindFirstChild("Circuits")
            if not circuits then return end

            local positions = {
                Vector3.new(-3513.808, 8.462, 554.146),
                Vector3.new(-3699.985, 8.544, 618.209),
                Vector3.new(-3388.813, 8.528, 582.247),
                Vector3.new(-3594.272, 8.642, 786.691),
                Vector3.new(-3230.885, 8.515, 681.428),
                Vector3.new(-3153.307, 8.554, 484.829)
            }

            local pillars = {}
            for _, pillar in ipairs(circuits:GetChildren()) do
                if pillar:IsA("Model") then
                    table.insert(pillars, { Model = pillar, Pos = pillar:GetPivot().Position })
                end
            end

            for _, pos in ipairs(positions) do
                if not char.Parent then break end
                
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
                char:PivotTo(CFrame.new(pos))
                task.wait(0.5)

                local targetPillar, shortestDist = nil, math.huge

                for _, data in ipairs(pillars) do
                    local dist = (data.Pos - pos).Magnitude
                    if dist < shortestDist then
                        shortestDist = dist
                        targetPillar = data.Model
                    end
                end

                if targetPillar then
                    local promptPart = targetPillar:FindFirstChild("PromptPart")
                    if promptPart then
                        local prompt = promptPart:FindFirstChildWhichIsA("ProximityPrompt", true)
                        if prompt then
                            prompt.HoldDuration = 0
                            prompt.RequiresLineOfSight = false
                            pcall(function()
                                if fireproximityprompt then fireproximityprompt(prompt, 0) end
                            end)
                        end
                    end
                    
                    task.wait(0.2)

                    pcall(function() reliable:FireServer("Section3/CircuitRoundComplete", targetPillar) end)
                    task.wait(0.15)
                    pcall(function() reliable:FireServer("Section3/CircuitRoundComplete", targetPillar) end)
                    task.wait(0.15)
                    pcall(function() reliable:FireServer("Section3/CircuitRoundComplete", targetPillar) end)
                    task.wait(0.15)
                end
            end

            local cutscene = s3:FindFirstChild("Cutscene")
            local trigger = cutscene and cutscene:FindFirstChild("Trigger")

            if trigger then
                char:PivotTo(CFrame.new(-3585, 8, 248))
                task.wait(0.5)
                pcall(function()
                    firetouchinterest(hrp, trigger, 0)
                    task.wait(0.1)
                    firetouchinterest(hrp, trigger, 1)
                end)
            end
            
            task.wait(25)
        end)
    end
})

local ForestESP = ForestTab:CreateSubTab({ Title = "ESP", Icon = "eye" })

local espGeneratorsEnabled = false
local genHighlights = {}

ForestESP:Toggle({
    Title = "Generators",
    Default = false,
    Callback = function(state)
        espGeneratorsEnabled = state
        for _, hl in pairs(genHighlights) do pcall(function() hl:Destroy() end) end
        table.clear(genHighlights)
        if not espGeneratorsEnabled then return end
        
        local function apply(obj)
            if genHighlights[obj] or not (obj:IsA("Model") or obj:IsA("BasePart")) then return end
            local hl = Instance.new("Highlight")
            hl.FillColor = Color3.fromRGB(0, 255, 0)
            hl.OutlineColor = Color3.fromRGB(0, 255, 0)
            hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            hl.Adornee = obj
            hl.Parent = obj
            genHighlights[obj] = hl
        end
        
        local s3 = workspace:FindFirstChild("Section3")
        local folder = s3 and s3:FindFirstChild("OBJECTIVE") and s3.OBJECTIVE:FindFirstChild("Circuits")
        if folder then
            for _, m in ipairs(folder:GetChildren()) do apply(m) end
            folder.ChildAdded:Connect(function(m) if espGeneratorsEnabled then apply(m) end end)
        end
    end
})

local espMizunoEnabled = false
local mizunoHighlights = {}
local mizunoBillboards = {}

ForestESP:Toggle({
    Title = "Monster",
    Default = false,
    Callback = function(state)
        espMizunoEnabled = state
        for _, hl in pairs(mizunoHighlights) do pcall(function() hl:Destroy() end) end
        for _, bb in pairs(mizunoBillboards) do pcall(function() bb:Destroy() end) end
        table.clear(mizunoHighlights) 
        table.clear(mizunoBillboards)
        if not espMizunoEnabled then return end
        
        local function apply(model)
            if mizunoHighlights[model] or not model then return end
            local hl = Instance.new("Highlight")
            hl.FillColor = Color3.fromRGB(255, 0, 0)
            hl.OutlineColor = Color3.fromRGB(0, 0, 0)
            hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            hl.Adornee = model
            hl.Parent = model
            mizunoHighlights[model] = hl
            
            local bb = Instance.new("BillboardGui")
            bb.Size = UDim2.new(0, 200, 0, 50)
            bb.StudsOffset = Vector3.new(0, 3, 0)
            bb.AlwaysOnTop = true
            bb.Parent = model
            
            local tl = Instance.new("TextLabel")
            tl.Size = UDim2.new(1, 0, 1, 0)
            tl.BackgroundTransparency = 1
            tl.Text = model.Name
            tl.TextColor3 = Color3.fromRGB(255, 0, 0)
            tl.TextStrokeTransparency = 0
            tl.TextSize = 13
            tl.Font = Enum.Font.FredokaOne
            tl.Parent = bb
            mizunoBillboards[model] = bb
        end
        
        local s3 = workspace:FindFirstChild("Section3")
        local folder = s3 and s3:FindFirstChild("Monster")
        if folder then
            for _, m in ipairs(folder:GetChildren()) do apply(m) end
            folder.ChildAdded:Connect(function(m) if espMizunoEnabled then apply(m) end end)
        end
    end
})

local IJOTab = Window:CreateTab({ Title = "IJO", Icon = "flask-conical" })
local IJOMain = IJOTab:CreateSubTab({ Title = "Main", Icon = "gamepad-2", Default = true })

IJOMain:Button({
    Title = "Grab KeyCard",
    Callback = function()
        task.spawn(function()
            local char = game:GetService("Players").LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end

            local function tpAndPrompt(target)
                if not target then return end
                local part = target:IsA("BasePart") and target or target:FindFirstChildWhichIsA("BasePart", true)
                if part then
                    hrp.AssemblyLinearVelocity = Vector3.zero
                    hrp.AssemblyAngularVelocity = Vector3.zero
                    char:PivotTo(part.CFrame + Vector3.new(0, 2, 0))
                    task.wait(0.2)
                    
                    local prompt = target:FindFirstChildWhichIsA("ProximityPrompt", true)
                    if prompt then
                        prompt.HoldDuration = 0
                        prompt.RequiresLineOfSight = false
                        pcall(function()
                            if fireproximityprompt then 
                                fireproximityprompt(prompt, 0) 
                            end
                        end)
                    end
                    task.wait(0.2)
                end
            end

            local s4 = workspace:FindFirstChild("Section4")
            local floor1 = s4 and s4:FindFirstChild("Lab") and s4.Lab:FindFirstChild("Floor1")
            local entrance = floor1 and floor1:FindFirstChild("Entrance")

            if entrance then
                tpAndPrompt(entrance:FindFirstChild("IDCARD"))
                tpAndPrompt(entrance:FindFirstChild("SFXPart"))
            end
        end)
    end
})

IJOMain:Button({
    Title = "Auto Fix Valves",
    Callback = function()
        task.spawn(function()
            local char = game:GetService("Players").LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end

            local s4 = workspace:FindFirstChild("Section4")
            local valvesFolder = s4 and s4:FindFirstChild("Lab") and s4.Lab:FindFirstChild("CleanseRoomObjective") and s4.Lab.CleanseRoomObjective:FindFirstChild("Valves")
            if not valvesFolder then return end

            local valveList = {}
            for _, valve in ipairs(valvesFolder:GetChildren()) do
                if valve:IsA("Model") and valve.Name:match("^Valve%d+$") then
                    table.insert(valveList, valve)
                end
            end

            table.sort(valveList, function(a, b)
                return (tonumber(a.Name:match("%d+")) or 0) < (tonumber(b.Name:match("%d+")) or 0)
            end)

            for _, valve in ipairs(valveList) do
                if not char.Parent then break end
                
                hrp.AssemblyLinearVelocity = Vector3.zero
                char:PivotTo(valve:GetPivot() + Vector3.new(0, 1, 3))
                task.wait(0.15)

                for _, turner in ipairs(valve:GetChildren()) do
                    if turner.Name == "Turners" then
                        local prompt = turner:FindFirstChildWhichIsA("ProximityPrompt", true)
                        if prompt then
                            prompt.HoldDuration = 0
                            prompt.RequiresLineOfSight = false
                            
                            local startTime = tick()
                            while turner:GetAttribute("Solved") ~= true and (tick() - startTime < 2) do
                                if fireproximityprompt then
                                    fireproximityprompt(prompt, 0)
                                end
                                task.wait(0.03)
                            end
                        end
                    end
                end
                task.wait(0.1)
            end
        end)
    end
})

IJOMain:Button({
    Title = "Auto Shape Terminal",
    Callback = function()
        task.spawn(function()
            local char = game:GetService("Players").LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end

            local rel = game:GetService("ReplicatedStorage"):FindFirstChild("modules") and game:GetService("ReplicatedStorage").modules:FindFirstChild("Packet") and game:GetService("ReplicatedStorage").modules.Packet:FindFirstChild("Reliable")
            local terminalsFolder = workspace:FindFirstChild("Section4") and workspace.Section4:FindFirstChild("Lab") and workspace.Section4.Lab:FindFirstChild("CleanseRoomObjective") and workspace.Section4.Lab.CleanseRoomObjective:FindFirstChild("ShapeTerminals")
            
            if not (rel and terminalsFolder) then return end

            local list = {}
            for _, term in ipairs(terminalsFolder:GetChildren()) do
                if (term:IsA("Model") or term:IsA("BasePart")) and term.Name ~= "ControlSystemOnline" then
                    table.insert(list, term)
                end
            end
            
            table.sort(list, function(a, b) 
                return (tonumber(a.Name:match("%d+")) or 0) < (tonumber(b.Name:match("%d+")) or 0) 
            end)

            for _, term in ipairs(list) do
                if not char.Parent then break end
                
                hrp.AssemblyLinearVelocity = Vector3.zero
                char:PivotTo(term:GetPivot() + Vector3.new(0, 1, 3))
                task.wait(0.1)

                local prompt = term:FindFirstChildWhichIsA("ProximityPrompt", true)
                if prompt then
                    prompt.HoldDuration = 0
                    if fireproximityprompt then fireproximityprompt(prompt, 0) end
                end
                
                task.spawn(function()
                    rel:FireServer("ShapeTerminal/RoundComplete", term)
                    task.wait(0.1)
                    rel:FireServer("ShapeTerminal/RoundComplete", term)
                    task.wait(0.1)
                    rel:FireServer("ShapeTerminal/Release", term)
                end)
                
                task.wait(0.3)
            end
        end)
    end
})

IJOMain:Button({
    Title = "Exit Lab",
    Callback = function()
        task.spawn(function()
            local char = game:GetService("Players").LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end

            local s4 = workspace:FindFirstChild("Section4")
            local exitObj = s4 and s4:FindFirstChild("Lab") and s4.Lab:FindFirstChild("ExitToStairs") and s4.Lab.ExitToStairs:FindFirstChild("EXIT")

            if exitObj then
                local part = exitObj:IsA("BasePart") and exitObj or exitObj:FindFirstChildWhichIsA("BasePart", true)
                if part then
                    hrp.AssemblyLinearVelocity = Vector3.zero
                    char:PivotTo(part.CFrame + Vector3.new(0, 2, 2))
                    task.wait(0.2)

                    local prompt = exitObj:FindFirstChildWhichIsA("ProximityPrompt", true)
                    if prompt then
                        prompt.HoldDuration = 0
                        prompt.RequiresLineOfSight = false
                        prompt.Enabled = true
                        pcall(function()
                            if fireproximityprompt then fireproximityprompt(prompt, 0) end
                        end)
                    end
                end
            end
        end)
    end
})

local IJOESP = IJOTab:CreateSubTab({ Title = "ESP", Icon = "eye" })

local espBoulderC4Enabled = false
local boulderHighlights = {}

IJOESP:Toggle({
    Title = "Boulder Seal & C4",
    Default = false,
    Callback = function(state)
        espBoulderC4Enabled = state
        for _, hl in pairs(boulderHighlights) do pcall(function() hl:Destroy() end) end
        table.clear(boulderHighlights)
        if not espBoulderC4Enabled then return end
        
        local function apply(obj)
            if boulderHighlights[obj] or not (obj:IsA("Model") or obj:IsA("BasePart")) then return end
            local hl = Instance.new("Highlight")
            hl.FillColor = Color3.fromRGB(0, 255, 0)
            hl.OutlineColor = Color3.fromRGB(0, 0, 0)
            hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            hl.Adornee = obj
            hl.Parent = obj
            boulderHighlights[obj] = hl
            
            local bb = Instance.new("BillboardGui")
            bb.Size = UDim2.new(0, 200, 0, 50)
            bb.StudsOffset = Vector3.new(0, 3, 0)
            bb.AlwaysOnTop = true
            bb.Parent = obj
            
            local tl = Instance.new("TextLabel")
            tl.Size = UDim2.new(1, 0, 1, 0)
            tl.BackgroundTransparency = 1
            tl.Text = obj.Name
            tl.TextColor3 = Color3.fromRGB(0, 255, 0)
            tl.TextStrokeTransparency = 0
            tl.TextSize = 13
            tl.Font = Enum.Font.FredokaOne
            tl.Parent = bb
        end
        
        local s4 = workspace:FindFirstChild("Section4")
        local f1 = s4 and s4:FindFirstChild("Lab") and s4.Lab:FindFirstChild("Floor1")
        if f1 then
            local obj2 = f1:FindFirstChild("Objective2")
            local boulder = obj2 and obj2:FindFirstChild("C4Explode") and obj2.C4Explode:FindFirstChild("BoulderSeal")
            if boulder then apply(boulder) end
            
            local obj3 = f1:FindFirstChild("Objective3")
            local c4Explode3 = obj3 and obj3:FindFirstChild("C4Explode")
            if c4Explode3 then
                for _, m in ipairs(c4Explode3:GetChildren()) do apply(m) end
                c4Explode3.ChildAdded:Connect(function(m) if espBoulderC4Enabled then apply(m) end end)
            end
        end
    end
})

local espLabMonsterEnabled = false
local labMonsterHL = {}

IJOESP:Toggle({
    Title = "Monster",
    Default = false,
    Callback = function(state)
        espLabMonsterEnabled = state
        for _, hl in pairs(labMonsterHL) do pcall(function() hl:Destroy() end) end
        table.clear(labMonsterHL)
        if not espLabMonsterEnabled then return end
        
        local function apply(model)
            if labMonsterHL[model] or not (model:IsA("Model") or model:IsA("BasePart")) then return end
            local hl = Instance.new("Highlight")
            hl.FillColor = Color3.fromRGB(255, 0, 0)
            hl.OutlineColor = Color3.fromRGB(0, 0, 0)
            hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            hl.Adornee = model
            hl.Parent = model
            labMonsterHL[model] = hl
            
            local bb = Instance.new("BillboardGui")
            bb.Size = UDim2.new(0, 200, 0, 50)
            bb.StudsOffset = Vector3.new(0, 3, 0)
            bb.AlwaysOnTop = true
            bb.Parent = model
            
            local tl = Instance.new("TextLabel")
            tl.Size = UDim2.new(1, 0, 1, 0)
            tl.BackgroundTransparency = 1
            tl.Text = model.Name
            tl.TextColor3 = Color3.fromRGB(255, 0, 0)
            tl.TextStrokeTransparency = 0
            tl.TextSize = 13
            tl.Font = Enum.Font.FredokaOne
            tl.Parent = bb
        end
        
        local s4 = workspace:FindFirstChild("Section4")
        local folder = s4 and s4:FindFirstChild("Monster")
        if folder then
            for _, m in ipairs(folder:GetChildren()) do apply(m) end
            folder.ChildAdded:Connect(function(m) if espLabMonsterEnabled then apply(m) end end)
        end
    end
})

local espTerminalValveEnabled = false
local objHighlights = {}

IJOESP:Toggle({
    Title = "Terminal & Valve",
    Default = false,
    Callback = function(state)
        espTerminalValveEnabled = state
        for _, hl in pairs(objHighlights) do pcall(function() hl:Destroy() end) end
        table.clear(objHighlights)
        if not espTerminalValveEnabled then return end
        
        local function apply(obj)
            if objHighlights[obj] or not (obj:IsA("Model") or obj:IsA("BasePart")) then return end
            local hl = Instance.new("Highlight")
            hl.FillColor = Color3.fromRGB(0, 255, 0)
            hl.OutlineColor = Color3.fromRGB(0, 0, 0)
            hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            hl.Adornee = obj
            hl.Parent = obj
            objHighlights[obj] = hl
        end
        
        local function setup(folder)
            if not folder then return end
            for _, m in ipairs(folder:GetChildren()) do apply(m) end
            folder.ChildAdded:Connect(function(m) if espTerminalValveEnabled then apply(m) end end)
        end
        
        local s4 = workspace:FindFirstChild("Section4")
        local cleanse = s4 and s4:FindFirstChild("Lab") and s4.Lab:FindFirstChild("CleanseRoomObjective")
        if cleanse then
            setup(cleanse:FindFirstChild("Valves"))
            setup(cleanse:FindFirstChild("ShapeTerminals"))
        end
    end
})

local WaterTab = Window:CreateTab({ Title = "Water", Icon = "droplet" })
local WaterStairs = WaterTab:CreateSubTab({ Title = "Stairs", Icon = "footprints", Default = true })
local WaterMain = WaterTab:CreateSubTab({ Title = "Main", Icon = "gamepad-2" })
local WaterESP = WaterTab:CreateSubTab({ Title = "ESP", Icon = "eye" })

WaterMain:Button({
    Title = "Power Switch",
    Callback = function()
        task.spawn(function()
            local char = game:GetService("Players").LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            local ps = workspace:FindFirstChild("Section5") and workspace.Section5:FindFirstChild("MainObjective") and workspace.Section5.MainObjective:FindFirstChild("PowerSwitch")
            if not ps then return end
            hrp.CFrame = ps:GetPivot()
            task.wait(0.2)
            local pr = ps:FindFirstChildWhichIsA("ProximityPrompt", true)
            if pr and fireproximityprompt then pr.HoldDuration = 0 fireproximityprompt(pr, 0) end
        end)
    end
})

WaterMain:Button({
    Title = "Auto WireBoxes",
    Callback = function()
        task.spawn(function()
            local rel = game:GetService("ReplicatedStorage"):FindFirstChild("modules") and game:GetService("ReplicatedStorage").modules:FindFirstChild("Packet") and game:GetService("ReplicatedStorage").modules.Packet:FindFirstChild("Reliable")
            if not rel then return end
            local b = workspace:FindFirstChild("Section5") and workspace.Section5:FindFirstChild("MainObjective") and workspace.Section5.MainObjective:FindFirstChild("Boxes")
            if not b then return end
            for _, w in ipairs(b:GetChildren()) do
                if w.Name == "WireBox" then
                    pcall(function() rel:FireServer("Section5/WireBoxClaim", w) end)
                    local s = w:FindFirstChild("Screw", true)
                    if s then pcall(function() rel:FireServer("Section5/WireBoxScrewDone", s) end) end
                    local l = w:FindFirstChild("Lid", true)
                    if l then pcall(function() rel:FireServer("Section5/WireBoxLidOpen", l) end) end
                    local c = w:FindFirstChild("Cuttable")
                    if c then for _, ci in ipairs(c:GetChildren()) do pcall(function() rel:FireServer("Section5/WireBoxCutDone", ci) end) end end
                    pcall(function() rel:FireServer("Section5/WireBoxComplete", w) end)
                end
            end
        end)
    end
})

WaterStairs:Button({
    Title = "Skip Stairs",
    Callback = function()
        task.spawn(function()
            local hrp = game:GetService("Players").LocalPlayer.Character and game:GetService("Players").LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            hrp.CFrame = CFrame.new(-1857.36, -340.11, 4673.78)
            task.wait(0.1)
            local tw = game:GetService("TweenService"):Create(hrp, TweenInfo.new(1, Enum.EasingStyle.Linear), {CFrame = CFrame.new(-1832.44, -340.11, 4672.79)})
            tw:Play() tw.Completed:Wait()
        end)
    end
})

WaterStairs:Toggle({
    Title = "Auto Shoot Blocks",
    Default = false,
    Callback = function(s)
        if not s then return end
        task.spawn(function()
            while s do
                local f = workspace:FindFirstChild("Section5") and workspace.Section5:FindFirstChild("StairsSection") and workspace.Section5.StairsSection:FindFirstChild("FleshBlock")
                if f then for _, b in ipairs(f:GetChildren()) do local r = b:FindFirstChild("body") and b.body:FindFirstChild("RemoteEvent") if r then r:FireServer() end end end
                task.wait(0.05)
            end
        end)
    end
})

WaterStairs:Toggle({
    Title = "Auto Shoot HogoGuntai",
    Default = false,
    Callback = function(s)
        if not s then return end
        task.spawn(function()
            while s do
                local h = workspace:FindFirstChild("Section5") and workspace.Section5:FindFirstChild("StairsSection") and workspace.Section5.StairsSection:FindFirstChild("Monster") and workspace.Section5.StairsSection.Monster:FindFirstChild("HogoGuntai")
                if h then local r = h:FindFirstChild("RemoteEvent") or h:FindFirstChildWhichIsA("RemoteEvent", true) if r then r:FireServer() end end
                task.wait(0.05)
            end
        end)
    end
})

local psHl, wmHl, bxHl = {}, {}, {}

WaterESP:Toggle({
    Title = "Power Switch",
    Default = false,
    Callback = function(s)
        if psHl[1] then psHl[1]:Destroy() table.clear(psHl) end
        if not s then return end
        local ps = workspace:FindFirstChild("Section5") and workspace.Section5:FindFirstChild("MainObjective") and workspace.Section5.MainObjective:FindFirstChild("PowerSwitch")
        if ps then
            local h = Instance.new("Highlight") h.FillColor = Color3.new(0,1,0) h.OutlineColor = Color3.new(0,1,0) h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop h.Adornee = ps h.Parent = ps table.insert(psHl, h)
        end
    end
})

WaterESP:Toggle({
    Title = "Monster",
    Default = false,
    Callback = function(s)
        for _, h in pairs(wmHl) do h:Destroy() end table.clear(wmHl)
        if not s then return end
        local f = workspace:FindFirstChild("Section5") and workspace.Section5:FindFirstChild("Monster")
        if f then for _, m in ipairs(f:GetChildren()) do
            if m:IsA("Model") then
                local h = Instance.new("Highlight") h.FillColor = Color3.new(1,0,0) h.OutlineColor = Color3.new(0,0,0) h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop h.Adornee = m h.Parent = m table.insert(wmHl, h)
                local b = Instance.new("BillboardGui") b.Size = UDim2.fromOffset(200,50) b.StudsOffset = Vector3.new(0,3,0) b.AlwaysOnTop = true b.Parent = m
                local t = Instance.new("TextLabel") t.Size = UDim2.fromScale(1,1) t.BackgroundTransparency = 1 t.Text = m.Name t.TextColor3 = Color3.new(1,0,0) t.TextStrokeTransparency = 0 t.TextSize = 13 t.Font = Enum.Font.FredokaOne t.Parent = b
            end
        end end
    end
})

WaterESP:Toggle({
    Title = "Wirebox",
    Default = false,
    Callback = function(s)
        for _, h in pairs(bxHl) do h:Destroy() end table.clear(bxHl)
        if not s then return end
        local f = workspace:FindFirstChild("Section5") and workspace.Section5:FindFirstChild("MainObjective") and workspace.Section5.MainObjective:FindFirstChild("Boxes")
        if f then for _, m in ipairs(f:GetChildren()) do
            if m:IsA("Model") or m:IsA("BasePart") then
                local h = Instance.new("Highlight") h.FillColor = Color3.new(0,1,0) h.OutlineColor = Color3.new(0,1,0) h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop h.Adornee = m h.Parent = m table.insert(bxHl, h)
            end
        end end
    end
})
