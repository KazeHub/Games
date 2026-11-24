local KazeUI = KazeUI or loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/KazeHub/UI/refs/heads/main/UILibrary.lua.txt"
))()

local Window = KazeUI:CreateWindow({
    Title = "SQUID GAME X",
    Author = "KAZE",
    Version = "GAME",
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

local GameMain = GameTab:CreateSubTab({ Title = "Main", Icon = "gamepad-2", Default = false })

local autoPickupEnabled = false
local pickupConnection = nil
local pickupDebounce = false

GameMain:Toggle({
    Title = "Auto Pick Up Baby", Default = false,
    Callback = function(state)
        autoPickupEnabled = state
        if pickupConnection then pickupConnection:Disconnect() pickupConnection = nil end
        if not autoPickupEnabled then return end

        pickupConnection = RunService.Heartbeat:Connect(function()
            if not autoPickupEnabled or pickupDebounce then return end
            
            local char = LocalPlayer.Character
            if not char then return end

            if char:FindFirstChild("Baby", true) then return end

            for _, model in ipairs(Workspace:GetChildren()) do
                if model.Name == "BabyPickup" then
                    local prompt = model:FindFirstChild("PickupPrompt", true)
                    if prompt and prompt.Enabled then
                        pickupDebounce = true
                        
                        pcall(function()
                            if fireproximityprompt then
                                fireproximityprompt(prompt)
                            else
                                prompt:InputHoldBegin()
                                task.wait(prompt.HoldDuration + 0.05)
                                prompt:InputHoldEnd()
                            end
                        end)
                        
                        task.wait(1)
                        pickupDebounce = false
                        break
                    end
                end
            end
        end)
    end
})

local CombatTab = Window:CreateTab({ Title = "Combat", Icon = "crosshair" })
local CombatWeapons = CombatTab:CreateSubTab({ Title = "Weapons", Icon = "sword", Default = true })
local CombatGun = CombatTab:CreateSubTab({ Title = "Gun", Icon = "crosshair", Default = false })
local CombatHitbox = CombatTab:CreateSubTab({ Title = "Hitbox", Icon = "box", Default = false })

local function createAutoSlashToggle(toolName, title)
    local enabled = false
    local conn = nil
    local lastSlash = 0
    local delay = 0.15

    CombatWeapons:Toggle({
        Title = title,
        Default = false,
        Callback = function(state)
            enabled = state
            if conn then
                conn:Disconnect()
                conn = nil
            end

            if enabled then
                conn = RunService.Heartbeat:Connect(function()
                    if not enabled then return end
                    if tick() - lastSlash < delay then return end
                    lastSlash = tick()

                    local char = LocalPlayer.Character
                    if not char then return end
                    
                    local tool = char:FindFirstChild(toolName)
                    if tool then
                        pcall(function()
                            tool:Activate()
                        end)
                    end
                end)
            end
        end
    })
end

createAutoSlashToggle("Fork", "Auto Attack (Fork)")
createAutoSlashToggle("Knife", "Auto Attack (Knife)")
createAutoSlashToggle("Slap", "Auto Attack (Punch)")

local currentRange = 25
CombatGun:Slider({
    Title = "Combat Range",
    Min = 0,
    Max = 1000,
    Default = 25,
    Callback = function(v)
        currentRange = v
    end
})

-- ==========================================
-- NEW: SAFE PLAYERS DROPDOWN
-- ==========================================
local SafePlayers = {} -- Table para i-store ang mga pangalan ng safe players

CombatGun:BoxDropdown({
    Title = "Whitelisted (Safe from Aura)", -- Mas creative na title
    SearchBar = true,
    PlayerList = true,
    Multi = true,
    Callback = function(list)
        local set = {}
        if type(list) == "table" then
            for _, name in ipairs(list) do
                set[name] = true
            end
        end
        SafePlayers = set
    end
})

-- ==========================================
-- AURA KILL (Updated with Safe Players)
-- ==========================================
local auraKillActive = false
local auraKillConn = nil

CombatGun:Toggle({
    Title = "Aura Kill",
    Default = false,
    Callback = function(state)
        auraKillActive = state
        if auraKillConn then auraKillConn:Disconnect() auraKillConn = nil end
        
        if not auraKillActive then return end

        auraKillConn = RunService.Heartbeat:Connect(function()
            if not auraKillActive then return end
            
            local player = game:GetService("Players").LocalPlayer
            local char = player.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end

            local backpack = player:FindFirstChild("Backpack")
            local weapon = char:FindFirstChildWhichIsA("Tool") 
                        or (backpack and backpack:FindFirstChild("MPS-5")) 
                        or (backpack and backpack:FindFirstChildWhichIsA("Tool"))

            if not weapon then return end

            local rs = game:GetService("ReplicatedStorage")
            local weaponFired = rs:FindFirstChild("Local") 
                and rs.Local:FindFirstChild("GunSystem") 
                and rs.Local.GunSystem:FindFirstChild("Network") 
                and rs.Local.GunSystem.Network:FindFirstChild("WeaponFired")
                
            local weaponHit = rs:FindFirstChild("Local") 
                and rs.Local:FindFirstChild("GunSystem") 
                and rs.Local.GunSystem:FindFirstChild("Network") 
                and rs.Local.GunSystem.Network:FindFirstChild("WeaponHit")

            if not weaponFired or not weaponHit then return end

            for _, target in ipairs(game:GetService("Players"):GetPlayers()) do
                -- CHECK KUNG SAFE ANG PLAYER
                if target ~= player and target.Character and not SafePlayers[target.Name] then
                    local tChar = target.Character
                    local tHrp = tChar:FindFirstChild("HumanoidRootPart")
                    local tHumanoid = tChar:FindFirstChildOfClass("Humanoid")
                    local tTorso = tChar:FindFirstChild("UpperTorso") or tChar:FindFirstChild("Torso")
                    
                    if tHrp and tHumanoid and tHumanoid.Health > 0 and tTorso then
                        local dist = (tHrp.Position - hrp.Position).Magnitude
                        if dist <= currentRange then
                            pcall(function()
                                weaponFired:FireServer(
                                    weapon,
                                    {
                                        tHrp.Position,
                                        Vector3.new(0, 0, -1),
                                        Vector2.new(0, 1)
                                    }
                                )
                                
                                weaponHit:FireServer(
                                    weapon,
                                    {
                                        p = tTorso.Position,
                                        pid = 1,
                                        part = tTorso,
                                        d = dist,
                                        maxDist = dist,
                                        h = tHumanoid,
                                        m = Enum.Material.Plastic,
                                        n = Vector3.new(0, 1, 0),
                                        t = 0.42185773238282009,
                                        sid = 1
                                    }
                                )
                            end)
                        end
                    end
                end
            end
        end)
    end
})

CombatGun:Section("Guns")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = game:GetService("Players").LocalPlayer

local Shared = ReplicatedStorage:WaitForChild("Shared", 5)
local WeaponsFolder = Shared and Shared:WaitForChild("Weapons", 5)

local SelectedWeapon = nil
local ClonedWeapons = setmetatable({}, {__mode = "k"}) -- Table para i-track ang mga clone

local function GetWeaponOptions()
    local options = {}
    if WeaponsFolder then
        for _, tool in ipairs(WeaponsFolder:GetChildren()) do
            if tool:IsA("Tool") then
                table.insert(options, { Text = tool.Name, Tool = tool })
            end
        end
    end
    return options
end

CombatGun:BoxDropdown({
    Title = "Select Weapon",
    SearchBar = true,
    Options = GetWeaponOptions(),
    Default = "Select Weapon",
    Callback = function(selected)
        SelectedWeapon = selected
    end
})

CombatGun:Button({
    Title = "Take Gun",
    Callback = function()
        if not SelectedWeapon or SelectedWeapon == "Select Weapon" then return end

        task.spawn(function()
            local weapon = WeaponsFolder and WeaponsFolder:FindFirstChild(SelectedWeapon)
            
            if weapon and weapon:IsA("Tool") then
                local backpack = LocalPlayer:FindFirstChild("Backpack")
                if backpack then
                    local clonedWeapon = weapon:Clone()
                    ClonedWeapons[clonedWeapon] = true -- I-track ang clone
                    clonedWeapon.Parent = backpack
                end
            end
        end)
    end
})

CombatGun:Button({
    Title = "Delete Equipped Gun",
    Callback = function()
        task.spawn(function()
            local char = LocalPlayer.Character
            if not char then return end

            for _, tool in ipairs(char:GetChildren()) do
                if tool:IsA("Tool") then
                    -- I-delete lang kung ito ay galing sa ating clone
                    if ClonedWeapons[tool] then
                        tool:Destroy()
                        ClonedWeapons[tool] = nil
                    end
                end
            end
        end)
    end
})

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local HitboxConfig = {
    Names = {},
    Size = 10,
    SelectedPlayer = false,
    Player = false,
    Guard = false,
    Detective = false,
    Frontman = false,
    BabyCarrier = false,
    Glassmaker = false
}

local OriginalProperties = setmetatable({}, {__mode = "k"})
local updateAccumulator = 0

local function ValidName(name)
    if type(name) ~= "string" then return false end
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Name == name then return true end
    end
    return false
end

local function HitboxRestore(root)
    local original = OriginalProperties[root]
    if not original then return end
    if root.Parent then
        root.Size = original.Size
        root.Transparency = original.Transparency
        root.Color = original.Color
        root.Material = original.Material
        root.CanCollide = original.CanCollide
    end
    OriginalProperties[root] = nil
end

local function HitboxRestoreAll()
    for root in pairs(OriginalProperties) do
        HitboxRestore(root)
    end
end

local function GetHitboxType(player, character)
    local teamName = player.Team and player.Team.Name or "NoTeam"
    if character:FindFirstChild("BabyBack", true) then return "BabyCarrier" end
    if player:GetAttribute("IsFrontman") or teamName == "Frontman" then return "Frontman" end
    if character:FindFirstChild("Glassmaker", true) then return "Glassmaker" end
    if teamName == "Guard" then return "Guard" end
    if teamName == "Detective" then return "Detective" end
    if teamName == "Player" then return "Player" end
end

local function UpdateHitbox(player)
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")

    if not root or not humanoid then
        return
    end

    -- Kung patay na, wag muna i-restore kasi mag-rerespawn naman at magbabago ng character
    if humanoid.Health <= 0 then
        if root then HitboxRestore(root) end
        return
    end

    local hitboxType = GetHitboxType(player, character)
    local selectedEnabled = HitboxConfig.SelectedPlayer and HitboxConfig.Names[player.Name]
    local categoryEnabled = hitboxType and HitboxConfig[hitboxType]
    local enabled = selectedEnabled or categoryEnabled

    if not enabled then
        HitboxRestore(root)
        return
    end

    if not OriginalProperties[root] then
        OriginalProperties[root] = {
            Size = root.Size,
            Transparency = root.Transparency,
            Color = root.Color,
            Material = root.Material,
            CanCollide = root.CanCollide
        }
    end

    -- Transparency 0.3 as requested
    root.Size = Vector3.new(HitboxConfig.Size, HitboxConfig.Size, HitboxConfig.Size)
    root.Transparency = 0.3
    root.Color = Color3.fromRGB(0, 100, 255)
    root.Material = Enum.Material.Neon
    root.CanCollide = false
end

CombatHitbox:BoxDropdown({
    Title = "Select Players for Hitbox",
    SearchBar = true,
    PlayerList = true,
    Multi = true,
    Callback = function(list)
        local set = {}
        if type(list) == "table" then
            for _, name in ipairs(list) do
                if ValidName(name) then
                    set[name] = true
                end
            end
        end
        HitboxConfig.Names = set
    end
})

CombatHitbox:Toggle({
    Title = "Hitbox Selected Player",
    Default = false,
    Callback = function(state)
        HitboxConfig.SelectedPlayer = state
        if not state then
            for root in pairs(OriginalProperties) do
                local char = root.Parent
                if char then
                    local plr = Players:GetPlayerFromCharacter(char)
                    if plr and HitboxConfig.Names[plr.Name] then
                        HitboxRestore(root)
                    end
                end
            end
        end
    end
})

CombatHitbox:Slider({
    Title = "Hitbox Size",
    Min = 10,
    Max = 1000,
    Default = 10,
    Callback = function(value)
        HitboxConfig.Size = math.clamp(value, 10, 1000)
    end
})

local function AddHitboxToggle(title, key)
    CombatHitbox:Toggle({
        Title = title,
        Default = false,
        Callback = function(state)
            HitboxConfig[key] = state
            if not state then
                for root in pairs(OriginalProperties) do
                    local char = root.Parent
                    if char then
                        local plr = Players:GetPlayerFromCharacter(char)
                        if plr and GetHitboxType(plr, char) == key then
                            HitboxRestore(root)
                        end
                    end
                end
            end
        end
    })
end

AddHitboxToggle("Hitbox Player", "Player")
AddHitboxToggle("Hitbox Guard", "Guard")
AddHitboxToggle("Hitbox Detective", "Detective")
AddHitboxToggle("Hitbox Frontman", "Frontman")
AddHitboxToggle("Hitbox Baby Carrier", "BabyCarrier")
AddHitboxToggle("Hitbox Glassmaker", "Glassmaker")

-- Para agad mag-apply pag nag-respawn
Players.PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Connect(function(char)
        task.wait(0.1) -- wait for HumanoidRootPart to load
        if char:FindFirstChild("HumanoidRootPart") then
            UpdateHitbox(plr)
        end
    end)
end)

LocalPlayer.CharacterAdded:Connect(function()
    -- Optional: Refresh lahat pag nag-respawn ka
end)

RunService.Heartbeat:Connect(function(dt)
    if not HitboxConfig.SelectedPlayer and not HitboxConfig.Player and not HitboxConfig.Guard and not HitboxConfig.Detective and not HitboxConfig.Frontman and not HitboxConfig.BabyCarrier and not HitboxConfig.Glassmaker then
        if next(OriginalProperties) then
            HitboxRestoreAll()
        end
        return
    end

    updateAccumulator += dt
    if updateAccumulator < 0.2 then return end
    updateAccumulator = 0

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            UpdateHitbox(player)
        end
    end

    for root in pairs(OriginalProperties) do
        if not root.Parent then
            OriginalProperties[root] = nil
        end
    end
end)

Players.PlayerRemoving:Connect(function(player)
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if root then HitboxRestore(root) end
end)

local ESPTab = Window:CreateTab({ Title = "ESP", Icon = "eye" })
local ESPMain = ESPTab:CreateSubTab({ Title = "Main", Icon = "users", Default = true })

local ESPConfig = { Player = false, Guard = false, Detective = false, Frontman = false, BabyCarrier = false, Glassmaker = false }

local ESPColors = {
    Player = Color3.fromRGB(255, 255, 255),
    Guard = Color3.fromRGB(255, 105, 180),
    Detective = Color3.fromRGB(255, 215, 0),
    Frontman = Color3.fromRGB(255, 0, 255),
    BabyCarrier = Color3.fromRGB(255, 215, 0),
    Glassmaker = Color3.fromRGB(255, 215, 0)
}

local ESPMode = "Original"

local activeHighlights = setmetatable({}, {__mode = "k"})
local activeBillboards = setmetatable({}, {__mode = "k"})
local updateAccumulator = 0

local function clearAllESP()
    for char, hls in pairs(activeHighlights) do
        for espType, hl in pairs(hls) do
            hl:Destroy()
        end
    end
    for char, bbs in pairs(activeBillboards) do
        for espType, bb in pairs(bbs) do
            bb:Destroy()
        end
    end
    table.clear(activeHighlights)
    table.clear(activeBillboards)
end

local function clearESPType(espType)
    for char, hls in pairs(activeHighlights) do
        if hls[espType] then
            hls[espType]:Destroy()
            hls[espType] = nil
        end
    end
    for char, bbs in pairs(activeBillboards) do
        if bbs[espType] then
            bbs[espType]:Destroy()
            bbs[espType] = nil
        end
    end
end

local ESPConfigSection = ESPMain:SectionUI({ Title = "ESP Settings", Open = true })

ESPConfigSection:Dropdown({
    Title = "ESP Mode",
    Default = "Original",
    Options = { "Original", "Better" },
    Callback = function(value)
        ESPMode = value
        clearAllESP()
    end
})

ESPConfigSection:ColorPicker({
    Title = "Player Color", Default = ESPColors.Player,
    Callback = function(color) ESPColors.Player = color end
})
ESPConfigSection:ColorPicker({
    Title = "Guard Color", Default = ESPColors.Guard,
    Callback = function(color) ESPColors.Guard = color end
})
ESPConfigSection:ColorPicker({
    Title = "Detective Color", Default = ESPColors.Detective,
    Callback = function(color) ESPColors.Detective = color end
})
ESPConfigSection:ColorPicker({
    Title = "Frontman Color", Default = ESPColors.Frontman,
    Callback = function(color) ESPColors.Frontman = color end
})
ESPConfigSection:ColorPicker({
    Title = "Baby Carrier Color", Default = ESPColors.BabyCarrier,
    Callback = function(color) ESPColors.BabyCarrier = color end
})
ESPConfigSection:ColorPicker({
    Title = "Glassmaker Color", Default = ESPColors.Glassmaker,
    Callback = function(color) ESPColors.Glassmaker = color end
})

ESPMain:Toggle({
    Title = "ESP Player", Default = false,
    Callback = function(state) 
        ESPConfig.Player = state
        if not state then clearESPType("Player") end
    end
})

ESPMain:Toggle({
    Title = "ESP Guard", Default = false,
    Callback = function(state) 
        ESPConfig.Guard = state
        if not state then clearESPType("Guard") end
    end
})

ESPMain:Toggle({
    Title = "ESP Detective", Default = false,
    Callback = function(state) 
        ESPConfig.Detective = state
        if not state then clearESPType("Detective") end
    end
})

ESPMain:Toggle({
    Title = "ESP Frontman", Default = false,
    Callback = function(state) 
        ESPConfig.Frontman = state
        if not state then clearESPType("Frontman") end
    end
})

ESPMain:Toggle({
    Title = "ESP Baby Carrier", Default = false,
    Callback = function(state) 
        ESPConfig.BabyCarrier = state
        if not state then clearESPType("BabyCarrier") end
    end
})

ESPMain:Toggle({
    Title = "ESP Glassmaker", Default = false,
    Callback = function(state) 
        ESPConfig.Glassmaker = state
        if not state then clearESPType("Glassmaker") end
    end
})

RunService.Heartbeat:Connect(function(dt)
    if not ESPConfig.Player and not ESPConfig.Guard and not ESPConfig.Detective and not ESPConfig.Frontman and not ESPConfig.BabyCarrier and not ESPConfig.Glassmaker then 
        return 
    end
    
    updateAccumulator = updateAccumulator + dt
    if updateAccumulator < 0.2 then return end
    updateAccumulator = 0

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local char = plr.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                local root = char.HumanoidRootPart
                local hum = char:FindFirstChildOfClass("Humanoid")
                
                local teamName = plr.Team and plr.Team.Name or "NoTeam"
                local isPlayerTeam = (teamName == "Player")
                local isGuard = (teamName == "Guard")
                local isDetective = (teamName == "Detective")
                local isFrontman = plr:GetAttribute("IsFrontman") or (teamName == "Frontman")
                local babyBack = char:FindFirstChild("BabyBack", true)
                local glassmaker = char:FindFirstChild("Glassmaker", true)
                
                activeHighlights[char] = activeHighlights[char] or {}
                activeBillboards[char] = activeBillboards[char] or {}

                local function updateESP(espType, enabled, labelText)
                    local color = ESPColors[espType]
                    
                    if enabled then
                        if not activeHighlights[char][espType] or not activeHighlights[char][espType].Parent then
                            local hl = Instance.new("Highlight")
                            hl.Name = espType .. "ESP"
                            hl.FillColor = color; hl.OutlineColor = color
                            hl.FillTransparency = 0.5; hl.OutlineTransparency = 0
                            hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                            hl.Adornee = char; hl.Parent = char
                            activeHighlights[char][espType] = hl
                        else
                            activeHighlights[char][espType].FillColor = color
                            activeHighlights[char][espType].OutlineColor = color
                        end

                        local bb = activeBillboards[char][espType]
                        local healthPct = hum.Health / hum.MaxHealth
                        local healthColor = Color3.fromRGB(255 * (1 - healthPct), 255 * healthPct, 0)
                        local dist = math.floor((root.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude)

                        if ESPMode == "Original" then
                            if not bb or not bb.Parent or bb:FindFirstChild("HealthBarBG") then
                                if bb then bb:Destroy() end
                                
                                local newBb = Instance.new("BillboardGui")
                                newBb.Name = espType .. "BB"
                                newBb.Size = UDim2.new(0, 200, 0, 50)
                                newBb.StudsOffset = Vector3.new(0, 3, 0)
                                newBb.AlwaysOnTop = true
                                newBb.Parent = root

                                local tl = Instance.new("TextLabel")
                                tl.Name = "TextLabel"
                                tl.Size = UDim2.new(1, 0, 1, 0)
                                tl.BackgroundTransparency = 1
                                tl.TextStrokeTransparency = 0
                                tl.TextColor3 = color
                                tl.TextSize = 14
                                tl.Font = Enum.Font.FredokaOne
                                tl.Text = labelText .. "\n" .. plr.Name .. " | " .. math.floor(hum.Health) .. " HP"
                                tl.Parent = newBb

                                activeBillboards[char][espType] = newBb
                            else
                                local tl = bb:FindFirstChild("TextLabel")
                                if tl then
                                    tl.TextColor3 = color
                                    tl.Text = labelText .. "\n" .. plr.Name .. " | " .. math.floor(hum.Health) .. " HP"
                                end
                            end
                        else
                            if not bb or not bb.Parent or not bb:FindFirstChild("HealthBarBG") then
                                if bb then bb:Destroy() end
                                
                                local newBb = Instance.new("BillboardGui")
                                newBb.Name = espType .. "BB"
                                newBb.Size = UDim2.new(0, 180, 0, 60)
                                newBb.StudsOffset = Vector3.new(0, 3, 0)
                                newBb.AlwaysOnTop = true
                                newBb.Parent = root

                                local tl = Instance.new("TextLabel")
                                tl.Name = "TextLabel"
                                tl.Size = UDim2.new(1, 0, 0.5, 0)
                                tl.BackgroundTransparency = 1
                                tl.TextStrokeTransparency = 0
                                tl.TextColor3 = color
                                tl.TextSize = 14
                                tl.Font = Enum.Font.FredokaOne
                                tl.Text = labelText .. " | " .. plr.Name .. " [" .. dist .. "m]"
                                tl.Parent = newBb

                                local healthTxt = Instance.new("TextLabel")
                                healthTxt.Name = "HealthText"
                                healthTxt.Size = UDim2.new(1, 0, 0.2, 0)
                                healthTxt.Position = UDim2.new(0, 0, 0.5, 0)
                                healthTxt.BackgroundTransparency = 1
                                healthTxt.TextStrokeTransparency = 0
                                healthTxt.TextColor3 = healthColor
                                healthTxt.TextSize = 12
                                healthTxt.Font = Enum.Font.GothamBold
                                healthTxt.Text = math.floor(hum.Health) .. " / " .. math.floor(hum.MaxHealth) .. " HP"
                                healthTxt.Parent = newBb

                                local bg = Instance.new("Frame")
                                bg.Name = "HealthBarBG"
                                bg.Size = UDim2.new(1, 0, 0.15, 0)
                                bg.Position = UDim2.new(0, 0, 0.75, 0)
                                bg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                                bg.BorderSizePixel = 1
                                bg.BorderColor3 = Color3.fromRGB(255, 255, 255)
                                bg.Parent = newBb

                                local healthFrame = Instance.new("Frame")
                                healthFrame.Name = "HealthFrame"
                                healthFrame.Size = UDim2.new(healthPct, 0, 1, 0)
                                healthFrame.BackgroundColor3 = healthColor
                                healthFrame.BorderSizePixel = 0
                                healthFrame.Parent = bg

                                activeBillboards[char][espType] = newBb
                            else
                                local tl = bb:FindFirstChild("TextLabel")
                                if tl then
                                    tl.TextColor3 = color
                                    tl.Text = labelText .. " | " .. plr.Name .. " [" .. dist .. "m]"
                                end
                                local healthTxt = bb:FindFirstChild("HealthText")
                                if healthTxt then
                                    healthTxt.TextColor3 = healthColor
                                    healthTxt.Text = math.floor(hum.Health) .. " / " .. math.floor(hum.MaxHealth) .. " HP"
                                end
                                local bg = bb:FindFirstChild("HealthBarBG")
                                if bg then
                                    local healthFrame = bg:FindFirstChild("HealthFrame")
                                    if healthFrame then
                                        healthFrame.Size = UDim2.new(healthPct, 0, 1, 0)
                                        healthFrame.BackgroundColor3 = healthColor
                                    end
                                end
                            end
                        end
                    else
                        if activeHighlights[char][espType] then
                            activeHighlights[char][espType]:Destroy()
                            activeHighlights[char][espType] = nil
                        end
                        if activeBillboards[char][espType] then
                            activeBillboards[char][espType]:Destroy()
                            activeBillboards[char][espType] = nil
                        end
                    end
                end

                if babyBack then
                    updateESP("Player", false, "Player")
                    updateESP("Guard", false, "Guard")
                    updateESP("Detective", false, "Detective")
                    updateESP("Frontman", false, "Frontman")
                    updateESP("BabyCarrier", ESPConfig.BabyCarrier, "Carried Baby")
                else
                    updateESP("Player", ESPConfig.Player and isPlayerTeam, "Player")
                    updateESP("Guard", ESPConfig.Guard and isGuard, "Guard")
                    updateESP("Detective", ESPConfig.Detective and isDetective, "Detective")
                    updateESP("Frontman", ESPConfig.Frontman and isFrontman, "Frontman")
                    updateESP("BabyCarrier", false, "Carried Baby")
                end
                
                updateESP("Glassmaker", ESPConfig.Glassmaker and glassmaker, "Glassmaker")
            end
        end
    end
end)

local PlayerGame = Window:CreateTab({ Title = "Player GamePlay", Icon = "play" })
local PlayerGameRLGL = PlayerGame:CreateSubTab({ Title = "RL & GL", Icon = "siren", Default = true })

local autoPlayEnabled = false
local rlglConnection = nil

PlayerGameRLGL:Toggle({
    Title = "Auto Play", Default = false,
    Callback = function(state)
        autoPlayEnabled = state
        
        if rlglConnection then rlglConnection:Disconnect() rlglConnection = nil end
        
        if not autoPlayEnabled then
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if hum and root then 
                hum.WalkSpeed = 16
                hum:MoveTo(root.Position) 
            end
            return 
        end

        local map = Workspace:FindFirstChild("Map")
        local rlgl = map and map:FindFirstChild("RedLightGreenLight")
        local innerMap = rlgl and rlgl:FindFirstChild("Map")
        local finishLine = innerMap and innerMap:FindFirstChild("FinishLine")
        
        if not finishLine then return end

        rlglConnection = RunService.Heartbeat:Connect(function()
            if not autoPlayEnabled then return end
            
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local root = char and char:FindFirstChild("HumanoidRootPart")
            
            if hum and root then
                if Workspace:GetAttribute("RLGL_RedLight") then
                    if hum.WalkSpeed ~= 0 then
                        hum.WalkSpeed = 0
                        hum:MoveTo(root.Position)
                    end
                else
                    if hum.WalkSpeed ~= 40 then
                        hum.WalkSpeed = 40
                    end
                    hum:MoveTo(finishLine.Position)
                end
            end
        end)
    end
})

local PlayerGameHoneycomb = PlayerGame:CreateSubTab({ Title = "Honeycomb", Icon = "hexagon", Default = false })

PlayerGameHoneycomb:Button({
    Title = "Auto Win Honeycomb",
    Callback = function()
        task.spawn(function()
            if not LocalPlayer:GetAttribute("HONEYCOMB_START_CUTTING") then 
                LocalPlayer:GetAttributeChangedSignal("HONEYCOMB_START_CUTTING"):Wait() 
            end
            
            local honeycombGui = LocalPlayer.PlayerGui:WaitForChild("Honeycomb", 5)
            if not honeycombGui then return end
            
            local shapeValue = honeycombGui:WaitForChild("Shape", 5)
            local connection = honeycombGui:WaitForChild("Connection", 5)
            
            if shapeValue and connection then
                local shapeModel = shapeValue.Value
                local path = shapeModel and shapeModel:WaitForChild("Path", 5)
                
                if path then
                    local allParts = {}
                    for _, part in ipairs(path:GetChildren()) do
                        if not part:GetAttribute("Completed") then 
                            table.insert(allParts, part)
                            part.Transparency = 0 
                        end
                    end
                    
                    for i = 1, #allParts, 10 do
                        local chunk = {}
                        for j = i, math.min(i + 9, #allParts) do 
                            table.insert(chunk, allParts[j]) 
                        end
                        connection:FireServer(chunk)
                        task.wait(0.05)
                    end
                end
            end
        end)
    end
})

local PlayerGamePentathlon = PlayerGame:CreateSubTab({ Title = "Pentathlon", Icon = "target", Default = false })

PlayerGamePentathlon:Toggle({
    Title = "Auto Play",
    Default = false,
    Callback = function(state)
        if not state then return end
        
        task.spawn(function()
            local _l = game:GetService("Players").LocalPlayer
            local _rs = game:GetService("ReplicatedStorage")
            local _w = game:GetService("Workspace")
            local vu = game:GetService("VirtualUser")
            
            local isRunning = true
            local ddakjiDone = false
            local jegiStarted = false
            local topWrapped = false
            local topThrown = false
            local stoneStarted = false
            local clickedObjects = {}

            local function HoldClick(duration)
                vu:CaptureController()
                vu:Button1Down(Vector2.new(0.5, 0.5), workspace.CurrentCamera.CFrame)
                task.wait(duration or 0.4)
                vu:Button1Up(Vector2.new(0.5, 0.5), workspace.CurrentCamera.CFrame)
            end

            while isRunning do
                if not _l:GetAttribute("PENTA_ONGOING") then
                    isRunning = false
                    break
                end

                -- 1. DDAKJI (Timing)
                local ddakjiName = _l:GetAttribute("PENTA_DDAKJI_START")
                local ddakjiTarget = _l:GetAttribute("PENTA_DDAKJI_TARGET")
                if ddakjiName and ddakjiTarget and not ddakjiDone then
                    local remote = _rs:FindFirstChild(ddakjiName)
                    if remote then
                        task.wait(0.5)
                        remote:FireServer(ddakjiTarget) 
                        ddakjiDone = true
                    end
                elseif not ddakjiName then
                    ddakjiDone = false
                end

                -- 2. FLYING STONE (Aim & Throw)
                local stoneStart = _l:GetAttribute("PENTA_STONE_START")
                if stoneStart and not stoneStarted then
                    local remote = _rs:FindFirstChild(stoneStart)
                    if remote then
                        task.wait(1) -- Wait for the game to load
                        
                        -- Try to aim at the target stone
                        local char = _l.Character
                        local hrp = char and char:FindFirstChild("HumanoidRootPart")
                        
                        if hrp then
                            -- Look for the target stone (usually in a folder or named Target/Stone)
                            local targetStone = _w:FindFirstChild("TargetStone", true) or _w:FindFirstChild("Target", true)
                            
                            if targetStone and targetStone:IsA("BasePart") then
                                -- Snap character to face the target
                                hrp.CFrame = CFrame.lookAt(hrp.Position, targetStone.Position)
                            end
                        end
                        
                        task.wait(0.2)
                        -- 0.5 is usually the mid-power sweet spot. If it overshoots, change this to 0.4
                        remote:FireServer(0.5) 
                        stoneStarted = true
                    end
                elseif not stoneStart then
                    stoneStarted = false
                end

                -- 3. CLICKING GAMES (Pairs, Memory, Balls, Gonggi)
                local clickGame = _l:GetAttribute("PENTA_PAIRS_START") or _l:GetAttribute("PENTA_MEMORY_START") or _l:GetAttribute("PENTA_BALLS_START") or _l:GetAttribute("PENTA_GONGGI_START")
                if clickGame then
                    local remote = _rs:FindFirstChild(clickGame)
                    local triggerFolder = _l:FindFirstChild("TriggerFolder") and _l.TriggerFolder.Value
                    
                    if remote and triggerFolder then
                        for _, obj in ipairs(triggerFolder:GetDescendants()) do
                            if obj:IsA("BasePart") and not clickedObjects[obj] then
                                local isHighlighted = false
                                local hl = obj:FindFirstChildOfClass("Highlight")
                                local sb = obj:FindFirstChildOfClass("SelectionBox")
                                
                                if (hl and hl.Enabled) or (sb and sb.Visible) or obj:GetAttribute("Active") then
                                    isHighlighted = true
                                elseif _l:GetAttribute("PENTA_BALLS_START") and obj.Color == Color3.fromRGB(255, 255, 0) then
                                    isHighlighted = true 
                                end

                                if isHighlighted then
                                    clickedObjects[obj] = true
                                    if _l:GetAttribute("PENTA_GONGGI_START") then
                                        HoldClick(0.15)
                                        remote:FireServer("PebbleClick", obj.Name)
                                    else
                                        remote:FireServer(obj.Name)
                                    end
                                    task.wait(0.15)
                                end
                            end
                        end
                    end
                end

                -- 4. SPINNING TOP (Wrapping & Throwing)
                local spinStartName = _l:GetAttribute("PENTA_SPINNING_START")
                if spinStartName and not topWrapped then
                    local remote = _rs:FindFirstChild(spinStartName)
                    if remote then
                        for i = 1, 12 do
                            remote:FireServer("onCheckpointReached", i)
                            task.wait(0.05)
                        end
                        topWrapped = true
                    end
                elseif not spinStartName then
                    topWrapped = false
                end

                local spinThrowName = _l:GetAttribute("PENTA_SPINNING_UUID")
                local spinTarget = _l:GetAttribute("PENTA_SPINNING_TARGET")
                if spinThrowName and spinTarget and not topThrown then
                    local remote = _rs:FindFirstChild(spinThrowName)
                    if remote then
                        task.wait(0.5)
                        remote:FireServer("throwSpinningTop", spinTarget) 
                        topThrown = true
                    end
                elseif not spinThrowName then
                    topThrown = false
                end

                -- 5. JEGI KICKS (Spam the ChangeState true)
                local jegiKicksStart = _l:GetAttribute("PENTA_JEBI_KICKS_START")
                if jegiKicksStart then
                    local jegiName = _l:GetAttribute("PENTA_JEBI_START")
                    local remote = jegiName and _rs:FindFirstChild(jegiName)
                    if remote then
                        if not jegiStarted then
                            remote:FireServer("StartJebi")
                            jegiStarted = true
                        end
                        remote:FireServer("ChangeState", true)
                    end
                    task.wait(0.1)
                elseif not jegiKicksStart then
                    jegiStarted = false
                end

                task.wait(0.1) 
            end
        end)
    end
})

local PlayerGameRebellion = PlayerGame:CreateSubTab({ Title = "Rebellion", Icon = "shield", Default = false })

PlayerGameRebellion:Button({
    Title = "Enter Frontman Room",
    Callback = function()
        task.spawn(function()
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end

            local staircase = Workspace:FindFirstChild("Staircase")
            local assets = staircase and staircase:FindFirstChild("Assets")
            local stairs = assets and assets:FindFirstChild("stairsssss32313133")
            local model = stairs and stairs:FindFirstChild("Model")
            local balcony = model and model:FindFirstChild("Balcony")
            local door = balcony and balcony:FindFirstChild("Door")

            if not door then
                door = stairs and stairs:FindFirstChild("Door", true)
            end

            if door then
                local doorCFrame = door:IsA("BasePart") and door.CFrame or door:GetPivot()

                if doorCFrame then
                    hrp.AssemblyLinearVelocity = Vector3.zero
                    hrp.AssemblyAngularVelocity = Vector3.zero
                    hrp.CFrame = doorCFrame + Vector3.new(0, 3, 0)
                    
                    task.wait(0.2)

                    -- Find the nearest enabled prompt
                    local nearestPrompt = nil
                    local shortestDist = 10

                    for _, obj in ipairs(Workspace:GetDescendants()) do
                        if obj:IsA("ProximityPrompt") and obj.Enabled and obj.Parent and obj.Parent:IsA("BasePart") then
                            local dist = (hrp.Position - obj.Parent.Position).Magnitude
                            if dist < shortestDist then
                                shortestDist = dist
                                nearestPrompt = obj
                            end
                        end
                    end

                    if nearestPrompt then
                        pcall(function()
                            if fireproximityprompt then
                                fireproximityprompt(nearestPrompt)
                            else
                                nearestPrompt:InputHoldBegin()
                                task.wait(nearestPrompt.HoldDuration + 0.05)
                                nearestPrompt:InputHoldEnd()
                            end
                        end)
                    end
                end
            end
        end)
    end
})

local PlayerGameMusicalChair = PlayerGame:CreateSubTab({ Title = "Musical Chair", Icon = "armchair", Default = false })

local autoChairEnabled = false
local chairConnection = nil
local chairDebounce = false

PlayerGameMusicalChair:Toggle({
    Title = "Auto Sit",
    Default = false,
    Callback = function(state)
        autoChairEnabled = state
        
        if chairConnection then chairConnection:Disconnect() chairConnection = nil end
        if not autoChairEnabled then return end
        
        chairConnection = Workspace:GetAttributeChangedSignal("MusicalChairsTimer"):Connect(function()
            if not autoChairEnabled or chairDebounce then return end
            
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            
            if hrp and hum and not hum.SeatPart then
                local map = Workspace:FindFirstChild("Map")
                local musicalChairs = map and (map:FindFirstChild("MusicalChairs") or map:FindFirstChild("MusicalChairsMap"))
                
                if musicalChairs then
                    for _, obj in ipairs(musicalChairs:GetDescendants()) do
                        if obj:IsA("BasePart") and (obj.Name == "Chair" or obj.Name == "Seat" or obj:IsA("Seat")) and not obj.Occupant then
                            chairDebounce = true
                            
                            hrp.AssemblyLinearVelocity = Vector3.zero
                            hrp.AssemblyAngularVelocity = Vector3.zero
                            hrp.CFrame = obj.CFrame + Vector3.new(0, 3, 0)
                            
                            task.wait(0.1)
                            
                            pcall(function()
                                firetouchinterest(hrp, obj, 0)
                                task.wait()
                                firetouchinterest(hrp, obj, 1)
                            end)
                            
                            if obj:IsA("Seat") then
                                pcall(function() obj:Sit(hum) end)
                            end
                            
                            task.wait(1)
                            chairDebounce = false
                            break 
                        end
                    end
                end
            end
        end)
    end
})

local PlayerGameHideSeek = PlayerGame:CreateSubTab({ Title = "Hide & Seek", Icon = "search", Default = false })

local autoKillBlueEnabled = false
local killBlueConn = nil
local currentTargetPlr = nil
local targetStartPos = nil
local tweenAlpha = 0
local isTweening = false
local safeZoneCFrame = CFrame.new(-805.61, 23.82, 310.84)
local TWEEN_SPEED = 60

PlayerGameHideSeek:Toggle({
    Title = "Auto Kill Blue Team", Default = false,
    Callback = function(state)
        autoKillBlueEnabled = state
        currentTargetPlr = nil
        isTweening = false
        
        if killBlueConn then killBlueConn:Disconnect() killBlueConn = nil end
        
        if not autoKillBlueEnabled then
            local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
                hrp.CFrame = safeZoneCFrame
            end
            return 
        end

        killBlueConn = RunService.Heartbeat:Connect(function(dt)
            if not autoKillBlueEnabled then return end

            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local backpack = LocalPlayer:FindFirstChild("Backpack")
            local humanoid = char and char:FindFirstChildOfClass("Humanoid")
            
            if not hrp or not humanoid then return end

            -- Check if current target is dead or lost the vest
            if currentTargetPlr then
                local targetChar = currentTargetPlr.Character
                local targetHum = targetChar and targetChar:FindFirstChildOfClass("Humanoid")
                local hasBlue = targetChar and targetChar:FindFirstChild("Vest_blue", true) ~= nil
                
                if not targetChar or not targetHum or targetHum.Health <= 0 or not hasBlue then
                    currentTargetPlr = nil
                    isTweening = false
                end
            end

            -- Find new target if none
            if not currentTargetPlr then
                local shortestDistance = math.huge
                for _, plr in ipairs(Players:GetPlayers()) do
                    if plr ~= LocalPlayer and plr.Character then
                        local plrChar = plr.Character
                        local hasBlue = plrChar:FindFirstChild("Vest_blue", true)
                        local plrHrp = plrChar:FindFirstChild("HumanoidRootPart")
                        local plrHum = plrChar:FindFirstChildOfClass("Humanoid")
                        
                        if hasBlue and plrHrp and plrHum and plrHum.Health > 0 then
                            local dist = (hrp.Position - plrHrp.Position).Magnitude
                            if dist < shortestDistance then
                                shortestDistance = dist
                                currentTargetPlr = plr
                                isTweening = true
                                tweenAlpha = 0
                                targetStartPos = hrp.Position
                            end
                        end
                    end
                end
            end

            -- Kung may target
            if currentTargetPlr then
                local targetChar = currentTargetPlr.Character
                local targetHrp = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
                
                if targetHrp then
                    -- Equip Knife
                    local knife = backpack and backpack:FindFirstChild("Knife")
                    if knife and knife.Parent ~= char then
                        humanoid:EquipTool(knife)
                    end
                    
                    -- Calculate behind position (4 studs away)
                    local behindPos = targetHrp.CFrame * CFrame.new(0, 0, 4)
                    local targetCFrame = CFrame.lookAt(behindPos.Position, targetHrp.Position)

                    if isTweening then
                        -- Heartbeat Tween
                        local distance = (behindPos.Position - targetStartPos).Magnitude
                        local duration = distance / TWEEN_SPEED
                        
                        tweenAlpha = math.min(tweenAlpha + (dt / math.max(duration, 0.01)), 1)
                        local currentPos = targetStartPos:Lerp(behindPos.Position, tweenAlpha)
                        
                        hrp.AssemblyLinearVelocity = Vector3.zero
                        hrp.AssemblyAngularVelocity = Vector3.zero
                        hrp.CFrame = CFrame.new(currentPos, targetHrp.Position)
                        
                        if tweenAlpha >= 1 then
                            isTweening = false
                        end
                    else
                        -- Auto Slash kapag nasa 5 studs na
                        hrp.AssemblyLinearVelocity = Vector3.zero
                        hrp.AssemblyAngularVelocity = Vector3.zero
                        hrp.CFrame = targetCFrame
                        
                        local equippedKnife = char:FindFirstChild("Knife")
                        if equippedKnife then
                            pcall(function()
                                equippedKnife:Activate()
                            end)
                        end
                    end
                end
            else
                -- Walang target, balik sa safe zone
                if (hrp.Position - safeZoneCFrame.Position).Magnitude > 5 then
                    hrp.AssemblyLinearVelocity = Vector3.zero
                    hrp.AssemblyAngularVelocity = Vector3.zero
                    hrp.CFrame = safeZoneCFrame
                end
            end
        end)
    end
})

local CollectPickups = false
local PickupConnection

PlayerGameHideSeek:Toggle({
    Title = "Auto Collect Drops",
    Default = false,
    Callback = function(state)
        CollectPickups = state
        if not state then
            if PickupConnection then
                PickupConnection:Disconnect()
                PickupConnection = nil
            end
            return
        end

        PickupConnection = RunService.Heartbeat:Connect(function()
            if not CollectPickups or not firetouchinterest then return end

            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local pickups = Workspace:FindFirstChild("Map")
                and Workspace.Map:FindFirstChild("HideNSeek")
                and Workspace.Map.HideNSeek:FindFirstChild("Pickups")

            if not hrp or not pickups then return end

            for _, obj in ipairs(pickups:GetDescendants()) do
                if not CollectPickups then break end
                if obj:IsA("BasePart") and obj:FindFirstChildWhichIsA("TouchTransmitter") then
                    pcall(function()
                        firetouchinterest(hrp, obj, 0)
                        firetouchinterest(hrp, obj, 1)
                    end)
                end
            end
        end)
    end
})

PlayerGameHideSeek:Button({
    Title = "Safe Zone",
    Callback = function()
        task.spawn(function()
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then 
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
                hrp.CFrame = CFrame.new(-805.61, 23.82, 310.84) 
            end
        end)
    end
})

PlayerGameHideSeek:Section("Hitbox")

local ESPHitboxConfigHS = {
    Blue = false,
    Red = false,
    Size = 10
}

local OriginalHitboxesHS = setmetatable({}, {__mode = "k"})
local updateAccumulatorHS = 0

local function RestoreHitboxHS(root)
    local original = OriginalHitboxesHS[root]
    if not original then return end
    if root.Parent then
        root.Size = original.Size
        root.Transparency = original.Transparency
        root.Color = original.Color
        root.Material = original.Material
        root.CanCollide = original.CanCollide
    end
    OriginalHitboxesHS[root] = nil
end

local function RestoreHitboxTypeHS(espType)
    for root in pairs(OriginalHitboxesHS) do
        local char = root.Parent
        if char then
            local hasType = espType == "Blue" and char:FindFirstChild("Vest_blue", true) 
                         or espType == "Red" and char:FindFirstChild("Vest_red", true)
            if hasType then RestoreHitboxHS(root) end
        end
    end
end

PlayerGameHideSeek:Slider({
    Title = "Team Hitbox Size",
    Min = 10,
    Max = 1000,
    Default = 10,
    Callback = function(value)
        ESPHitboxConfigHS.Size = math.clamp(value, 10, 1000)
    end
})

PlayerGameHideSeek:Toggle({
    Title = "Hitbox Blue Team",
    Default = false,
    Callback = function(state)
        ESPHitboxConfigHS.Blue = state
        if not state then RestoreHitboxTypeHS("Blue") end
    end
})

PlayerGameHideSeek:Toggle({
    Title = "Hitbox Red Team",
    Default = false,
    Callback = function(state)
        ESPHitboxConfigHS.Red = state
        if not state then RestoreHitboxTypeHS("Red") end
    end
})

RunService.Heartbeat:Connect(function(dt)
    if not ESPHitboxConfigHS.Blue and not ESPHitboxConfigHS.Red then
        if next(OriginalHitboxesHS) then
            for root in pairs(OriginalHitboxesHS) do
                RestoreHitboxHS(root)
            end
        end
        return
    end

    updateAccumulatorHS += dt
    if updateAccumulatorHS < 0.2 then return end
    updateAccumulatorHS = 0

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local char = plr.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")

            if root and hum and hum.Health > 0 then
                local hasBlue = char:FindFirstChild("Vest_blue", true) ~= nil
                local hasRed = char:FindFirstChild("Vest_red", true) ~= nil
                
                local enabled = (ESPHitboxConfigHS.Blue and hasBlue) or (ESPHitboxConfigHS.Red and hasRed)

                if enabled then
                    if not OriginalHitboxesHS[root] then
                        OriginalHitboxesHS[root] = {
                            Size = root.Size,
                            Transparency = root.Transparency,
                            Color = root.Color,
                            Material = root.Material,
                            CanCollide = root.CanCollide
                        }
                    end

                    root.Size = Vector3.new(ESPHitboxConfigHS.Size, ESPHitboxConfigHS.Size, ESPHitboxConfigHS.Size)
                    root.Transparency = 0.7
                    root.Color = Color3.fromRGB(0, 100, 255)
                    root.Material = Enum.Material.Neon
                    root.CanCollide = false
                else
                    RestoreHitboxHS(root)
                end
            elseif root then
                RestoreHitboxHS(root)
            end
        end
    end

    for root in pairs(OriginalHitboxesHS) do
        if not root.Parent then OriginalHitboxesHS[root] = nil end
    end
end)

Players.PlayerRemoving:Connect(function(plr)
    local char = plr.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if root then RestoreHitboxHS(root) end
end)

PlayerGameHideSeek:Section("ESP")

local ESPConfigHS = { Blue = false, Red = false }
local activeHighlightsHS = setmetatable({}, {__mode = "k"})
local activeBillboardsHS = setmetatable({}, {__mode = "k"})

local function clearESPTypeHS(espType)
    if not ESPConfigHS[espType] then
        for char, hls in pairs(activeHighlightsHS) do
            if hls[espType] then
                hls[espType]:Destroy()
                hls[espType] = nil
            end
        end
        for char, bbs in pairs(activeBillboardsHS) do
            if bbs[espType] then
                bbs[espType]:Destroy()
                bbs[espType] = nil
            end
        end
    end
end

PlayerGameHideSeek:Toggle({
    Title = "ESP Blue Team", Default = false,
    Callback = function(state) ESPConfigHS.Blue = state; clearESPTypeHS("Blue") end
})

PlayerGameHideSeek:Toggle({
    Title = "ESP Red Team", Default = false,
    Callback = function(state) ESPConfigHS.Red = state; clearESPTypeHS("Red") end
})

local updateAccumulatorHS = 0
RunService.Heartbeat:Connect(function(dt)
    if not ESPConfigHS.Blue and not ESPConfigHS.Red then return end
    
    updateAccumulatorHS = updateAccumulatorHS + dt
    if updateAccumulatorHS < 0.2 then return end
    updateAccumulatorHS = 0

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local char = plr.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                local root = char.HumanoidRootPart
                local hum = char:FindFirstChildOfClass("Humanoid")
                
                local hasBlue = char:FindFirstChild("Vest_blue", true) ~= nil
                local hasRed = char:FindFirstChild("Vest_red", true) ~= nil
                
                activeHighlightsHS[char] = activeHighlightsHS[char] or {}
                activeBillboardsHS[char] = activeBillboardsHS[char] or {}

                local function updateESP(espType, color, enabled, labelText)
                    if enabled then
                        if not activeHighlightsHS[char][espType] or not activeHighlightsHS[char][espType].Parent then
                            local hl = Instance.new("Highlight")
                            hl.Name = espType .. "ESP"
                            hl.FillColor = color; hl.OutlineColor = color
                            hl.FillTransparency = 0.5; hl.OutlineTransparency = 0
                            hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                            hl.Adornee = char; hl.Parent = char
                            activeHighlightsHS[char][espType] = hl
                        end

                        if not activeBillboardsHS[char][espType] or not activeBillboardsHS[char][espType].Parent then
                            local bb = Instance.new("BillboardGui")
                            bb.Name = espType .. "BB"
                            bb.Size = UDim2.new(0, 200, 0, 50)
                            bb.StudsOffset = Vector3.new(0, 3, 0)
                            bb.AlwaysOnTop = true
                            bb.Parent = root

                            local tl = Instance.new("TextLabel")
                            tl.Size = UDim2.new(1, 0, 1, 0)
                            tl.BackgroundTransparency = 1
                            tl.TextStrokeTransparency = 0
                            tl.TextColor3 = color
                            tl.TextSize = 14
                            tl.Font = Enum.Font.FredokaOne
                            tl.Text = labelText .. "\n" .. plr.Name .. " | " .. math.floor(hum.Health) .. " HP"
                            tl.Parent = bb

                            activeBillboardsHS[char][espType] = bb
                        else
                            local bb = activeBillboardsHS[char][espType]
                            local tl = bb:FindFirstChildOfClass("TextLabel")
                            if tl then
                                tl.Text = labelText .. "\n" .. plr.Name .. " | " .. math.floor(hum.Health) .. " HP"
                            end
                        end
                    else
                        if activeHighlightsHS[char][espType] then
                            activeHighlightsHS[char][espType]:Destroy()
                            activeHighlightsHS[char][espType] = nil
                        end
                        if activeBillboardsHS[char][espType] then
                            activeBillboardsHS[char][espType]:Destroy()
                            activeBillboardsHS[char][espType] = nil
                        end
                    end
                end

                updateESP("Blue", Color3.fromRGB(0, 170, 255), ESPConfigHS.Blue and hasBlue, "Blue Team")
                updateESP("Red", Color3.fromRGB(255, 0, 0), ESPConfigHS.Red and hasRed, "Red Team")

            end
        end
    end
end)

local espState = { highlights = {}, conn = nil }

local function setDoorESP(state)
    local exitDoors = Workspace:FindFirstChild("Map") 
        and Workspace.Map:FindFirstChild("HideNSeek") 
        and Workspace.Map.HideNSeek:FindFirstChild("Elements") 
        and Workspace.Map.HideNSeek.Elements:FindFirstChild("ExitDoors")
        
    if not exitDoors then return end
    
    if not state then
        if espState.conn then espState.conn:Disconnect() espState.conn = nil end
        for _, hl in pairs(espState.highlights) do if hl then hl:Destroy() end end
        espState.highlights = {}
        return
    end
    
    local function apply(model)
        if not model:IsA("Model") or espState.highlights[model] then return end
        local hl = Instance.new("Highlight")
        hl.Name = "DoorESP"
        hl.FillColor = Color3.new(1, 1, 1)
        hl.OutlineColor = Color3.new(1, 1, 1)
        hl.FillTransparency = 0.5
        hl.OutlineTransparency = 0
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Adornee = model
        hl.Parent = model
        espState.highlights[model] = hl
    end
    
    for _, m in ipairs(exitDoors:GetChildren()) do apply(m) end
    espState.conn = exitDoors.ChildAdded:Connect(apply)
end

PlayerGameHideSeek:Toggle({ 
    Title = "ESP Door", 
    Default = false, 
    Callback = setDoorESP 
})

local pickupsESPEnabled = false
local pickupObjects = {}
local pickupConn = nil
local pickupUpdateConn = nil
local pickupLastUpdate = 0

local function clearPickupsESP()
    for obj, data in pairs(pickupObjects) do
        if data.Highlight then data.Highlight:Destroy() end
        if data.Billboard then data.Billboard:Destroy() end
    end
    pickupObjects = {}
    if pickupConn then pickupConn:Disconnect() pickupConn = nil end
    if pickupUpdateConn then pickupUpdateConn:Disconnect() pickupUpdateConn = nil end
end

local function createPickupsESP(obj)
    if not obj or pickupObjects[obj] or not (obj:IsA("Model") or obj:IsA("BasePart")) then return end
    local part = obj:IsA("BasePart") and obj or obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart", true)
    if not part then return end

    local hl = Instance.new("Highlight")
    hl.Name = "KazePickupESP"
    hl.FillColor = Color3.fromRGB(255, 255, 255) -- White
    hl.OutlineColor = Color3.fromRGB(0, 0, 0)     -- Black
    hl.FillTransparency = 0.5
    hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Adornee = obj
    hl.Parent = obj

    local bb = Instance.new("BillboardGui")
    bb.Name = "KazePickupBB"
    bb.Size = UDim2.new(0, 200, 0, 50)
    bb.StudsOffset = Vector3.new(0, 3, 0)
    bb.AlwaysOnTop = true
    bb.Parent = part

    local tl = Instance.new("TextLabel")
    tl.Name = "PickupText"
    tl.Size = UDim2.new(1, 0, 1, 0)
    tl.BackgroundTransparency = 1
    tl.TextStrokeTransparency = 0
    tl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    tl.TextColor3 = Color3.fromRGB(255, 255, 255)
    tl.TextSize = 14
    tl.Font = Enum.Font.FredokaOne
    tl.Text = obj.Name
    tl.Parent = bb

    pickupObjects[obj] = { Highlight = hl, Billboard = bb, TextLabel = tl, Part = part }
end

PlayerGameHideSeek:Toggle({
    Title = "ESP Pickups",
    Default = false,
    Callback = function(state)
        pickupsESPEnabled = state
        clearPickupsESP()
        if not pickupsESPEnabled then return end

        local pickups = Workspace:FindFirstChild("Map")
            and Workspace.Map:FindFirstChild("HideNSeek")
            and Workspace.Map.HideNSeek:FindFirstChild("Pickups")

        if not pickups then return end

        for _, obj in ipairs(pickups:GetChildren()) do
            if obj:IsA("Model") or obj:IsA("BasePart") then
                createPickupsESP(obj)
            end
        end

        pickupConn = pickups.ChildAdded:Connect(function(obj)
            if pickupsESPEnabled then createPickupsESP(obj) end
        end)

        pickupUpdateConn = RunService.Heartbeat:Connect(function()
            if not pickupsESPEnabled then return end
            if tick() - pickupLastUpdate < 0.2 then return end
            pickupLastUpdate = tick()

            local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if not hrp then return end

            for obj, data in pairs(pickupObjects) do
                if obj and obj.Parent and data.Part and data.Part.Parent and data.TextLabel then
                    local dist = math.floor((hrp.Position - data.Part.Position).Magnitude)
                    data.TextLabel.Text = string.format("%s [%dm]", obj.Name, dist)
                else
                    if data.Highlight then data.Highlight:Destroy() end
                    if data.Billboard then data.Billboard:Destroy() end
                    pickupObjects[obj] = nil
                end
            end
        end)
    end
})

local PlayerGameMingle = PlayerGame:CreateSubTab({ Title = "Mingle", Icon = "users", Default = false })

local autoMingleEnabled = false
local mingleConn = nil

PlayerGameMingle:Toggle({
    Title = "Auto Enter Room", 
    Description = "Auto enter room when it needed one.", 
    Default = false,
    Callback = function(state)
        autoMingleEnabled = state
        if mingleConn then mingleConn:Disconnect() mingleConn = nil end
        if not autoMingleEnabled then return end

        mingleConn = RunService.Heartbeat:Connect(function()
            if not autoMingleEnabled then return end
            if not workspace:GetAttribute("MINGLE_ONGOING") then return end

            local lp = LocalPlayer
            local targetCount = workspace:GetAttribute("MINGLE_TARGET") or 0
            
            local myRoom = lp:GetAttribute("MINGLE_ROOM")
            local myCount = lp:GetAttribute("MINGLE_ROOM_COUNT") or 0
            if myRoom and myCount >= targetCount then return end

            local map = workspace:FindFirstChild("Map")
            local mingleMap = map and map:FindFirstChild("Mingle")
            local roomsFolder = mingleMap and mingleMap:FindFirstChild("Map") and mingleMap.Map:FindFirstChild("Rooms")

            if roomsFolder then
                for _, room in ipairs(roomsFolder:GetChildren()) do
                    local roomName = room.Name
                    local roomPlayers = 0
                    
                    for _, plr in ipairs(Players:GetPlayers()) do
                        if plr:GetAttribute("MINGLE_ROOM") == roomName then
                            roomPlayers = roomPlayers + 1
                        end
                    end

                    local neededCount = targetCount - roomPlayers
                    
                    if neededCount == 1 and roomName ~= myRoom then
                        -- Hanapin ang Floor (loob ng room), hindi ang Door (labas)
                        local floor = room:FindFirstChild("Floor") 
                            or room:FindFirstChild("Center") 
                            or room:FindFirstChild("TeleportPart")
                        
                        -- Kung wala, kunin ang unang BasePart na "hindi" door/prompt
                        if not floor then
                            for _, part in ipairs(room:GetDescendants()) do
                                if part:IsA("BasePart") 
                                    and not part.Name:lower():find("door") 
                                    and not part.Name:lower():find("prompt") 
                                    and not part:FindFirstChildWhichIsA("ProximityPrompt") 
                                then
                                    floor = part
                                    break
                                end
                            end
                        end

                        if floor then
                            local char = lp.Character
                            if char and char:FindFirstChild("HumanoidRootPart") then
                                local hrp = char.HumanoidRootPart
                                
                                -- 1. Noclip
                                for _, p in ipairs(char:GetDescendants()) do
                                    if p:IsA("BasePart") then p.CanCollide = false end
                                end
                                
                                -- 2. Teleport inside (Floor center)
                                hrp.AssemblyLinearVelocity = Vector3.zero
                                hrp.AssemblyAngularVelocity = Vector3.zero
                                hrp.CFrame = floor.CFrame + Vector3.new(0, 3, 0)
                                
                                task.wait(0.2)
                                
                                -- 3. Fire Prompt (kahit malayo sa door, mag-fifire pa rin)
                                local doorPrompt = room:FindFirstChildWhichIsA("ProximityPrompt", true)
                                if doorPrompt and doorPrompt.Enabled then
                                    pcall(function()
                                        fireproximityprompt(doorPrompt)
                                    end)
                                end
                                
                                task.wait(0.1)
                                
                                -- 4. Restore Collision
                                for _, p in ipairs(char:GetDescendants()) do
                                    if p:IsA("BasePart") then p.CanCollide = true end
                                end
                            end
                        end
                        break
                    end
                end
            end
        end)
    end
})


local PlayerGameJumpRope = PlayerGame:CreateSubTab({ Title = "Jump Rope", Icon = "activity", Default = false })

PlayerGameJumpRope:Button({
    Title = "Auto Win",
    Callback = function()
        task.spawn(function()
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end

            local safetyPart = Workspace:FindFirstChild("Map")
                and Workspace.Map:FindFirstChild("JumpRope")
                and Workspace.Map.JumpRope:FindFirstChild("Safety")

            if safetyPart then
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
                hrp.CFrame = safetyPart.CFrame + Vector3.new(0, 3, 0)
            end
        end)
    end
})

PlayerGameJumpRope:Toggle({
    Title = "Anti Hit", 
    Default = false,
    Callback = function(state)
        if not state then return end
        
        task.spawn(function()
            local ropeHit = Workspace:FindFirstChild("Map") 
                and Workspace.Map:FindFirstChild("JumpRope") 
                and Workspace.Map.JumpRope:FindFirstChild("Rope") 
                and Workspace.Map.JumpRope.Rope:FindFirstChild("Hit")
                
            if ropeHit then
                if ropeHit:IsA("BasePart") then 
                    ropeHit.CanCollide = false 
                end
                
                for _, obj in ipairs(ropeHit:GetDescendants()) do
                    if obj:IsA("TouchTransmitter") then 
                        obj:Destroy() 
                    elseif obj:IsA("BasePart") then 
                        obj.CanCollide = false 
                    end
                end
                
                local directTouch = ropeHit:FindFirstChildOfClass("TouchTransmitter")
                if directTouch then 
                    directTouch:Destroy() 
                end
            end
        end)
    end
})

local PlayerGameTUG = PlayerGame:CreateSubTab({ 
    Title = "Tug of War", 
    Icon = "flag", 
    Default = false 
})

PlayerGameTUG:Toggle({
    Title = "Auto Pull", 
    Default = false,
    Callback = function(state)
        if state then
            local lp = game:GetService("Players").LocalPlayer
            local rs = game:GetService("ReplicatedStorage")
            local hm = hookmetamethod or hookmetamethod_game
            
            -- Hook to ensure 'ChangeState' is always true
            local old_namecall
            old_namecall = hm("__namecall", function(self, ...)
                local args = {...}
                if getnamecallmethod() == "FireServer" and self:IsA("RemoteEvent") then
                    if args[1] == "ChangeState" or args[1] == "Pull" or args[1] == "TugPull" then
                        args[2] = true
                    end
                end
                return old_namecall(self, unpack(args))
            end)

            task.spawn(function()
                while state do
                    local tugName = lp:GetAttribute("TUG_PULL_START") or lp:GetAttribute("TUG_START")
                    if tugName then
                        local remote = rs:FindFirstChild(tugName)
                        if remote then
                            pcall(function()
                                remote:FireServer("StartTug")
                                remote:FireServer("ChangeState", true)
                            end)
                        end
                    end
                    task.wait(0.05)
                end
            end)
        end
    end
})

local PlayerGameMinusOne = PlayerGame:CreateSubTab({ Title = "Minus One", Icon = "minus", Default = false })

PlayerGameMinusOne:Button({
    Title = "Hide (Invisible Spot)",
    Callback = function()
        task.spawn(function()
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end

            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
            hrp.CFrame = CFrame.new(1249, 286, 601)
            
            Window:Notify({
                Title = "Minus One",
                Content = "Teleported to safe spot!",
                Duration = 3
            })
        end)
    end
})



local PlayerGameGlass = PlayerGame:CreateSubTab({ Title = "Glass", Icon = "square", Default = false })

local glassEspEnabled = false
local glassHighlights = {}
local glassConnections = {}

local function clearGlassESP()
    for _, conn in ipairs(glassConnections) do pcall(function() conn:Disconnect() end) end
    table.clear(glassConnections)
    for _, hl in pairs(glassHighlights) do pcall(function() hl:Destroy() end) end
    table.clear(glassHighlights)
end

local function applyGlassHighlight(part)
    if not part:IsA("BasePart") or glassHighlights[part] then return end
    local hl = Instance.new("Highlight")
    hl.Name = "KazeGlassESP"
    hl.Adornee = part
    hl.FillTransparency = 0.4
    hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    
    local function updateColor()
        if part.CanCollide then 
            hl.FillColor = Color3.fromRGB(0, 255, 0)
            hl.OutlineColor = Color3.fromRGB(0, 255, 0)
        else 
            hl.FillColor = Color3.fromRGB(255, 0, 0)
            hl.OutlineColor = Color3.fromRGB(255, 0, 0) 
        end
    end
    
    updateColor()
    hl.Parent = part
    glassHighlights[part] = hl
    table.insert(glassConnections, part:GetPropertyChangedSignal("CanCollide"):Connect(updateColor))
end

PlayerGameGlass:Toggle({
    Title = "Glass ESP", Default = false,
    Callback = function(Value)
        glassEspEnabled = Value
        clearGlassESP()
        if not glassEspEnabled then return end
        
        task.spawn(function()
            local folder = Workspace:FindFirstChild("Glasses", true) or Workspace:FindFirstChild("Glass", true)
            if folder then
                for _, part in ipairs(folder:GetDescendants()) do applyGlassHighlight(part) end
                table.insert(glassConnections, folder.DescendantAdded:Connect(function(part) 
                    if glassEspEnabled then applyGlassHighlight(part) end 
                end))
                return
            end
            
            local waitConn
            waitConn = Workspace.DescendantAdded:Connect(function(inst)
                if not glassEspEnabled then waitConn:Disconnect() return end
                if inst.Name == "Glasses" or inst.Name == "Glass" then
                    if inst:IsA("Folder") or inst:IsA("Model") then
                        waitConn:Disconnect()
                        for _, part in ipairs(inst:GetDescendants()) do applyGlassHighlight(part) end
                        table.insert(glassConnections, inst.DescendantAdded:Connect(function(part) 
                            if glassEspEnabled then applyGlassHighlight(part) end 
                        end))
                    end
                end
            end)
            table.insert(glassConnections, waitConn)
        end)
    end
})

local trollGlassEnabled = false
local trollBlocks = {}
local trollConnections = {}

local function clearTrollGlass()
    for _, conn in ipairs(trollConnections) do pcall(function() conn:Disconnect() end) end
    table.clear(trollConnections)
    for _, block in pairs(trollBlocks) do pcall(function() block:Destroy() end) end
    table.clear(trollBlocks)
end

local function applyTrollBlock(part)
    if not part:IsA("BasePart") or trollBlocks[part] or part.CanCollide == true then return end
    local block = Instance.new("Part")
    block.Name = "TrollSolidBlock"
    block.Size = part.Size + Vector3.new(0.5, 0.5, 0.5)
    block.CFrame = part.CFrame
    block.Anchored = true
    block.CanCollide = true
    block.Material = Enum.Material.Neon
    block.Color = Color3.fromRGB(255, 165, 0)
    block.Transparency = 0.5
    block.Parent = part
    trollBlocks[part] = block
end

PlayerGameGlass:Toggle({
    Title = "Troll Glass", Default = false,
    Callback = function(Value)
        trollGlassEnabled = Value
        clearTrollGlass()
        if not trollGlassEnabled then return end
        
        task.spawn(function()
            local folder = Workspace:FindFirstChild("Glasses", true) or Workspace:FindFirstChild("Glass", true)
            if folder then
                for _, part in ipairs(folder:GetDescendants()) do applyTrollBlock(part) end
                table.insert(trollConnections, folder.DescendantAdded:Connect(function(part) 
                    if trollGlassEnabled then applyTrollBlock(part) end 
                end))
                return
            end
            
            local waitConn
            waitConn = Workspace.DescendantAdded:Connect(function(inst)
                if not trollGlassEnabled then waitConn:Disconnect() return end
                if inst.Name == "Glasses" or inst.Name == "Glass" then
                    if inst:IsA("Folder") or inst:IsA("Model") then
                        waitConn:Disconnect()
                        for _, part in ipairs(inst:GetDescendants()) do applyTrollBlock(part) end
                        table.insert(trollConnections, inst.DescendantAdded:Connect(function(part) 
                            if trollGlassEnabled then applyTrollBlock(part) end 
                        end))
                    end
                end
            end)
            table.insert(trollConnections, waitConn)
        end)
    end
})

local PlayerGameSquidGame = PlayerGame:CreateSubTab({Title = "Squid Game", Icon = "shield", Default = false})

local antiPushEnabled = false
local antiPushConn = nil

PlayerGameSquidGame:Toggle({
    Title = "Anti Push", 
    Default = false,
    Callback = function(state)
        antiPushEnabled = state
        
        if antiPushConn then antiPushConn:Disconnect() antiPushConn = nil end
        if not antiPushEnabled then return end

        local rs = game:GetService("ReplicatedStorage")
        local movementRemote = rs:FindFirstChild("Remotes") 
            and rs.Remotes:FindFirstChild("PlayerMovementClientSide")
            
        if not movementRemote then return end

        -- 1. I-disable agad ang ragdoll sa simula
        pcall(function()
            firesignal(movementRemote.OnClientEvent, "disableRagdoll", LocalPlayer.Character)
        end)

        -- 2. Bantayan ang character para kapag may nag-trigger ng ragdoll, i-disable agad
        antiPushConn = RunService.Heartbeat:Connect(function()
            if not antiPushEnabled then return end
            
            local char = LocalPlayer.Character
            if not char then return end
            
            -- Check if the humanoid is in ragdoll state
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum and hum:GetState() == Enum.HumanoidStateType.Physics then
                pcall(function()
                    firesignal(movementRemote.OnClientEvent, "disableRagdoll", char)
                end)
            end
        end)
    end
})

local PlayerGameSquidSky = PlayerGame:CreateSubTab({ Title = "Main", Icon = "shield", Default = false })

local antiPushEnabled = false
local antiPushConn = nil

PlayerGameSquidSky:Toggle({
    Title = "Anti Push", 
    Default = false,
    Callback = function(state)
        antiPushEnabled = state
        
        if antiPushConn then antiPushConn:Disconnect() antiPushConn = nil end
        if not antiPushEnabled then return end

        local rs = game:GetService("ReplicatedStorage")
        local movementRemote = rs:FindFirstChild("Remotes") 
            and rs.Remotes:FindFirstChild("PlayerMovementClientSide")
            
        if not movementRemote then return end

        -- 1. I-disable agad ang ragdoll sa simula
        pcall(function()
            firesignal(movementRemote.OnClientEvent, "disableRagdoll", LocalPlayer.Character)
        end)

        -- 2. Bantayan ang character para kapag may nag-trigger ng ragdoll, i-disable agad
        antiPushConn = RunService.Heartbeat:Connect(function()
            if not antiPushEnabled then return end
            
            local char = LocalPlayer.Character
            if not char then return end
            
            -- Check if the humanoid is in ragdoll state
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum and hum:GetState() == Enum.HumanoidStateType.Physics then
                pcall(function()
                    firesignal(movementRemote.OnClientEvent, "disableRagdoll", char)
                end)
            end
        end)
    end
})

local antiFallEnabled = false
local antiFallConn = nil
local antiFallPlatform = nil

PlayerGameSquidSky:Toggle({
    Title = "Anti-Fall Platform",
    Default = false,
    Callback = function(state)
        antiFallEnabled = state
        
        if antiFallConn then antiFallConn:Disconnect() antiFallConn = nil end
        if antiFallPlatform then antiFallPlatform:Destroy() antiFallPlatform = nil end
        
        if not antiFallEnabled then return end

        -- Gumawa ng invisible na platform
        antiFallPlatform = Instance.new("Part")
        antiFallPlatform.Name = "KazeAntiFallPlatform"
        antiFallPlatform.Size = Vector3.new(12, 1, 12)
        antiFallPlatform.Transparency = 1
        antiFallPlatform.Anchored = true
        antiFallPlatform.CanCollide = true
        antiFallPlatform.Parent = Workspace

        antiFallConn = RunService.Heartbeat:Connect(function()
            if not antiFallEnabled then return end
            
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            
            if hrp and antiFallPlatform then
                -- Ilagay ang platform sa ilalim mo
                antiFallPlatform.CFrame = CFrame.new(hrp.Position.X, hrp.Position.Y - 3.5, hrp.Position.Z)
            end
        end)
    end
})

local PlayerGameEscape = PlayerGame:CreateSubTab({ Title = "Escape", Icon = "door-open", Default = false })

PlayerGameEscape:Button({
    Title = "Escape",
    Callback = function()
        task.spawn(function()
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end

            local triggerPart = Workspace:FindFirstChild("Map")
                and Workspace.Map:FindFirstChild("IslandEscape")
                and Workspace.Map.IslandEscape:FindFirstChild("BoatCutsceneTrigger")
                and Workspace.Map.IslandEscape.BoatCutsceneTrigger:FindFirstChild("Part")

            if triggerPart then
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
                hrp.CFrame = triggerPart.CFrame + Vector3.new(0, 3, 0)
                
                task.wait(0.2)
                
                if firetouchinterest then
                    firetouchinterest(hrp, triggerPart, 0)
                    task.wait(0.1)
                    firetouchinterest(hrp, triggerPart, 1)
                end
            end
        end)
    end
})

PlayerGameEscape:Button({
    Title = "Remove Mines",
    Callback = function()
        task.spawn(function()
            local mines = Workspace:FindFirstChild("Map")
                and Workspace.Map:FindFirstChild("IslandEscape")
                and Workspace.Map.IslandEscape:FindFirstChild("Mines")

            if mines then
                mines:Destroy()
                Window:Notify({
                    Title = "Island Escape",
                    Content = "Mines removed successfully!",
                    Duration = 3
                })
            else
                Window:Notify({
                    Title = "Island Escape",
                    Content = "No Mines Detected",
                    Duration = 3
                })
            end
        end)
    end
})

local DetectiveTab = Window:CreateTab({ Title = "Detective", Icon = "hat-glasses" })
local DetectiveMain = DetectiveTab:CreateSubTab({ Title = "Main", Icon = "hat-glasses", Default = true })
local DetectiveESP = DetectiveTab:CreateSubTab({ Title = "ESP", Icon = "eye", Default = false })

DetectiveMain:Section("Evidence")

local function getExactPrompt(obj)
    if not obj then return nil end
    local p = obj:FindFirstChildOfClass("ProximityPrompt")
    if p then return p end
    for _, desc in ipairs(obj:GetChildren()) do
        local childPrompt = desc:FindFirstChildOfClass("ProximityPrompt")
        if childPrompt then return childPrompt end
    end
    return nil
end

DetectiveMain:Button({
    Title = "Collect Evidence",
    Callback = function()
        task.spawn(function()
            local char = LocalPlayer.Character
            if not char then return end
            
            local evidenceFolder = Workspace:FindFirstChild("Data") 
                and Workspace.Data:FindFirstChild("Detective") 
                and Workspace.Data.Detective:FindFirstChild("Evidence") 
                and Workspace.Data.Detective.Evidence:FindFirstChild("Instances")
            
            if evidenceFolder then
                local count = 0
                
                for _, ev in ipairs(evidenceFolder:GetChildren()) do
                    if count >= 8 or not char.Parent then break end
                    
                    if ev and ev.Parent then
                        local evCFrame
                        if ev:IsA("BasePart") then 
                            evCFrame = ev.CFrame
                        elseif ev:IsA("Model") then 
                            evCFrame = ev:GetPivot() 
                        end
                        
                        if evCFrame then
                            -- 1. Teleport
                            char:PivotTo(evCFrame + Vector3.new(0, 3, 0))
                            task.wait(0.5) -- ANTIHIN MO MUNA BAGO MAG-FIRE
                            
                            -- 2. Fire Prompt
                            local evPrompt = getExactPrompt(ev)
                            if evPrompt and evPrompt.Enabled then
                                pcall(function()
                                    if fireproximityprompt then 
                                        fireproximityprompt(evPrompt)
                                    else 
                                        evPrompt:InputHoldBegin()
                                        task.wait(evPrompt.HoldDuration + 0.05)
                                        evPrompt:InputHoldEnd() 
                                    end
                                end)
                            end
                            
                            task.wait(0.5) -- ANTIHIN MO ULIT BAGO LUMIPAT SA SUNOD
                            count = count + 1
                        end
                    end
                end
            end
        end)
    end
})

DetectiveMain:Button({
    Title = "Deposit Evidence",
    Callback = function()
        task.spawn(function()
            local char = LocalPlayer.Character
            if not char then return end
            
            local rearPart = Workspace:FindFirstChild("Data") and Workspace.Data:FindFirstChild("Detective") and Workspace.Data.Detective:FindFirstChild("Boat") and Workspace.Data.Detective.Boat:FindFirstChild("Speedy Bowrider") and Workspace.Data.Detective.Boat["Speedy Bowrider"]:FindFirstChild("RearPart")
            
            if rearPart then
                char:PivotTo(rearPart.CFrame + Vector3.new(0, 3, 0))
                task.wait(0.3)
                
                local boatPrompt = getExactPrompt(rearPart)
                if boatPrompt and boatPrompt.Enabled then
                    pcall(function()
                        if fireproximityprompt then fireproximityprompt(boatPrompt)
                        else boatPrompt:InputHoldBegin(); task.wait(boatPrompt.HoldDuration + 0.05); boatPrompt:InputHoldEnd() end
                    end)
                end
                task.wait(0.5)
            end
        end)
    end
})

DetectiveESP:Section("Evidence")

local evidenceEspEnabled = false
local evidenceHighlights = {}
local evidenceConnections = {}

local function clearEvidenceESP()
    for _, conn in ipairs(evidenceConnections) do pcall(function() conn:Disconnect() end) end
    table.clear(evidenceConnections)
    for _, hl in pairs(evidenceHighlights) do pcall(function() hl:Destroy() end) end
    table.clear(evidenceHighlights)
end

local function applyEvidenceHighlight(obj)
    if not obj or evidenceHighlights[obj] then return end
    
    if obj:IsA("BasePart") or obj:IsA("Model") then
        local hl = Instance.new("Highlight")
        hl.Name = "EvidenceESP"
        hl.FillColor = Color3.fromRGB(255, 255, 0)
        hl.OutlineColor = Color3.fromRGB(255, 255, 0)
        hl.FillTransparency = 0.5
        hl.OutlineTransparency = 0
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Adornee = obj
        hl.Parent = obj
        
        evidenceHighlights[obj] = hl
    end
end

DetectiveESP:Toggle({
    Title = "ESP Evidence",
    Default = false,
    Callback = function(state)
        evidenceEspEnabled = state
        clearEvidenceESP()
        
        if not evidenceEspEnabled then return end
        
        task.spawn(function()
            local data = Workspace:FindFirstChild("Data")
            local detective = data and data:FindFirstChild("Detective")
            local evidence = detective and detective:FindFirstChild("Evidence")
            local instances = evidence and evidence:FindFirstChild("Instances")
            
            if instances then
                for _, obj in ipairs(instances:GetChildren()) do
                    applyEvidenceHighlight(obj)
                end
                
                table.insert(evidenceConnections, instances.ChildAdded:Connect(function(obj)
                    if evidenceEspEnabled then
                        applyEvidenceHighlight(obj)
                    end
                end))
            end
        end)
    end
})

DetectiveESP:Section("Island")

local detectiveActive = false
local detectiveConn = nil

DetectiveESP:Toggle({
    Title = "ESP Island",
    Default = false,
    Callback = function(state)
        detectiveActive = state
        if detectiveConn then detectiveConn:Disconnect() detectiveConn = nil end
        
        if not detectiveActive then
            pcall(function()
                local det = Workspace:FindFirstChild("Data") 
                    and Workspace.Data:FindFirstChild("FinalFightTP") 
                    and Workspace.Data.FinalFightTP:FindFirstChild("DetectiveTp")
                if det then
                    if det:FindFirstChild("KazeDetectiveESP") then
                        det.KazeDetectiveESP:Destroy()
                    end
                    if det:FindFirstChild("KazeDetectiveBillboard") then
                        det.KazeDetectiveBillboard:Destroy()
                    end
                end
            end)
        else
            detectiveConn = RunService.Heartbeat:Connect(function()
                if not detectiveActive then return end
                pcall(function()
                    local det = Workspace:FindFirstChild("Data") 
                        and Workspace.Data:FindFirstChild("FinalFightTP") 
                        and Workspace.Data.FinalFightTP:FindFirstChild("DetectiveTp")
                    if det then
                        if not det:FindFirstChild("KazeDetectiveESP") then
                            local hl = Instance.new("Highlight")
                            hl.Name = "KazeDetectiveESP"
                            hl.FillColor = Color3.fromRGB(0, 255, 128)
                            hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                            hl.FillTransparency = 0.4
                            hl.OutlineTransparency = 0
                            hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                            hl.Parent = det
                        end
                        if not det:FindFirstChild("KazeDetectiveBillboard") then
                            local bb = Instance.new("BillboardGui")
                            bb.Name = "KazeDetectiveBillboard"
                            bb.Size = UDim2.new(0, 100, 0, 40)
                            bb.StudsOffset = Vector3.new(0, 3, 0)
                            bb.AlwaysOnTop = true
                            bb.Parent = det

                            local txt = Instance.new("TextLabel")
                            txt.Size = UDim2.new(1, 0, 1, 0)
                            txt.BackgroundTransparency = 1
                            txt.Font = Enum.Font.GothamBold
                            txt.Text = "Island"
                            txt.TextColor3 = Color3.fromRGB(255, 255, 255)
                            txt.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                            txt.TextStrokeTransparency = 0
                            txt.TextSize = 16
                            txt.Parent = bb
                        end
                    end
                end)
            end)
        end
    end
})


local GuardTab = Window:CreateTab({ Title = "Guard", Icon = "venetian-mask" })

local GuardMain = GuardTab:CreateSubTab({ Title = "Main", Icon = "venetian-mask", Default = true })

-- ==========================================
-- AUTO BURN COFFINS
-- ==========================================
local autoCleanEnabled = false
local cleanConn = nil
local cleanThrottle = 0

GuardMain:Toggle({
    Title = "Auto Clean DeadBodies", Default = false,
    Callback = function(state)
        autoCleanEnabled = state
        if cleanConn then cleanConn:Disconnect() cleanConn = nil end
        if not autoCleanEnabled then return end

        cleanConn = RunService.Heartbeat:Connect(function()
            if not autoCleanEnabled then return end
            if tick() - cleanThrottle < 0.5 then return end
            cleanThrottle = tick()

            -- Loop through ALL dead characters in the workspace
            local data = Workspace:FindFirstChild("Data")
            local deadFolder = data and data:FindFirstChild("DeadCharacters")

            if not deadFolder then return end

            for _, body in ipairs(deadFolder:GetChildren()) do
                if body and body:IsA("Model") then
                    local prompt = body:FindFirstChildWhichIsA("ProximityPrompt", true)
                    
                    if prompt and prompt.Enabled then
                        -- 1. Override the distance limit so we can fire it from anywhere
                        pcall(function()
                            prompt.MaxActivationDistance = 10000
                            prompt.RequiresLineOfSight = false
                        end)

                        -- 2. Fire the prompt
                        pcall(function()
                            if fireproximityprompt then 
                                fireproximityprompt(prompt) 
                            else 
                                prompt:InputHoldBegin()
                                task.wait(prompt.HoldDuration + 0.05)
                                prompt:InputHoldEnd() 
                            end
                        end)
                    end
                end
            end
        end)
    end
})

local autoBurnEnabled = false
local burnConn = nil
local burnThrottle = 0
local burnState = "tp1" -- states: tp1, pick, tp2, burn

GuardMain:Toggle({
    Title = "Auto Burn Coffins",
    Default = false,
    Callback = function(state)
        autoBurnEnabled = state
        if burnConn then burnConn:Disconnect() burnConn = nil end
        
        if not autoBurnEnabled then return end
        
        local pos1 = CFrame.new(8119, 82, 3578)
        local pos2 = CFrame.new(8115, 81, 3551)
        local pos2Vector = Vector3.new(8115, 81, 3551)

        burnConn = RunService.Heartbeat:Connect(function()
            if not autoBurnEnabled then return end
            if tick() - burnThrottle < 0.2 then return end
            burnThrottle = tick()

            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local data = Workspace:FindFirstChild("Data")
            local incRoom = data and data:FindFirstChild("IncinerationRoom")
            local pickupFolder = incRoom and incRoom:FindFirstChild("PickupCoffins")
            local deadFolder = data and data:FindFirstChild("DeadCharacters")

            if not hrp then return end

            if burnState == "tp1" then
                if pickupFolder and #pickupFolder:GetChildren() > 0 then
                    hrp.AssemblyLinearVelocity = Vector3.zero
                    hrp.AssemblyAngularVelocity = Vector3.zero
                    hrp.CFrame = pos1
                    burnState = "pick"
                end

            elseif burnState == "pick" then
                local picked = false
                if pickupFolder then
                    for _, child in ipairs(pickupFolder:GetChildren()) do
                        local prompt = child:FindFirstChildWhichIsA("ProximityPrompt", true)
                        if prompt and prompt.Enabled then
                            pcall(function()
                                if fireproximityprompt then fireproximityprompt(prompt) 
                                else prompt:InputHoldBegin(); task.wait(prompt.HoldDuration + 0.05); prompt:InputHoldEnd() end
                            end)
                            picked = true
                            break
                        end
                    end
                end
                
                if picked then
                    burnState = "tp2"
                else
                    burnState = "tp1"
                end

            elseif burnState == "tp2" then
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
                hrp.CFrame = pos2
                burnState = "burn"

            elseif burnState == "burn" then
                local nearestPrompt = nil
                local shortestDist = 5
                
                if incRoom then
                    for _, desc in ipairs(incRoom:GetDescendants()) do
                        if desc:IsA("ProximityPrompt") then
                            local parentPart = desc.Parent
                            if parentPart and parentPart:IsA("BasePart") then
                                local dist = (parentPart.Position - pos2Vector).Magnitude
                                if dist <= 5 and dist < shortestDist then
                                    shortestDist = dist
                                    nearestPrompt = desc
                                end
                            end
                        end
                    end
                end

                if nearestPrompt and nearestPrompt.Enabled then
                    pcall(function()
                        if fireproximityprompt then fireproximityprompt(nearestPrompt) 
                        else nearestPrompt:InputHoldBegin(); task.wait(nearestPrompt.HoldDuration + 0.05); nearestPrompt:InputHoldEnd() end
                    end)
                end

                -- Check if player model has coffin, if yes, it means we are still holding it and it hasn't been processed
                local hasCoffin = char:FindFirstChild("Coffin", true) ~= nil

                if not hasCoffin then
                    burnState = "tp1"
                end
            end
        end)
    end
})

local GuardKitchen = GuardTab:CreateSubTab({ Title = "Kitchen", Icon = "chef-hat", Default = false })

GuardKitchen:Button({
    Title = "Auto Kitchen",
    Callback = function()
        task.spawn(function()
            pcall(function()
                local Players = game:GetService("Players")
                local Workspace = game:GetService("Workspace")
                local hrp = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if not hrp then return end

                local kitchen = Workspace.Data.Kitchen
                local boxes = kitchen.Boxes
                local pots = kitchen.Pots

                local potTargets = {
                    {pos = Vector3.new(8198, 101, 3642), isSmoke = true},
                    {pos = Vector3.new(8203, 101, 3643), isSmoke = false},
                    {pos = Vector3.new(8207, 101, 3642), isSmoke = false},
                    {pos = Vector3.new(8197, 101, 3656), isSmoke = false},
                    {pos = Vector3.new(8203, 101, 3656), isSmoke = false},
                    {pos = Vector3.new(8208, 101, 3656), isSmoke = false}
                }

                local function triggerNearestPrompt(parentObj, targetPos)
                    local closest, dist = nil, math.huge
                    for _, desc in ipairs(parentObj:GetDescendants()) do
                        if desc:IsA("ProximityPrompt") and desc.Enabled then
                            local pPos = desc.Parent:IsA("BasePart") and desc.Parent.Position or (desc.Parent:IsA("Model") and desc.Parent:GetPivot().Position)
                            if pPos then
                                local d = (pPos - targetPos).Magnitude
                                if d < dist then
                                    dist = d
                                    closest = desc
                                end
                            end
                        end
                    end
                    if closest then
                        fireproximityprompt(closest)
                    end
                end

                local function grabIngredients()
                    hrp.CFrame = CFrame.new(8199, 101, 3628)
                    task.wait(0.25)

                    local grabbedVeg, grabbedBeef = false, false
                    for _, model in ipairs(boxes:GetChildren()) do
                        if not grabbedVeg and model.Name == "Vegetables" then
                            local prompt = model:FindFirstChildWhichIsA("ProximityPrompt", true)
                            if prompt and prompt.Enabled then
                                fireproximityprompt(prompt)
                                grabbedVeg = true
                                task.wait(0.15)
                            end
                        elseif not grabbedBeef and model.Name == "Beef" then
                            local prompt = model:FindFirstChildWhichIsA("ProximityPrompt", true)
                            if prompt and prompt.Enabled then
                                fireproximityprompt(prompt)
                                grabbedBeef = true
                                task.wait(0.15)
                            end
                        end
                        if grabbedVeg and grabbedBeef then break end
                    end
                end

                for _, target in ipairs(potTargets) do
                    grabIngredients()
                    hrp.CFrame = CFrame.new(target.pos)
                    task.wait(0.25)
                    triggerNearestPrompt(pots, target.pos)
                    task.wait(0.2)
                end
            end)
        end)
    end
})

local autoStoreEnabled = false
local storeConn = nil

GuardKitchen:Toggle({
    Title = "Auto Store Cooked Food", Default = false,
    Callback = function(state)
        autoStoreEnabled = state
        if storeConn then storeConn:Disconnect() storeConn = nil end
        if not autoStoreEnabled then return end

        storeConn = RunService.Heartbeat:Connect(function()
            if not autoStoreEnabled then return end

            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end

            local potsFolder = Workspace:FindFirstChild("Data") 
                and Workspace.Data:FindFirstChild("Kitchen") 
                and Workspace.Data.Kitchen:FindFirstChild("Pots")

            local storePart = Workspace:FindFirstChild("Data") 
                and Workspace.Data:FindFirstChild("GuardQuarters") 
                and Workspace.Data.GuardQuarters:FindFirstChild("Armoury") 
                and Workspace.Data.GuardQuarters.Armoury:FindFirstChild("Misc") 
                and Workspace.Data.GuardQuarters.Armoury.Misc:FindFirstChild("StoreFood")

            if not potsFolder or not storePart then return end

            local function getPrompt(obj)
                if not obj then return nil end
                return obj:FindFirstChildWhichIsA("ProximityPrompt", true)
            end

            local function firePrompt(prompt)
                if prompt and prompt.Enabled then
                    pcall(function()
                        if fireproximityprompt then 
                            fireproximityprompt(prompt) 
                        else 
                            prompt:InputHoldBegin() 
                            task.wait(prompt.HoldDuration + 0.05) 
                            prompt:InputHoldEnd() 
                        end
                    end)
                end
            end

            -- Find any TakeFoodPrompt that is Enabled (cooked)
            local cookedPot = nil
            for _, pot in ipairs(potsFolder:GetChildren()) do
                if pot.Name == "Pot" then
                    local takePrompt = pot:FindFirstChild("TakeFoodPrompt")
                    if takePrompt and takePrompt.Enabled then
                        cookedPot = pot
                        break
                    end
                end
            end

            if cookedPot then
                local takePrompt = cookedPot:FindFirstChild("TakeFoodPrompt")
                local potPart = cookedPot:FindFirstChildWhichIsA("BasePart", true)

                if takePrompt and potPart then
                    -- Teleport to Cooked Pot
                    hrp.AssemblyLinearVelocity = Vector3.zero
                    hrp.AssemblyAngularVelocity = Vector3.zero
                    hrp.CFrame = potPart.CFrame + Vector3.new(0, 3, 0)
                    task.wait(0.3)

                    -- Take Food
                    firePrompt(takePrompt)
                    task.wait(0.3)

                    -- Teleport to Store Food
                    hrp.AssemblyLinearVelocity = Vector3.zero
                    hrp.AssemblyAngularVelocity = Vector3.zero
                    hrp.CFrame = CFrame.new(8218, 101, 3648)
                    task.wait(0.3)

                    -- Store Food
                    local storePrompt = getPrompt(storePart)
                    firePrompt(storePrompt)
                    task.wait(0.3)
                end
            end
        end)
    end
})

