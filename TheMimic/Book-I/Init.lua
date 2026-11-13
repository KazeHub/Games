local KazeUI = KazeUI or loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/KazeHub/UI/refs/heads/main/libraryUI.txt"
))()

local Window = KazeUI:CreateWindow({
    Title = "THE MIMIC",
    Author = "KAZE",
    Version = "BOOK I",
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
local Control4 = Window:CreateTab({ Title = "Control 4", Icon = "Book" })

--------------------------------------------------
-- CONTROL 1 TAB
--------------------------------------------------

local JigokuSection = Control1:SectionUI({
    Title = "Jigoku",
    Open = false
})

JigokuSection:Button({
    Title = "Jigoku Check",
    Callback = function()
        local npc = workspace:FindFirstChild("IdleNPC")

        if npc then
            Window:Notify({
                Title = "Jigoku Check",
                Content = "Jigoku is here",
                Duration = 4
            })
        else
            Window:Notify({
                Title = "Jigoku Check",
                Content = "Jigoku is not here",
                Duration = 4
            })
        end
    end
})

JigokuSection:Button({
    Title = "Talk To Red Guy",
    Callback = function()
        local npc = workspace:FindFirstChild("IdleNPC")
        if not npc then
            Window:Notify({
                Title = "Error",
                Content = "Jigoku is not here",
                Duration = 4
            })
            return
        end

        local character = player.Character or player.CharacterAdded:Wait()
        local hrp = character:WaitForChild("HumanoidRootPart")

        -- Teleport to specific coordinates
        SafeTeleport(hrp, Vector3.new(310.4, 3.2, 322.7))
        
        -- Wait 0.3s then fire prompt
        task.wait(0.3)
        for _, prompt in ipairs(npc:GetDescendants()) do
            if prompt:IsA("ProximityPrompt") then
                fireproximityprompt(prompt)
            end
        end

        -- Wait 0.016s then fire prompt again
        task.wait(0.016)
        for _, prompt in ipairs(npc:GetDescendants()) do
            if prompt:IsA("ProximityPrompt") then
                fireproximityprompt(prompt)
            end
        end
    end
})


local TweenService=game:GetService("TweenService")
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local Workspace=game:GetService("Workspace")

local function GetHRP()
    local p=Players.LocalPlayer
    if not p then return end
    local c=p.Character
    if not c then
        c=p.Character or p.CharacterAdded:Wait()
    end
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function GetPart(o)
    if not o then return end
    if o:IsA("BasePart") then return o end
    if o:IsA("Model") then return o.PrimaryPart or o:FindFirstChildWhichIsA("BasePart",true) end
end

local function TP(o)
    local h=GetHRP()
    local p=GetPart(o)
    if h and p then h.CFrame=p.CFrame end
end

local function FireTouch(o)
    local h=GetHRP()
    local p=GetPart(o)
    if not h or not p then return end
    if firetouchinterest then
        firetouchinterest(h,p,0)
        task.wait()
        firetouchinterest(h,p,1)
    else
        h.CFrame=p.CFrame
    end
end

local function TweenTo(pos)
    local h=GetHRP()
    if not h then return end
    local t=TweenService:Create(h,TweenInfo.new(2,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{CFrame=CFrame.new(pos)})
    t:Play()
end

local espObjects={}
local espConnections={}

local function ClearESP(o)
    local d=espObjects[o]
    if d then
        for _,v in ipairs(d) do pcall(function() v:Destroy() end) end
        espObjects[o]=nil
    end
end

local function ESPPart(o)
    if not o then return end
    if o:IsA("BasePart") then return o end
    if o:IsA("Model") then return o.PrimaryPart or o:FindFirstChildWhichIsA("BasePart",true) end
end

local function AddItemESP(o)
    if not o or not o.Parent or espObjects[o] then return end
    local p=ESPPart(o)
    if not p then return end
    local h=Instance.new("Highlight")
    h.Name="ControlI_ItemESP"
    h.FillColor=Color3.fromRGB(255,255,0)
    h.OutlineColor=Color3.fromRGB(255,255,255)
    h.FillTransparency=0.5
    h.OutlineTransparency=0
    h.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
    h.Adornee=o
    h.Parent=o
    local b=Instance.new("BillboardGui")
    b.Name="ControlI_ItemName"
    b.Size=UDim2.fromOffset(150,30)
    b.StudsOffset=Vector3.new(0,2,0)
    b.AlwaysOnTop=true
    b.Parent=p
    local t=Instance.new("TextLabel")
    t.BackgroundTransparency=1
    t.Size=UDim2.fromScale(1,1)
    t.Text=o.Name
    t.TextColor3=Color3.fromRGB(255,255,0)
    t.TextStrokeColor3=Color3.fromRGB(0,0,0)
    t.TextStrokeTransparency=0
    t.TextSize=13
    t.Font=Enum.Font.SourceSansBold
    t.Parent=b
    espObjects[o]={h,b}
end

local function AddMonsterESP(o)
    if not o or not o.Parent or espObjects[o] or not o:IsA("Model") then return end
    local p=ESPPart(o)
    if not p then return end
    local h=Instance.new("Highlight")
    h.Name="ControlI_MonsterESP"
    h.FillColor=Color3.fromRGB(255,0,0)
    h.OutlineColor=Color3.fromRGB(255,255,255)
    h.FillTransparency=0.5
    h.OutlineTransparency=0
    h.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
    h.Adornee=o
    h.Parent=o
    espObjects[o]={h}
end

Control1:Section("STAGE I")

Control1:Button({
    Title="Auto Win",
    Callback=function()
        task.spawn(function()
            FireTouch(Workspace:FindFirstChild("Game Teleporter"))
        end)
    end
})

Control1:Toggle({
    Title="ESP Item",
    Default=false,
    Callback=function(s)
        local g=Workspace:FindFirstChild("Givers")
        for _,n in ipairs({"Key1","Key2","Key3"}) do
            local o=g and g:FindFirstChild(n)
            if s then AddItemESP(o) else ClearESP(o) end
        end
    end
})

Control1:Toggle({
    Title="ESP Monster",
    Default=false,
    Callback=function(s)
        local g=Workspace:FindFirstChild("GameAI")
        local o=g and g:FindFirstChild("AI")
        if s then AddMonsterESP(o) else ClearESP(o) end
    end
})

Control1:Section("STAGE II")

Control1:Button({
    Title="Auto Win",
    Callback=function()
        task.spawn(function()
            local group=Workspace:FindFirstChild("GroupTP")
            local touch=group and group:FindFirstChild("Touch2")
            if not touch then return end
            TP(touch)
            task.wait(10)
            TweenTo(Vector3.new(2141,257,-2969))
        end)
    end
})

Control1:Toggle({
    Title="ESP Monster",
    Default=false,
    Callback=function(s)
        local targets={}
        local g=Workspace:FindFirstChild("GameAI")
        local g2=Workspace:FindFirstChild("GameAI2")

        if g then
            targets[#targets+1]=g:FindFirstChild("KurikoFloor")
            targets[#targets+1]=g:FindFirstChild("KurikoCeiling")
        end

        if g2 then
            targets[#targets+1]=g2:FindFirstChild("Biwaki")
            targets[#targets+1]=g2:FindFirstChild("realshizu")
            local c=g2:GetChildren()
            for _,i in ipairs({14,11,16,15,17,13,12}) do
                targets[#targets+1]=c[i]
            end
        end

        for _,o in ipairs(targets) do
            if s then AddMonsterESP(o) else ClearESP(o) end
        end
    end
})
local Players=game:GetService("Players")
local Workspace=game:GetService("Workspace")

local function GetHRP()
    local p=Players.LocalPlayer
    if not p then return end
    local c=p.Character or p.CharacterAdded:Wait()
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function GetPart(o)
    if not o then return end
    if o:IsA("BasePart") then return o end
    if o:IsA("Model") then return o.PrimaryPart or o:FindFirstChildWhichIsA("BasePart",true) end
end

local function FireTouch(o)
    local h=GetHRP()
    local p=GetPart(o)
    if not h or not p then return end
    if firetouchinterest then
        firetouchinterest(h,p,0)
        task.wait()
        firetouchinterest(h,p,1)
    else
        h.CFrame=p.CFrame
    end
end

local espObjects={}

local function ClearESP(o)
    local d=espObjects[o]
    if d then
        for _,v in ipairs(d) do pcall(function() v:Destroy() end) end
        espObjects[o]=nil
    end
end

local function ESPPart(o)
    if not o then return end
    if o:IsA("BasePart") then return o end
    if o:IsA("Model") then return o.PrimaryPart or o:FindFirstChildWhichIsA("BasePart",true) end
end

local function AddItemESP(o)
    if not o or not o.Parent or espObjects[o] then return end
    local p=ESPPart(o)
    if not p then return end
    local h=Instance.new("Highlight")
    h.Name="ControlII_ItemESP"
    h.FillColor=Color3.fromRGB(255,255,0)
    h.OutlineColor=Color3.fromRGB(255,255,255)
    h.FillTransparency=0.5
    h.OutlineTransparency=0
    h.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
    h.Adornee=o
    h.Parent=o
    local b=Instance.new("BillboardGui")
    b.Name="ControlII_ItemName"
    b.Size=UDim2.fromOffset(150,30)
    b.StudsOffset=Vector3.new(0,2,0)
    b.AlwaysOnTop=true
    b.Parent=p
    local t=Instance.new("TextLabel")
    t.BackgroundTransparency=1
    t.Size=UDim2.fromScale(1,1)
    t.Text=o.Name
    t.TextColor3=Color3.fromRGB(255,255,0)
    t.TextStrokeColor3=Color3.fromRGB(0,0,0)
    t.TextStrokeTransparency=0
    t.TextSize=13
    t.Font=Enum.Font.SourceSansBold
    t.Parent=b
    espObjects[o]={h,b}
end

local function AddMonsterESP(o)
    if not o or not o.Parent or espObjects[o] or not o:IsA("Model") then return end
    if not ESPPart(o) then return end
    local h=Instance.new("Highlight")
    h.Name="ControlII_MonsterESP"
    h.FillColor=Color3.fromRGB(255,0,0)
    h.OutlineColor=Color3.fromRGB(255,255,255)
    h.FillTransparency=0.5
    h.OutlineTransparency=0
    h.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
    h.Adornee=o
    h.Parent=o
    espObjects[o]={h}
end

local function StageTargets(stage,kind)
    if stage==1 then
        if kind=="Monster" then
            local g=Workspace:FindFirstChild("GameAI")
            return {
                g and g:FindFirstChild("AI"),
                g and g:FindFirstChild("Kusonoki")
            }
        else
            local c=Workspace:GetChildren()
            return {
                Workspace:FindFirstChild("Butterfly"),
                c[143],
                Workspace:FindFirstChild("Key1")
            }
        end
    else
        if kind=="Monster" then
            local g=Workspace:FindFirstChild("GameAI2")
            local g1=Workspace:FindFirstChild("GameAI")
            return {
                g and g:FindFirstChild("AI"),
                g1 and g1:FindFirstChild("AI")
            }
        else
            local c=Workspace:GetChildren()
            return {
                Workspace:FindFirstChild("Butterfly"),
                c[281]
            }
        end
    end
end

local function SetESP(stage,kind,state)
    for _,o in ipairs(StageTargets(stage,kind)) do
        if state then
            if kind=="Monster" then
                AddMonsterESP(o)
            else
                AddItemESP(o)
            end
        else
            ClearESP(o)
        end
    end
end

Control2:Section("STAGE I")

Control2:Button({
    Title="Auto Win",
    Callback=function()
        task.spawn(function()
            FireTouch(Workspace:FindFirstChild("Game Teleporter"))
        end)
    end
})

Control2:Toggle({
    Title="ESP Items",
    Default=false,
    Callback=function(s)
        SetESP(1,"Item",s)
    end
})

Control2:Toggle({
    Title="ESP Monsters",
    Default=false,
    Callback=function(s)
        SetESP(1,"Monster",s)
    end
})

Control2:Section("STAGE II")

Control2:Button({
    Title="Auto Win",
    Callback=function()
        task.spawn(function()
            FireTouch(Workspace:FindFirstChild("Game Teleporter"))
        end)
    end
})

Control2:Toggle({
    Title="ESP Items",
    Default=false,
    Callback=function(s)
        SetESP(2,"Item",s)
    end
})

Control2:Toggle({
    Title="ESP Monsters",
    Default=false,
    Callback=function(s)
        SetESP(2,"Monster",s)
    end
})

Control2:Section("STAGE III")

Control2:Button({
    Title="Auto Win",
    Callback=function()
        task.spawn(function()
            local touch=Workspace:FindFirstChild("Teleporters")
            touch=touch and touch:FindFirstChild("Touch")
            local h=GetHRP()
            local p=GetPart(touch)
            if not h or not p then return end
            h.CFrame=p.CFrame
            task.wait(5)
            local tween=game:GetService("TweenService"):Create(
                h,
                TweenInfo.new(2,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),
                {CFrame=CFrame.new(1162,85,-353)}
            )
            tween:Play()
        end)
    end
})

Control2:Toggle({
    Title="ESP Items",
    Default=false,
    Callback=function(s)
        local o=Workspace:FindFirstChild("Butterfly")
        if s then AddItemESP(o) else ClearESP(o) end
    end
})

Control2:Toggle({
    Title="ESP Monster",
    Default=false,
    Callback=function(s)
        local g=Workspace:FindFirstChild("GameAI")
        local o=g and g:FindFirstChild("AI")
        if s then AddMonsterESP(o) else ClearESP(o) end
    end
})


--------------------------------------------------
-- CONTROL 3 TAB
--------------------------------------------------
local Players=game:GetService("Players")
local Workspace=game:GetService("Workspace")

local function GetHRP()
    local p=Players.LocalPlayer
    if not p then return end
    local c=p.Character or p.CharacterAdded:Wait()
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function GetPart(o)
    if not o then return end
    if o:IsA("BasePart") then return o end
    if o:IsA("Model") then return o.PrimaryPart or o:FindFirstChildWhichIsA("BasePart",true) end
end

local function FireTouch(o)
    local h=GetHRP()
    local p=GetPart(o)
    if not h or not p then return end
    if firetouchinterest then
        firetouchinterest(h,p,0)
        task.wait()
        firetouchinterest(h,p,1)
    else
        h.CFrame=p.CFrame
    end
end

local espObjects={}

local function ClearESP(o)
    local d=espObjects[o]
    if d then
        for _,v in ipairs(d) do pcall(function() v:Destroy() end) end
        espObjects[o]=nil
    end
end

local function ESPPart(o)
    if not o then return end
    if o:IsA("BasePart") then return o end
    if o:IsA("Model") then return o.PrimaryPart or o:FindFirstChildWhichIsA("BasePart",true) end
end

local function AddItemESP(o,name)
    if not o or not o.Parent or espObjects[o] then return end
    local p=ESPPart(o)
    if not p then return end
    local h=Instance.new("Highlight")
    h.Name="ControlIII_ItemESP"
    h.FillColor=Color3.fromRGB(255,255,0)
    h.OutlineColor=Color3.fromRGB(255,255,255)
    h.FillTransparency=0.5
    h.OutlineTransparency=0
    h.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
    h.Adornee=o
    h.Parent=o
    local b=Instance.new("BillboardGui")
    b.Name="ControlIII_ItemName"
    b.Size=UDim2.fromOffset(150,30)
    b.StudsOffset=Vector3.new(0,2,0)
    b.AlwaysOnTop=true
    b.Parent=p
    local t=Instance.new("TextLabel")
    t.BackgroundTransparency=1
    t.Size=UDim2.fromScale(1,1)
    t.Text=name or o.Name
    t.TextColor3=Color3.fromRGB(255,255,0)
    t.TextStrokeColor3=Color3.fromRGB(0,0,0)
    t.TextStrokeTransparency=0
    t.TextSize=13
    t.Font=Enum.Font.SourceSansBold
    t.Parent=b
    espObjects[o]={h,b}
end

local function AddMonsterESP(o)
    if not o or not o.Parent or espObjects[o] or not o:IsA("Model") then return end
    if not ESPPart(o) then return end
    local h=Instance.new("Highlight")
    h.Name="ControlIII_MonsterESP"
    h.FillColor=Color3.fromRGB(255,0,0)
    h.OutlineColor=Color3.fromRGB(255,255,255)
    h.FillTransparency=0.5
    h.OutlineTransparency=0
    h.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
    h.Adornee=o
    h.Parent=o
    espObjects[o]={h}
end

Control3:Section("STAGE I")

Control3:Button({
    Title="Auto Win",
    Callback=function()
        task.spawn(function()
            FireTouch(Workspace:FindFirstChild("Game Teleporter"))
        end)
    end
})

Control3:AddLabel("Codes")

Control3:Paragraph({
    Title="First Code",
    Content="3015"
})

Control3:Paragraph({
    Title="Second Code",
    Content="8749"
})

Control3:Toggle({
    Title="ESP Items",
    Default=false,
    Callback=function(s)
        local targets={
            {Workspace:FindFirstChild("Crowbar")},
            {Workspace:FindFirstChild("Blade")},
            {Workspace:FindFirstChild("OfferItem") and Workspace.OfferItem:FindFirstChild("Sword"),"Place Sword"},
            {Workspace:FindFirstChild("Butterfly")}
        }
        for _,v in ipairs(targets) do
            if s then AddItemESP(v[1],v[2]) else ClearESP(v[1]) end
        end
    end
})

Control3:Toggle({
    Title="ESP Monster",
    Default=false,
    Callback=function(s)
        local g=Workspace:FindFirstChild("GameAI")
        local o=g and g:FindFirstChild("kaito")
        if s then AddMonsterESP(o) else ClearESP(o) end
    end
})

Control3:Section("STAGE II")

Control3:Button({
    Title="Auto Win",
    Callback=function()
        task.spawn(function()
            FireTouch(Workspace:FindFirstChild("Game Teleporter"))
        end)
    end
})

Control3:Toggle({
    Title="ESP Items",
    Default=false,
    Callback=function(s)
        local g=Workspace:FindFirstChild("Givers")
        local b=Workspace:FindFirstChild("BellFolder")
        local targets={
            g and g:FindFirstChild("Key1"),
            g and g:FindFirstChild("Key2"),
            g and g:FindFirstChild("Blade"),
            g and g:FindFirstChild("Corrupted"),
            Workspace:FindFirstChild("Rose"),
            b and b:FindFirstChild("Bell"),
            b and b:FindFirstChild("Bell2"),
            b and b:FindFirstChild("Bell3"),
            b and b:FindFirstChild("Bell4"),
            b and b:FindFirstChild("Bell5")
        }
        for _,o in ipairs(targets) do
            if s then AddItemESP(o) else ClearESP(o) end
        end
    end
})

Control3:Toggle({
    Title="ESP Monster",
    Default=false,
    Callback=function(s)
        local g=Workspace:FindFirstChild("GameAI")
        local o=g and g:FindFirstChild("AI")
        if s then AddMonsterESP(o) else ClearESP(o) end
    end
})

Control3:Section("STAGE III")

Control3:Button({
    Title="Auto Win",
    Callback=function()
        task.spawn(function()
            local player=Players.LocalPlayer
            local character=player.Character or player.CharacterAdded:Wait()
            local hrp=character:WaitForChild("HumanoidRootPart")
            local t3=Workspace:FindFirstChild("Teleporters3")
            local t2=Workspace:FindFirstChild("Teleporters2")
            local final=Workspace:FindFirstChild("FinalCutscene")
            if not t3 or not t2 or not final then return end
            SafeTeleport(hrp,t3.Touch.Position)
            repeat task.wait(5) until (hrp.Position-t3.Point.Position).Magnitude<20
            task.wait(0.5)
            SafeTween(hrp,t2.Touch.Position)
            repeat task.wait(0.1) until (hrp.Position-t2.Point.Position).Magnitude<20
            task.wait(0.5)
            SafeTween(hrp,final.Door.Position)
        end)
    end
})

Control3:Toggle({
    Title="ESP Items",
    Default=false,
    Callback=function(s)
        local c=Workspace:GetChildren()
        local targets={
            c[124],
            Workspace:FindFirstChild("CodeDoor")
        }
        for _,o in ipairs(targets) do
            if s then AddItemESP(o) else ClearESP(o) end
        end
    end
})

Control3:Toggle({
    Title="ESP Monster",
    Default=false,
    Callback=function(s)
        local o=Workspace:FindFirstChild("omukadeMAIN")
        if s then AddMonsterESP(o) else ClearESP(o) end
    end
})

--------------------------------------------------
-- CONTROL 4 TAB
--------------------------------------------------
local Players=game:GetService("Players")
local Workspace=game:GetService("Workspace")

local function GetHRP()
    local p=Players.LocalPlayer
    if not p then return end
    local c=p.Character or p.CharacterAdded:Wait()
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function GetPart(o)
    if not o then return end
    if o:IsA("BasePart") then return o end
    if o:IsA("Model") then return o.PrimaryPart or o:FindFirstChildWhichIsA("BasePart",true) end
end

local function FireTouch(o)
    local h=GetHRP()
    local p=GetPart(o)
    if not h or not p then return end
    if firetouchinterest then
        firetouchinterest(h,p,0)
        task.wait()
        firetouchinterest(h,p,1)
    else
        h.CFrame=p.CFrame
    end
end

local function FirePrompt(o)
    if not o then return end
    local p=o:IsA("ProximityPrompt") and o or o:FindFirstChildWhichIsA("ProximityPrompt",true)
    if p then
        pcall(function()
            p.Enabled=true
            fireproximityprompt(p)
        end)
    end
end

local espObjects={}

local function ClearESP(o)
    local d=espObjects[o]
    if d then
        for _,v in ipairs(d) do pcall(function() v:Destroy() end) end
        espObjects[o]=nil
    end
end

local function ESPPart(o)
    if not o then return end
    if o:IsA("BasePart") then return o end
    if o:IsA("Model") then return o.PrimaryPart or o:FindFirstChildWhichIsA("BasePart",true) end
end

local function AddItemESP(o,name)
    if not o or not o.Parent or espObjects[o] then return end
    local p=ESPPart(o)
    if not p then return end
    local h=Instance.new("Highlight")
    h.Name="ControlIV_ItemESP"
    h.FillColor=Color3.fromRGB(255,255,0)
    h.OutlineColor=Color3.fromRGB(255,255,255)
    h.FillTransparency=0.5
    h.OutlineTransparency=0
    h.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
    h.Adornee=o
    h.Parent=o
    local b=Instance.new("BillboardGui")
    b.Name="ControlIV_ItemName"
    b.Size=UDim2.fromOffset(150,30)
    b.StudsOffset=Vector3.new(0,2,0)
    b.AlwaysOnTop=true
    b.Parent=p
    local t=Instance.new("TextLabel")
    t.BackgroundTransparency=1
    t.Size=UDim2.fromScale(1,1)
    t.Text=name or o.Name
    t.TextColor3=Color3.fromRGB(255,255,0)
    t.TextStrokeColor3=Color3.fromRGB(0,0,0)
    t.TextStrokeTransparency=0
    t.TextSize=13
    t.Font=Enum.Font.SourceSansBold
    t.Parent=b
    espObjects[o]={h,b}
end

local function AddMonsterESP(o)
    if not o or not o.Parent or espObjects[o] or not o:IsA("Model") then return end
    if not ESPPart(o) then return end
    local h=Instance.new("Highlight")
    h.Name="ControlIV_MonsterESP"
    h.FillColor=Color3.fromRGB(255,0,0)
    h.OutlineColor=Color3.fromRGB(255,255,255)
    h.FillTransparency=0.5
    h.OutlineTransparency=0
    h.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
    h.Adornee=o
    h.Parent=o
    espObjects[o]={h}
end

Control4:Section("STAGE I")

Control4:Button({
    Title="Auto Win",
    Callback=function()
        task.spawn(function()
            FireTouch(Workspace:FindFirstChild("Game Teleporter"))
        end)
    end
})

Control4:Toggle({
    Title="ESP Items",
    Default=false,
    Callback=function(s)
        local c=Workspace:GetChildren()
        local m=c[120] and c[120]:FindFirstChild("Model")
        m=m and m:FindFirstChild("Model")
        local targets={
            {m and m:GetChildren()[4] and m:GetChildren()[4]:FindFirstChild("Handle"),"Key1"},
            {c[31] and c[31]:FindFirstChild("Handle"),"Key2"},
            {c[29] and c[29]:FindFirstChild("Handle"),"Crowbar"},
            {c[27] and c[27]:FindFirstChild("Handle"),"Key 3"}
        }
        for _,v in ipairs(targets) do
            if s then AddItemESP(v[1],v[2]) else ClearESP(v[1]) end
        end
    end
})

Control4:Toggle({
    Title="ESP Monsters",
    Default=false,
    Callback=function(s)
        local g=Workspace:FindFirstChild("GameAI")
        local c=g and g:GetChildren()
        local targets={
            c and c[4],
            g and g:FindFirstChild("Manq"),
            c and c[2],
            c and c[3]
        }
        for _,o in ipairs(targets) do
            if s then AddMonsterESP(o) else ClearESP(o) end
        end
    end
})

Control4:Section("STAGE II")

Control4:Button({
    Title="Auto Win",
    Callback=function()
        task.spawn(function()
            local folder=Workspace:FindFirstChild("Butterflies")
            if not folder then return end
            local items=folder:GetChildren()
            for _,item in ipairs(items) do
                if item and item.Parent then
                    local h=GetHRP()
                    local p=GetPart(item)
                    if h and p then
                        h.CFrame=p.CFrame+Vector3.new(0,2,0)
                        task.wait(0.2)
                        FirePrompt(item)
                        task.wait(0.2)
                    end
                end
            end
        end)
    end
})

Control4:Toggle({
    Title="ESP Items",
    Default=false,
    Callback=function(s)
        local f=Workspace:FindFirstChild("Butterflies")
        local c=f and f:GetChildren()
        local targets={
            c and c[13],
            f and f:FindFirstChild("Butterfly"),
            c and c[7],
            c and c[2],
            c and c[11],
            c and c[10],
            c and c[9],
            c and c[8],
            c and c[12],
            c and c[6],
            c and c[5],
            c and c[4],
            c and c[3]
        }
        for _,o in ipairs(targets) do
            if s then AddItemESP(o) else ClearESP(o) end
        end
    end
})

Control4:Toggle({
    Title="ESP Monsters",
    Default=false,
    Callback=function(s)
        local g=Workspace:FindFirstChild("GameAI")
        local o=g and g:FindFirstChild("Scarar")
        if s then AddMonsterESP(o) else ClearESP(o) end
    end
})

Control4:Section("STAGE III")


Control4:Button({
    Title = "Auto Win",
    Callback = function()
        local Players = game:GetService("Players")
        local player = Players.LocalPlayer
        local character = player.Character or player.CharacterAdded:Wait()
        local HRP = character:WaitForChild("HumanoidRootPart", 3)
        if not HRP then return end

        local itemsFolder = workspace:FindFirstChild("GameInfo") and workspace.GameInfo:FindFirstChild("PuzzleItems")
        if itemsFolder then
            for _, v in ipairs(itemsFolder:GetChildren()) do
                if v:IsA("Model") or v:IsA("BasePart") then
                    local part = v:IsA("BasePart") and v or v:FindFirstChildWhichIsA("BasePart")
                    if part then
                        HRP.CFrame = part.CFrame + Vector3.new(0, 3, 0)
                        task.wait(0.5)

                        for _, d in ipairs(v:GetDescendants()) do
                            if d:IsA("ProximityPrompt") then
                                pcall(function()
                                    d.HoldDuration = 0
                                    fireproximityprompt(d, 0)
                                end)
                                task.wait(0.016)
                            end
                        end
                    end
                end
            end
        end

        local well = workspace:FindFirstChild("Well")
        if well then
            local wellPart = well:IsA("BasePart") and well or well:FindFirstChildWhichIsA("BasePart")
            if wellPart then
                HRP.CFrame = wellPart.CFrame + Vector3.new(0, 3, 0)
                task.wait(0.5)
            end

            for i = 1, 6 do
                for _, p in ipairs(well:GetDescendants()) do
                    if p:IsA("ProximityPrompt") then
                        pcall(function()
                            p.HoldDuration = 0
                            fireproximityprompt(p, 0)
                        end)
                        task.wait(0.016)
                    end
                end
            end
        end
    end
})

Control4:AddLabel("Codes")

Control4:Paragraph({
    Title="CODE",
    Content="2573"
})

Control4:Toggle({
    Title="ESP Items",
    Default=false,
    Callback=function(s)
        local f=Workspace:FindFirstChild("GameInfo")
        local items=f and f:FindFirstChild("PuzzleItems")
        local c=items and items:GetChildren()
        local targets={
            Workspace:FindFirstChild("Key"),
            c and c[6],
            items and items:FindFirstChild("GrabItem"),
            c and c[3],
            c and c[2],
            c and c[4],
            c and c[5]
        }
        for _,o in ipairs(targets) do
            if s then AddItemESP(o) else ClearESP(o) end
        end
    end
})

Control4:Toggle({
    Title="ESP Monster",
    Default=false,
    Callback=function(s)
        local g=Workspace:FindFirstChild("GameAI")
        local o=g and g:FindFirstChild("Scarar")
        if s then AddMonsterESP(o) else ClearESP(o) end
    end
})

Control4:Section("Saigomo's Lair")

local autoEquipEnabled = false

local function getKatana()
    return player.Backpack:FindFirstChild("Katana") or (player.Character and player.Character:FindFirstChild("Katana"))
end

local function isKatanaEquipped()
    local character = player.Character
    if not character then return false end
    return character:FindFirstChild("Katana") ~= nil
end

local function equipKatana()
    if not isKatanaEquipped() then
        local katana = getKatana()
        if katana and player.Character then
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid:EquipTool(katana)
            end
        end
    end
end

Control4:Toggle({
    Title = "Auto Equip Katana",
    Default = false,
    Callback = function(state)
        autoEquipEnabled = state
        if autoEquipEnabled then
            task.spawn(function()
                while autoEquipEnabled do
                    equipKatana()
                    task.wait(1)
                end
            end)
        end
    end
})

Control4:Toggle({
    Title = "Auto Click Katana",
    Default = false,
    Callback = function(state)
        getgenv().AutoKatana = state
        if state then
            task.spawn(function()
                while getgenv().AutoKatana do
                    local char = player.Character
                    if char and char:FindFirstChild("HumanoidRootPart") then
                        local katana = char:FindFirstChild("Katana")
                        if katana and katana:IsA("Tool") then
                            pcall(function()
                                katana:Activate()
                            end)
                        end
                    end
                    task.wait(0.1)
                end
            end)
        end
    end
})

-- Heart Floating Logic
local heartsEnabled = false
local floatConnection
local FLOAT_HEIGHT = 35

local Hearts = {
    {
        get = function() return workspace:FindFirstChild("GameHearts") and workspace.GameHearts:GetChildren()[3] end,
        position = Vector3.new(2808, 105, 2431)
    },
    {
        get = function() return workspace:FindFirstChild("GameHearts") and workspace.GameHearts:FindFirstChild("Heart") end,
        position = Vector3.new(3215, 115, 2187)
    },
    {
        get = function() return workspace:FindFirstChild("GameHearts") and workspace.GameHearts:GetChildren()[2] end,
        position = Vector3.new(2598, 120, 2425)
    }
}

local function startFloating(position)
    local char = player.Character or player.CharacterAdded:Wait()
    local rootPart = char:WaitForChild("HumanoidRootPart")

    floatConnection = RunService.Heartbeat:Connect(function()
        if rootPart then
            rootPart.Velocity = Vector3.zero
            rootPart.AssemblyLinearVelocity = Vector3.zero
            rootPart.CFrame = CFrame.new(position + Vector3.new(0, FLOAT_HEIGHT, 0))
        end
    end)
end

local function stopFloating()
    if floatConnection then
        floatConnection:Disconnect()
        floatConnection = nil
    end
    local char = player.Character
    local rootPart = char and char:FindFirstChild("HumanoidRootPart")
    if rootPart then
        rootPart.Velocity = Vector3.zero
        rootPart.AssemblyLinearVelocity = Vector3.zero
    end
end

local function isDestroyed(heart)
    return heart and heart:FindFirstChild("Destroyed")
end

local function waitForDestroyed(heart)
    if not heart or isDestroyed(heart) then return end
    heart:WaitForChild("Destroyed")
end

local function killHearts()
    for _, heartData in ipairs(Hearts) do
        if not heartsEnabled then break end

        local heart = heartData.get()
        if heart and not isDestroyed(heart) then
            startFloating(heartData.position)
            waitForDestroyed(heart)
            stopFloating()
            task.wait(0.2)
        end
    end

    stopFloating()
    heartsEnabled = false
end

Control4:Toggle({
    Title = "Kill All Sama's Heart",
    Default = false,
    Callback = function(state)
        heartsEnabled = state
        if heartsEnabled then
            task.spawn(killHearts)
        else
            stopFloating()
        end
    end
})

-- Kill Saigomo Logic
local saigomoEnabled = false
local followConnection
local hitboxConnection
local SAIGOMO_FLOAT_HEIGHT = 27
local DESIRED_SIZE = Vector3.new(150, 21, 21)

local function getSaigomo()
    return workspace:FindFirstChild("BossBattle") and workspace.BossBattle:FindFirstChild("Saigomo")
end

local function getSaigomoPosition()
    local saigomo = getSaigomo()
    if not saigomo then return end
    if saigomo.PrimaryPart then
        return saigomo.PrimaryPart.Position
    end
    local part = saigomo:FindFirstChildWhichIsA("BasePart")
    return part and part.Position
end

local function enlargeHitbox()
    local saigomo = getSaigomo()
    if saigomo then
        local hitbox = saigomo:FindFirstChild("SpiderHitbox")
        if hitbox and hitbox:IsA("BasePart") then
            hitbox.Size = DESIRED_SIZE
            hitbox.Transparency = 1
        end
    end
end

local function startFollowSaigomo()
    local char = player.Character or player.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart")

    hitboxConnection = RunService.Heartbeat:Connect(enlargeHitbox)
    followConnection = RunService.Heartbeat:Connect(function()
        if not saigomoEnabled or not hrp then return end
        local pos = getSaigomoPosition()
        if pos then
            hrp.CFrame = CFrame.new(pos + Vector3.new(0, SAIGOMO_FLOAT_HEIGHT, 0))
        end
    end)
end

local function stopFollowSaigomo()
    if followConnection then
        followConnection:Disconnect()
        followConnection = nil
    end
    if hitboxConnection then
        hitboxConnection:Disconnect()
        hitboxConnection = nil
    end
end

Control4:Toggle({
    Title = "Kill Saigomo",
    Default = false,
    Callback = function(state)
        saigomoEnabled = state
        if saigomoEnabled then
            startFollowSaigomo()
        else
            stopFollowSaigomo()
        end
    end
})
