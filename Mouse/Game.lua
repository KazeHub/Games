local KazeUI = KazeUI or loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/KazeHub/UI/refs/heads/main/UILibrary.lua.txt"
))()

local Window = KazeUI:CreateWindow({
    Title = "MOUSE",
    Author = "KAZE",
    Version = "",
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

local jumpBoostValue = 50
local jumpBoostEnabled = false
local infJumpEnabled = false
local jumpConn = nil

local function applyJumpBoost()
	pcall(function()
		local char = game:GetService("Players").LocalPlayer.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.UseJumpPower = true
			hum.JumpPower = jumpBoostEnabled and jumpBoostValue or 50
		end
	end)
end

Main:Slider({
	Title = "Jump Boost",
	Min = 50,
	Max = 300,
	Default = 50,
	Callback = function(v)
		jumpBoostValue = v
		if jumpBoostEnabled then
			applyJumpBoost()
		end
	end
})

Main:Toggle({
	Title = "Jump Boost",
	Default = false,
	Callback = function(state)
		jumpBoostEnabled = state
		applyJumpBoost()
	end
})

Main:Toggle({
	Title = "Infinite Jump",
	Default = false,
	Callback = function(state)
		infJumpEnabled = state
		if jumpConn then
			jumpConn:Disconnect()
			jumpConn = nil
		end
		if infJumpEnabled then
			jumpConn = game:GetService("UserInputService").JumpRequest:Connect(function()
				if not infJumpEnabled then return end
				local char = game:GetService("Players").LocalPlayer.Character
				local hum = char and char:FindFirstChildOfClass("Humanoid")
				if hum then
					hum:ChangeState(Enum.HumanoidStateType.Jumping)
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

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local MainTab = Window:CreateTab({ Title = "Main", Icon = "house" })
local MainSub = MainTab:CreateSubTab({ Title = "Main", Icon = "house", Default = true })
local ESPSub = MainTab:CreateSubTab({ Title = "ESP", Icon = "eye", Default = false })

local safePos = Vector3.new(-1, 85, 428)
local lifeboatCFrame = CFrame.new(-1.5, 90, 646, -1, 0, 0, 0, 0.991459846, -0.130412206, -0, -0.130412206, -0.991459966)

local function getHrp()
	local char = LocalPlayer.Character
	return char and char:FindFirstChild("HumanoidRootPart")
end

local function tpTo(cf)
	local hrp = getHrp()
	if not hrp then return false end
	pcall(function()
		hrp.AssemblyLinearVelocity = Vector3.zero
		hrp.AssemblyAngularVelocity = Vector3.zero
		hrp.CFrame = cf
	end)
	return true
end

local function getObjectPosition(obj)
	if not obj or not obj.Parent then return nil end
	if obj:IsA("Model") then
		return obj:GetPivot().Position
	end
	if obj:IsA("BasePart") then
		return obj.Position
	end
	local part = obj:FindFirstChildWhichIsA("BasePart", true)
	return part and part.Position or nil
end

local validSearchTargets = {
	CoalPit = "Model",
	PotatoSack = "MeshPart",
	Bed = "Model",
	Barrel = "Model"
}

local function isTargetSearchObject(obj)
	if not obj or not obj.Parent then return false end
	local expected = validSearchTargets[obj.Name]
	if not expected then return false end
	if expected == "MeshPart" then
		return obj:IsA("MeshPart") or obj:IsA("BasePart")
	end
	return obj:IsA(expected)
end

local objectHighlights = {}
local objectAddedConn = nil
local objectEspEnabled = false

local function clearObjectESP()
	objectEspEnabled = false
	if objectAddedConn then
		pcall(function() objectAddedConn:Disconnect() end)
		objectAddedConn = nil
	end
	for target, hl in pairs(objectHighlights) do
		pcall(function()
			if hl and hl.Parent then
				hl:Destroy()
			end
		end)
		objectHighlights[target] = nil
	end
end

local function applyObjectESP(obj)
	if not objectEspEnabled or not isTargetSearchObject(obj) then return end
	if objectHighlights[obj] then return end
	pcall(function()
		local hl = Instance.new("Highlight")
		hl.Name = "KazeObjectESP"
		hl.FillColor = Color3.fromRGB(255, 220, 0)
		hl.OutlineColor = Color3.fromRGB(255, 255, 255)
		hl.FillTransparency = 0.5
		hl.OutlineTransparency = 0
		hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		hl.Adornee = obj
		hl.Parent = obj
		objectHighlights[obj] = hl
	end)
end

ESPSub:Toggle({
	Title = "ESP Search Objects",
	Default = false,
	Callback = function(state)
		clearObjectESP()
		if not state then return end
		objectEspEnabled = true

		task.spawn(function()
			local descendants = Workspace:GetDescendants()
			for i = 1, #descendants do
				if not objectEspEnabled then break end
				local obj = descendants[i]
				if isTargetSearchObject(obj) then
					applyObjectESP(obj)
				end
				if i % 150 == 0 then
					task.wait()
				end
			end
		end)

		objectAddedConn = Workspace.DescendantAdded:Connect(function(obj)
			if objectEspEnabled and isTargetSearchObject(obj) then
				task.defer(applyObjectESP, obj)
			end
		end)
	end
})

local mickeyHighlights = {}
local mickeyAddedConn = nil
local mickeyEspEnabled = false

local function clearMickeyESP()
	mickeyEspEnabled = false
	if mickeyAddedConn then
		pcall(function() mickeyAddedConn:Disconnect() end)
		mickeyAddedConn = nil
	end
	for target, hl in pairs(mickeyHighlights) do
		pcall(function()
			if hl and hl.Parent then
				hl:Destroy()
			end
		end)
		mickeyHighlights[target] = nil
	end
end

local function createMickeyESP(obj)
	if not mickeyEspEnabled or not obj or mickeyHighlights[obj] then return end
	if obj.Name ~= "MickeyVisual" then return end
	pcall(function()
		local hl = Instance.new("Highlight")
		hl.Name = "KazeMonsterESP"
		hl.FillColor = Color3.fromRGB(255, 0, 0)
		hl.OutlineColor = Color3.fromRGB(255, 255, 255)
		hl.FillTransparency = 0.5
		hl.OutlineTransparency = 0
		hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		hl.Adornee = obj
		hl.Parent = obj
		mickeyHighlights[obj] = hl
	end)
end

ESPSub:Toggle({
	Title = "ESP Mickey",
	Default = false,
	Callback = function(state)
		clearMickeyESP()
		if not state then return end
		mickeyEspEnabled = true

		local existing = Workspace:FindFirstChild("MickeyVisual")
		if existing then
			createMickeyESP(existing)
		end

		mickeyAddedConn = Workspace.ChildAdded:Connect(function(obj)
			if mickeyEspEnabled and obj.Name == "MickeyVisual" then
				task.defer(createMickeyESP, obj)
			end
		end)
	end
})

local autoFindKeyEnabled = false
local findKeyConn = nil
local isFindingKeyStep = false

local function findNearestSearchPrompt()
	local hrp = getHrp()
	if not hrp then return nil end

	local targets = {
		["CoalPit"] = true,
		["PotatoSack"] = true,
		["Bed"] = true,
		["Barrel"] = true
	}

	local nearestPrompt = nil
	local shortestDist = math.huge

	for _, obj in ipairs(Workspace:GetDescendants()) do
		if obj:IsA("ProximityPrompt") and obj.Enabled and obj.Parent and obj.Parent:IsA("BasePart") then
			local parentName = obj.Parent.Name
			if targets[parentName] or (obj.Parent.Parent and targets[obj.Parent.Parent.Name]) then
				local dist = (hrp.Position - obj.Parent.Position).Magnitude
				if dist < shortestDist then
					shortestDist = dist
					nearestPrompt = obj
				end
			end
		end
	end
	return nearestPrompt
end

MainSub:Toggle({
	Title = "Auto Find Key",
	Default = false,
	Callback = function(state)
		autoFindKeyEnabled = state
		isFindingKeyStep = false
		if findKeyConn then
			pcall(function() findKeyConn:Disconnect() end)
			findKeyConn = nil
		end
		if not autoFindKeyEnabled then
			tpTo(CFrame.new(safePos))
			return
		end

		findKeyConn = RunService.Heartbeat:Connect(function()
			if not autoFindKeyEnabled or isFindingKeyStep then return end
			local currentHrp = getHrp()
			if not currentHrp then return end

			local targetPrompt = findNearestSearchPrompt()
			if targetPrompt and targetPrompt.Parent then
				isFindingKeyStep = true
				task.spawn(function()
					pcall(function()
						local targetPart = targetPrompt.Parent
						tpTo(targetPart.CFrame + Vector3.new(0, 3, 0))
						task.wait(0.15)
						if not autoFindKeyEnabled then return end

						if fireproximityprompt then
							fireproximityprompt(targetPrompt)
						else
							targetPrompt:InputHoldBegin()
							task.wait(targetPrompt.HoldDuration + 0.05)
							targetPrompt:InputHoldEnd()
						end
						task.wait(0.2)
					end)
					isFindingKeyStep = false
				end)
			else
				tpTo(CFrame.new(safePos))
			end
		end)
	end
})

local function getPadlockLeverPrompt()
	local boat = Workspace:FindFirstChild("Boat")
	local padlocks = boat and boat:FindFirstChild("Padlocks")
	local lever = padlocks and padlocks:FindFirstChild("Lever")
	if not lever then
		local model = padlocks and padlocks:FindFirstChild("Model")
		lever = model and model:FindFirstChild("Lever")
	end
	if not lever then return nil, nil end
	local prompt = lever:FindFirstChild("ProximityPrompt") or lever:FindFirstChildWhichIsA("ProximityPrompt", true)
	return lever, prompt
end

MainSub:Button({
	Title = "Unlock Padlock",
	Callback = function()
		task.spawn(function()
			tpTo(CFrame.new(0, 63, 609))
			task.wait(0.25)

			pcall(function()
				local _, prompt = getPadlockLeverPrompt()
				if prompt then
					prompt.Enabled = true
					if fireproximityprompt then
						fireproximityprompt(prompt)
					end
				end
			end)

			task.wait(0.25)
			tpTo(CFrame.new(safePos))
		end)
	end
})

MainSub:Button({
	Title = "Stop Engine",
	Callback = function()
		task.spawn(function()
			tpTo(CFrame.new(6, 35, 626))
			task.wait(0.25)

			pcall(function()
				local boat = Workspace:FindFirstChild("Boat")
				local engineStop = boat and boat:FindFirstChild("EngineStop")
				local prompt = engineStop and engineStop:FindFirstChildWhichIsA("ProximityPrompt", true)
				if prompt then
					prompt.Enabled = true
					if fireproximityprompt then
						fireproximityprompt(prompt)
					end
				end
			end)

			task.wait(0.25)
			tpTo(CFrame.new(safePos))
		end)
	end
})

MainSub:Button({
	Title = "Lower the lifeboat",
	Callback = function()
		task.spawn(function()
			tpTo(CFrame.new(0, 63, 609))
			task.wait(0.5)

			local lever, prompt = getPadlockLeverPrompt()
			if lever and prompt then
				local leverPos = getObjectPosition(lever)
				if leverPos then
					local maxDist = prompt.MaxActivationDistance
					local origLOS = prompt.RequiresLineOfSight
					local originalCamType = Camera.CameraType
					local originalCamCFrame = Camera.CFrame

					prompt.Enabled = true
					prompt.MaxActivationDistance = 250
					prompt.RequiresLineOfSight = false

					Camera.CameraType = Enum.CameraType.Scriptable
					Camera.CFrame = CFrame.new(Camera.CFrame.Position, leverPos)

					tpTo(CFrame.new(leverPos))
					task.wait(0.3)

					pcall(function()
						prompt:InputHoldBegin()
					end)
					task.wait(prompt.HoldDuration + 0.1)
					pcall(function()
						prompt:InputHoldEnd()
					end)

					Camera.CameraType = originalCamType
					Camera.CFrame = originalCamCFrame
					prompt.MaxActivationDistance = maxDist
					prompt.RequiresLineOfSight = origLOS
				end
			end

			task.wait(0.25)
			tpTo(CFrame.new(safePos))
		end)
	end
})

MainSub:Button({
	Title = "Enter Lifeboat",
	Callback = function()
		task.spawn(function()
			tpTo(lifeboatCFrame)
		end)
	end
})
