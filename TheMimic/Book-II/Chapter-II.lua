local KazeUI = KazeUI or loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/KazeHub/UI/refs/heads/main/libraryUI.txt"
))()

local Window = KazeUI:CreateWindow({
    Title = "THE MIMIC",
    Author = "KAZE",
    Version = "BOOK II",
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

local Workspace = clonenav or (cloneref and cloneref(game:GetService("Workspace"))) or game:GetService("Workspace")

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


local Lighting = clonenav or (cloneref and cloneref(game:GetService("Lighting"))) or game:GetService("Lighting")

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

local RunService = clonenav or (cloneref and cloneref(game:GetService("RunService"))) or game:GetService("RunService")
local Players = clonenav or (cloneref and cloneref(game:GetService("Players"))) or game:GetService("Players")
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
local tpWalkConnection = nil

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
                    hrp.CFrame = hrp.CFrame + (humanoid.MoveDirection * (TPWalkSpeed * 0.05))
                end
            end)
        end
    end
})

-- ==========================================
-- 1. FIXED FLY SCRIPT (NO FALLING ON STOP)
-- ==========================================
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
                        -- Kapag gumagalaw: Unanchor at galawin ang CFrame
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
                        -- Kapag huminto: I-anchor ang HRP para hindi bumaba/mahulog
                        hrp.AssemblyLinearVelocity = Vector3.zero
                        hrp.AssemblyAngularVelocity = Vector3.zero
                        hrp.Anchored = true
                    end
                end
            end)
        end
    end
})

-- Services
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local StarterGui = game:GetService("StarterGui")
local Terrain = Workspace:FindFirstChildOfClass("Terrain")

local LocalPlayer = Players.LocalPlayer

-- State Variables
local isAutoPromptToggled = false
local isEspToggled = false

local yenEspHolders = {}
local yenEspConnection = nil
local autoPromptTask = nil

local PROXIMITY_RANGE = 15

-- UI Initialization (Assumes 'Window' is defined globally in your script loader)
local GameTab = Window:CreateTab({
    Title = "Game",
    Icon = "gamepad-2"
})

local autoPressE = false

GameTab:Toggle({
    Title = "Auto free yourself",
    Default = false,
    Callback = function(state)
        autoPressE = state
        if not state then return end

        task.spawn(function()
            local VirtualInputManager = game:GetService("VirtualInputManager")
            local PlayerGui = game:GetService("Players").LocalPlayer.PlayerGui

            while autoPressE do
                local grabbedUI = PlayerGui:FindFirstChild("BossFight") and PlayerGui.BossFight:FindFirstChild("GrabbedUI")
                if grabbedUI and grabbedUI.Visible then
                    pcall(function()
                        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
                        task.wait(0.01)
                        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
                    end)
                end
                task.wait()
            end
        end)
    end
})

-- Helper Functions
local function getCharacterRoot()
	if CachedHRP and CachedHRP.Parent then return CachedHRP end
	local char = LocalPlayer.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	CachedHRP = hrp
	return hrp
end

local function getYenFolder()
	local mimicFolder = Workspace:FindFirstChild("MimicCurrencySpawns")
	return mimicFolder and mimicFolder:FindFirstChild("Yen")
end

-- Auto Collect Loop
local function startAutoPrompt()
	if autoPromptTask then return end

	autoPromptTask = task.spawn(function()
		while isAutoPromptToggled do
			local rootPart = getCharacterRoot()
			local yenFolder = getYenFolder()
			
			if rootPart and yenFolder then
				for _, item in ipairs(yenFolder:GetChildren()) do
					if not isAutoPromptToggled then break end
					
					local targetPart = nil
					if item:IsA("BasePart") then
						targetPart = item
					elseif item:IsA("Model") then
						targetPart = item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart", true)
					end

					if targetPart then
						local distance = (targetPart.Position - rootPart.Position).Magnitude
						if distance <= PROXIMITY_RANGE then
							local prompt = item:FindFirstChildOfClass("ProximityPrompt") or item:FindFirstChild("ProximityPrompt", true)
							if prompt then
								pcall(function()
									prompt.HoldDuration = 0
									fireproximityprompt(prompt, 0)
								end)
							end
						end
					end
				end
			end
			
			task.wait(0.05)
		end
		autoPromptTask = nil
	end)
end

local function stopAutoPrompt()
	isAutoPromptToggled = false
	if autoPromptTask then
		pcall(function() task.cancel(autoPromptTask) end)
		autoPromptTask = nil
	end
end

-- ESP Functions
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

	local targetPart = nil
	if item:IsA("BasePart") then
		targetPart = item
	elseif item:IsA("Model") then
		targetPart = item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart", true)
	else
		targetPart = item:FindFirstChildWhichIsA("BasePart", true)
	end

	if not targetPart then return end

	pcall(function()
		local highlight = Instance.new("Highlight")
		highlight.Name = "YenHighlight"
		highlight.Adornee = item
		highlight.FillColor = Color3.fromRGB(255, 215, 0)
		highlight.OutlineColor = Color3.fromRGB(0, 0, 0)
		highlight.FillTransparency = 0.4
		highlight.OutlineTransparency = 0
		highlight.Parent = item

		local billboard = Instance.new("BillboardGui")
		billboard.Name = "YenTextBillboard"
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

		yenEspHolders[item] = {
			Highlight = highlight,
			Billboard = billboard,
			TextLabel = textLabel,
			Part = targetPart
		}
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

local function startYenEsp()
	clearYenEsp()

	local yenFolder = getYenFolder()
	if yenFolder then
		for _, item in ipairs(yenFolder:GetChildren()) do
			if isEspToggled then
				addYenEspToItem(item)
			end
		end

		yenFolder.ChildAdded:Connect(function(item)
			if isEspToggled then
				task.wait(0.05)
				addYenEspToItem(item)
			end
		end)

		yenFolder.ChildRemoved:Connect(function(item)
			removeYenEspFromItem(item)
		end)
	end

	local yenLastUpdate = 0
	yenEspConnection = RunService.Heartbeat:Connect(function()
		if not isEspToggled then return end
		local now = tick()
		if now - yenLastUpdate < 0.2 then return end
		yenLastUpdate = now
		local rootPart = getCharacterRoot()
		for item, data in pairs(yenEspHolders) do
			if item and item.Parent and data.Part and data.Part.Parent and data.TextLabel then
				if rootPart then
					local distance = math.floor((data.Part.Position - rootPart.Position).Magnitude)
					data.TextLabel.Text = string.format("Yen [%sm]", distance)
				else
					data.TextLabel.Text = "Yen"
				end
			else
				removeYenEspFromItem(item)
			end
		end
	end)
end

-- UI Controls
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
            StarterGui:SetCore("SendNotification", {
                Title = "Performance Booster",
                Text = "Low GFX Applied Successfully!",
                Duration = 3
            })
        end)
    end
})

GameTab:Toggle({
    Title = "Yen Collect",
    Default = false,
    Callback = function(state)
        isAutoPromptToggled = state
        if state then
            startAutoPrompt()
        else
            stopAutoPrompt()
        end
    end
})

GameTab:Toggle({
    Title = "ESP Yen",
    Default = false,
    Callback = function(state)
        isEspToggled = state
        if state then
            startYenEsp()
        else
            clearYenEsp()
        end
    end
})

GameTab:Button({
    Title = "Collect Yen",
    Callback = function()
        if not isEspToggled then return end

        local rootPart = getCharacterRoot()
        if not rootPart then return end

        local originalCFrame = rootPart.CFrame
        local collecting = true
        local collected = {}

        task.spawn(function()
            while collecting do
                local foundCoin = false

                for item, data in pairs(yenEspHolders) do
                    if not isEspToggled then
                        collecting = false
                        break
                    end

                    if item and item.Parent and data and data.Part and data.Part.Parent and not collected[item] then
                        foundCoin = true
                        collected[item] = true

                        rootPart = getCharacterRoot()
                        if not rootPart then
                            collecting = false
                            break
                        end

                        rootPart.CFrame = data.Part.CFrame + Vector3.new(0, 2, 0)
                        task.wait(0.2)

                        local prompt = item:FindFirstChildOfClass("ProximityPrompt")
                            or item:FindFirstChild("ProximityPrompt", true)

                        if prompt then
                            pcall(function()
                                prompt.HoldDuration = 0
                                fireproximityprompt(prompt, 0)
                            end)
                        end

                        task.wait(0.1)
                    end
                end

                if not foundCoin then
                    task.wait(0.25)

                    for item in pairs(yenEspHolders) do
                        if item and item.Parent and not collected[item] then
                            foundCoin = true
                            break
                        end
                    end

                    if not foundCoin then
                        collecting = false
                    end
                end

                task.wait(0.05)
            end

            rootPart = getCharacterRoot()
            if rootPart then
                rootPart.CFrame = originalCFrame
            end
        end)
    end
})

-- ==========================================
-- 2. NEW TAB: OCEAN AUTOMATION
-- ==========================================
local TweenService = clonenav or (cloneref and cloneref(game:GetService("TweenService"))) or game:GetService("TweenService")

local OceanTab = Window:CreateTab({
    Title = "Ocean Stage",
    Icon = "bubbles"
})

local CHECKPOINT_CFRAME = CFrame.new(259.5, 57.1138611, -66.891983, 1, -0, 0, 0, 0.999976754, 0.00681940094, -0, -0.00681940094, 0.999976754)
local WIN_CFRAME = CFrame.new(-539.382019, 84.8812408, -88.504715, 1, 0, 0, 0, 1, 0, 0, 0, 1)

-- Espesyal na function para hanapin ang Hitbox_Entrance at i-fire ang touch interest nito
local function fireEntranceTouch(hrp)
    if not hrp then return end
    
    -- Hinahanap ang Hitbox_Entrance o anumang part na may TouchInterest sa buong workspace
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj.Name == "Hitbox_Entrance" and obj:IsA("BasePart") then
            pcall(function()
                -- Sunod-sunod na fires para masigurong marehistro ng server ang pagdapo
                firetouchinterest(hrp, obj, 0)
                task.wait(0.05)
                firetouchinterest(hrp, obj, 1)
            end)
        end
    end
end

-- Button 1: Auto Win [Normal]
OceanTab:Button({
    Title = "Auto Win [Normal]",
    Callback = function()
        task.spawn(function()
            local character = LocalPlayer.Character
            if not character then return end
            
            local hrp = character:FindFirstChild("HumanoidRootPart")
            
            if flyConnection then
                flyConnection:Disconnect()
                flyConnection = nil
            end
            
            for _, part in ipairs(CachedNoclipParts or {}) do
                if v:IsA("BasePart") then
                    v.CanCollide = false
                end
            end
            
            if hrp then
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
            end
            
            -- Step 1: Teleport sa Checkpoint (Y: 57.11)
            character:PivotTo(CHECKPOINT_CFRAME)
            
            if hrp then
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
                fireEntranceTouch(hrp) -- I-fire ang Hitbox_Entrance touch
            end
            
            task.wait(0.5)
            
            -- Step 2: Teleport sa Win Location
            character = LocalPlayer.Character or game:GetService("Players").LocalPlayer.Character
            if character then
                character:PivotTo(WIN_CFRAME)
            end
            
            hrp = character and character:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
            end
        end)
    end
})

-- Button 2: Auto Win [Nightmare]
OceanTab:Button({
    Title = "Auto Win [Nightmare]",
    Callback = function()
        task.spawn(function()
            local character = LocalPlayer.Character
            if not character then return end
            
            local hrp = character:FindFirstChild("HumanoidRootPart")
            
            if flyConnection then
                flyConnection:Disconnect()
                flyConnection = nil
            end
            
            for _, part in ipairs(CachedNoclipParts or {}) do
                if v:IsA("BasePart") then
                    v.CanCollide = false
                end
            end
            
            if hrp then
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
            end
            
            -- Step 1: Teleport sa Checkpoint at i-fire ang Hitbox_Entrance
            character:PivotTo(CHECKPOINT_CFRAME)
            
            if hrp then
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
                fireEntranceTouch(hrp)
                hrp.Anchored = true -- Stuck/Anchor player
            end
            
            Window:Notify({
                Title = "Bypass Anti-Cheat",
                Content = "Wait 30 Seconds",
                Duration = 30
            })
            
            task.wait(30)
            
            -- Step 2: Unanchor at Teleport sa Win Location
            character = LocalPlayer.Character or game:GetService("Players").LocalPlayer.Character
            hrp = character and character:FindFirstChild("HumanoidRootPart")
            
            if hrp then
                hrp.Anchored = false
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
            end
            
            if character then
                character:PivotTo(WIN_CFRAME)
            end
            
            hrp = character and character:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
            end
        end)
    end
})

--------------------------------------------------
-- EAT RAT STAGE
--------------------------------------------------
local EatRatStage = Window:CreateTab({
    Title = "Eat Rat Stage",
    Icon = "rat"
})

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local player = Players.LocalPlayer

local function getChar()
    if not player then return nil end
    return player.Character or player.CharacterAdded:Wait()
end

local function getHRP()
    local char = getChar()
    if not char then return nil end
    return char:WaitForChild("HumanoidRootPart",5)
end

local function setNoclip(state)
    local char = getChar()
    if char then
        for _, part in ipairs(CachedNoclipParts or {}) do
            if part:IsA("BasePart") then
                part.CanCollide = not state
            end
        end
    end
end

local function resetOrientation()
    local char = getChar()
    if char then
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
    end
end

local function firePrompt(prompt)
    if not prompt or not prompt:IsA("ProximityPrompt") then
        return false
    end

    if not prompt.Enabled then
        return false
    end

    local oldDuration = prompt.HoldDuration
    prompt.HoldDuration = 0

    task.wait(0.05)

    if fireproximityprompt then
        fireproximityprompt(prompt)
    else
        prompt:InputHoldBegin()
        task.wait(0.05)
        prompt:InputHoldEnd()
    end

    task.wait(0.1)
    prompt.HoldDuration = oldDuration

    return true
end

local function findModel(name)
    for _,obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj.Name == name then
            return obj
        end
    end
end

local function getModelPart(obj)
    if not obj then return nil end

    if obj:IsA("BasePart") then
        return obj
    end

    if obj:IsA("Model") then
        if obj.PrimaryPart then
            return obj.PrimaryPart
        end

        return obj:FindFirstChildWhichIsA("BasePart",true)
    end

    return nil
end

local function fireNearestPrompt(model)
    if not model then return false end

    local part = getModelPart(model)
    if not part then return false end

    local nearestPrompt
    local nearestDistance = math.huge

    for _,obj in ipairs(model:GetDescendants()) do
        if obj:IsA("ProximityPrompt") and obj.Enabled then
            local parent = obj.Parent

            if parent and parent:IsA("BasePart") then
                local distance =
                    (parent.Position - part.Position).Magnitude

                if distance < nearestDistance then
                    nearestDistance = distance
                    nearestPrompt = obj
                end
            end
        end
    end

    if nearestPrompt then
        return firePrompt(nearestPrompt)
    end

    return false
end

local function tweenTo(hrp,position,duration)
    local tween = TweenService:Create(
        hrp,
        TweenInfo.new(
            duration,
            Enum.EasingStyle.Linear,
            Enum.EasingDirection.Out
        ),
        {
            CFrame = CFrame.new(position)
        }
    )

    tween:Play()
    tween.Completed:Wait()
end

--------------------------------------------------
-- NORMAL
--------------------------------------------------
EatRatStage:Button({
    Title = "Auto Escape [Normal]",

    Callback = function()
        local hrp = getHRP()
        if not hrp then return end

        setNoclip(true)

        hrp.CFrame =
            CFrame.new(-3955.11,594.22,317.36)

        task.wait(0.2)

        setNoclip(false)
        resetOrientation()

        local door = findModel("TeleportDoor")

        if door then
            fireNearestPrompt(door)
        end
    end
})

--------------------------------------------------
-- NIGHTMARE
--------------------------------------------------
EatRatStage:Button({
    Title = "Auto Escape [Nightmare]",

    Callback = function()
        local hrp = getHRP()
        if not hrp then return end

        --------------------------------------------------
        -- START
        --------------------------------------------------
        setNoclip(true)

        hrp.CFrame =
            CFrame.new(-3381.44,575.79,886.38)

        task.wait(0.2)

        --------------------------------------------------
        -- FIRST SMOOTH MOVE
        --------------------------------------------------
        tweenTo(
            hrp,
            Vector3.new(
                -3576.40,
                602.74,
                888.10
            ),
            0.5
        )

        --------------------------------------------------
        -- PROX DOOR A
        --------------------------------------------------
        setNoclip(false)
        resetOrientation()

        local doorA = findModel("ProxDoorA")

        if doorA then
            fireNearestPrompt(doorA)
        end

        task.wait(0.5)

        --------------------------------------------------
        -- SECOND SMOOTH MOVE
        --------------------------------------------------
        setNoclip(true)

        tweenTo(
            hrp,
            Vector3.new(
                -3601.271240234375,
                608.8807373046875,
                766.185546875
            ),
            0.5
        )

        --------------------------------------------------
        -- PROX DOOR B
        --------------------------------------------------
        setNoclip(false)
        resetOrientation()

        local doorB = findModel("ProxDoorB")

        if doorB then
            fireNearestPrompt(doorB)
        end

        --------------------------------------------------
        -- WAIT POSITION
        --------------------------------------------------
        setNoclip(true)

        hrp.CFrame =
            CFrame.new(
                -3956.21,
                594.22,
                331.77
            )

        --------------------------------------------------
        -- ANTI CHEAT WAIT
        --------------------------------------------------
        Window:Notify({
            Title = "Anti Cheat",
            Content = "Bypassing Anti Cheat Wait 50 Seconds!",
            Duration = 50
        })

        task.wait(50)

        --------------------------------------------------
        -- FINAL POSITION
        -- ANCHOR PLAYER HERE
        --------------------------------------------------
        setNoclip(true)

        hrp.CFrame =
            CFrame.new(
                -3955.11,
                594.22,
                317.36
            )

        hrp.Anchored = true

        task.wait(0.2)

        --------------------------------------------------
        -- FINAL DOOR
        --------------------------------------------------
        setNoclip(false)
        resetOrientation()

        local finalDoor = findModel("TeleportDoor")

        if finalDoor then
            fireNearestPrompt(finalDoor)
        end
    end
})
--------------------------------------------------
-- MEAT STAGE
--------------------------------------------------
local MeatStage = Window:CreateTab({Title = "Meat Stage", Icon = "drumstick"})

MeatStage:Button({
    Title = "Talk",
    Callback = function()
        local hrp = getHRP()
        if not hrp then return end
        setNoclip(true)
        hrp.CFrame = CFrame.new(-4445.06, 711.37, 1164.52)
        task.wait(0.2)
        setNoclip(false)
        resetOrientation()
        local npc = findModel("NoppeNPC")
        if npc then fireNearestPrompt(npc) end
    end
})

--------------------------------------------------
-- MEAT ROOM
--------------------------------------------------

local selectedRestaurant = nil

local function getRestaurants()
    local restaurants = {}

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj.Name == "RestaurantRoom" then
            table.insert(restaurants, obj)
        end
    end

    return restaurants
end

MeatStage:Dropdown({
    Title = "Meat Room",
    Default = "Select",
    Options = {
        "Restaurant I",
        "Restaurant II",
        "Restaurant III"
    },

    Callback = function(value)
        selectedRestaurant = value
    end
})

--------------------------------------------------
-- TELEPORT
--------------------------------------------------

MeatStage:Button({
    Title = "Teleport",
    Callback = function()
        if not selectedRestaurant then
            Window:Notify({
                Title = "Meat Room",
                Content = "Please select a Restaurant first!",
                Duration = 3
            })
            return
        end

        local restaurants = getRestaurants()

        local roman = {
            [1]="I",[2]="II",[3]="III",[4]="IV",[5]="V",
            [6]="VI",[7]="VII",[8]="VIII",[9]="IX",[10]="X",
            [11]="XI",[12]="XII",[13]="XIII",[14]="XIV",[15]="XV",
            [16]="XVI",[17]="XVII",[18]="XVIII",[19]="XIX",[20]="XX"
        }

        local index

        for i = 1,#restaurants do
            local name = "Restaurant "..(roman[i] or tostring(i))

            if selectedRestaurant == name then
                index = i
                break
            end
        end

        if not index then
            Window:Notify({
                Title = "Meat Room",
                Content = selectedRestaurant.." was not found!",
                Duration = 3
            })
            return
        end

        local restaurant = restaurants[index]

        if not restaurant then
            Window:Notify({
                Title = "Meat Room",
                Content = selectedRestaurant.." was not found!",
                Duration = 3
            })
            return
        end

        local bowl = restaurant:FindFirstChild("BowlGiver",true)

        if not bowl then
            Window:Notify({
                Title = "Meat Room",
                Content = "BowlGiver not found in "..selectedRestaurant.."!",
                Duration = 3
            })
            return
        end

        local bowlPart = getModelPart(bowl)
        if not bowlPart then return end

        local hrp = getHRP()
        if not hrp then return end

        hrp.Anchored = false
        hrp.CFrame = bowlPart.CFrame + Vector3.new(0,4,0)
    end
})

--------------------------------------------------
-- SUBMIT MEAT
--------------------------------------------------

MeatStage:Button({
    Title = "Submit Meat",

    Callback = function()
        local hrp = getHRP()
        if not hrp then return end

        -- First position
        hrp.Anchored = false
        hrp.CFrame = CFrame.new(
            -4434.61,
            711.37,
            1158.05
        )

        task.wait(0.016)

        -- Anchor to prevent sliding
        hrp.Anchored = true

        Window:Notify({
            Title = "Anti Cheat",
            Content = "Waiting 10 Seconds...",
            Duration = 10
        })

        task.wait(10)

        -- Second position
        hrp.Anchored = false
        hrp.CFrame = CFrame.new(
            -4445.06,
            711.37,
            1164.52
        )

        task.wait(0.2)

        -- Fire NoppeNPC prompt
        local npc = findModel("NoppeNPC")

        if npc then
            fireNearestPrompt(npc)
        end
    end
})

MeatStage:Button({
    Title = "Safe Zone",
    Callback = function()
        local hrp = getHRP()
        if not hrp then return end

        hrp.Anchored = false
        hrp.CFrame = CFrame.new(
            -4495.77,
            640.93,
            1173.78
        )
    end
})

MeatStage:Button({
    Title = "Exit",
    Callback = function()
        local hrp = getHRP()
        if not hrp then return end

        local endRoom = findModel("EndRoom")
        if not endRoom then return end

        local door = endRoom:FindFirstChild("DoorTele", true)
        local doorPart = getModelPart(door)

        if door and doorPart then
            -- Teleport to Exit Door
            hrp.Anchored = false
            hrp.CFrame = doorPart.CFrame + Vector3.new(0, 3, 0)
            task.wait(0.2)

            -- Fire Proximity Prompt safely
            local prompt = door:FindFirstChildWhichIsA("ProximityPrompt", true)
            if prompt and prompt.Enabled then
                if fireproximityprompt then
                    fireproximityprompt(prompt)
                else
                    local oldDuration = prompt.HoldDuration
                    prompt.HoldDuration = 0
                    prompt:InputHoldBegin()
                    task.wait(0.05)
                    prompt:InputHoldEnd()
                    prompt.HoldDuration = oldDuration
                end
            end
        end
    end
})


--------------------------------------------------
-- ESP
--------------------------------------------------

MeatStage:Section("ESP")

local espAshina = false

local function updateAshinaESP()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj.Name == "Ashina" then

            local highlight = obj:FindFirstChild("AshinaESP")

            if espAshina then
                if not highlight then
                    highlight = Instance.new("Highlight")
                    highlight.Name = "AshinaESP"
                    highlight.Adornee = obj
                    highlight.Parent = obj

                    highlight.FillTransparency = 0.5
                    highlight.OutlineTransparency = 0
                end
            else
                if highlight then
                    highlight:Destroy()
                end
            end
        end
    end
end

MeatStage:Toggle({
    Title = "ESP Ashina",

    Callback = function(value)
        espAshina = value
        updateAshinaESP()
    end
})


--------------------------------------------------
-- CHASE STAGE
--------------------------------------------------

local ChaseStage = Window:CreateTab({
    Title = "Chase Stage",
    Icon = "skull"
})

local function fireTouchInterestAtPosition(position)
    local character = player.Character or player.CharacterAdded:Wait()
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            if (obj.Position - position).Magnitude <= 8 then
                firetouchinterest(hrp, obj, 0)
                task.wait(0.05)
                firetouchinterest(hrp, obj, 1)
                return
            end
        end
    end
end

ChaseStage:Button({
    Title = "Start",
    Callback = function()
        local hrp = getHRP()
        if not hrp then return end

        local position = Vector3.new(
            -4597.00879,
            835.562195,
            -37.2170372
        )

        hrp.Anchored = false
        hrp.CFrame = CFrame.new(position)

        task.wait(0.1)

        fireTouchInterestAtPosition(position)
    end
})

ChaseStage:Button({
    Title = "Auto Win",
    Callback = function()
        local hrp = getHRP()
        if not hrp then return end

        hrp.Anchored = false
        hrp.CFrame = CFrame.new(
            -5370.41455,
            688.742432,
            30.0315113
        )
    end
})

--------------------------------------------------
-- LEVERS
--------------------------------------------------

local LeversStage = Window:CreateTab({
    Title = "Levers",
    Icon = "toggle-left"
})

--------------------------------------------------
-- ENTER GATE
--------------------------------------------------

LeversStage:Button({
    Title = "Enter Door",

    Callback = function()
        local hrp = getHRP()
        if not hrp then return end

        local position = Vector3.new(
            -11033.720703125,
            -72.3996810913086,
            -12.63049602508545
        )

        hrp.Anchored = false
        hrp.CFrame = CFrame.new(position)

        task.wait(0.1)

        -- Fire TouchInterest
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") then
                if (obj.Position - position).Magnitude <= 8 then
                    firetouchinterest(hrp, obj, 0)
                    task.wait(0.05)
                    firetouchinterest(hrp, obj, 1)
                    break
                end
            end
        end
    end
})

--------------------------------------------------
-- AUTO LEVERS
--------------------------------------------------

LeversStage:Button({
    Title = "Auto Levers",

    Callback = function()
        local hrp = getHRP()
        if not hrp then return end

        -- Find the folder named "Levers" anywhere in Workspace
        local leversFolder

        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("Folder") and obj.Name == "Levers" then
                leversFolder = obj
                break
            end
        end

        if not leversFolder then
            Window:Notify({
                Title = "Auto Levers",
                Content = "Levers folder not found!",
                Duration = 3
            })
            return
        end

        -- Find Lever / Levers models inside the folder
        local levers = {}

        for _, obj in ipairs(leversFolder:GetChildren()) do
            if obj:IsA("Model")
                and (obj.Name == "Lever" or obj.Name == "Levers") then

                table.insert(levers, obj)
            end
        end

        -- Teleport and activate each lever
        for _, lever in ipairs(levers) do
            local leverPart = getModelPart(lever)

            if leverPart then
                hrp.Anchored = false

                -- TP to Lever + Y4
                hrp.CFrame =
                    leverPart.CFrame + Vector3.new(0, 4, 0)

                task.wait(0.2)

                -- Find ProximityPrompt
                local prompt =
                    lever:FindFirstChildWhichIsA(
                        "ProximityPrompt",
                        true
                    )

                if prompt and prompt.Enabled then
                    firePrompt(prompt)
                end

                -- Wait before next lever
                task.wait(0.016)
            end
        end
    end
})

LeversStage:Button({
    Title = "Exit",

    Callback = function()
        local hrp = getHRP()
        if not hrp then return end

        local position = Vector3.new(
            -10057.646484375,
            490.6839294433594,
            -8.682564735412598
        )

        hrp.Anchored = false
        hrp.CFrame = CFrame.new(position)

        task.wait(0.1)

        -- Fire TouchInterest
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") then
                if (obj.Position - position).Magnitude <= 8 then
                    firetouchinterest(hrp, obj, 0)
                    task.wait(0.05)
                    firetouchinterest(hrp, obj, 1)
                    break
                end
            end
        end
    end
})

LeversStage:Section("Math Stage")

LeversStage:Button({
    Title = "Skip Math",
    Callback = function()
        local hrp = getHRP()
        if not hrp then return end

        hrp.Anchored = false
        hrp.CFrame = CFrame.new(
            -2583.982666015625,
            997.7894897460938,
            -4922.7705078125
        )
    end
})

--------------------------------------------------
-- COOKING STAGE
--------------------------------------------------
local CookingStage = Window:CreateTab({
    Title = "Cooking Stage",
    Icon = "chef-hat"
})


local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local player = Players.LocalPlayer

local function getHRP()
    local char = player.Character or player.CharacterAdded:Wait()
    return char and char:WaitForChild("HumanoidRootPart",5)
end

local function getPart(obj)
    if not obj then return nil end
    if obj:IsA("BasePart") then return obj end
    if obj:IsA("Model") then
        if obj.PrimaryPart then return obj.PrimaryPart end
        return obj:FindFirstChildWhichIsA("BasePart",true)
    end
    return obj:FindFirstChildWhichIsA("BasePart",true)
end

local function findCooking()
    for _,obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Folder") and obj.Name == "Cooking" then
            return obj
        end
    end
end

local function findPrompt(obj)
    if not obj then return nil end
    if obj:IsA("ProximityPrompt") and obj.Enabled then
        return obj
    end
    for _,v in ipairs(obj:GetDescendants()) do
        if v:IsA("ProximityPrompt") and v.Enabled then
            return v
        end
    end
end

local function firePrompt(obj)
    local prompt = obj
    if not prompt or not prompt:IsA("ProximityPrompt") then
        prompt = findPrompt(obj)
    end
    if not prompt or not prompt.Enabled then return false end
    task.wait(0.1)
    if fireproximityprompt then
        fireproximityprompt(prompt)
    else
        prompt:InputHoldBegin()
        task.wait(math.max(prompt.HoldDuration,0.1))
        prompt:InputHoldEnd()
    end
    task.wait(0.2)
    return true
end

--------------------------------------------------
-- GIVERS
--------------------------------------------------
local function findGiver(name)
    local cooking = findCooking()
    if not cooking then return nil end
    local givers = cooking:FindFirstChild("Givers",true)
    if not givers then return nil end
    for _,obj in ipairs(givers:GetDescendants()) do
        if obj.Name:lower() == name:lower() then
            if obj:IsA("Model") or obj:IsA("BasePart") then
                return obj
            end
        end
    end
end

local function useGiver(name)
    local obj = findGiver(name)
    if not obj then
        Window:Notify({
            Title = "Cooking Stage",
            Content = name.." not found!",
            Duration = 3
        })
        return false
    end

    local hrp = getHRP()
    local part = getPart(obj)
    if not hrp or not part then return false end

    hrp.CFrame = part.CFrame + Vector3.new(0,5,0)
    task.wait(0.1)

    local prompt = findPrompt(obj)
    if not prompt then
        task.wait(0.1)
        prompt = findPrompt(obj)
    end

    if not prompt then
        Window:Notify({
            Title = "Cooking Stage",
            Content = "Prompt not found: "..name,
            Duration = 3
        })
        return false
    end

    firePrompt(prompt)
    return true
end

--------------------------------------------------
-- WOODEN COUNTER [24]
--------------------------------------------------
local function getCounter24()
    local cooking = findCooking()
    if not cooking then return nil end
    local counters = cooking:FindFirstChild("WoodenCounters",true)
    if not counters then return nil end
    return counters:GetChildren()[24]
end

local function getCounterPrompt(counter)
    if not counter then return nil,nil end

    local parts = {}

    for _,obj in ipairs(counter:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Name == "Part" then
            table.insert(parts,obj)
        end
    end

    for _,part in ipairs(parts) do
        local prompt = findPrompt(part)
        if prompt then
            return part,prompt
        end
    end

    local prompt = findPrompt(counter)
    if prompt then
        return getPart(counter),prompt
    end

    return nil,nil
end

local function useCounter24()
    local counter = getCounter24()
    if not counter then
        Window:Notify({
            Title = "Cooking Stage",
            Content = "WoodenCounters[24] not found!",
            Duration = 3
        })
        return false
    end

    local hrp = getHRP()
    local counterPart = getPart(counter)
    if not hrp or not counterPart then return false end

    hrp.CFrame = counterPart.CFrame + Vector3.new(0,5,0)
    task.wait(0.1)

    local promptPart,prompt = getCounterPrompt(counter)

    if not prompt then
        task.wait(0.1)
        promptPart,prompt = getCounterPrompt(counter)
    end

    if not prompt then
        Window:Notify({
            Title = "Cooking Stage",
            Content = "Counter prompt not found!",
            Duration = 3
        })
        return false
    end

    if promptPart then
        hrp.CFrame = promptPart.CFrame + Vector3.new(0,5,0)
        task.wait(0.1)
    end

    local finalPrompt = findPrompt(promptPart or counter)
    if finalPrompt then
        firePrompt(finalPrompt)
    else
        firePrompt(prompt)
    end

    return true
end

--------------------------------------------------
-- STOVE [4]
--------------------------------------------------
local function getStove4()
    local cooking = findCooking()
    if not cooking then return nil end

    local stoves = cooking:FindFirstChild("Stoves",true)
    if not stoves then return nil end

    return stoves:GetChildren()[4]
end

local function useStove4()
    local stove = getStove4()

    if not stove then
        Window:Notify({
            Title = "Cooking Stage",
            Content = "Cooking.Stoves[4] not found!",
            Duration = 3
        })
        return false
    end

    local hrp = getHRP()
    local stovePart = getPart(stove)
    if not hrp or not stovePart then return false end

    hrp.CFrame = stovePart.CFrame + Vector3.new(0,5,0)
    task.wait(0.1)

    local prompt = findPrompt(stove)

    if not prompt then
        task.wait(0.1)
        prompt = findPrompt(stove)
    end

    if not prompt then
        Window:Notify({
            Title = "Cooking Stage",
            Content = "Stove[4] prompt not found!",
            Duration = 3
        })
        return false
    end

    firePrompt(prompt)
    return true
end

--------------------------------------------------
-- TURN IN FOOD
--------------------------------------------------
local function useTurnInFood()
    local cooking = findCooking()
    if not cooking then return false end

    local turnIn = cooking:FindFirstChild("TurnInFood",true)
    if not turnIn then
        Window:Notify({
            Title = "Cooking Stage",
            Content = "TurnInFood not found!",
            Duration = 3
        })
        return false
    end

    local hrp = getHRP()
    if not hrp then return false end

    hrp.CFrame = CFrame.new(-2751.37,968.25,-4919.55)
    task.wait(0.1)

    local prompt = findPrompt(turnIn)

    if not prompt then
        task.wait(0.1)
        prompt = findPrompt(turnIn)
    end

    if not prompt then return false end

    firePrompt(prompt)
    return true
end

--------------------------------------------------
-- EYE BALL
--------------------------------------------------
local function cookEyeBall()
    if not useGiver("Bowl") then return false end
    if not useCounter24() then return false end
    if not useGiver("EyeBall") then
        if not useGiver("Eyeball") then return false end
    end
    if not useCounter24() then return false end
    if not useGiver("Spaghetti") then return false end
    if not useCounter24() then return false end
    task.wait(0.2)
    if not useCounter24() then return false end
    return useTurnInFood()
end

--------------------------------------------------
-- HAM SAUSAGE
--------------------------------------------------
local function cookHamSausage()
    if not useGiver("Pot") then return false end
    if not useCounter24() then return false end
    if not useGiver("Ham") then return false end
    if not useCounter24() then return false end
    if not useGiver("Sausage") then return false end
    if not useCounter24() then return false end
    task.wait(0.2)
    if not useCounter24() then return false end
    if not useStove4() then return false end
    task.wait(10)
    if not useGiver("Bowl") then return false end
    if not useCounter24() then return false end
    if not useStove4() then return false end
    if not useCounter24() then return false end
    task.wait(0.2)
    if not useCounter24() then return false end
    return useTurnInFood()
end

--------------------------------------------------
-- CHICKEN
--------------------------------------------------
local function cookChicken()
    if not useGiver("Pot") then return false end
    if not useCounter24() then return false end
    if not useGiver("Chicken") then return false end
    if not useCounter24() then return false end
    if not useGiver("Wrapped Meat") then return false end
    if not useCounter24() then return false end
    if not useGiver("Cheese") then return false end
    if not useCounter24() then return false end
    if not useCounter24() then return false end
    if not useStove4() then return false end
    task.wait(10)
    if not useGiver("Bowl") then return false end
    if not useCounter24() then return false end
    if not useStove4() then return false end
    if not useCounter24() then return false end
    if not useCounter24() then return false end
    return useTurnInFood()
end

--------------------------------------------------
-- AUTO COOK
--------------------------------------------------
local autoCook = false
local cookingBusy = false
local lastRecipe = nil

local function getCookingHolder()
    local playerGui = player:FindFirstChild("PlayerGui")
    if not playerGui then return nil end

    local cookingUI = playerGui:FindFirstChild("CookingUI")
    if not cookingUI then return nil end

    return cookingUI:FindFirstChild("Holder")
end

local function getRecipe()
    local holder = getCookingHolder()
    if not holder then return nil end

    local chicken = holder:FindFirstChild("Chicken Soup")
    if chicken then return "Chicken Soup" end

    local ham = holder:FindFirstChild("Ham Stew")
    if ham then return "Ham Stew" end

    local spaghetti = holder:FindFirstChild("Spaghetti N Eyeballs")
    if spaghetti then return "Spaghetti N Eyeballs" end

    return nil
end

local function cookRecipe(recipe)
    if cookingBusy then return end
    cookingBusy = true

    if recipe == "Chicken Soup" then
        cookChicken()
    elseif recipe == "Ham Stew" then
        cookHamSausage()
    elseif recipe == "Spaghetti N Eyeballs" then
        cookEyeBall()
    end

    task.wait(0.5)
    lastRecipe = nil
    cookingBusy = false
end

CookingStage:Toggle({
    Title = "Auto Cook",
    Description = "Recommend For Solo Only",
    Default = false,
    Callback = function(value)
        autoCook = value

        if not autoCook then
            lastRecipe = nil
            return
        end

        task.spawn(function()
            while autoCook do
                local recipe = getRecipe()

                if recipe and not cookingBusy then
                    if recipe ~= lastRecipe then
                        lastRecipe = recipe
                        cookRecipe(recipe)
                    end
                else
                    if not recipe and not cookingBusy then
                        lastRecipe = nil
                    end
                end

                task.wait(0.25)
            end
        end)
    end
})

local Cooking = CookingStage:SectionUI({
    Title = "Cook Food Manual (Multiplayer)",
    Open = false
})

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local player = Players.LocalPlayer

local function getHRP()
    local char = player.Character or player.CharacterAdded:Wait()
    return char and char:WaitForChild("HumanoidRootPart",5)
end

local function getPart(obj)
    if not obj then return nil end
    if obj:IsA("BasePart") then return obj end
    if obj:IsA("Model") then
        if obj.PrimaryPart then return obj.PrimaryPart end
        return obj:FindFirstChildWhichIsA("BasePart",true)
    end
    return obj:FindFirstChildWhichIsA("BasePart",true)
end

local function findCooking()
    for _,obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Folder") and obj.Name == "Cooking" then
            return obj
        end
    end
end

--------------------------------------------------
-- PROMPT SYSTEM
--------------------------------------------------
local function findPrompt(obj)
    if not obj then return nil end
    if obj:IsA("ProximityPrompt") and obj.Enabled then
        return obj
    end
    for _,v in ipairs(obj:GetDescendants()) do
        if v:IsA("ProximityPrompt") and v.Enabled then
            return v
        end
    end
end

local function firePrompt(prompt)
    if not prompt or not prompt:IsA("ProximityPrompt") then return false end
    if not prompt.Enabled then return false end

    task.wait(0.1)

    if not prompt.Enabled then return false end

    local success = pcall(function()
        if fireproximityprompt then
            fireproximityprompt(prompt)
        else
            prompt:InputHoldBegin()
            task.wait(math.max(prompt.HoldDuration,0.1))
            prompt:InputHoldEnd()
        end
    end)

    task.wait(0.2)
    return success
end

local function usePrompt(obj)
    for i = 1,5 do
        local prompt = findPrompt(obj)

        if prompt and prompt.Enabled then
            task.wait(0.1)

            if prompt.Enabled then
                if firePrompt(prompt) then
                    task.wait(0.15)

                    local newPrompt = findPrompt(obj)
                    if not newPrompt or not newPrompt.Enabled then
                        return true
                    end

                    return true
                end
            end
        end

        task.wait(0.1)
    end

    return false
end

--------------------------------------------------
-- GIVERS
--------------------------------------------------
local function findGiver(name)
    local cooking = findCooking()
    if not cooking then return nil end

    local givers = cooking:FindFirstChild("Givers",true)
    if not givers then return nil end

    for _,obj in ipairs(givers:GetDescendants()) do
        if obj.Name:lower() == name:lower() then
            if obj:IsA("Model") or obj:IsA("BasePart") then
                return obj
            end
        end
    end
end

local function useGiver(name)
    local obj = findGiver(name)

    if not obj then
        Window:Notify({
            Title = "Cooking Stage",
            Content = name.." not found!",
            Duration = 3
        })
        return false
    end

    local hrp = getHRP()
    local part = getPart(obj)

    if not hrp or not part then
        return false
    end

    hrp.CFrame = part.CFrame + Vector3.new(0,5,0)

    task.wait(0.1)

    if usePrompt(obj) then
        return true
    end

    Window:Notify({
        Title = "Cooking Stage",
        Content = "Failed to use "..name,
        Duration = 3
    })

    return false
end

--------------------------------------------------
-- WOODEN COUNTER [24]
--------------------------------------------------
local function getCounter24()
    local cooking = findCooking()
    if not cooking then return nil end

    local counters = cooking:FindFirstChild("WoodenCounters",true)
    if not counters then return nil end

    local children = counters:GetChildren()
    return children[24]
end

local function getCounterPrompt(counter)
    if not counter then return nil,nil end

    local parts = {}

    for _,obj in ipairs(counter:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Name == "Part" then
            table.insert(parts,obj)
        end
    end

    for _,part in ipairs(parts) do
        local prompt = findPrompt(part)
        if prompt then
            return part,prompt
        end
    end

    local prompt = findPrompt(counter)

    if prompt then
        return getPart(counter),prompt
    end

    return nil,nil
end

local function useCounter24()
    local counter = getCounter24()

    if not counter then
        Window:Notify({
            Title = "Cooking Stage",
            Content = "WoodenCounters[24] not found!",
            Duration = 3
        })
        return false
    end

    local hrp = getHRP()
    local counterPart = getPart(counter)

    if not hrp or not counterPart then
        return false
    end

    hrp.CFrame = counterPart.CFrame + Vector3.new(0,5,0)

    task.wait(0.1)

    for i = 1,5 do
        local promptPart,prompt = getCounterPrompt(counter)

        if promptPart and prompt then
            hrp.CFrame = promptPart.CFrame + Vector3.new(0,5,0)

            task.wait(0.1)

            local _,freshPrompt = getCounterPrompt(counter)

            if freshPrompt and freshPrompt.Enabled then
                task.wait(0.1)

                if firePrompt(freshPrompt) then
                    task.wait(0.15)
                    return true
                end
            end
        end

        task.wait(0.1)
    end

    Window:Notify({
        Title = "Cooking Stage",
        Content = "Counter[24] prompt failed!",
        Duration = 3
    })

    return false
end

--------------------------------------------------
-- STOVE [4]
--------------------------------------------------
local function getStove4()
    local cooking = findCooking()
    if not cooking then return nil end

    local stoves = cooking:FindFirstChild("Stoves",true)
    if not stoves then return nil end

    return stoves:GetChildren()[4]
end

local function useStove4()
    local stove = getStove4()

    if not stove then
        Window:Notify({
            Title = "Cooking Stage",
            Content = "Cooking.Stoves[4] not found!",
            Duration = 3
        })
        return false
    end

    local hrp = getHRP()
    local stovePart = getPart(stove)

    if not hrp or not stovePart then
        return false
    end

    hrp.CFrame = stovePart.CFrame + Vector3.new(0,5,0)

    task.wait(0.1)

    for i = 1,5 do
        local prompt = findPrompt(stove)

        if prompt and prompt.Enabled then
            task.wait(0.1)

            local freshPrompt = findPrompt(stove)

            if freshPrompt and freshPrompt.Enabled then
                if firePrompt(freshPrompt) then
                    task.wait(0.2)
                    return true
                end
            end
        end

        task.wait(0.1)
    end

    Window:Notify({
        Title = "Cooking Stage",
        Content = "Stove[4] prompt failed!",
        Duration = 3
    })

    return false
end

--------------------------------------------------
-- TURN IN FOOD
--------------------------------------------------
local function useTurnInFood()
    local cooking = findCooking()
    if not cooking then return false end

    local turnIn = cooking:FindFirstChild("TurnInFood",true)

    if not turnIn then
        Window:Notify({
            Title = "Cooking Stage",
            Content = "TurnInFood not found!",
            Duration = 3
        })
        return false
    end

    local hrp = getHRP()
    if not hrp then return false end

    hrp.CFrame = CFrame.new(-2751.37,968.25,-4919.55)

    task.wait(0.1)

    for i = 1,5 do
        local prompt = findPrompt(turnIn)

        if prompt and prompt.Enabled then
            task.wait(0.1)

            local freshPrompt = findPrompt(turnIn)

            if freshPrompt and freshPrompt.Enabled then
                if firePrompt(freshPrompt) then
                    task.wait(0.2)
                    return true
                end
            end
        end

        task.wait(0.1)
    end

    return false
end

--------------------------------------------------
-- EYE BALL
--------------------------------------------------
Cooking:Button({
    Title = "Eye Ball",
    Callback = function()
        if not useGiver("Bowl") then return end
        if not useCounter24() then return end

        if not useGiver("EyeBall") then
            if not useGiver("Eyeball") then
                return
            end
        end

        if not useCounter24() then return end
        if not useGiver("Spaghetti") then return end
        if not useCounter24() then return end

        task.wait(0.2)

        if not useCounter24() then return end
        useTurnInFood()
    end
})

--------------------------------------------------
-- HAM SAUSAGE
--------------------------------------------------
Cooking:Button({
    Title = "Ham Sausage",
    Callback = function()
        if not useGiver("Pot") then return end
        if not useCounter24() then return end
        if not useGiver("Ham") then return end
        if not useCounter24() then return end
        if not useGiver("Sausage") then return end
        if not useCounter24() then return end

        task.wait(0.2)

        if not useCounter24() then return end
        if not useStove4() then return end

        task.wait(10)

        if not useGiver("Bowl") then return end
        if not useCounter24() then return end
        if not useStove4() then return end
        if not useCounter24() then return end

        task.wait(0.2)

        if not useCounter24() then return end
        useTurnInFood()
    end
})

--------------------------------------------------
-- CHICKEN
--------------------------------------------------
Cooking:Button({
    Title = "Chicken",
    Callback = function()
        if not useGiver("Pot") then return end
        if not useCounter24() then return end
        if not useGiver("Chicken") then return end
        if not useCounter24() then return end
        if not useGiver("Wrapped Meat") then return end
        if not useCounter24() then return end
        if not useGiver("Cheese") then return end
        if not useCounter24() then return end
        if not useCounter24() then return end
        if not useStove4() then return end

        task.wait(10)

        if not useGiver("Bowl") then return end
        if not useCounter24() then return end
        if not useStove4() then return end
        if not useCounter24() then return end
        if not useCounter24() then return end

        useTurnInFood()
    end
})

CookingStage:Section("Chase Stage")

CookingStage:Button({
    Title = "Auto Win",
    Callback = function()
        local hrp = getHRP()
        if not hrp then return end

        hrp.CFrame = CFrame.new(-3249,1246,-6583)
        task.wait(0.1)

        local target = CFrame.new(
            -3341.95068,
            1237.81677,
            -6793.47754,
            0.981654584,0,0.190668017,
            0,1,0,
            -0.190668017,0,0.981654584
        )

        local TweenService = game:GetService("TweenService")
        local tween = TweenService:Create(
            hrp,
            TweenInfo.new(1,Enum.EasingStyle.Linear,Enum.EasingDirection.InOut),
            {CFrame = target}
        )

        tween:Play()
        tween.Completed:Wait()
    end
})


--------------------------------------------------
-- PUZZLE STAGE
--------------------------------------------------
local PuzzleStage = Window:CreateTab({
    Title = "Puzzle Stage",
    Icon = "puzzle"
})

PuzzleStage:Section("Stop & Go Stage")

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local player = Players.LocalPlayer

local function getHRP()
    local char = player.Character or player.CharacterAdded:Wait()
    return char and char:WaitForChild("HumanoidRootPart",5)
end

--------------------------------------------------
-- AUTO WIN
--------------------------------------------------
PuzzleStage:Button({
    Title = "Auto Win",
    Callback = function()
        local hrp = getHRP()
        if not hrp then return end

        hrp.CFrame = CFrame.new(
            -4186.85889,
            624.78833,
            -967.759338,
            0,0,-1,
            0,1,0,
            1,0,0
        )
    end
})

PuzzleStage:Section("Puzzle")
--------------------------------------------------
-- REMOVE MONSTER
--------------------------------------------------
PuzzleStage:Button({
    Title = "Remove Monster",
    Description = "If Multiplayer Tell Them Don't Move",
    Callback = function()
        local target

        for _,obj in ipairs(Workspace:GetDescendants()) do
            if obj.Name == "GAMESTART" and obj:IsA("BasePart") then
                target = obj
                break
            end
        end

        if target then
            target:Destroy()
        end
    end
})

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local player = Players.LocalPlayer

local selectedPuzzle = nil
local puzzleMap = {}

local function getHRP()
    local char = player.Character or player.CharacterAdded:Wait()
    return char and char:WaitForChild("HumanoidRootPart", 5)
end

local function toRoman(num)
    local values = {{1000,"M"},{900,"CM"},{500,"D"},{400,"CD"},{100,"C"},{90,"XC"},{50,"L"},{40,"XL"},{10,"X"},{9,"IX"},{5,"V"},{4,"IV"},{1,"I"}}
    local result = ""
    for _, data in ipairs(values) do
        while num >= data[1] do
            result = result .. data[2]
            num = num - data[1]
        end
    end
    return result
end

local function getPuzzleBase(model)
    if not model or not model:IsA("Model") then return nil end
    local base = model:FindFirstChild("Base")
    if base and base:IsA("BasePart") and base.Transparency ~= 1 then
        return base
    end
    return nil
end

local function scanPuzzles()
    local detected = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") then
            local num = tonumber(obj.Name)
            if num then
                local base = getPuzzleBase(obj)
                if base and not detected[num] then
                    detected[num] = obj
                end
            end
        end
    end
    return detected
end

local puzzleDropdown = PuzzleStage:Dropdown({
    Title = "Select Puzzle",
    Values = {"Select"},
    Default = "Select",
    Callback = function(value)
        selectedPuzzle = value
    end
})

PuzzleStage:Button({
    Title = "Teleport",
    Callback = function()
        local freshPuzzles = scanPuzzles()
        local ordered = {}
        puzzleMap = {}

        for num, model in pairs(freshPuzzles) do
            table.insert(ordered, { Number = num, Model = model, Name = "Puzzle " .. toRoman(num) })
        end
        table.sort(ordered, function(a, b) return a.Number < b.Number end)
        for _, data in ipairs(ordered) do
            puzzleMap[data.Name] = data.Model
        end

        if not selectedPuzzle or selectedPuzzle == "Select" then
            Window:Notify({ Title = "Puzzle Stage", Content = "Please select a puzzle first!", Duration = 3 })
            return
        end

        local puzzle = puzzleMap[selectedPuzzle]
        if not puzzle or not puzzle.Parent then
            Window:Notify({ Title = "Puzzle Stage", Content = selectedPuzzle .. " was not found!", Duration = 3 })
            return
        end

        local base = getPuzzleBase(puzzle)
        if not base then
            Window:Notify({ Title = "Puzzle Stage", Content = selectedPuzzle .. " is not loaded!", Duration = 3 })
            return
        end

        local hrp = getHRP()
        if hrp then
            hrp.CFrame = base.CFrame + Vector3.new(0, 5, 0)
        end
    end
})

task.spawn(function()
    while task.wait(1) do
        local found = scanPuzzles()
        local orderedKeys = {}
        for num in pairs(found) do
            table.insert(orderedKeys, num)
        end
        table.sort(orderedKeys)

        if #orderedKeys > 0 then
            local newValues = {}
            local tempMap = {}
            for _, num in ipairs(orderedKeys) do
                local name = "Puzzle " .. toRoman(num)
                table.insert(newValues, name)
                tempMap[name] = found[num]
            end

            puzzleMap = tempMap
            if puzzleDropdown.SetValues then
                puzzleDropdown:SetValues(newValues)
            elseif puzzleDropdown.Refresh then
                puzzleDropdown:Refresh(newValues)
            end
        end
    end
end)

--------------------------------------------------
-- EXIT
--------------------------------------------------
PuzzleStage:Button({
    Title = "Exit",

    Callback = function()
        local hrp = getHRP()
        if not hrp then return end

        hrp.CFrame = CFrame.new(
            -4080.46,
            743.82,
            -951.88
        )

        task.wait(0.1)

        local door = nil

        for _,obj in ipairs(Workspace:GetDescendants()) do
            if obj.Name == "DoorTeleport"
            and obj:IsA("BasePart") then
                door = obj
                break
            end
        end

        if not door then
            Window:Notify({
                Title = "Puzzle Stage",
                Content = "DoorTeleport not found!",
                Duration = 3
            })
            return
        end

        local prompt = door:FindFirstChildWhichIsA(
            "ProximityPrompt",
            true
        )

        if prompt and prompt.Enabled then
            fireproximityprompt(prompt)
        else
            Window:Notify({
                Title = "Puzzle Stage",
                Content = "DoorTeleport prompt not found!",
                Duration = 3
            })
        end
    end
})

--------------------------------------------------
-- CHIHIRO STAGE TAB
--------------------------------------------------
local ChihiroStage = Window:CreateTab({ Title = "Chihiro Stage", Icon = "user" })

local function isMotherNearTarget(target)
    if not target then return true end

    local mother = Workspace:FindFirstChild("Mother", true)
    if not mother or not mother:IsA("Model") then
        return false
    end

    local motherPart = getPart(mother)
    local targetPart = getPart(target)

    if not motherPart or not targetPart then
        return false
    end

    local distance = (motherPart.Position - targetPart.Position).Magnitude

    return distance > 0 and distance <= 30
end

ChihiroStage:Button({
    Title = "Find Chihiro",
    Callback = function()
        local hrp = getHRP()
        if not hrp then return end

        local hidingSpots = Workspace:FindFirstChild("HidingSpots", true)
        if not hidingSpots then
            Window:Notify({
                Title = "Chihiro Stage",
                Content = "HidingSpots folder not found!",
                Duration = 3
            })
            return
        end

        local parentFolder = hidingSpots.Parent
        if not parentFolder then return end

        local daughterModel = parentFolder:FindFirstChild("Daughter")
        if not daughterModel then
            Window:Notify({
                Title = "Chihiro Stage",
                Content = "Daughter model not found!",
                Duration = 3
            })
            return
        end

        -- Check Mother -> Daughter distance
        if isMotherNearTarget(daughterModel) then
            Window:Notify({
                Title = "Chihiro Stage",
                Content = "Mother is within 30 studs of Daughter! Teleport cancelled.",
                Duration = 3
            })
            return
        end

        local targetPart = getPart(daughterModel)
        if not targetPart then
            Window:Notify({
                Title = "Chihiro Stage",
                Content = "Daughter part not found!",
                Duration = 3
            })
            return
        end

        local originalCFrame = hrp.CFrame
        local sideOffset = targetPart.CFrame.RightVector * 3

        hrp.CFrame = targetPart.CFrame + sideOffset
        task.wait(0.5)

        hrp.CFrame = originalCFrame
    end
})

ChihiroStage:Button({
    Title = "Enter Door",
    Callback = function()
        local hrp = getHRP()
        if not hrp then return end

        local hidingSpots = Workspace:FindFirstChild("HidingSpots", true)
        if not hidingSpots then
            Window:Notify({
                Title = "Chihiro Stage",
                Content = "HidingSpots folder not found!",
                Duration = 3
            })
            return
        end

        local parentFolder = hidingSpots.Parent
        if not parentFolder then return end

        local doorModel = parentFolder:FindFirstChild("Door")
        if not doorModel then
            Window:Notify({
                Title = "Chihiro Stage",
                Content = "Door model not found!",
                Duration = 3
            })
            return
        end

        local glowingPart = doorModel:FindFirstChild("Glowing", true)
        if not glowingPart or not glowingPart:IsA("BasePart") then
            Window:Notify({
                Title = "Chihiro Stage",
                Content = "Glowing part not found!",
                Duration = 3
            })
            return
        end

        -- Check Mother -> Door distance
        if isMotherNearTarget(glowingPart) then
            Window:Notify({
                Title = "Chihiro Stage",
                Content = "Mother is within 30 studs of Door! Teleport cancelled.",
                Duration = 3
            })
            return
        end

        hrp.CFrame = glowingPart.CFrame
        task.wait(0.1)

        if firetouchinterest then
            firetouchinterest(hrp, glowingPart, 0)
            task.wait(0.1)
            firetouchinterest(hrp, glowingPart, 1)
        end
    end
})

ChihiroStage:Section("ESP")

ChihiroStage:Toggle({
    Title = "ESP Mother",
    Default = false,
    Callback = function(enabled)
        local function findMother()
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("Model") and obj.Name == "Mother" then
                    return obj
                end
            end
            return nil
        end

        if enabled then
            task.spawn(function()
                while enabled do
                    local mother = findMother()

                    if mother then
                        local highlight = mother:FindFirstChild("KazeMotherESP")

                        if not highlight then
                            highlight = Instance.new("Highlight")
                            highlight.Name = "KazeMotherESP"
                            highlight.Adornee = mother
                            highlight.FillTransparency = 0.5
                            highlight.OutlineTransparency = 0
                            highlight.Parent = mother
                        end

                        break
                    end

                    task.wait(0.5)
                end
            end)
        else
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("Highlight") and obj.Name == "KazeMotherESP" then
                    obj:Destroy()
                end
            end
        end
    end
})

ChihiroStage:Section("Notes Stage")

ChihiroStage:Button({
    Title = "Grab Notes",
    Callback = function()
        local hrp = getHRP()
        if not hrp then return end

        local notesFolder = Workspace:FindFirstChild("Notes", true)
        if not notesFolder then
            Window:Notify({
                Title = "Chihiro Stage",
                Content = "Notes folder not found!",
                Duration = 3
            })
            return
        end

        local notes = {}

        for _,obj in ipairs(notesFolder:GetDescendants()) do
            if obj:IsA("BasePart") and obj.Name == "Note" then
                table.insert(notes, obj)
            end
        end

        if #notes == 0 then
            Window:Notify({
                Title = "Chihiro Stage",
                Content = "No Notes found!",
                Duration = 3
            })
            return
        end

        table.sort(notes, function(a,b)
            return a:GetFullName() < b:GetFullName()
        end)

        for _,note in ipairs(notes) do
            if not note or not note.Parent then
                continue
            end

            hrp.CFrame = note.CFrame + Vector3.new(0,3,0)
            task.wait(0.2)

            local prompt = note:FindFirstChildWhichIsA(
                "ProximityPrompt",
                true
            )

            if prompt and prompt.Enabled then
                fireproximityprompt(prompt)
                task.wait(0.016)
            end
        end
    end
})

--------------------------------------------------
-- BOSS
--------------------------------------------------
local Boss = Window:CreateTab({
    Title = "Boss Stage",
    Icon = "swords"
})

Boss:Section("Snake Stage")

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local player = Players.LocalPlayer

local autoCannon = false

local function getHRP()
    local char = player.Character or player.CharacterAdded:Wait()
    if not char then return nil end
    return char:WaitForChild("HumanoidRootPart",5)
end

local function getPart(obj)
    if not obj then return nil end
    if obj:IsA("BasePart") then return obj end

    if obj:IsA("Model") then
        if obj.PrimaryPart then
            return obj.PrimaryPart
        end
        return obj:FindFirstChildWhichIsA("BasePart",true)
    end

    return obj:FindFirstChildWhichIsA("BasePart",true)
end

local function findPrompt(obj)
    if not obj then return nil end

    if obj:IsA("ProximityPrompt") and obj.Enabled then
        return obj
    end

    for _,v in ipairs(obj:GetDescendants()) do
        if v:IsA("ProximityPrompt") and v.Enabled then
            return v
        end
    end

    return nil
end

local function findBallGiver()
    local battleship

    for _,obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj.Name == "BATTLESHIP" then
            battleship = obj
            break
        end
    end

    if not battleship then return nil end

    local ballGivers = battleship:FindFirstChild("BallGivers",true)
    if not ballGivers then return nil end

    return ballGivers:FindFirstChild("BallGiver",true)
end

local function fireBallGiver()
    local ballGiver = findBallGiver()
    if not ballGiver then return false end

    local prompt = findPrompt(ballGiver)
    if not prompt then return false end

    if fireproximityprompt then
        fireproximityprompt(prompt)
    else
        prompt:InputHoldBegin()
        task.wait(math.max(prompt.HoldDuration,0.1))
        prompt:InputHoldEnd()
    end

    return true
end

Boss:Toggle({
    Title = "Auto Cannon",
    Default = false,

    Callback = function(enabled)
        autoCannon = enabled

        if not enabled then
            return
        end

        task.spawn(function()
            local ballGiver = findBallGiver()

            -- Teleport ONLY ONCE when starting
            if ballGiver then
                local hrp = getHRP()
                local part = getPart(ballGiver)

                if hrp and part then
                    hrp.CFrame = part.CFrame + Vector3.new(0,5,0)
                    task.wait(0.2)
                end
            end

            -- After that, DO NOT teleport anymore
            while autoCannon do
                fireBallGiver()
                task.wait(0.2)
            end
        end)
    end
})

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local player = Players.LocalPlayer

local antiLaser = false
local savedCFrame = nil
local safe = false
local poisonConnection = nil

local SAFE_POSITION = CFrame.new(1978,217,-4716)

local function getHRP()
    local character = player.Character or player.CharacterAdded:Wait()
    if not character then return nil end
    return character:FindFirstChild("HumanoidRootPart")
end

local function findNureMain()
    for _,obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj.Name == "NureMain" then
            return obj
        end
    end
    return nil
end

local function findPoison(nureMain)
    if not nureMain then return nil end

    for _,child in ipairs(nureMain:GetChildren()) do
        if child.Name == "POISON" and child:IsA("BasePart") then
            return child
        end
    end

    return nil
end

local function getPoison()
    local nureMain = findNureMain()
    if not nureMain then return nil end
    return findPoison(nureMain)
end

local function goSafe()
    if safe then return end

    local hrp = getHRP()
    if not hrp then return end

    savedCFrame = hrp.CFrame
    safe = true

    hrp.Anchored = false
    hrp.CFrame = SAFE_POSITION

    task.wait(0.05)

    if antiLaser and safe then
        hrp.Anchored = true
    end
end

local function goBack()
    if not safe then return end

    local hrp = getHRP()
    if not hrp then return end

    hrp.Anchored = false

    if savedCFrame then
        hrp.CFrame = savedCFrame
    end

    savedCFrame = nil
    safe = false
end

local function monitorPoison(poison)
    if poisonConnection then
        poisonConnection:Disconnect()
        poisonConnection = nil
    end

    poisonConnection = poison:GetPropertyChangedSignal("Transparency"):Connect(function()
        if not antiLaser then return end

        if poison.Transparency == 0.5 then
            goSafe()

        elseif poison.Transparency == 1 then
            goBack()
        end
    end)

    -- Check current state immediately
    if poison.Transparency == 0.5 then
        goSafe()
    elseif poison.Transparency == 1 then
        goBack()
    end
end

Boss:Toggle({
    Title = "Anti Laser",
    Default = false,

    Callback = function(enabled)
        antiLaser = enabled

        if not enabled then
            if poisonConnection then
                poisonConnection:Disconnect()
                poisonConnection = nil
            end

            goBack()
            return
        end

        task.spawn(function()
            while antiLaser do
                local poison = getPoison()

                if poison then
                    monitorPoison(poison)
                    break
                end

                task.wait(0.2)
            end
        end)
    end
})

Boss:Section("Final Form")

--------------------------------------------------
-- AUTO CUTLASS
--------------------------------------------------
local autoCutlass = false

local function getCharacter()
    return player.Character or player.CharacterAdded:Wait()
end

local function getHRP()
    local character = getCharacter()
    return character and character:FindFirstChild("HumanoidRootPart")
end

local function findNureStage2()
    for _,obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj.Name == "NureStage2" then
            return obj
        end
    end
    return nil
end

local function findTailHitbox2()
    local nure = findNureStage2()
    if not nure then return nil end

    local tail = nure:FindFirstChild("TailHitbox2", true)

    if tail and tail:IsA("BasePart") then
        return tail
    end

    return nil
end

local function hasTouchInterest(tail)
    if not tail then return false end

    for _,obj in ipairs(tail:GetChildren()) do
        if obj:IsA("TouchTransmitter") or obj.Name == "TouchInterest" then
            return true
        end
    end

    return false
end

local function findCutlass()
    local character = getCharacter()
    local backpack = player:FindFirstChildOfClass("Backpack")

    local tool = character:FindFirstChild("Cutlass")

    if tool and tool:IsA("Tool") then
        return tool
    end

    if backpack then
        tool = backpack:FindFirstChild("Cutlass")

        if tool and tool:IsA("Tool") then
            return tool
        end
    end

    return nil
end

local function equipCutlass()
    local character = getCharacter()
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local cutlass = findCutlass()

    if not humanoid or not cutlass then
        return nil
    end

    if cutlass.Parent ~= character then
        humanoid:EquipTool(cutlass)
        task.wait()
    end

    return cutlass
end

Boss:Toggle({
    Title = "Auto Boss",
    Description = "Final Boss",
    Default = false,

    Callback = function(enabled)
        autoCutlass = enabled

        if not enabled then
            return
        end

        local cutlass = findCutlass()

        if not cutlass then
            autoCutlass = false

            Window:Notify({
                Title = "Katana",
                Content = "Grab Katana First",
                Duration = 3
            })

            return
        end

        task.spawn(function()
            while autoCutlass do
                local hrp = getHRP()
                local tail = findTailHitbox2()

                if hrp and tail then
                    cutlass = equipCutlass()

                    if cutlass then
                        if hasTouchInterest(tail) then
                            -- TouchInterest detected: move to safe position
                            hrp.CFrame = CFrame.new(
                                1978,
                                217,
                                -4716
                            )
                        else
                            -- TouchInterest gone: return to TailHitbox2
                            hrp.CFrame = tail.CFrame

                            pcall(function()
                                cutlass:Activate()
                            end)
                        end
                    end
                end

                task.wait(0.016)
            end
        end)
    end
})
