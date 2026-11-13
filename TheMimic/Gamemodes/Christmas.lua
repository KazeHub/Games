local KazeUI = KazeUI or loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/KazeHub/UI/refs/heads/main/libraryUI.txt"
))()

local Window = KazeUI:CreateWindow({
    Title = "THE MIMIC",
    Author = "KAZE",
    Version = "CHRISTMAS",
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

local Christmas=Window:CreateTab({
    Title="Christmas",
    Icon="tree"
})

local ChristmasESPEnabled=false
local ChristmasESPSelections={}
local ChristmasESPObjects={}
local ChristmasESPConnections={}

local function ClearChristmasESP()
    for _,obj in ipairs(ChristmasESPObjects) do
        if obj then
            pcall(function()
                obj:Destroy()
            end)
        end
    end

    for _,conn in ipairs(ChristmasESPConnections) do
        if conn then
            pcall(function()
                conn:Disconnect()
            end)
        end
    end

    ChristmasESPObjects={}
    ChristmasESPConnections={}
end

local function ChristmasESPPart(obj)
    if not obj then return nil end

    if obj:IsA("BasePart") then
        return obj
    end

    if obj:IsA("Model") then
        return obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart",true)
    end

    return obj:FindFirstChildWhichIsA("BasePart",true)
end

local function CreateChristmasESP(obj)
    if not obj or not obj.Parent then return end

    local part=ChristmasESPPart(obj)
    if not part then return end

    local highlight=Instance.new("Highlight")
    highlight.Name="ChristmasESP"
    highlight.FillColor=Color3.fromRGB(0,255,0)
    highlight.OutlineColor=Color3.fromRGB(255,255,255)
    highlight.FillTransparency=0.5
    highlight.OutlineTransparency=0
    highlight.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Adornee=obj
    highlight.Parent=obj

    table.insert(ChristmasESPObjects,highlight)

    local billboard=Instance.new("BillboardGui")
    billboard.Name="ChristmasESPName"
    billboard.Size=UDim2.new(0,150,0,35)
    billboard.StudsOffset=Vector3.new(0,2,0)
    billboard.AlwaysOnTop=true
    billboard.Parent=part

    table.insert(ChristmasESPObjects,billboard)

    local text=Instance.new("TextLabel")
    text.BackgroundTransparency=1
    text.Size=UDim2.new(1,0,1,0)
    text.TextStrokeTransparency=0
    text.TextStrokeColor3=Color3.fromRGB(0,0,0)
    text.TextColor3=Color3.fromRGB(0,255,0)
    text.TextSize=13
    text.Font=Enum.Font.SourceSansBold
    text.Text=obj.Name
    text.Parent=billboard

    local lastUpdate=0

    local conn=RunService.Heartbeat:Connect(function()
        if tick()-lastUpdate<0.4 then return end
        lastUpdate=tick()

        if not ChristmasESPEnabled or not obj.Parent then
            pcall(function()
                highlight:Destroy()
                billboard:Destroy()
            end)
            return
        end

        local character=LocalPlayer.Character
        local hrp=character and character:FindFirstChild("HumanoidRootPart")

        if hrp then
            local targetPosition=ChristmasGetPart(obj)

            if targetPosition then
                local distance=(hrp.Position-targetPosition.Position).Magnitude
                text.Text=obj.Name.."\n["..math.floor(distance).."]"
            end
        end
    end)

    table.insert(ChristmasESPConnections,conn)
end

local function SetupChristmasESPFolder(folder)
    if not folder then return end

    for _,obj in ipairs(folder:GetChildren()) do
        CreateChristmasESP(obj)
    end

    local conn=folder.ChildAdded:Connect(function(obj)
        if ChristmasESPEnabled then
            task.wait(0.1)

            if obj.Parent then
                CreateChristmasESP(obj)
            end
        end
    end)

    table.insert(ChristmasESPConnections,conn)
end

local function SetupChristmasESP()
    ClearChristmasESP()

    if not ChristmasESPEnabled then
        return
    end

    if ChristmasESPSelections["Items"] then
        local quests=Workspace:FindFirstChild("Quests")
        local quest1=quests and quests:FindFirstChild("1")
        local items=quest1 and quest1:FindFirstChild("Items")

        if items then
            SetupChristmasESPFolder(items)
        end
    end

    if ChristmasESPSelections["Toys"] then
        local quests=Workspace:FindFirstChild("Quests")
        local quest2=quests and quests:FindFirstChild("2")
        local toys=quest2 and quest2:FindFirstChild("CollectToys")

        if toys then
            SetupChristmasESPFolder(toys)
        end
    end

    if ChristmasESPSelections["Monster"] then
        local gameAI=Workspace:FindFirstChild("GameAI")

        if gameAI then
            SetupChristmasESPFolder(gameAI)
        end
    end
end

Christmas:Dropdown({
    Title="ESP",
    Values={
        "Items",
        "Toys",
        "Monster"
    },
    Multi=true,
    Default={},
    Callback=function(values)
        ChristmasESPSelections={}

        if type(values)=="table" then
            for _,value in ipairs(values) do
                ChristmasESPSelections[value]=true
            end
        end

        if ChristmasESPEnabled then
            SetupChristmasESP()
        end
    end
})

Christmas:Toggle({
    Title="Enable ESP",
    Default=false,
    Callback=function(state)
        ChristmasESPEnabled=state
        SetupChristmasESP()
    end
})

local ChristmasSafeCFrame=CFrame.new(-240,10,-200)

local function ChristmasGetHRP()
    local character=LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    return character and character:FindFirstChild("HumanoidRootPart")
end

local function ChristmasGetPart(obj)
    if not obj then return nil end
    if obj:IsA("BasePart") then return obj end
    if obj:IsA("Model") then
        return obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart",true)
    end
    return obj:FindFirstChildWhichIsA("BasePart",true)
end

local function ChristmasGetPrompt(obj)
    if not obj then return nil end
    if obj:IsA("ProximityPrompt") then return obj
    end
    return obj:FindFirstChildWhichIsA("ProximityPrompt",true)
end

local function ChristmasFirePrompt(obj)
    local prompt=ChristmasGetPrompt(obj)
    if not prompt then return false end

    pcall(function()
        prompt.Enabled=true
        fireproximityprompt(prompt)
    end)

    return true
end

local function ChristmasTeleportTo(obj)
    local hrp=ChristmasGetHRP()
    local part=ChristmasGetPart(obj)

    if hrp and part then
        hrp.CFrame=part.CFrame+Vector3.new(0,3,0)
        return true
    end

    return false
end

local function ChristmasSafeZone()
    local hrp=ChristmasGetHRP()
    if hrp then
        hrp.CFrame=ChristmasSafeCFrame
    end
end

Christmas:Button({
    Title="Safe Zone",
    Callback=function()
        ChristmasSafeZone()
    end
})

Christmas:Button({
    Title="Talk",
    Callback=function()
        task.spawn(function()
            local elf=Workspace:FindFirstChild("NPCs")
            elf=elf and elf:FindFirstChild("Elf")
            elf=elf and elf:FindFirstChild("Elf")

            if elf then
                if ChristmasTeleportTo(elf) then
                    task.wait(0.2)
                    ChristmasFirePrompt(elf)
                    task.wait(0.1)
                end
            end

            ChristmasSafeZone()
        end)
    end
})

Christmas:Section("Stage I")

Christmas:Button({
    Title="Auto Win",
    Callback=function()
        task.spawn(function()
            local quests=Workspace:FindFirstChild("Quests")
            local quest=quests and quests:FindFirstChild("1")
            local items=quest and quest:FindFirstChild("Items")

            if not items then return end

            local itemNames={
                "Controls",
                "Extinguisher",
                "Ropes",
                "RepairPoint"
            }

            for _,name in ipairs(itemNames) do
                local item=items:FindFirstChild(name)

                if item then
                    if ChristmasTeleportTo(item) then
                        task.wait(0.2)
                        ChristmasFirePrompt(item)
                        task.wait(0.1)
                    end
                end
            end

            ChristmasSafeZone()
        end)
    end
})

Christmas:Section("Stage II")

Christmas:Button({
    Title="Auto Win",
    Callback=function()
        task.spawn(function()
            local quests=Workspace:FindFirstChild("Quests")
            local quest=quests and quests:FindFirstChild("2")
            local collectToys=quest and quest:FindFirstChild("CollectToys")

            if not collectToys then return end

            for _,toy in ipairs(collectToys:GetChildren()) do
                if not toy or not toy.Parent then
                    continue
                end

                local part=ChristmasGetPart(toy)
                local prompt=ChristmasGetPrompt(toy)

                if part and prompt then
                    local hrp=ChristmasGetHRP()

                    if not hrp then
                        return
                    end

                    hrp.CFrame=part.CFrame+Vector3.new(0,3,0)
                    task.wait(0.2)

                    if toy.Parent then
                        ChristmasFirePrompt(toy)
                    end

                    while toy.Parent do
                        task.wait(0.1)

                        if toy.Parent then
                            ChristmasFirePrompt(toy)
                        else
                            break
                        end
                    end
                end
            end

            ChristmasSafeZone()
        end)
    end
})

Christmas:Section("Stage III")

Christmas:Button({
    Title="Get Key",
    Callback=function()
        task.spawn(function()
            local gameAI=Workspace:FindFirstChild("GameAI")

            if not gameAI then
                return
            end

            local keyModel

            for _,obj in ipairs(gameAI:GetChildren()) do
                if obj:IsA("Model") then
                    keyModel=obj
                    break
                end
            end

            if not keyModel then
                return
            end

            local targetPart=ChristmasGetPart(keyModel)
            local prompt=ChristmasGetPrompt(keyModel)

            if not targetPart or not prompt then
                return
            end

            local hrp=ChristmasGetHRP()

            if not hrp then
                return
            end

            local targetPosition=targetPart.Position
            local direction=hrp.Position-targetPosition

            if direction.Magnitude<0.1 then
                direction=Vector3.new(0,0,1)
            end

            direction=direction.Unit

            local behindPosition=targetPosition+(direction*15)

            behindPosition=Vector3.new(
                behindPosition.X,
                hrp.Position.Y,
                behindPosition.Z
            )

            hrp.CFrame=CFrame.lookAt(
                behindPosition,
                Vector3.new(
                    targetPosition.X,
                    behindPosition.Y,
                    targetPosition.Z
                )
            )

            task.wait(0.2)
            ChristmasFirePrompt(keyModel)
            task.wait(0.1)

            ChristmasSafeZone()
        end)
    end
})
