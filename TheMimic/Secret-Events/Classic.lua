local KazeUI = KazeUI or loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/KazeHub/UI/refs/heads/main/libraryUI.txt"
))()

local Window = KazeUI:CreateWindow({
    Title = "THE MIMIC CLASSIC",
    Author = "KAZE",
    Version = "CLASSIC",
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
            tpWalkConnection = RunService.RenderStepped:Connect(function(dt)
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

local GameTab = Window:CreateTab({
    Title = "Game",
    Icon = "gamepad-2"
})

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

--// === SERVICES (UNC) ===
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")

local player = Players.LocalPlayer

--// === SAFE TELEPORT & TWEEN HELPERS ===
local function SafeTeleport(hrp, pos)
    if not hrp then return end
    hrp.Anchored = true
    hrp.CFrame = CFrame.new(pos + Vector3.new(0, 5, 0))
    hrp.Velocity = Vector3.zero
    hrp.AssemblyLinearVelocity = Vector3.zero
    task.wait(0.15)
    hrp.Anchored = false
end

local function SafeTween(hrp, pos)
    if not hrp then return end
    hrp.Anchored = true
    TweenService:Create(
        hrp,
        TweenInfo.new(2.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
        { CFrame = CFrame.new(pos + Vector3.new(0, 5, 0)) }
    ):Play()
    task.wait(2.6)
    hrp.Anchored = false
end

--------------------------------------------------
-- TABS CREATION
--------------------------------------------------
local Control1 = Window:CreateTab({ Title = "Control 1", Icon = "Book" })
local Control2 = Window:CreateTab({ Title = "Control 2", Icon = "Book" })
local Control3 = Window:CreateTab({ Title = "Control 3", Icon = "Book" })

--------------------------------------------------
-- CONTROL 1 TAB
--------------------------------------------------

Control1:Section("The House of Death Stage")

Control1:Button({
    Title = "Auto Win",
    Callback = function()
        local character = player.Character or player.CharacterAdded:Wait()
        local hrp = character:WaitForChild("HumanoidRootPart")
        local tp = Workspace:FindFirstChild("Game Teleporter")

        if tp then
            task.wait(0.75)
            SafeTeleport(hrp, tp.Position)
        end
    end
})

Control1:Section("Hotel Stage")

Control1:Button({
    Title = "Auto Win",
    Callback = function()
        local character = player.Character or player.CharacterAdded:Wait()
        local hrp = character:WaitForChild("HumanoidRootPart")

        local platform = workspace:FindFirstChild("Platform")

        if platform then
            -- Safely pivot/teleport to the target platform position
            hrp.CFrame = platform.CFrame + Vector3.new(0, 5, 0)
        end
    end
})


--------------------------------------------------
-- CONTROL 2 TAB
--------------------------------------------------
Control2:Section("Imperial Palace Stage")

Control2:Button({
    Title = "Auto Win",
    Callback = function()
        local character = player.Character or player.CharacterAdded:Wait()
        local hrp = character:WaitForChild("HumanoidRootPart")
        local tp = Workspace:FindFirstChild("Game Teleporter")

        if tp then
            task.wait(0.25)
            SafeTeleport(hrp, tp.Position)
        end
    end
})

Control2:Section("Realm of the Forgotten Stage")

Control2:Button({
    Title = "Auto Win",
    Callback = function()
        local character = player.Character or player.CharacterAdded:Wait()
        local hrp = character:WaitForChild("HumanoidRootPart")
        local tp = Workspace:FindFirstChild("Game Teleporter")

        if tp then
            task.wait(0.25)
            SafeTeleport(hrp, tp.Position)
        end
    end
})

Control2:Section("Labyrinth Stage")

local TweenService = game:GetService("TweenService")

Control2:Button({
    Title = "Auto Win",
    Callback = function()
        local character = player.Character or player.CharacterAdded:Wait()
        local hrp = character:WaitForChild("HumanoidRootPart")

        -- 1. Initial teleport
        SafeTeleport(hrp, Vector3.new(881, 73, -354))

        -- 2. Delay
        task.wait(0.5)

        -- 3. Smooth tween to target coordinates
        local targetCFrame = CFrame.new(1143, 84, -351)
        local tweenInfo = TweenInfo.new(
            2.5, -- Duration in seconds (adjust if you want it faster or slower)
            Enum.EasingStyle.Sine,
            Enum.EasingDirection.Out
        )

        local tween = TweenService:Create(hrp, tweenInfo, { CFrame = targetCFrame })
        tween:Play()
    end
})



--------------------------------------------------
-- CONTROL 3 TAB
--------------------------------------------------
Control3:Section("The Looping Minka Stage")

Control3:Button({
    Title = "Auto Win",
    Callback = function()
        local character = player.Character or player.CharacterAdded:Wait()
        local hrp = character:WaitForChild("HumanoidRootPart")
        local tp = Workspace:FindFirstChild("Game Teleporter")

        if tp then
            task.wait(0.25)
            SafeTeleport(hrp, tp.Position)
        end
    end
})

Control3:Section("The Sakura Swamp Stage")

Control3:Button({
    Title = "Auto Win",
    Callback = function()
        local character = player.Character or player.CharacterAdded:Wait()
        local hrp = character:WaitForChild("HumanoidRootPart")
        local tp = Workspace:FindFirstChild("Game Teleporter")

        if tp then
            task.wait(0.25)
            SafeTeleport(hrp, tp.Position)
        end
    end
})

Control3:Section("The Indigent Family's Minka Stage")

Control3:Button({
    Title = "Auto Win",
    Callback = function()
        local character = player.Character or player.CharacterAdded:Wait()
        local hrp = character:WaitForChild("HumanoidRootPart")

        -- Target coordinates
        local initialPos = Vector3.new(255.908203125, 17.105751037597656, -315.80157470703125)
        local checkPos = Vector3.new(445, 16, -718)
        local finalPos = Vector3.new(430.96466064453125, 17.80474090576172, -844.690185546875)

        -- Step 1: Initial teleport
        SafeTeleport(hrp, initialPos)

        -- Step 2: Wait until the player is within 20 units of checkPos
        repeat 
            task.wait(0.1)
        until (hrp.Position - checkPos).Magnitude < 20

        -- Step 3: Wait 0.5 seconds then tween to final position
        task.wait(0.5)
        
        if typeof(SafeTween) == "function" then
            SafeTween(hrp, finalPos)
        else
            -- Fallback smooth tween if SafeTween isn't defined in your script environment
            local TweenService = game:GetService("TweenService")
            local tweenInfo = TweenInfo.new(2.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
            local tween = TweenService:Create(hrp, tweenInfo, { CFrame = CFrame.new(finalPos) })
            tween:Play()
        end
    end
})
