local KazeUI = KazeUI or loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/KazeHub/UI/refs/heads/main/libraryUI.txt"
))()

local Window = KazeUI:CreateWindow({
    Title = "THE MIMIC",
    Author = "KAZE",
    Version = "JIGOKU",
    Size = UDim2.fromOffset(500, 370),
    Icon = "79414074886215",
    Theme = "Obsidian",
    GlowStyle = "None",
    GlowColor = false,
    
    PopupTitle = "Welcome to Kaze Hub!",
    PopupContent = "Thank you for using my script! if you found any bug, please report it to the discord.",
    DiscordLink = "https://discord.gg/DKGRny4DD",
    YoutubeLink = "https://www.youtube.com/@Kaze_Hub",

    OpenButton = {
        Icon = "79414074886215",
        Hidable = false,
        Size = UDim2.fromOffset(60, 60)
    },
})

local Player = Window:CreateTab({
    Title = "Player",
    Icon = "user"
})

local Workspace = (typeof(cloneref) == "function" and cloneref(game:GetService("Workspace"))) or game:GetService("Workspace")
local Lighting = (typeof(cloneref) == "function" and cloneref(game:GetService("Lighting"))) or game:GetService("Lighting")
local RunService = (typeof(cloneref) == "function" and cloneref(game:GetService("RunService"))) or game:GetService("RunService")
local Players = (typeof(cloneref) == "function" and cloneref(game:GetService("Players"))) or game:GetService("Players")
local LocalPlayer = Players.LocalPlayer


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

Player:Section("Client")

local InstantPromptEnabled = false
local promptConnection

Player:Toggle({
    Title = "Instant Prompt",
    Default = false,
    Callback = function(s)
        InstantPromptEnabled = s
        
        if promptConnection then
            promptConnection:Disconnect()
            promptConnection = nil
        end
        
        if InstantPromptEnabled then
            task.defer(function()
                for _, prompt in ipairs(Workspace:GetDescendants()) do
                    if prompt:IsA("ProximityPrompt") then
                        prompt.HoldDuration = 0
                    end
                end
            end)
            
            promptConnection = Workspace.DescendantAdded:Connect(function(descendant)
                if descendant:IsA("ProximityPrompt") then
                    descendant.HoldDuration = 0
                end
            end)
        end
    end
})

local FB_ENABLED = false
local fbConnection
local origAmbient = Lighting.Ambient
local origOutdoorAmbient = Lighting.OutdoorAmbient
local origBrightness = Lighting.Brightness
local origClockTime = Lighting.ClockTime
local origShadows = Lighting.GlobalShadows

Player:Toggle({
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
            fbConnection = Lighting:GetPropertyChangedSignal("Ambient"):Connect(applyBright)
        else
            Lighting.Ambient = origAmbient
            Lighting.OutdoorAmbient = origOutdoorAmbient
            Lighting.Brightness = origBrightness
            Lighting.ClockTime = origClockTime
            Lighting.GlobalShadows = origShadows
        end
    end
})

local NoclipEnabled = false
local noclipConnection

Player:Toggle({
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

local TPWalkSpeed = 1
local TPWalkEnabled = false
local tpWalkConnection

Player:Slider({
    Title = "TP Walk Speed",
    Min = 1,
    Max = 10,
    Default = 1,
    Callback = function(v)
        TPWalkSpeed = v
    end
})

Player:Toggle({
    Title = "Enable TP Walk",
    Default = false,
    Callback = function(s)
        TPWalkEnabled = s

        if tpWalkConnection then
            tpWalkConnection:Disconnect()
            tpWalkConnection = nil
        end

        if TPWalkEnabled then
            tpWalkConnection = RunService.Heartbeat:Connect(function(dt)
                local hrp = CachedHRP
                local humanoid = CachedHumanoid
                if not hrp or not hrp.Parent then
                    local character = LocalPlayer.Character
                    if not character then return end
                    hrp = character:FindFirstChild("HumanoidRootPart")
                    humanoid = character:FindFirstChildOfClass("Humanoid")
                    CachedHRP = hrp
                    CachedHumanoid = humanoid
                end
                if hrp and humanoid and humanoid.MoveDirection.Magnitude > 0 then
                    hrp.CFrame = hrp.CFrame + (humanoid.MoveDirection * (TPWalkSpeed * 0.15))
                end
            end)
        end
    end
})

local TargetFlySpeed = 16
local FLY_ENABLED = false
local flyConnection

Player:Slider({
    Title = "Fly Speed",
    Min = 16,
    Max = 100,
    Default = 16,
    Callback = function(val)
        TargetFlySpeed = val
    end
})

Player:Toggle({
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
            local camera = Workspace.CurrentCamera
            
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

local Jigoku = Window:CreateTab({ Title = "Jigoku", Icon = "flame" })

Jigoku:Section("Main")

Jigoku:Button({
    Title = "Start",
    Callback = function()
        task.spawn(function()
            local plr = Players.LocalPlayer
            local character = plr.Character or plr.CharacterAdded:Wait()
            local hrp = character and character:FindFirstChild("HumanoidRootPart")
            if not character or not hrp then return end

            local touchPart = Workspace:FindFirstChild("[ID]Touch1")
            if touchPart then
                hrp.Anchored = false
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
                
                local targetCF = touchPart:IsA("BasePart") and touchPart.CFrame or touchPart:GetPivot()
                character:PivotTo(targetCF)
            end
        end)
    end
})

Jigoku:Button({
    Title = "Auto Orb",
    Callback = function()
        task.spawn(function()
            local plr = Players.LocalPlayer
            local character = plr.Character or plr.CharacterAdded:Wait()
            local HRP = character:WaitForChild("HumanoidRootPart", 3)
            if not HRP then return end

            local gameAI = Workspace:FindFirstChild("GameAI")
            local folder = gameAI and gameAI:FindFirstChild("Souls")
            if not folder then return end

            for _, v in ipairs(folder:GetChildren()) do
                if v and v.Parent == folder and (v:IsA("Model") or v:IsA("BasePart")) then
                    local part = v:IsA("BasePart") and v or v:FindFirstChildWhichIsA("BasePart")
                    if part then
                        HRP.CFrame = part.CFrame + Vector3.new(0, 3, 0)
                        task.wait(0.25)

                        -- Fire prompts
                        for _, d in ipairs(v:GetDescendants()) do
                            if d:IsA("ProximityPrompt") then
                                fireproximityprompt(d)
                            end
                        end

                        -- Wait until the orb is removed from the folder before moving to the next
                        local startTime = tick()
                        while v and v.Parent == folder and (tick() - startTime < 1.5) do
                            task.wait(0.05)
                            -- Retry firing prompt if it didn't register right away
                            for _, d in ipairs(v:GetDescendants()) do
                                if d:IsA("ProximityPrompt") then
                                    fireproximityprompt(d)
                                end
                            end
                        end
                    end
                end
            end

            task.wait(0.25)
            HRP.CFrame = CFrame.new(603.6, 76.4, 495.6)
        end)
    end
})

Jigoku:Section("ESP")

local shihyoshaEnabled = false
local shihyoshaObjects = {}
local shihyoshaConnections = {}

local function clearShihyoshaESP()
    for _, obj in ipairs(shihyoshaObjects) do
        if obj and obj.Parent then pcall(function() obj:Destroy() end) end
    end
    for _, conn in ipairs(shihyoshaConnections) do
        if conn then pcall(function() conn:Disconnect() end) end
    end
    shihyoshaObjects = {}
    shihyoshaConnections = {}
end

local function getPartPosition(model)
    if not model then return nil end
    if model:IsA("BasePart") then return model.Position end
    if model:IsA("Model") then
        if model.PrimaryPart then return model.PrimaryPart.Position end
        local hrp = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Torso") or model:FindFirstChild("UpperTorso")
        if hrp and hrp:IsA("BasePart") then return hrp.Position end
        for _, child in ipairs(model:GetDescendants()) do
            if child:IsA("BasePart") then return child.Position end
        end
    end
    return nil
end

local function createShihyoshaESP(model)
    if not model or not model:IsA("Model") then return end
    
    local partToAdorn = model.PrimaryPart or model:FindFirstChild("HumanoidRootPart") or model:FindFirstChildWhichIsA("BasePart", true)
    if not partToAdorn then return end

    local highlight = Instance.new("Highlight")
    highlight.Name = "ShihyoshaHighlight"
    highlight.FillColor = Color3.fromRGB(255, 0, 0)
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.Adornee = model
    highlight.Parent = model
    table.insert(shihyoshaObjects, highlight)

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ShihyoshaBillboard"
    billboard.Size = UDim2.new(0, 150, 0, 35)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = partToAdorn
    table.insert(shihyoshaObjects, billboard)

    local text = Instance.new("TextLabel")
    text.BackgroundTransparency = 1
    text.Size = UDim2.new(1, 0, 1, 0)
    text.TextStrokeTransparency = 0
    text.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    text.TextColor3 = Color3.fromRGB(255, 0, 0)
    text.TextScaled = false
    text.TextSize = 13
    text.Font = Enum.Font.SourceSansBold
    text.Text = "Shihyosha"
    text.Parent = billboard

    local conn = RunService.RenderStepped:Connect(function()
        if not shihyoshaEnabled or not model.Parent then
            pcall(function()
                billboard:Destroy()
                highlight:Destroy()
            end)
            return
        end
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local targetPos = getPartPosition(model)
        if hrp and targetPos then
            local dist = (hrp.Position - targetPos).Magnitude
            text.Text = "Shihyosha\n[" .. math.floor(dist) .. "]"
        end
    end)
    table.insert(shihyoshaConnections, conn)
end

Jigoku:Toggle({
    Title = "ESP Shihyosha",
    Default = false,
    Callback = function(s)
        shihyoshaEnabled = s
        clearShihyoshaESP()
        if not s then return end

        local aiContainer = Workspace:FindFirstChild("GameAI") and Workspace.GameAI:FindFirstChild("AI")
        if aiContainer then
            if aiContainer:IsA("Model") then
                createShihyoshaESP(aiContainer)
            else
                for _, obj in ipairs(aiContainer:GetChildren()) do
                    if obj:IsA("Model") and obj.Name ~= "AnimSaves" then
                        createShihyoshaESP(obj)
                    end
                end

                local conn = aiContainer.ChildAdded:Connect(function(obj)
                    if shihyoshaEnabled and obj:IsA("Model") and obj.Name ~= "AnimSaves" then
                        task.wait(0.1)
                        createShihyoshaESP(obj)
                    end
                end)
                table.insert(shihyoshaConnections, conn)
            end
        end
    end
})

local orbsEnabled = false
local orbsObjects = {}
local orbsConnections = {}

local function clearOrbsESP()
    for _, obj in ipairs(orbsObjects) do
        if obj and obj.Parent then pcall(function() obj:Destroy() end) end
    end
    for _, conn in ipairs(orbsConnections) do
        if conn then pcall(function() conn:Disconnect() end) end
    end
    orbsObjects = {}
    orbsConnections = {}
end

local function createOrbESP(model)
    if not model then return end
    
    local partToAdorn = nil
    if model:IsA("Model") then
        partToAdorn = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
    elseif model:IsA("BasePart") then
        partToAdorn = model
    end

    if not partToAdorn then return end

    local highlight = Instance.new("Highlight")
    highlight.Name = "OrbHighlight"
    highlight.FillColor = Color3.fromRGB(0, 255, 255)
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.Adornee = model
    highlight.Parent = model
    table.insert(orbsObjects, highlight)

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "OrbBillboard"
    billboard.Size = UDim2.new(0, 150, 0, 35)
    billboard.StudsOffset = Vector3.new(0, 2, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = partToAdorn
    table.insert(orbsObjects, billboard)

    local text = Instance.new("TextLabel")
    text.BackgroundTransparency = 1
    text.Size = UDim2.new(1, 0, 1, 0)
    text.TextStrokeTransparency = 0
    text.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    text.TextColor3 = Color3.fromRGB(0, 255, 255)
    text.TextScaled = false
    text.TextSize = 13
    text.Font = Enum.Font.SourceSansBold
    text.Text = "Orb"
    text.Parent = billboard

    local conn = RunService.RenderStepped:Connect(function()
        if not orbsEnabled or not model.Parent then
            pcall(function()
                billboard:Destroy()
                highlight:Destroy()
            end)
            return
        end
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local targetPos = getPartPosition(model)
        if hrp and targetPos then
            local dist = (hrp.Position - targetPos).Magnitude
            text.Text = "Orb\n[" .. math.floor(dist) .. "]"
        end
    end)
    table.insert(orbsConnections, conn)
end

Jigoku:Toggle({
    Title = "ESP Orbs",
    Default = false,
    Callback = function(s)
        orbsEnabled = s
        clearOrbsESP()
        if not s then return end

        local soulsFolder = Workspace:FindFirstChild("GameAI") and Workspace.GameAI:FindFirstChild("Souls")
        if soulsFolder then
            for _, obj in ipairs(soulsFolder:GetChildren()) do
                createOrbESP(obj)
            end

            local conn = soulsFolder.ChildAdded:Connect(function(obj)
                if orbsEnabled then
                    task.wait(0.1)
                    createOrbESP(obj)
                end
            end)
            table.insert(orbsConnections, conn)
        end
    end
})
