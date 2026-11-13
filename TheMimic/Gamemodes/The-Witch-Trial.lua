local KazeUI = KazeUI or loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/KazeHub/UI/refs/heads/main/libraryUI.txt"
))()

local Window = KazeUI:CreateWindow({
    Title = "THE MIMIC",
    Author = "KAZE",
    Version = "THE WITCH TRIAL",
    Size = UDim2.fromOffset(500, 370),
    Icon = "79414074886215",
    Theme = "Obsidian",
    GlowStyle = "None",
    GlowColor = false,

    PopupTitle = "Welcome to Kaze Hub!",
    PopupContent = "Thank you for using my script! If you found any bug, please report it to the discord.",
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

local Lighting = (typeof(cloneref) == "function" and cloneref(game:GetService("Lighting"))) or game:GetService("Lighting")

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
                    hrp.CFrame = hrp.CFrame + (humanoid.MoveDirection * (TPWalkSpeed * 0.35))
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

local TWT=Window:CreateTab({
    Title="The Witch Trial",
    Icon="ghost"
})

local TweenService=game:GetService("TweenService")
local RunService=game:GetService("RunService")
local Players=game:GetService("Players")
local LocalPlayer=Players.LocalPlayer
local Workspace=game:GetService("Workspace")

local function getHRP()
    local character=LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    return character and character:FindFirstChild("HumanoidRootPart")
end

local function getTeleportPart()
    local teleporter=Workspace:FindFirstChild("Game Teleporter")
    if not teleporter then return nil end
    if teleporter:IsA("BasePart") then
        return teleporter
    end
    if teleporter:IsA("Model") then
        return teleporter.PrimaryPart or teleporter:FindFirstChildWhichIsA("BasePart",true)
    end
    return teleporter:FindFirstChildWhichIsA("BasePart",true)
end

local function teleportToGameTeleporter()
    local hrp=getHRP()
    local teleporter=getTeleportPart()
    if hrp and teleporter then
        hrp.CFrame=teleporter.CFrame
    end
end

TWT:Section("Stage I")

TWT:Button({
    Title="Auto Win",
    Callback=function()
        teleportToGameTeleporter()
    end
})

TWT:Section("Stage II")

TWT:Button({
    Title="Auto Win",
    Callback=function()
        teleportToGameTeleporter()
    end
})

TWT:Section("Stage III")

TWT:Button({
    Title="Auto Win",
    Callback=function()
        teleportToGameTeleporter()
    end
})

local twtESPEnabled=false
local twtESPObjects={}
local twtESPConnections={}
local twtESPModels={}

local function getPartPosition(obj)
    if not obj then return nil end

    if obj:IsA("BasePart") then
        return obj.Position
    end

    if obj:IsA("Model") then
        if obj.PrimaryPart then
            return obj.PrimaryPart.Position
        end

        local part=obj:FindFirstChildWhichIsA("BasePart",true)
        if part then
            return part.Position
        end

        local ok,cf=obj:GetBoundingBox()
        if ok and cf then
            return cf.Position
        end
    end

    return nil
end

local function clearTWTESP()
    for _,obj in ipairs(twtESPObjects) do
        if obj then
            pcall(function()
                obj:Destroy()
            end)
        end
    end

    for _,conn in ipairs(twtESPConnections) do
        if conn then
            pcall(function()
                conn:Disconnect()
            end)
        end
    end

    twtESPObjects={}
    twtESPConnections={}
    twtESPModels={}
end

local function createTWTESP(model)
    if not model or not model.Parent then return end
    if twtESPModels[model] then return end

    local partToAdorn=nil

    if model:IsA("Model") then
        partToAdorn=model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart",true)
    elseif model:IsA("BasePart") then
        partToAdorn=model
    end

    if not partToAdorn then return end

    twtESPModels[model]=true

    local highlight=Instance.new("Highlight")
    highlight.Name="TWT_ESP_Highlight"
    highlight.FillColor=Color3.fromRGB(255,0,0)
    highlight.OutlineColor=Color3.fromRGB(255,255,255)
    highlight.FillTransparency=0.5
    highlight.OutlineTransparency=0
    highlight.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Adornee=model
    highlight.Parent=model

    table.insert(twtESPObjects,highlight)

    local billboard=Instance.new("BillboardGui")
    billboard.Name="TWT_ESP_Billboard"
    billboard.Size=UDim2.new(0,150,0,35)
    billboard.StudsOffset=Vector3.new(0,2,0)
    billboard.AlwaysOnTop=true
    billboard.Parent=partToAdorn

    table.insert(twtESPObjects,billboard)

    local text=Instance.new("TextLabel")
    text.BackgroundTransparency=1
    text.Size=UDim2.new(1,0,1,0)
    text.TextStrokeTransparency=0
    text.TextStrokeColor3=Color3.fromRGB(0,0,0)
    text.TextColor3=Color3.fromRGB(255,0,0)
    text.TextScaled=false
    text.TextSize=13
    text.Font=Enum.Font.SourceSansBold
    text.Text=model.Name
    text.Parent=billboard

    local lastUpdate=0

    local conn=RunService.Heartbeat:Connect(function()
        if tick()-lastUpdate<0.4 then return end
        lastUpdate=tick()

        if not twtESPEnabled or not model.Parent then
            twtESPModels[model]=nil

            pcall(function()
                billboard:Destroy()
            end)

            pcall(function()
                highlight:Destroy()
            end)

            return
        end

        local character=LocalPlayer.Character
        local hrp=character and character:FindFirstChild("HumanoidRootPart")
        local targetPos=getPartPosition(model)

        if hrp and targetPos then
            local distance=(hrp.Position-targetPos).Magnitude
            text.Text=model.Name.."\n["..math.floor(distance).."]"
        else
            text.Text=model.Name
        end
    end)

    table.insert(twtESPConnections,conn)
end

TWT:Toggle({
    Title="ESP Monsters",
    Default=false,
    Callback=function(state)
        twtESPEnabled=state
        clearTWTESP()

        if not state then
            return
        end

        local gameAI=Workspace:FindFirstChild("GameAI")
        if not gameAI then
            return
        end

        for _,obj in ipairs(gameAI:GetChildren()) do
            if obj:IsA("Model") then
                createTWTESP(obj)
            end
        end

        local childAddedConnection=gameAI.ChildAdded:Connect(function(obj)
            if not twtESPEnabled then return end

            if obj:IsA("Model") then
                task.wait(0.1)

                if twtESPEnabled and obj.Parent then
                    createTWTESP(obj)
                end
            end
        end)

        table.insert(twtESPConnections,childAddedConnection)

        local childRemovedConnection=gameAI.ChildRemoved:Connect(function(obj)
            twtESPModels[obj]=nil
        end)

        table.insert(twtESPConnections,childRemovedConnection)
    end
})
