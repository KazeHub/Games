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
                if Lighting.Brightness ~= 2 then Lighting.Brightness = 2 end
                if Lighting.ClockTime ~= 14 then Lighting.ClockTime = 14 end
                if Lighting.GlobalShadows ~= false then Lighting.GlobalShadows = false end
                local a = Color3.fromRGB(178, 178, 178)
                if Lighting.Ambient ~= a then Lighting.Ambient = a end
                if Lighting.OutdoorAmbient ~= a then Lighting.OutdoorAmbient = a end
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
        end
    end
    -- also accessories meshes on character direct children only (no full GetDescendants every frame)
    for _, acc in ipairs(char:GetChildren()) do
        if acc:IsA("Accessory") then
            local handle = acc:FindFirstChild("Handle")
            if handle and handle:IsA("BasePart") then
                CachedNoclipParts[#CachedNoclipParts + 1] = handle
            end
        end
    end
end
rebuildNoclipParts(CachedCharacter)

LocalPlayer.CharacterAdded:Connect(function(char)
    CachedCharacter = char
    CachedHumanoid = char:WaitForChild("Humanoid", 5)
    CachedHRP = char:WaitForChild("HumanoidRootPart", 5)
    task.defer(function()
        task.wait(0.1)
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
                    hrp.CFrame = hrp.CFrame + (humanoid.MoveDirection * (TPWalkSpeed * 0.5 * dt * 40))
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

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Terrain = Workspace:FindFirstChildOfClass("Terrain")

local LocalPlayer = Players.LocalPlayer

local isAutoPromptToggled = false
local isEspToggled = false
local autoPressE = false

local yenEspHolders = {}
local yenEspConnection = nil
local autoPromptTask = nil

local PROXIMITY_RANGE = 15

local GameTab = Window:CreateTab({
    Title = "Game",
    Icon = "gamepad-2"
})

local function getCharacterRoot()
	if CachedHRP and CachedHRP.Parent then return CachedHRP end
	local char = LocalPlayer.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	CachedHRP = hrp
	return hrp
end

local function startAutoPrompt()
	if autoPromptTask then return end

	autoPromptTask = task.spawn(function()
		while isAutoPromptToggled do
			local rootPart = getCharacterRoot()
			local mimicFolder = Workspace:FindFirstChild("MimicCurrencySpawns")
			
			if rootPart and mimicFolder then
				local yenFolder = mimicFolder:FindFirstChild("Yen")
				if yenFolder then
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

	local mimicFolder = Workspace:FindFirstChild("MimicCurrencySpawns")
	if mimicFolder then
		local yenFolder = mimicFolder:FindFirstChild("Yen")
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

GameTab:Toggle({
    Title = "Auto Free Yourself",
    Default = false,
    Callback = function(state)
        autoPressE = state
        if not state then return end

        task.spawn(function()
            local VirtualInputManager = game:GetService("VirtualInputManager")
            local PlayerGui = game:GetService("Players").LocalPlayer.PlayerGui

            while autoPressE do
                local grabbedUI = PlayerGui:FindFirstChild("QuickTime") and PlayerGui.QuickTime:FindFirstChild("GrabbedUI")
                if grabbedUI and grabbedUI.Visible then
                    pcall(function()
                        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
                        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
                    end)
                end
                task.wait(0.05)
            end
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
        local collected = {}

        task.spawn(function()
            while isEspToggled do
                local found = false

                for item, data in pairs(yenEspHolders) do
                    if not isEspToggled then break end

                    if item and item.Parent and data and data.Part and data.Part.Parent and not collected[item] then
                        found = true
                        collected[item] = true

                        rootPart = getCharacterRoot()
                        if not rootPart then break end

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

                if not found then
                    task.wait(0.25)

                    local newCoin = false

                    for item in pairs(yenEspHolders) do
                        if item and item.Parent and not collected[item] then
                            newCoin = true
                            break
                        end
                    end

                    if not newCoin then
                        break
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

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

local AutoBossEnabled = false
local AtAmmo = false
local BossTween = nil
local BossFollowConnection = nil
local BossFireTask = nil

local BOSS_DISTANCE = 60
local BOSS_Y = 42
local TWEEN_TIME = 0.18
local FIRE_DELAY = 0.12

local function getCharacter()
    return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
end

local function getHRP()
    local character = getCharacter()
    return character:FindFirstChild("HumanoidRootPart")
end

local function getChenooHitbox()
    local XmasEvent = workspace:FindFirstChild("XmasEvent")
    local Boss = XmasEvent and XmasEvent:FindFirstChild("Boss")
    local Chenoo = Boss and Boss:FindFirstChild("Chenoo")
    return Chenoo and Chenoo:FindFirstChild("ChenooHitboxHead")
end

local function getBossFrontCFrame(hitbox)
    if not hitbox then
        return nil
    end

    local cf = hitbox.CFrame
    local flatLook = Vector3.new(cf.LookVector.X, 0, cf.LookVector.Z)

    if flatLook.Magnitude == 0 then
        return nil
    end

    flatLook = flatLook.Unit

    local pos = cf.Position + flatLook * BOSS_DISTANCE

    return CFrame.lookAt(
        Vector3.new(pos.X, BOSS_Y, pos.Z),
        Vector3.new(cf.Position.X, BOSS_Y, cf.Position.Z),
        Vector3.yAxis
    )
end

local function getShotgun()
    local character = getCharacter()
    local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
    local shotgun = character:FindFirstChild("Shotgun")

    if shotgun then
        return shotgun
    end

    if backpack then
        shotgun = backpack:FindFirstChild("Shotgun")

        if shotgun then
            local humanoid = character:FindFirstChildOfClass("Humanoid")

            if humanoid then
                humanoid:EquipTool(shotgun)
            end

            task.wait()

            return character:FindFirstChild("Shotgun") or shotgun
        end
    end

    return nil
end

local function getShotgunRemote()
    local shotgun = getShotgun()
    return shotgun and shotgun:FindFirstChild("Remote")
end

local function getAmmoText()
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    local shotgunUI = playerGui and playerGui:FindFirstChild("ShotgunUI")
    local ammo = shotgunUI and shotgunUI:FindFirstChild("Ammo")

    if not ammo then
        return nil
    end

    local ok, text = pcall(function()
        return ammo.ContentText
    end)

    if ok and text ~= nil then
        return tostring(text)
    end

    local contentText = ammo:FindFirstChild("ContentText")

    if contentText then
        local ok2, value = pcall(function()
            return contentText.Text
        end)

        if ok2 then
            return tostring(value)
        end
    end

    return nil
end

local function getAmmo()
    local text = getAmmoText()

    if not text then
        return nil, nil
    end

    text = text:gsub("%s+", "")

    local current, maximum = text:match("(%d+)%/(%d+)")

    return tonumber(current), tonumber(maximum)
end

local function isAmmoZeroZero()
    local current, maximum = getAmmo()
    return current == 0 and maximum == 0
end

local function reloadShotgun()
    local remote = getShotgunRemote()

    if not remote then
        return false
    end

    pcall(function()
        remote:FireServer({
            [1] = "Reload"
        })
    end)

    task.wait(0.2)

    return true
end

local function fireShotgun()
    local remote = getShotgunRemote()
    local hitbox = getChenooHitbox()
    local hrp = getHRP()

    if not remote or not hitbox or not hrp then
        return false
    end

    local aimCFrame = CFrame.lookAt(
        hrp.Position,
        hitbox.Position,
        Vector3.yAxis
    )

    pcall(function()
        remote:FireServer({
            [1] = "Fire",
            [2] = aimCFrame
        })
    end)

    return true
end

local function findAmmoObject()
    local XmasEvent = workspace:FindFirstChild("XmasEvent")
    local crates = XmasEvent and XmasEvent:FindFirstChild("AmmoCrates")

    if not crates then
        return nil, nil
    end

    for _, object in ipairs(crates:GetChildren()) do
        local prompt = object:FindFirstChildWhichIsA("ProximityPrompt", true)

        if prompt then
            return object, prompt
        end
    end

    return nil, nil
end

local function getObjectPart(object)
    if not object then
        return nil
    end

    if object:IsA("BasePart") then
        return object
    end

    if object:IsA("Attachment") and object.Parent:IsA("BasePart") then
        return object.Parent
    end

    if object:IsA("Model") then
        return object.PrimaryPart
            or object:FindFirstChildWhichIsA("BasePart", true)
    end

    return object:FindFirstChildWhichIsA("BasePart", true)
end

local function fireAmmoPrompt(prompt)
    if not prompt or not prompt.Parent then
        return false
    end

    if fireproximityprompt then
        pcall(function()
            fireproximityprompt(prompt)
        end)

        return true
    end

    pcall(function()
        prompt:InputHoldBegin()
        task.wait(math.max(prompt.HoldDuration, 0.05))
        prompt:InputHoldEnd()
    end)

    return true
end

local function stopBossTween()
    if BossTween then
        BossTween:Cancel()
        BossTween = nil
    end
end

local function collectAmmo()
    local hrp = getHRP()

    if not hrp then
        return false
    end

    -- Completely disable boss movement
    AtAmmo = true
    stopBossTween()

    -- Make sure no boss tween is running
    task.wait(0.3)

    if not AutoBossEnabled then
        AtAmmo = false
        return false
    end

    local object, prompt = findAmmoObject()

    if not object or not prompt then
        AtAmmo = false
        return false
    end

    local part = getObjectPart(object)

    if not part then
        AtAmmo = false
        return false
    end

    -- Teleport directly to ammo
    hrp.CFrame = part.CFrame + Vector3.new(0, 2, 0)

    task.wait(0.3)

    -- Stay completely away from Chenoo while collecting
    while AutoBossEnabled and isAmmoZeroZero() do
        fireAmmoPrompt(prompt)
        task.wait(0.3)
    end

    if not AutoBossEnabled then
        AtAmmo = false
        return false
    end

    -- Keep away from Chenoo for another 0.3 seconds
    task.wait(0.3)

    -- Now allow boss following again
    AtAmmo = false

    return not isAmmoZeroZero()
end

local function stopBoss()
    AtAmmo = false

    if BossFollowConnection then
        BossFollowConnection:Disconnect()
        BossFollowConnection = nil
    end

    stopBossTween()

    BossFireTask = nil
end

local function startBoss()
    stopBoss()

    local hrp = getHRP()
    local hitbox = getChenooHitbox()

    if not hrp or not hitbox then
        return
    end

    local firstCFrame = getBossFrontCFrame(hitbox)

    if not firstCFrame then
        return
    end

    hrp.CFrame = firstCFrame

    BossFollowConnection = RunService.Heartbeat:Connect(function()
        if not AutoBossEnabled or AtAmmo then
            return
        end

        local currentHRP = getHRP()
        local currentHitbox = getChenooHitbox()

        if not currentHRP or not currentHitbox then
            return
        end

        local targetCFrame = getBossFrontCFrame(currentHitbox)

        if not targetCFrame then
            return
        end

        if not BossTween
            or BossTween.PlaybackState ~= Enum.PlaybackState.Playing then

            BossTween = TweenService:Create(
                currentHRP,
                TweenInfo.new(
                    TWEEN_TIME,
                    Enum.EasingStyle.Linear,
                    Enum.EasingDirection.Out
                ),
                {
                    CFrame = targetCFrame
                }
            )

            BossTween:Play()
        end
    end)

    BossFireTask = task.spawn(function()
        local lastFire = 0

        while AutoBossEnabled do
            local shotgun = getShotgun()

            if not shotgun then
                task.wait(0.2)
                continue
            end

            local ammo, maximum = getAmmo()

            if ammo == nil then
                task.wait(0.15)
                continue
            end

            if ammo == 0 and maximum == 0 then
                collectAmmo()
                task.wait()
                continue
            end

            if ammo == 0 and maximum and maximum > 0 then
                reloadShotgun()
                task.wait(0.2)
                continue
            end

            if not AtAmmo and os.clock() - lastFire >= FIRE_DELAY then
                if fireShotgun() then
                    lastFire = os.clock()
                end
            end

            task.wait()
        end
    end)
end

local ChristmasSection = GameTab:SectionUI({
    Title = "Xmas Event",
    Open = false
})

ChristmasSection:Button({
    Title = "Boss Trigger",
    Callback = function()
        local hrp = getHRP()

        if not hrp then
            return
        end

        hrp.CFrame = CFrame.new(
            -982.162048,
            58.6572495,
            -4985.2417,
            1, 0, 0,
            0, 1, 0,
            0, 0, 1
        )
    end
})

ChristmasSection:Toggle({
    Title = "Auto Yeti",
    Default = false,
    Callback = function(state)
        AutoBossEnabled = state

        if state then
            startBoss()
        else
            stopBoss()
        end
    end
})

local GozuTab = Window:CreateTab({
    Title = "Gozu & Mezu Stage",
    Icon = "chess-knight"
})

GozuTab:Button({
    Title = "Start [Multiplayer]",
    Callback = function()
        local doorTrigger = workspace["Intro [no script]"].Cutscene.DoorTrigger
        local rootPart = game.Players.LocalPlayer.Character.HumanoidRootPart
        
        rootPart.CFrame = doorTrigger.CFrame
        if firetouchinterest then
            firetouchinterest(rootPart, doorTrigger, 0)
            task.wait(0.1)
            firetouchinterest(rootPart, doorTrigger, 1)
        end
    end
})

GozuTab:Button({
    Title = "Skip [Solo]",
    Callback = function()
        local npcTrigger = workspace.Section1.NPC.Trigger
        local rootPart = game.Players.LocalPlayer.Character.HumanoidRootPart
        
        rootPart.CFrame = npcTrigger.CFrame
        if firetouchinterest then
            firetouchinterest(rootPart, npcTrigger, 0)
            task.wait(0.1)
            firetouchinterest(rootPart, npcTrigger, 1)
        end
    end
})


local HeartStage = Window:CreateTab({
    Title = "Heart Stage",
    Icon = "heart"
})

HeartStage:Button({
    Title = "Talk",
    Callback = function()
        local npcTrigger = workspace.Section1.NPC.Trigger
        local rootPart = game.Players.LocalPlayer.Character.HumanoidRootPart
        
        rootPart.CFrame = npcTrigger.CFrame
        if firetouchinterest then
            firetouchinterest(rootPart, npcTrigger, 0)
            task.wait(0.1)
            firetouchinterest(rootPart, npcTrigger, 1)
        end
    end
})

HeartStage:Button({
    Title = "Auto Spin",
    Callback = function()
        local spinModel = workspace.Section1.Puzzle.SpinModel
        local prompt = spinModel:FindFirstChild("ProximityPrompt", true)
        local rootPart = game.Players.LocalPlayer.Character.HumanoidRootPart
        
        rootPart.CFrame = CFrame.new(-71.80, 49.34, 10.63)
        
        if prompt then
            prompt.Enabled = true
            
            for i = 1, 10 do
                if fireproximityprompt then
                    fireproximityprompt(prompt)
                end
                task.wait(1)
            end
        end
    end
})

HeartStage:Section("Chase Stage")

HeartStage:Button({
    Title="Finish Chase",
    Callback=function()
        local player=game:GetService("Players").LocalPlayer
        local character=player.Character or player.CharacterAdded:Wait()
        local rootPart=character:FindFirstChild("HumanoidRootPart")
        if not rootPart then return end

        rootPart.CFrame=CFrame.new(-100.90,45.50,-397.24)
        task.wait(0.1)

        local nearestPrompt=nil
        local shortestDistance=10

        for _,obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("ProximityPrompt") and obj.Parent and obj.Parent:IsA("BasePart") then
                local distance=(rootPart.Position-obj.Parent.Position).Magnitude

                if distance<=shortestDistance then
                    shortestDistance=distance
                    nearestPrompt=obj
                end
            end
        end

        if nearestPrompt then
            pcall(function()
                nearestPrompt.Enabled=true
            end)

            if fireproximityprompt then
                pcall(function()
                    fireproximityprompt(nearestPrompt)
                end)
            end
        end
    end
})

local GrinDemonStage = Window:CreateTab({
    Title = "GrinDemon Stage",
    Icon = "skull"
})

GrinDemonStage:Section("ESP")

local espEnabled = false
local espObjects = {}
local espConnections = {}

local function clearESP()
    for _, obj in ipairs(espObjects) do
        if obj and obj.Parent then obj:Destroy() end
    end
    for _, conn in ipairs(espConnections) do
        if conn then conn:Disconnect() end
    end
    espObjects = {}
    espConnections = {}
end

local function createESP(model, name)
    if not model or not model:FindFirstChild("HumanoidRootPart") then return end

    local highlight = Instance.new("Highlight")
    highlight.Name = "senzaiESP"
    highlight.FillColor = Color3.fromRGB(255, 0, 0)
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.Adornee = model
    highlight.Parent = model
    table.insert(espObjects, highlight)

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "senzaiBillboard"
    billboard.Size = UDim2.new(0, 200, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 4, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = model.HumanoidRootPart
    table.insert(espObjects, billboard)

    local text = Instance.new("TextLabel")
    text.BackgroundTransparency = 1
    text.Size = UDim2.new(1, 0, 1, 0)
    text.TextStrokeTransparency = 0
    text.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    text.TextColor3 = Color3.fromRGB(255, 255, 0)
    text.TextScaled = false
    text.TextSize = 13
    text.Font = Enum.Font.SourceSansBold
    text.Parent = billboard

    local conn = game:GetService("RunService").Heartbeat:Connect(function()
        if not espEnabled or not model or not model.Parent then
            pcall(function()
                if billboard then billboard:Destroy() end
                if highlight then highlight:Destroy() end
            end)
            if conn then conn:Disconnect() end
            return
        end
        local char = game.Players.LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") and model:FindFirstChild("HumanoidRootPart") then
            local dist = (char.HumanoidRootPart.Position - model.HumanoidRootPart.Position).Magnitude
            text.Text = name .. "\n[" .. math.floor(dist) .. "]"
        end
    end)
    table.insert(espConnections, conn)
end

GrinDemonStage:Toggle({
    Title = "ESP GrinDemon",
    Default = false,
    Callback = function(s)
        espEnabled = s
        clearESP()
        if not s then return end

        local grinDemonNM = workspace:FindFirstChild("Section1") 
            and workspace.Section1:FindFirstChild("Maze") 
            and workspace.Section1.Maze:FindFirstChild("GrinDemonNM")
        if grinDemonNM then
            createESP(grinDemonNM, "GrinDemonNM")
        end

        local grinDemon = workspace:FindFirstChild("Section1") 
            and workspace.Section1:FindFirstChild("Maze") 
            and workspace.Section1.Maze:FindFirstChild("GrinDemon")
        if grinDemon then
            createESP(grinDemon, "GrinDemon")
        end
    end
})

GrinDemonStage:Section("Main")

GrinDemonStage:Button({
    Title="Auto GrinDemon",
    Callback=function()
        local player=Players.LocalPlayer
        local Workspace=game:GetService("Workspace")
        local ReplicatedStorage=game:GetService("ReplicatedStorage")
        local maze=Workspace.Section1.Maze
        local crafting=maze:FindFirstChild("Crafting")
        local char=player.Character or player.CharacterAdded:Wait()
        local hrp=char:WaitForChild("HumanoidRootPart")
        local originalCFrame=hrp.CFrame

        local function firePrompt(p)
            if not p or not p:IsA("ProximityPrompt") or not p.Enabled then return false end
            if fireproximityprompt then
                pcall(function() fireproximityprompt(p) end)
            else
                pcall(function()
                    p:InputHoldBegin()
                    p:InputHoldEnd()
                end)
            end
            return true
        end

        local function hasItems()
            local cloth,stick=0,0
            local backpack=player:FindFirstChild("Backpack")
            local character=player.Character
            for _,container in ipairs({backpack,character}) do
                if container then
                    for _,item in ipairs(container:GetChildren()) do
                        if item.Name=="Cloth" then cloth+=1
                        elseif item.Name=="Stick" then stick+=1 end
                    end
                end
            end
            return cloth>=1 and stick>=2
        end

        local holes=maze:FindFirstChild("Holes")
        if not holes then return end

        for _,hole in ipairs(holes:GetChildren()) do
            if hasItems() then break end
            if hole.Name=="Hole" and hole:IsA("BasePart") then
                local p=hole:FindFirstChildWhichIsA("ProximityPrompt",true)
                if p then
                    hrp.CFrame=hole.CFrame+Vector3.new(0,3,0)
                    task.wait(0.3)
                    while not hasItems() and p.Parent and p.Enabled do
                        firePrompt(p)
                        task.wait(0.05)
                    end
                end
            end
        end

        if not hasItems() then
            hrp.CFrame=originalCFrame
            return
        end

        local tables=crafting and crafting:FindFirstChild("Tables")
        local monster=tables and tables:FindFirstChild("Monster")
        if not monster then
            hrp.CFrame=originalCFrame
            return
        end

        local monsterPart=monster:IsA("BasePart") and monster or monster.PrimaryPart or monster:FindFirstChildWhichIsA("BasePart",true)
        local monsterPrompt=monster:FindFirstChildWhichIsA("ProximityPrompt",true)
        if not monsterPart or not monsterPrompt then
            hrp.CFrame=originalCFrame
            return
        end

        hrp.CFrame=monsterPart.CFrame+Vector3.new(0,3,0)
        task.wait(0.3)
        firePrompt(monsterPrompt)
        task.wait(0.1)

        local packages=ReplicatedStorage:FindFirstChild("Packages")
        local packet=packages and packages:FindFirstChild("Packet")
        local packetFunc=packet and packet:FindFirstChild("PacketFunction")
        if packetFunc and packetFunc:IsA("RemoteFunction") then
            pcall(function()
                packetFunc:InvokeServer(0,{
                    ["__args"]={},
                    ["__tree"]={[1]="CraftingService",[2]="Interact"},
                    ["__callType"]=0
                })
            end)
        end

        local torch
        for _=1,200 do
            local backpack=player:FindFirstChild("Backpack")
            local character=player.Character
            torch=(character and character:FindFirstChild("Torch")) or (backpack and backpack:FindFirstChild("Torch"))
            if torch then break end
            task.wait(0.05)
        end

        if not torch then
            hrp.CFrame=originalCFrame
            return
        end

        char=player.Character or player.CharacterAdded:Wait()
        hrp=char:WaitForChild("HumanoidRootPart")
        local humanoid=char:FindFirstChildOfClass("Humanoid")
        if humanoid and torch.Parent~=char then
            humanoid:EquipTool(torch)
            task.wait(0.1)
        end

        local flameFolder=crafting and crafting:FindFirstChild("ArmFlames")
        local flameModel=flameFolder and flameFolder:FindFirstChild("ArmFlames")
        if not flameModel or not flameModel:IsA("Model") then
            hrp.CFrame=originalCFrame
            return
        end

        local flamePart=flameModel.PrimaryPart or flameModel:FindFirstChildWhichIsA("BasePart",true)
        local flamePrompt=flameModel:FindFirstChildWhichIsA("ProximityPrompt",true)
        if not flamePart or not flamePrompt then
            hrp.CFrame=originalCFrame
            return
        end

        hrp.CFrame=flamePart.CFrame+Vector3.new(0,3,0)
        task.wait(0.3)
        firePrompt(flamePrompt)
        task.wait(0.1)

        local remote=torch:FindFirstChild("RemoteEvent",true)
        if not remote or not remote:IsA("RemoteEvent") then
            hrp.CFrame=originalCFrame
            return
        end

        local safeParts={}
        for _,obj in ipairs(Workspace:GetChildren()) do
            if obj.Name=="Part" and obj:IsA("BasePart") then
                table.insert(safeParts,obj)
            end
        end

        local demons={}
        for _,name in ipairs({"GrinDemon","GrinDemonNM"}) do
            local demon=maze:FindFirstChild(name)
            if demon and demon:IsA("Model") then table.insert(demons,demon) end
        end
        if #demons==0 then
            hrp.CFrame=originalCFrame
            return
        end

        local function getRoot(demon)
            return demon:FindFirstChild("HumanoidRootPart") or demon.PrimaryPart or demon:FindFirstChildWhichIsA("BasePart",true)
        end

        local function nearPart(pos)
            for _,part in ipairs(safeParts) do
                if (pos-part.Position).Magnitude<=30 then return true end
            end
            return false
        end

        local target,root
        while not target do
            for _,demon in ipairs(demons) do
                local r=getRoot(demon)
                if r and not nearPart(r.Position) then
                    target=demon
                    root=r
                    break
                end
            end
            if not target then task.wait(0.05) end
        end

        root=getRoot(target)
        if not root then
            hrp.CFrame=originalCFrame
            return
        end

        local targetPosition=root.Position
        local behindPosition=targetPosition-(root.CFrame.LookVector*32)

        while nearPart(behindPosition) do
            task.wait(0.05)
            root=getRoot(target)
            if not root then
                hrp.CFrame=originalCFrame
                return
            end
            targetPosition=root.Position
            behindPosition=targetPosition-(root.CFrame.LookVector*32)
        end

        local perfectAim=CFrame.lookAt(behindPosition,targetPosition,Vector3.yAxis)
        hrp.CFrame=perfectAim
        task.wait(0.2)

        pcall(function()
            remote:FireServer(perfectAim)
        end)

        task.wait(0.2)
        if hrp and hrp.Parent then
            hrp.CFrame=originalCFrame
        end
    end
})

GrinDemonStage:Button({
    Title = "Exit GrinDemon",
    Callback = function()
        local Players = game:GetService("Players")
        local TweenService = game:GetService("TweenService")
        local player = Players.LocalPlayer
        local character = player.Character or player.CharacterAdded:Wait()
        local hrp = character:WaitForChild("HumanoidRootPart")

        hrp.CFrame = CFrame.new(-326, 7, -968)
        task.wait(0.5)

        local tween = TweenService:Create(
            hrp,
            TweenInfo.new(1.3, Enum.EasingStyle.Linear),
            {CFrame = CFrame.new(-327, 7, -1115)}
        )

        tween:Play()
        tween.Completed:Wait()
    end
})

local BellStage = Window:CreateTab({
    Title = "Bell Stage",
    Icon = "bell"
})

BellStage:Button({
    Title = "Kill Flies",
    Callback = function()
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
                        hrp.CFrame = targetPart.CFrame
                        
                        local currentSword = char:FindFirstChild("Bone Sword")
                        if currentSword then
                            currentSword:Activate()
                        end
                        
                        task.wait(3)
                    end
                end
            end
        end
    end
})

local SelectedBell = nil
local BellMap = {}

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

BellStage:Dropdown({
Title = "Bells",
Values = RefreshBells(),
Default = "Select Bell",
Callback = function(value)
SelectedBell = value
end
})

BellStage:Button({
Title = "Teleport & Auto Solve",
Callback = function()
if not SelectedBell or SelectedBell == "Select Bell" then return end

RefreshBells()  
    local bell = BellMap[SelectedBell]  
    if not bell then return end  

    -- Teleport  
    local targetCFrame, prompt = GetBellTarget(bell)  
    local hrp = GetHRP()  

    if targetCFrame and hrp then  
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

    -- Listener na tuloy-tuloy lang na nakakabit sa background  
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

    -- Trigger ProximityPrompt sa simula  
    if prompt then  
        prompt.Enabled = true  
        if fireproximityprompt then  
            fireproximityprompt(prompt)  
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

        -- Maghintay habang pumarada ang mga flashes  
        repeat  
            task.wait(0.05)  
            if #currentSequence > lastRecordedCount then  
                lastRecordedCount = #currentSequence  
                quietTime = tick()  
            end  
        until (tick() - quietTime > 1.2 and #currentSequence > 0) or (tick() - startTime > 7)  

        if #currentSequence == 0 then break end  

        -- Kung Round 2 o 3 na, tanggalin ang UNANG narecord dahil kasama rito ang huling button ng lumang round  
        if round > 1 and #currentSequence > 0 then  
            table.remove(currentSequence, 1)  
        end  

        -- Kopyahin ang lilinisin na sequence para i-click  
        local roundToFire = {unpack(currentSequence)}  
        local totalButtons = #roundToFire  

        task.wait(0.2)  

        for idx, btnPart in ipairs(roundToFire) do  
            -- BAGO I-CLICK ANG HULING BUTTON: Linisin at i-reset ang recording tracker  
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

    -- Cleanup connections pagkatapos  
    for _, conn in ipairs(connections) do  
        conn:Disconnect()  
    end  
end

})

local SolvedDoors = {}
local LastValidDoor = nil

-- Helper to extract shape names from SurfaceGui
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

BellStage:Button({
    Title = "Auto Solve Door",
    Callback = function()
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

        -- 1. Search for nearest unsolved door with SurfaceGui children
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

        -- 2. Fallback to last valid door if no new doors have active SurfaceGui children
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

        -- 3. Teleport
        local targetCFrame = targetDoor.PrimaryPart and targetDoor.PrimaryPart.CFrame or targetDoor:GetPivot()
        if hrp and targetCFrame then
            hrp.CFrame = targetCFrame + Vector3.new(0, 3, 5)
        end

        -- 4. Wait 0.5s then Fire Proximity Prompt
        task.wait(0.5)

        local prompt = targetDoor:FindFirstChildWhichIsA("ProximityPrompt", true)
        if prompt then
            prompt.Enabled = true
            if fireproximityprompt then
                fireproximityprompt(prompt)
            else
                pcall(function()
                    prompt:InputHoldBegin()
                    prompt:InputHoldEnd()
                end)
            end
        end

        -- 5. Pass 1 (Remote)
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

        -- 6. Delay
        task.wait(0.5)

        -- 7. Pass 2 (Remote)
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
    end
})

BellStage:Section("Chase Stage")

BellStage:Button({
    Title = "Auto Win",
    Callback = function()
        local player = game:GetService("Players").LocalPlayer
        local char = player.Character or player.CharacterAdded:Wait()
        local hrp = char:FindFirstChild("HumanoidRootPart")

        local section2_5 = workspace:FindFirstChild("Section2.5")
        local chaseSequence = section2_5 and section2_5:FindFirstChild("ChaseSequence")
        local endChase = chaseSequence and chaseSequence:FindFirstChild("EndChase")

        if endChase and hrp then
            local targetCFrame = endChase:IsA("Model") and endChase:GetPivot() or endChase.CFrame
            hrp.CFrame = targetCFrame + Vector3.new(0, 3, 0)
        else
            warn("EndChase location not found.")
        end
    end
})

local EnzukaiTab = Window:CreateTab({
    Title = "Boat Stage",
    Icon = "sailboat"
})

-- Button: Tween to Trigger2
EnzukaiTab:Button({
    Title = "Start Enzukai",
    Callback = function()
        local player = game:GetService("Players").LocalPlayer
        local char = player.Character or player.CharacterAdded:Wait()
        local hrp = char:FindFirstChild("HumanoidRootPart")

        local section2_5 = workspace:FindFirstChild("Section2.5")
        local mindGame = section2_5 and section2_5:FindFirstChild("MindGame")
        local intro = mindGame and mindGame:FindFirstChild("Intro")
        local trigger2 = intro and intro:FindFirstChild("Trigger2")

        if trigger2 and hrp then
            local targetCFrame = trigger2:IsA("Model") and trigger2:GetPivot() or trigger2.CFrame
            local TweenService = game:GetService("TweenService")
            
            -- Calculates smooth speed based on distance
            local distance = (hrp.Position - targetCFrame.Position).Magnitude
            local tweenInfo = TweenInfo.new(distance / 50, Enum.EasingStyle.Linear)
            
            local tween = TweenService:Create(hrp, tweenInfo, {CFrame = targetCFrame})
            tween:Play()
        else
            warn("Trigger2 part not found.")
        end
    end
})

local AutoEnzukaiEnabled=false

EnzukaiTab:Toggle({
    Title="Auto Enzukai",
    Default=false,
    Callback=function(Value)
        AutoEnzukaiEnabled=Value

        if not Value then return end

        task.spawn(function()
            local Players=game:GetService("Players")
            local player=Players.LocalPlayer

            while AutoEnzukaiEnabled do
                pcall(function()
                    local section=workspace:FindFirstChild("Section2.5")
                    local mindGame=section and section:FindFirstChild("MindGame")
                    local boats=mindGame and mindGame:FindFirstChild("Boats")

                    if not boats then return end

                    for _,boat in ipairs(boats:GetChildren()) do
                        if not AutoEnzukaiEnabled then break end
                        if not boat.Parent then continue end

                        local assigned=boat:FindFirstChild("AssignedPlayer")

                        if assigned and assigned.Value==player then
                            local enzukai=boat:FindFirstChild("EnzukaiGame")

                            if enzukai then
                                local root=enzukai:FindFirstChild("RootPart")

                                if root then
                                    local attachment=
                                        root:FindFirstChild("PromptAttachment")

                                    local prompt=
                                        attachment and
                                        attachment:FindFirstChild("ProximityPrompt")

                                    if prompt and prompt.Parent then
                                        if prompt.Enabled then
                                            fireproximityprompt(prompt)
                                        end
                                    end
                                end
                            end

                            break
                        end
                    end
                end)

                task.wait(0.1)
            end
        end)
    end
})

local FatherStage = Window:CreateTab({
    Title = "Father Stage",
    Icon = "house"
})

FatherStage:Button({
    Title = "Safe Zone",
    Callback = function()
        local player = game:GetService("Players").LocalPlayer
        local character = player.Character or player.CharacterAdded:Wait()
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        hrp.CFrame = CFrame.new(1137.72, 28.66, -2401.24)
    end
})

FatherStage:Toggle({
    Title = "Anti Isamu",
    Default = false,
    Callback = function(Value)
        _G.AntiIsamu = Value

        task.spawn(function()
            while _G.AntiIsamu do
                local hitbox = workspace.Section3.IsamuAI:FindFirstChild("Hitbox")
                if hitbox and hitbox:IsA("BasePart") then
                    hitbox.CanTouch = false
                end
                task.wait(0.1)
            end

            local hitbox = workspace.Section3.IsamuAI:FindFirstChild("Hitbox")
            if hitbox and hitbox:IsA("BasePart") then
                hitbox.CanTouch = true
            end
        end)
    end
})

FatherStage:Section("Train Stage")

FatherStage:Button({
    Title = "Trigger Train",
    Callback = function()
        local Players = game:GetService("Players")
        local player = Players.LocalPlayer
        local character = player.Character or player.CharacterAdded:Wait()
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        local stage = workspace["Section3.5"]
        local crowbarSpot = stage.GrabCrowBarCutscene.crowbar
        local fence = stage.GrabCrowBarCutscene.WoodenFence
        local trainTrigger = stage.GhostTrain.TrainTrigger

        local function GetPart(obj)
            if obj:IsA("BasePart") then
                return obj
            end
            return obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart", true)
        end

        local crowbarPart = GetPart(crowbarSpot)
        local fencePart = GetPart(fence)
        local triggerPart = GetPart(trainTrigger)

        if not crowbarPart or not fencePart or not triggerPart then return end

        -- Go to Crowbar
        hrp.CFrame = crowbarPart.CFrame + Vector3.new(0, 5, 0)
        task.wait(0.3)

        -- Wait for Crowbar to appear in inventory
        local crowbar
        repeat
            crowbar = player.Backpack:FindFirstChild("Crowbar")
            if not crowbar and character then
                crowbar = character:FindFirstChild("Crowbar")
            end
            task.wait(0.1)
        until crowbar

        -- Go to Wooden Fence
        hrp.CFrame = fencePart.CFrame + Vector3.new(0, 5, 0)
        task.wait(0.3)

        -- Equip Crowbar
        if crowbar.Parent == player.Backpack then
            character.Humanoid:EquipTool(crowbar)
        end
        task.wait(0.2)

        -- Slash / click with Crowbar
        local equippedCrowbar = character:FindFirstChild("Crowbar")
        if equippedCrowbar then
            local activate = equippedCrowbar:FindFirstChildWhichIsA("RemoteEvent", true)
            local remoteFunction = equippedCrowbar:FindFirstChildWhichIsA("RemoteFunction", true)

            if activate then
                pcall(function()
                    activate:FireServer()
                end)
            elseif remoteFunction then
                pcall(function()
                    remoteFunction:InvokeServer()
                end)
            else
                pcall(function()
                    equippedCrowbar:Activate()
                end)
            end
        end

        task.wait(0.5)

        -- Go to Train Trigger
        hrp.CFrame = triggerPart.CFrame + Vector3.new(0, 5, 0)
    end
})

local LarvasTab = Window:CreateTab({
    Title = "Larvas Stage",
    Icon = "worm"
})

LarvasTab:Button({
    Title = "Auto Collect",
    Callback = function()
        local Players = game:GetService("Players")
        local player = Players.LocalPlayer
        local character = player.Character or player.CharacterAdded:Wait()
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        local section4 = workspace.Section4
        local givers = section4.HotPotato.Givers
        local dogWall = section4.DogWall

        local function GetPart(obj)
            if obj:IsA("BasePart") then
                return obj
            end
            return obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart", true)
        end

        local function GetPrompt(obj)
            return obj:FindFirstChildWhichIsA("ProximityPrompt", true)
        end

        while true do
            local dogPrompt = GetPrompt(dogWall)
            if not dogPrompt then
                break
            end

            local giverFound = false

            for _, giver in ipairs(givers:GetChildren()) do
                if giver:IsA("Model") then
                    local giverPart = GetPart(giver)
                    local giverPrompt = GetPrompt(giver)

                    if giverPart and giverPrompt then
                        giverFound = true

                        hrp.CFrame = giverPart.CFrame + Vector3.new(0, 5, 0)
                        task.wait(0.2)

                        pcall(function()
                            fireproximityprompt(giverPrompt)
                        end)

                        task.wait(0.2)

                        local currentDogPrompt = GetPrompt(dogWall)
                        if not currentDogPrompt then
                            break
                        end

                        local dogPart = GetPart(dogWall)
                        if dogPart then
                            hrp.CFrame = dogPart.CFrame + Vector3.new(0, 5, 0)
                            task.wait(0.2)

                            pcall(function()
                                fireproximityprompt(currentDogPrompt)
                            end)
                        end

                        task.wait(0.2)

                        if not GetPrompt(dogWall) then
                            break
                        end
                    end
                end
            end

            if not giverFound then
                break
            end

            task.wait(0.1)
        end
    end
})

LarvasTab:Section("Mud Stage")

LarvasTab:Button({
    Title = "Auto Win",
    Callback = function()
        local Players = game:GetService("Players")
        local player = Players.LocalPlayer
        local character = player.Character or player.CharacterAdded:Wait()
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        hrp.CFrame = CFrame.new(2406.13, 17.53, 6152.59)
    end
})


local YureiStage = Window:CreateTab({
    Title = "Yurei Stage",
    Icon = "rose"
})

local SelectedHouse = nil
local HouseMap = {}

local RomanNumerals = {
    [1] = "House I",
    [2] = "House II",
    [3] = "House III",
    [4] = "House IV",
    [5] = "House V"
}

local function RefreshHouses()
    local section5 = workspace:FindFirstChild("Section5")
    local ispy = section5 and section5:FindFirstChild("ISPY")
    local housesFolder = ispy and ispy:FindFirstChild("Houses")

    HouseMap = {}
    local values = {}

    for i = 1, 5 do
        local label = RomanNumerals[i]
        table.insert(values, label)

        if housesFolder then
            local house = housesFolder:FindFirstChild("House" .. i)
            if house then
                HouseMap[label] = house
            end
        end
    end

    return values
end

local function GetHouseTarget(house)
    local playerObj = house:FindFirstChild("Player")
    local target = playerObj and playerObj:FindFirstChild("HumanoidRootPart")

    if not target then
        target = playerObj
    end

    if not target then
        return nil
    end

    if target:IsA("BasePart") then
        return target.CFrame
    elseif target:IsA("Model") then
        return target:GetPivot()
    end

    local part = target:FindFirstChildWhichIsA("BasePart", true)
    return part and part.CFrame
end

YureiStage:Dropdown({
    Title = "Houses",
    Values = RefreshHouses(),
    Default = "Select House",
    Callback = function(value)
        SelectedHouse = value
    end
})

-- TELEPORT ONLY
YureiStage:Button({
    Title = "Teleport",
    Callback = function()
        if not SelectedHouse or SelectedHouse == "Select House" then
            return
        end

        RefreshHouses()

        local house = HouseMap[SelectedHouse]
        if not house then
            warn("House not found")
            return
        end

        local player = game:GetService("Players").LocalPlayer
        local char = player.Character or player.CharacterAdded:Wait()
        local hrp = char:FindFirstChild("HumanoidRootPart")

        if not hrp then
            return
        end

        local targetCFrame = GetHouseTarget(house)

        if not targetCFrame then
            warn("House target not found")
            return
        end

        hrp.CFrame = targetCFrame + Vector3.new(0, 3, 0)
    end
})

-- SOLVE ONLY
YureiStage:Button({
    Title = "Solve",
    Callback = function()
        if not SelectedHouse or SelectedHouse == "Select House" then
            return
        end

        RefreshHouses()

        local house = HouseMap[SelectedHouse]
        if not house then
            warn("House not found")
            return
        end

        local Players = game:GetService("Players")
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local player = Players.LocalPlayer

        local char = player.Character or player.CharacterAdded:Wait()
        local hrp = char:FindFirstChild("HumanoidRootPart")

        if not hrp then
            return
        end

        local prompt = house:FindFirstChildWhichIsA("ProximityPrompt", true)

        if not prompt then
            warn("House ProximityPrompt not found")
            return
        end

        prompt.Enabled = true

        pcall(function()
            if fireproximityprompt then
                fireproximityprompt(prompt)
            else
                prompt:InputHoldBegin()
                prompt:InputHoldEnd()
            end
        end)

        task.wait(0.5)

        local playerGui = player:WaitForChild("PlayerGui")
        local section5Gui = playerGui:WaitForChild("Section5")
        local textLabel = section5Gui:WaitForChild("TextLabel")

        repeat
            task.wait(0.1)
        until textLabel.Visible == true

        local rawText = textLabel.Text

        if not rawText or rawText == "" then
            rawText = textLabel.LocalizedText
        end

        if not rawText or rawText == "" then
            warn("No I-SPY text found")
            return
        end

        local packages = ReplicatedStorage:FindFirstChild("Packages")
        local packet = packages and packages:FindFirstChild("Packet")
        local PacketFunction = packet and packet:FindFirstChild("PacketFunction")

        if not PacketFunction then
            warn("PacketFunction not found")
            return
        end

        -- Split ONLY by comma
        for item in string.gmatch(rawText, "([^,]+)") do
            item = item:match("^%s*(.-)%s*$")

            if item and item ~= "" then
                item = item:gsub("%s+", "")

                print("Sending:", item)

                pcall(function()
                    PacketFunction:InvokeServer(0, {
                        ["__args"] = {
                            [1] = item
                        },
                        ["__tree"] = {
                            [1] = "IspyService",
                            [2] = "Clicked"
                        },
                        ["__callType"] = 0
                    })
                end)

                task.wait(0.15)
            end
        end
    end
})

YureiStage:Section("Boss Stage")

local AutoYureiEnabled=false

YureiStage:Toggle({
    Title="Auto Yurei",
    Default=false,
    Callback=function(state)
        AutoYureiEnabled=state
        if not AutoYureiEnabled then return end

        task.spawn(function()
            local Players=game:GetService("Players")
            local player=Players.LocalPlayer

            local YUREI_DISTANCE=50
            local MESH_SAFE_DISTANCE=40
            local TELEPORT_WAIT=0.1
            local SPECIAL_SAFE_CFRAME=CFrame.new(3053.23,-52.22,-430.15)
            local FALLBACK_CFRAME=CFrame.new(3162.95,17,-634.14)

            local katanaIndex=1
            local hrp

            local function GetCharacter()
                local char=player.Character or player.CharacterAdded:Wait()
                local root=char:FindFirstChild("HumanoidRootPart")
                local humanoid=char:FindFirstChildOfClass("Humanoid")
                return char,root,humanoid
            end

            local function GetKatanas()
                local katanas={}
                local backpack=player:FindFirstChild("Backpack")
                local character=player.Character

                for _,container in ipairs({backpack,character}) do
                    if container then
                        for _,tool in ipairs(container:GetChildren()) do
                            if tool:IsA("Tool") and string.find(tool.Name,"Katana") then
                                table.insert(katanas,tool)
                            end
                        end
                    end
                end

                return katanas
            end

            -- YUREI / YUREI NM
            local function GetYurei()
                local section5=workspace:FindFirstChild("Section5")
                local boss=section5 and section5:FindFirstChild("Boss")
                local monsterFolder=boss and boss:FindFirstChild("MonsterFolder")

                if not monsterFolder then
                    return nil
                end

                return monsterFolder:FindFirstChild("Yurei")
                    or monsterFolder:FindFirstChild("YureiNM")
            end

            local function GetHitbox()
                local yurei=GetYurei()
                if not yurei then return nil end

                local hitbox=yurei:FindFirstChild("YureiHitbox",true)

                if hitbox and hitbox:IsA("BasePart") then
                    return hitbox
                end

                -- Fallback for YureiNM if it has no YureiHitbox
                local fallbackHitbox=yurei:FindFirstChildWhichIsA("BasePart",true)

                return fallbackHitbox
            end

            local function GetObjectCFrame(obj)
                if not obj then return nil end

                if obj:IsA("BasePart") then
                    return obj.CFrame
                elseif obj:IsA("Model") then
                    return obj:GetPivot()
                end

                local part=obj:FindFirstChildWhichIsA("BasePart",true)
                return part and part.CFrame
            end

            local function GetObjectPosition(obj)
                local cf=GetObjectCFrame(obj)
                return cf and cf.Position
            end

            local function GetObjectTransparency(obj)
                if not obj then return 1 end

                if obj:IsA("BasePart") then
                    return obj.Transparency
                end

                local part=obj:FindFirstChildWhichIsA("BasePart",true)

                if part then
                    return part.Transparency
                end

                return 1
            end

            local function IsGrowSFXPlaying()
                local section5=workspace:FindFirstChild("Section5")
                local boss=section5 and section5:FindFirstChild("Boss")
                local healTree=boss and boss:FindFirstChild("HealTree")
                local tree=healTree and healTree:FindFirstChild("Tree")
                local growSFX=tree and tree:FindFirstChild("GrowSFX")

                if growSFX and growSFX:IsA("Sound") then
                    return growSFX.IsPlaying
                end

                return false
            end

            -- SPECIAL ATTACK
            local function GetDangerousAttackParts()
                local section5=workspace:FindFirstChild("Section5")
                local boss=section5 and section5:FindFirstChild("Boss")
                local attack=boss and boss:FindFirstChild("SpecialAttack1")

                if not attack then
                    return {}
                end

                local parts={}

                for _,obj in ipairs(attack:GetDescendants()) do
                    if obj:IsA("BasePart") and obj:FindFirstChild("TouchInterest") then
                        table.insert(parts,obj)
                    end
                end

                return parts
            end

            local function HandleSpecialAttack()
                local parts=GetDangerousAttackParts()

                if #parts>0 then
                    if hrp and hrp.Parent then
                        hrp.CFrame=SPECIAL_SAFE_CFRAME
                        hrp.Anchored=true
                    end
                else
                    if hrp and hrp.Parent then
                        hrp.Anchored=false
                    end
                end
            end

            -- HEALTREE PRIORITY
            local function GetPriorityTarget()
                local section5=workspace:FindFirstChild("Section5")
                local boss=section5 and section5:FindFirstChild("Boss")
                local healTree=boss and boss:FindFirstChild("HealTree")

                if healTree then
                    local treeMax=healTree:FindFirstChild("TreeMax")
                    local treeMin=healTree:FindFirstChild("TreeMin")

                    if treeMin then
                        local treeMaxVisible=false

                        if treeMax then
                            treeMaxVisible=GetObjectTransparency(treeMax)==0
                        end

                        local growPlaying=IsGrowSFXPlaying()

                        if treeMaxVisible or growPlaying then
                            local treeMinPosition=GetObjectPosition(treeMin)

                            if treeMinPosition then
                                return treeMinPosition,"TreeMin"
                            end
                        end
                    end
                end

                local hitbox=GetHitbox()

                if hitbox then
                    return hitbox.Position,"YureiHitbox"
                end

                return nil,nil
            end

            -- YUREI POSITION
            local function GetYureiPosition()
                local yurei=GetYurei()

                if not yurei then
                    return nil
                end

                if yurei:IsA("Model") then
                    return yurei:GetBoundingBox().Position
                end

                return GetObjectPosition(yurei)
            end

            -- KATANA SAFETY
            local function IsKatanaNearYurei(position)
                local yureiPosition=GetYureiPosition()

                if not yureiPosition then
                    return false
                end

                return (position-yureiPosition).Magnitude<=MESH_SAFE_DISTANCE
            end

            local function IsVisibleKatana(obj)
                if not obj then
                    return false
                end

                if obj:IsA("BasePart") then
                    return obj.Transparency<1
                end

                local part=obj:FindFirstChildWhichIsA("BasePart",true)

                if part then
                    return part.Transparency<1
                end

                return true
            end

            local function GetKatanaPrompt(katana)
                if not katana then
                    return nil
                end

                return katana:FindFirstChildWhichIsA(
                    "ProximityPrompt",
                    true
                )
            end

            local function FirePrompt(prompt)
                if not prompt or not prompt.Parent then
                    return false
                end

                pcall(function()
                    prompt.Enabled=true
                end)

                if fireproximityprompt then
                    pcall(function()
                        fireproximityprompt(prompt)
                    end)

                    return true
                end

                pcall(function()
                    prompt:InputHoldBegin()
                    prompt:InputHoldEnd()
                end)

                return true
            end

            -- PERFECT AIM
            local function PriorityAim(targetPosition)
                local yurei=GetYurei()

                if not yurei or not targetPosition or not hrp then
                    return nil
                end

                local modelPosition

                if yurei:IsA("Model") then
                    modelPosition=yurei:GetBoundingBox().Position
                else
                    modelPosition=GetObjectPosition(yurei)
                end

                if not modelPosition then
                    return nil
                end

                local direction=hrp.Position-modelPosition

                if direction.Magnitude<0.01 then
                    direction=Vector3.new(0,0,-1)
                else
                    direction=direction.Unit
                end

                local safePosition=
                    modelPosition+
                    direction*YUREI_DISTANCE

                safePosition=Vector3.new(
                    safePosition.X,
                    hrp.Position.Y,
                    safePosition.Z
                )

                local aimPosition=Vector3.new(
                    targetPosition.X,
                    safePosition.Y,
                    targetPosition.Z
                )

                local perfectAim=CFrame.lookAt(
                    safePosition,
                    aimPosition,
                    Vector3.yAxis
                )

                hrp.CFrame=perfectAim

                return perfectAim
            end

            -- KATANA ORDER
            local function GetNextValidMesh(folder)
                local meshes=folder:GetChildren()

                if #meshes==0 then
                    return nil
                end

                if katanaIndex>#meshes then
                    katanaIndex=1
                end

                local checked=0

                while checked<#meshes do
                    local candidate=meshes[katanaIndex]

                    katanaIndex+=1

                    if katanaIndex>#meshes then
                        katanaIndex=1
                    end

                    checked+=1

                    if candidate and candidate.Parent then
                        if IsVisibleKatana(candidate) then
                            local cf=GetObjectCFrame(candidate)

                            if cf and not IsKatanaNearYurei(cf.Position) then
                                local prompt=GetKatanaPrompt(candidate)

                                if prompt then
                                    return candidate,cf,prompt
                                end
                            end
                        end
                    end
                end

                return nil
            end

            while AutoYureiEnabled do
                local char,newHrp,humanoid=GetCharacter()

                hrp=newHrp

                if not hrp or not humanoid then
                    task.wait(0.1)
                    continue
                end

                -- SPECIAL ATTACK HAS HIGHEST PRIORITY
                HandleSpecialAttack()

                if not AutoYureiEnabled then
                    break
                end

                if hrp.Anchored then
                    task.wait(0.03)
                    continue
                end

                local katanas=GetKatanas()

                -- KATANA COLLECTION
                if #katanas<3 then
                    local section5=workspace:FindFirstChild("Section5")
                    local boss=section5 and section5:FindFirstChild("Boss")
                    local folder=boss and boss:FindFirstChild("Katanas")

                    if folder then
                        local katana,katanaCFrame,prompt=
                            GetNextValidMesh(folder)

                        if katana and katanaCFrame and prompt then
                            if #GetDangerousAttackParts()>0 then
                                task.wait(0.03)
                                continue
                            end

                            hrp.CFrame=katanaCFrame

                            task.wait(TELEPORT_WAIT)

                            if #GetDangerousAttackParts()>0 then
                                task.wait(0.03)
                                continue
                            end

                            FirePrompt(prompt)

                            task.wait(0.05)
                        else
                            hrp.CFrame=FALLBACK_CFRAME
                            task.wait(0.05)
                        end
                    else
                        task.wait(0.1)
                    end

                -- YUREI ATTACK
                else
                    local yurei=GetYurei()
                    local hitbox=GetHitbox()

                    if yurei and hitbox then
                        for _,katana in ipairs(katanas) do
                            if not AutoYureiEnabled then
                                break
                            end

                            HandleSpecialAttack()

                            if not AutoYureiEnabled or hrp.Anchored then
                                break
                            end

                            if katana and katana.Parent then
                                humanoid:EquipTool(katana)

                                task.wait(0.03)

                                local remote=
                                    katana:FindFirstChildWhichIsA(
                                        "RemoteEvent",
                                        true
                                    )

                                if not remote then
                                    local equipped=
                                        char:FindFirstChild("Katana")

                                    if equipped then
                                        remote=
                                            equipped:FindFirstChildWhichIsA(
                                                "RemoteEvent",
                                                true
                                            )
                                    end
                                end

                                if remote then
                                    HandleSpecialAttack()

                                    if not AutoYureiEnabled or hrp.Anchored then
                                        break
                                    end

                                    local targetPosition,targetType=
                                        GetPriorityTarget()

                                    if targetPosition then
                                        local perfectAim=
                                            PriorityAim(targetPosition)

                                        if perfectAim then
                                            pcall(function()
                                                remote:FireServer(perfectAim)
                                            end)
                                        end
                                    end
                                end

                                task.wait(0.03)
                            end
                        end
                    else
                        task.wait(0.1)
                    end
                end

                task.wait(0.05)
            end

            if hrp and hrp.Parent then
                hrp.Anchored=false
            end
        end)
    end
})

YureiStage:Button({
    Title="Enter Tree Door",
    Callback=function()
        local player=game:GetService("Players").LocalPlayer
        local character=player.Character or player.CharacterAdded:Wait()
        local hrp=character:FindFirstChild("HumanoidRootPart")

        local portal=workspace.Section5.Boss.DeathAnimation.TreePortal.Part

        if not hrp or not portal then
            return
        end

        local prompt=portal:FindFirstChildWhichIsA("ProximityPrompt",true)

        if not prompt then
            return
        end

        hrp.CFrame=portal.CFrame
        task.wait(0.1)

        pcall(function()
            prompt.Enabled=true
            fireproximityprompt(prompt)
        end)
    end
})

local FinalStage=Window:CreateTab({
    Title="Final Stage",
    Icon="18743892922"
})

FinalStage:Button({
    Title="Start Cutscene",
    Callback=function()
        local player=game:GetService("Players").LocalPlayer
        local character=player.Character or player.CharacterAdded:Wait()
        local hrp=character:FindFirstChild("HumanoidRootPart")
        local target=workspace.Section6:FindFirstChild("TriggerCutscene")

        if hrp and target then
            if target:IsA("BasePart") then
                hrp.CFrame=target.CFrame
            elseif target:IsA("Model") then
                hrp.CFrame=target:GetPivot()
            end
        end
    end
})

FinalStage:Button({
    Title="Auto Win",
    Callback=function()
        local player=game:GetService("Players").LocalPlayer
        local character=player.Character or player.CharacterAdded:Wait()
        local hrp=character:FindFirstChild("HumanoidRootPart")

        if hrp then
            hrp.CFrame=CFrame.new(-1701, 88, 7782)
        end
    end
})
