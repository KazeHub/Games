local KazeUI = KazeUI or loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/KazeHub/UI/refs/heads/main/libraryUI.txt"
))()

local Window = KazeUI:CreateWindow({
    Title = "THE MIMIC",
    Author = "KAZE",
    Version = "HALLOWEEN",
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


--------------------------------------------------
-- GLOBAL SERVICES & CORE HELPERS
--------------------------------------------------
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local player = Players.LocalPlayer

local function getHRP()
    local char = player and (player.Character or player.CharacterAdded:Wait())
    if not char then return nil end
    return char:WaitForChild("HumanoidRootPart", 5)
end

local function getModelPart(obj)
    if not obj then return nil end
    if obj:IsA("BasePart") then return obj end
    if obj:IsA("Model") then
        if obj.PrimaryPart then return obj.PrimaryPart end
        return obj:FindFirstChildWhichIsA("BasePart", true)
    end
    return nil
end

local function getPrompt(obj)
    if not obj then return nil end
    if obj:IsA("ProximityPrompt") and obj.Enabled then return obj end

    for _, desc in ipairs(obj:GetDescendants()) do
        if desc:IsA("ProximityPrompt") and desc.Enabled then
            return desc
        end
    end
    return nil
end

local function firePrompt(prompt)
    if not prompt or not prompt:IsA("ProximityPrompt") or not prompt.Enabled then return false end
    
    if fireproximityprompt then
        fireproximityprompt(prompt)
    else
        local oldDuration = prompt.HoldDuration
        prompt.HoldDuration = 0
        prompt:InputHoldBegin()
        task.wait()
        prompt:InputHoldEnd()
        prompt.HoldDuration = oldDuration
    end
    return true
end

--------------------------------------------------
-- TABS CREATION
--------------------------------------------------
local HalloweenTab = Window:CreateTab({ Title = "Halloween", Icon = "ghost" })

local halloweenMonsterESPEnabled=false
local halloweenMonsterESPObjects={}
local halloweenMonsterESPConnections={}

local function ClearHalloweenMonsterESP()
    for _,obj in ipairs(halloweenMonsterESPObjects) do
        if obj then
            pcall(function()
                obj:Destroy()
            end)
        end
    end

    for _,conn in ipairs(halloweenMonsterESPConnections) do
        if conn then
            pcall(function()
                conn:Disconnect()
            end)
        end
    end

    halloweenMonsterESPObjects={}
    halloweenMonsterESPConnections={}
end

local function HalloweenMonsterGetPart(obj)
    if not obj then return nil end

    if obj:IsA("BasePart") then
        return obj
    end

    if obj:IsA("Model") then
        return obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart",true)
    end

    return obj:FindFirstChildWhichIsA("BasePart",true)
end

local function CreateHalloweenMonsterESP(obj)
    if not obj or not obj.Parent then return end

    local part=HalloweenMonsterGetPart(obj)
    if not part then return end

    local highlight=Instance.new("Highlight")
    highlight.Name="HalloweenMonsterESP"
    highlight.FillColor=Color3.fromRGB(255,0,0)
    highlight.OutlineColor=Color3.fromRGB(255,255,255)
    highlight.FillTransparency=0.5
    highlight.OutlineTransparency=0
    highlight.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Adornee=obj
    highlight.Parent=obj

    table.insert(halloweenMonsterESPObjects,highlight)

    local billboard=Instance.new("BillboardGui")
    billboard.Name="HalloweenMonsterESPName"
    billboard.Size=UDim2.new(0,150,0,35)
    billboard.StudsOffset=Vector3.new(0,2,0)
    billboard.AlwaysOnTop=true
    billboard.Parent=part

    table.insert(halloweenMonsterESPObjects,billboard)

    local text=Instance.new("TextLabel")
    text.BackgroundTransparency=1
    text.Size=UDim2.new(1,0,1,0)
    text.TextStrokeTransparency=0
    text.TextStrokeColor3=Color3.fromRGB(0,0,0)
    text.TextColor3=Color3.fromRGB(255,0,0)
    text.TextSize=13
    text.Font=Enum.Font.SourceSansBold
    text.Text=obj.Name
    text.Parent=billboard

    local lastUpdate=0

    local conn=RunService.Heartbeat:Connect(function()
        if tick()-lastUpdate<0.4 then return end
        lastUpdate=tick()

        if not halloweenMonsterESPEnabled or not obj.Parent then
            pcall(function()
                highlight:Destroy()
                billboard:Destroy()
            end)
            return
        end

        local character=LocalPlayer.Character
        local hrp=character and character:FindFirstChild("HumanoidRootPart")
        local targetPart=HalloweenMonsterGetPart(obj)

        if hrp and targetPart then
            local distance=(hrp.Position-targetPart.Position).Magnitude
            text.Text=obj.Name.."\n["..math.floor(distance).."]"
        end
    end)

    table.insert(halloweenMonsterESPConnections,conn)
end

HalloweenTab:Toggle({
    Title="ESP Monster",
    Default=false,
    Callback=function(state)
        halloweenMonsterESPEnabled=state
        ClearHalloweenMonsterESP()

        if not state then
            return
        end

        local targets={}

        local gameAI=Workspace:FindFirstChild("GameAI")
        local gameAIAI=gameAI and gameAI:FindFirstChild("AI")

        if gameAIAI then
            table.insert(targets,gameAIAI)
        end

        local ai=Workspace:FindFirstChild("AI")

        if ai then
            local bigSilly=ai:FindFirstChild("Big Silly")
            local kabocha=ai:FindFirstChild("Kabocha")
            local skintist=ai:FindFirstChild("Skintist")

            if bigSilly then
                table.insert(targets,bigSilly)
            end

            if kabocha then
                table.insert(targets,kabocha)
            end

            if skintist then
                table.insert(targets,skintist)
            end
        end

        for _,obj in ipairs(targets) do
            CreateHalloweenMonsterESP(obj)
        end
    end
})

--------------------------------------------------
-- INSIDE SECTIONUI (CANDY)
--------------------------------------------------
local CandySectionUI = HalloweenTab:SectionUI({ Title = "Candy", Open = true })
local CandyGroup = CandySectionUI:Group({ Title = "Candy Options", Open = true })

local espHighlights = {}

-- 1. Toggle ESP Candy
CandyGroup:Toggle({
    Title = "ESP Candy",
    Default = false,
    Callback = function(state)
        if state then
            local candyFolder = Workspace:FindFirstChild("Candy")
            if not candyFolder then return end

            local function applyESP(obj)
                if (obj:IsA("MeshPart") or obj:IsA("BasePart") or obj:IsA("Model")) and not espHighlights[obj] then
                    local highlight = Instance.new("Highlight")
                    highlight.Name = "CandyESP"
                    highlight.FillColor = Color3.fromRGB(255, 170, 0)
                    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                    highlight.FillTransparency = 0.4
                    highlight.OutlineTransparency = 0
                    highlight.Adornee = obj
                    highlight.Parent = obj
                    espHighlights[obj] = highlight
                end
            end

            for _, item in ipairs(candyFolder:GetDescendants()) do
                applyESP(item)
            end

            espHighlights["ChildAdded"] = candyFolder.DescendantAdded:Connect(function(item)
                applyESP(item)
            end)
        else
            if espHighlights["ChildAdded"] then
                espHighlights["ChildAdded"]:Disconnect()
                espHighlights["ChildAdded"] = nil
            end

            for obj, highlight in pairs(espHighlights) do
                if typeof(highlight) == "Instance" and highlight:IsA("Highlight") then
                    highlight:Destroy()
                end
            end
            table.clear(espHighlights)
        end
    end
})

-- 2. Button Collect Candy
CandyGroup:Button({
    Title = "Collect Candy",
    Callback = function()
        local hrp = getHRP()
        if not hrp then return end

        local candyFolder = Workspace:FindFirstChild("Candy")
        if not candyFolder then return end

        local originalCFrame = hrp.CFrame
        local candyList = {}

        for _, item in ipairs(candyFolder:GetChildren()) do
            if item:IsA("BasePart") or item:IsA("MeshPart") or item:IsA("Model") then
                table.insert(candyList, item)
            end
        end

        if #candyList == 0 then return end

        for _, candy in ipairs(candyList) do
            if candy and candy.Parent and candy:IsDescendantOf(Workspace) then
                local part = getModelPart(candy)
                if part then
                    -- Teleport delay 0.2s
                    hrp.CFrame = part.CFrame + Vector3.new(0, 3, 0)
                    task.wait(0.1)

                    -- Fire 1 to 5 times or until the object is destroyed
                    for fireCount = 1, 5 do
                        if not candy or not candy.Parent or not candy:IsDescendantOf(Workspace) then
                            break
                        end

                        local prompt = getPrompt(candy)
                        if prompt then
                            firePrompt(prompt)
                            task.wait(0.016) -- Fire delay 0.1s
                        else
                            task.wait(0.016)
                        end
                    end
                end
            end
        end

        task.wait(0.2)
        hrp.CFrame = originalCFrame
    end
})

HalloweenTab:Section("Stage I")
--------------------------------------------------
-- OUTSIDE SECTIONUI (AUTO WIN)
--------------------------------------------------
HalloweenTab:Button({
    Title = "Auto Win",
    Callback = function()
        local hrp = getHRP()
        if not hrp then return end

        local gameInfo = Workspace:FindFirstChild("GameInfo")
        local puzzleFolder = gameInfo and gameInfo:FindFirstChild("PuzzleItems")
        if not puzzleFolder then return end

        local originalCFrame = hrp.CFrame
        local puzzleItems = {}

        for _, item in ipairs(puzzleFolder:GetChildren()) do
            if item:IsA("BasePart") or item:IsA("MeshPart") or item:IsA("Model") then
                table.insert(puzzleItems, item)
            end
        end

        if #puzzleItems == 0 then return end

        -- 1. Collect all Puzzle Items inside the folder (Fires 1 to 5 times each)
        for _, puzzleItem in ipairs(puzzleItems) do
            if puzzleItem and puzzleItem.Parent and puzzleItem:IsDescendantOf(Workspace) then
                local part = getModelPart(puzzleItem)
                if part then
                    -- Teleport delay 0.2s
                    hrp.CFrame = part.CFrame + Vector3.new(0, 3, 0)
                    task.wait(0.2)

                    -- Fire 1 to 5 times per item or until destroyed
                    for fireCount = 1, 5 do
                        if not puzzleItem or not puzzleItem.Parent or not puzzleItem:IsDescendantOf(Workspace) then
                            break
                        end

                        local prompt = getPrompt(puzzleItem)
                        if prompt then
                            firePrompt(prompt)
                            task.wait(0.1) -- Fire delay 0.1s
                        else
                            task.wait(0.1)
                        end
                    end
                end
            end
        end

        -- 2. Teleport to workspace.Map.Well and fire 3 times
        local mapFolder = Workspace:FindFirstChild("Map")
        local wellObj = mapFolder and mapFolder:FindFirstChild("Well")

        if wellObj then
            local wellPart = getModelPart(wellObj)
            if wellPart then
                hrp.CFrame = wellPart.CFrame + Vector3.new(0, 4, 0)
                task.wait(0.2) -- Teleport delay 0.2s

                for i = 1, 3 do
                    local wellPrompt = getPrompt(wellObj)
                    if wellPrompt then
                        firePrompt(wellPrompt)
                    end
                    task.wait(0.5) -- 0.5s delay between fires
                end
            end
        end

        task.wait(0.2)
        hrp.CFrame = originalCFrame
    end
})

HalloweenTab:Section("Stage II")

local autoCandleEnabled = false

HalloweenTab:Toggle({
    Title = "Auto Candles",
    Default = false,
    Callback = function(state)
        autoCandleEnabled = state

        if autoCandleEnabled then
            task.spawn(function()
                local Players = game:GetService("Players")
                local player = Players.LocalPlayer
                local playerGui = player:WaitForChild("PlayerGui")
                local screenGui = playerGui:WaitForChild("ScreenGui")
                local timerLabel = screenGui:WaitForChild("TextLabel")

                local function executeCandleLoop()
                    local character = player.Character or player.CharacterAdded:Wait()
                    local hrp = character:FindFirstChild("HumanoidRootPart")
                    local candles = workspace:FindFirstChild("Candles")

                    if not hrp or not candles then return end

                    local originalCFrame = hrp.CFrame

                    local function GetPart(candle)
                        if candle:IsA("BasePart") then return candle end
                        if candle:IsA("Model") and candle.PrimaryPart then return candle.PrimaryPart end
                        return candle:FindFirstChildWhichIsA("BasePart", true)
                    end

                    local function GetPrompt(candle)
                        return candle:FindFirstChildWhichIsA("ProximityPrompt", true)
                    end

                    local function GetTime(candle)
                        local timeObj = candle:FindFirstChild("Time", true)
                        if not timeObj then return nil end

                        local ok, value = pcall(function() return timeObj.Text end)
                        if ok and value ~= nil then return tostring(value):gsub("%s+", "") end

                        ok, value = pcall(function() return timeObj.ContentText end)
                        if ok and value ~= nil then return tostring(value):gsub("%s+", "") end

                        ok, value = pcall(function() return timeObj.Value end)
                        if ok and value ~= nil then return tostring(value):gsub("%s+", "") end

                        return nil
                    end

                    local function IsZero(candle)
                        local value = GetTime(candle)
                        return value == "0" or value == "00" or value == "0:00" or value == "00:00"
                    end

                    local function Fire(prompt)
                        if not prompt or not prompt.Parent then return end
                        pcall(function()
                            prompt.Enabled = true
                            fireproximityprompt(prompt)
                        end)
                    end

                    for _, candle in ipairs(candles:GetChildren()) do
                        if not autoCandleEnabled then break end
                        if not candle or not candle.Parent then continue end

                        local part = GetPart(candle)
                        local prompt = GetPrompt(candle)

                        if not part or not prompt then continue end

                        hrp.CFrame = part.CFrame + Vector3.new(0, 3, 0)
                        task.wait(0.2)

                        Fire(prompt)
                        task.wait(0.016)

                        while autoCandleEnabled and candle.Parent and IsZero(candle) do
                            prompt = GetPrompt(candle)
                            if not prompt then break end

                            Fire(prompt)
                            task.wait(0.016)
                        end
                    end

                    if hrp and hrp.Parent then
                        hrp.CFrame = originalCFrame
                    end
                end

                -- Continuous monitoring loop
                local triggered = false
                while autoCandleEnabled do
                    local currentText = timerLabel.ContentText:gsub("%s+", "")
                    
                    if currentText == "0:30" and not triggered then
                        triggered = true
                        executeCandleLoop()
                    elseif currentText ~= "0:30" then
                        triggered = false
                    end
                    
                    task.wait(0.1)
                end
            end)
        end
    end
})

HalloweenTab:Button({
    Title="Manual Candles",
    Callback=function()
        task.spawn(function()
            local Players=game:GetService("Players")
            local player=Players.LocalPlayer
            local character=player.Character or player.CharacterAdded:Wait()
            local hrp=character:FindFirstChild("HumanoidRootPart")
            local candles=workspace:FindFirstChild("Candles")

            if not hrp or not candles then return end

            local originalCFrame=hrp.CFrame

            local function GetPart(candle)
                if candle:IsA("BasePart") then
                    return candle
                end
                if candle:IsA("Model") and candle.PrimaryPart then
                    return candle.PrimaryPart
                end
                return candle:FindFirstChildWhichIsA("BasePart",true)
            end

            local function GetPrompt(candle)
                return candle:FindFirstChildWhichIsA("ProximityPrompt",true)
            end

            local function GetTime(candle)
                local timeObj=candle:FindFirstChild("Time",true)
                if not timeObj then return nil end

                local ok,value=pcall(function()
                    return timeObj.Text
                end)
                if ok and value~=nil then
                    return tostring(value):gsub("%s+","")
                end

                ok,value=pcall(function()
                    return timeObj.ContentText
                end)
                if ok and value~=nil then
                    return tostring(value):gsub("%s+","")
                end

                ok,value=pcall(function()
                    return timeObj.Value
                end)
                if ok and value~=nil then
                    return tostring(value):gsub("%s+","")
                end

                return nil
            end

            local function IsZero(candle)
                local value=GetTime(candle)
                return value=="0" or value=="00" or value=="0:00" or value=="00:00"
            end

            local function Fire(prompt)
                if not prompt or not prompt.Parent then return end
                pcall(function()
                    prompt.Enabled=true
                    fireproximityprompt(prompt)
                end)
            end

            for _,candle in ipairs(candles:GetChildren()) do
                if not candle or not candle.Parent then
                    continue
                end

                local part=GetPart(candle)
                local prompt=GetPrompt(candle)

                if not part or not prompt then
                    continue
                end

                -- Teleport to this candle
                hrp.CFrame=part.CFrame+Vector3.new(0,3,0)
                task.wait(0.2)

                -- Fire once
                Fire(prompt)
                task.wait(0.016)

                -- If Time is still 0, fire again
                while candle.Parent and IsZero(candle) do
                    prompt=GetPrompt(candle)
                    if not prompt then break end

                    Fire(prompt)
                    task.wait(0.016)
                end
            end

            -- Return after all candles
            if hrp and hrp.Parent then
                hrp.CFrame=originalCFrame
            end
        end)
    end
})

HalloweenTab:Section("Stage III")

HalloweenTab:Button({
    Title = "Auto Potion",
    Callback = function()
        task.spawn(function()
            local Players = game:GetService("Players")
            local player = Players.LocalPlayer
            local character = player.Character or player.CharacterAdded:Wait()
            local hrp = character:FindFirstChild("HumanoidRootPart")

            if not hrp then return end

            local originalCFrame = hrp.CFrame

            -- Helper to get a valid BasePart from any object type (Model, Part, etc.)
            local function GetPart(obj)
                if obj:IsA("BasePart") then
                    return obj
                elseif obj:IsA("Model") then
                    if obj.PrimaryPart then return obj.PrimaryPart end
                    return obj:FindFirstChildWhichIsA("BasePart", true)
                end
                return obj:FindFirstChildWhichIsA("BasePart", true)
            end

            -- Helper to find proximity prompt inside the object or its children
            local function GetPrompt(obj)
                return obj:FindFirstChildWhichIsA("ProximityPrompt", true)
            end

            -- Helper to handle teleporting and interacting
            local function InteractWith(obj)
                if not obj or not obj.Parent then return end

                local part = GetPart(obj)
                local prompt = GetPrompt(obj)

                if part and prompt then
                    -- Teleport slightly above the object
                    hrp.CFrame = part.CFrame + Vector3.new(0, 3, 0)
                    task.wait(0.2)

                    -- Fire prompt
                    pcall(function()
                        prompt.Enabled = true
                        fireproximityprompt(prompt)
                    end)
                    task.wait(0.2)
                end
            end

            -- Folder list sequence
            local ingredientFolders = {
                workspace:FindFirstChild("MainObjective") and workspace.MainObjective.Ingredients:FindFirstChild("Bats"),
                workspace:FindFirstChild("MainObjective") and workspace.MainObjective.Ingredients:FindFirstChild("Eyes"),
                workspace:FindFirstChild("MainObjective") and workspace.MainObjective.Ingredients:FindFirstChild("Roses"),
                workspace:FindFirstChild("MainObjective") and workspace.MainObjective.Ingredients:FindFirstChild("Snakes"),
            }

            -- Process each folder item by item
            for _, folder in ipairs(ingredientFolders) do
                if folder then
                    for _, ingredient in ipairs(folder:GetChildren()) do
                        InteractWith(ingredient)
                    end
                end
            end

            -- Final step: Cauldron interaction
            local cauldron = workspace:FindFirstChild("MainObjective") and workspace.MainObjective:FindFirstChild("Cauldron")
            if cauldron then
                InteractWith(cauldron)
            end

            -- Return to original spot
            if hrp and hrp.Parent then
                hrp.CFrame = originalCFrame
            end
        end)
    end
})


local SelectedMonster = "Select"
local BehindToggle = false
local followConnection = nil
local OriginalCFrame = nil

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local BEHIND_DISTANCE = -35
local TARGET_Y_HEIGHT = 55

-- Map monster targets to their B - FLAMES instance
local FlamePaths = {
    ["Big Silly"] = function() return workspace.AI:FindFirstChild("Big Silly") and workspace.AI["Big Silly"]:FindFirstChild("B - FLAMES") end,
    ["Kabocha"]   = function() return workspace.AI:FindFirstChild("Kabocha") and workspace.AI.Kabocha:FindFirstChild("B - FLAMES") end,
    ["Skintist"]  = function() return workspace.AI:FindFirstChild("Skintist") and workspace.AI.Skintist:FindFirstChild("B - FLAMES") end,
}

local function startFollowing()
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart")

    if followConnection then
        followConnection:Disconnect()
    end

    followConnection = RunService.Heartbeat:Connect(function()
        if not BehindToggle or not hrp then return end

        local flameGetter = FlamePaths[SelectedMonster]
        local flame = flameGetter and flameGetter()

        if flame and flame:IsA("BasePart") then
            local flameCF = flame.CFrame
            local flamePos = flameCF.Position
            local flameLook = flameCF.LookVector

            -- Flat 2D vector for horizontal offset behind the flame
            local flatLook = Vector3.new(flameLook.X, 0, flameLook.Z).Unit

            -- X & Z are offset 35 studs behind B - FLAMES; Y is fixed strictly to 55
            local targetPos = Vector3.new(
                flamePos.X - (flatLook.X * BEHIND_DISTANCE),
                TARGET_Y_HEIGHT,
                flamePos.Z - (flatLook.Z * BEHIND_DISTANCE)
            )

            -- Face toward B - FLAMES at the same height plane
            hrp.CFrame = CFrame.lookAt(targetPos, Vector3.new(flamePos.X, TARGET_Y_HEIGHT, flamePos.Z))
        end
    end)
end

local function stopFollowing()
    if followConnection then
        followConnection:Disconnect()
        followConnection = nil
    end

    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")

    if OriginalCFrame and hrp and hrp.Parent then
        hrp.CFrame = OriginalCFrame
        OriginalCFrame = nil
    end
end

HalloweenTab:Dropdown({
    Title = "Monsters",
    Default = "Select",
    Options = {"Big Silly", "Kabocha", "Skintist"},
    Callback = function(option)
        SelectedMonster = option
    end
})

HalloweenTab:Toggle({
    Title = "Front Monster",
    Default = false,
    Callback = function(state)
        BehindToggle = state

        if BehindToggle then
            local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then
                OriginalCFrame = hrp.CFrame
            end
            
            startFollowing()
        else
            stopFollowing()
        end
    end
})
