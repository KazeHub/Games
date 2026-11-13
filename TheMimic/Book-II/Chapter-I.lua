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


--// =========================
--// SERVICES
--// =========================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local player = Players.LocalPlayer

--// =========================
--// UTILS
--// =========================
local function getChar()
    return player.Character or player.CharacterAdded:Wait()
end

local function getHRP()
    local char = getChar()
    return char:WaitForChild("HumanoidRootPart", 5)
end

local function safeFirePrompt(prompt)
    if prompt and prompt:IsA("ProximityPrompt") and prompt.Enabled then
        fireproximityprompt(prompt)
    end
end

local function safeFireTouch(part, timeout)
    local hrp = getHRP()
    if not hrp or not part then return end
    
    firetouchinterest(hrp, part, 0)
    task.wait(timeout or 0.1)
    firetouchinterest(hrp, part, 1)
end

local function fireTouchNearby(hrp, radius)
    radius = radius or 10
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("TouchInterest") and v.Parent and v.Parent:IsA("BasePart") then
            if (v.Parent.Position - hrp.Position).Magnitude <= radius then
                safeFireTouch(v.Parent)
                task.wait(0.1)
            end
        end
    end
end

--// =========================
--// TABS CREATION
--// =========================

local Tab1 = Window:CreateTab({
    Title = "Sister",
    Icon = "users"
})

local Tab2 = Window:CreateTab({
    Title = "Nure's Zone",
    Icon = "line-squiggle"
})

local Tab3 = Window:CreateTab({
    Title = "Yoki Town",
    Icon = "building-2"
})

local Tab4 = Window:CreateTab({
    Title = "Broken Ship",
    Icon = "anchor"
})

--// =========================
--// TAB 1: MINKA STAGE CONTENT
--// =========================

Tab1:Button({
    Title = "Read The Book",
    Description = "",
    Callback = function()
        local hrp = getHRP()
        if not hrp then return end

        for _, v in ipairs(workspace:GetDescendants()) do
            if v:IsA("Model") and v.Name == "Book" then
                local cf, size = v:GetBoundingBox()

                hrp.CFrame = cf + Vector3.new(0, size.Y/2 + 3, 0)
                task.wait(0.3)

                for _, p in ipairs(v:GetDescendants()) do
                    if p:IsA("ProximityPrompt") then
                        safeFirePrompt(p)
                    end
                end
                break
            end
        end
    end
})

local canClickRat = true

Tab1:Button({
    Title = "Auto Rat Task",
    Description = "",
    Callback = function()
        if not canClickRat then return end
        canClickRat = false

        local hrp = getHRP()
        local char = getChar()
        local backpack = player:WaitForChild("Backpack")

        if not hrp or not char then 
            canClickRat = true
            return 
        end

        local ratModel
        for _, a in ipairs(workspace:GetChildren()) do
            if a.Name:match("^%{0x[%w]+%}$") then
                for _, b in ipairs(a:GetChildren()) do
                    if b.Name:match("^%{0x[%w]+%}$") then
                        for _, m in ipairs(b:GetChildren()) do
                            if m:IsA("Model") and m.PrimaryPart and m.PrimaryPart.Name == "Cube" then
                                ratModel = m
                                break
                            end
                        end
                    end
                    if ratModel then break end
                end
            end
            if ratModel then break end
        end

        if not ratModel then
            Window:Notify({
                Title = "Error",
                Content = "Rat Model not found!",
                Duration = 3
            })
            canClickRat = true
            return
        end

        hrp.CFrame = ratModel.PrimaryPart.CFrame + Vector3.new(0, 3, 0)
        task.wait(0.1)

        local function hasRat()
            for _, t in ipairs(backpack:GetChildren()) do
                if t:IsA("Tool") and t.Name:lower():find("rat") then
                    return true
                end
            end
            for _, t in ipairs(char:GetChildren()) do
                if t:IsA("Tool") and t.Name:lower():find("rat") then
                    return true
                end
            end
            return false
        end

        local timeout = 0
        while not hasRat() and timeout < 10 do
            for _, p in ipairs(ratModel:GetDescendants()) do
                if p:IsA("ProximityPrompt") then
                    safeFirePrompt(p)
                end
            end
            timeout = timeout + 0.4
            task.wait(0.3)
        end

        hrp.CFrame = CFrame.new(-1540.82, -30.17, -3544.40)
        task.wait(0.3)

        for _, p in ipairs(workspace:GetDescendants()) do
            if p:IsA("ProximityPrompt") and p.Parent:IsA("BasePart") then
                if (p.Parent.Position - hrp.Position).Magnitude < 10 then
                    safeFirePrompt(p)
                end
            end
        end

        local toolName = "Poisoned Rat"
        local tool
        local t = 0

        while t < 8 do
            tool = backpack:FindFirstChild(toolName) or char:FindFirstChild(toolName)
            if tool then
                tool.Parent = char
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then hum:EquipTool(tool) end
                break
            end
            t += 0.2
            task.wait(0.2)
        end

        hrp.CFrame = CFrame.new(-1563.34, -28.91, -3408.55)
        task.wait(0.3)

        local dropTimeout = 0
        while (backpack:FindFirstChild(toolName) or char:FindFirstChild(toolName)) and dropTimeout < 10 do
            for _, p in ipairs(workspace:GetDescendants()) do
                if p:IsA("ProximityPrompt") and p.Parent:IsA("BasePart") then
                    if (p.Parent.Position - hrp.Position).Magnitude < 10 then
                        safeFirePrompt(p)
                    end
                end
            end
            dropTimeout = dropTimeout + 0.1
            task.wait(0.1)
        end

        hrp.CFrame = CFrame.new(-1667.52, -22.74, -3401.50)

        task.delay(5, function()
            canClickRat = true
        end)
    end
})

Tab1:Button({
    Title = "Exit",
    Description = "",
    Callback = function()
        local hrp = getHRP()
        if not hrp then return end

        local targetCFrame = CFrame.new(-1510.22, -29.25, -3418.08)
        hrp.CFrame = targetCFrame
        task.wait(0.3)

        for _, prompt in ipairs(workspace:GetDescendants()) do
            if prompt:IsA("ProximityPrompt") and prompt.Parent:IsA("BasePart") and (prompt.Parent.Position - hrp.Position).Magnitude < 10 then
                safeFirePrompt(prompt)
            end
        end
    end
})

Tab1:Button({
    Title = "Escape Chase",
    Description = "",
    Callback = function()
        local hrp = getHRP()
        if not hrp then return end

        local targetCFrame = CFrame.new(
            -960.75, -42.4749985, -3599.55005,
            1, 0, 0,
            0, 1, 0,
            0, 0, 1
        )

        hrp.CFrame = targetCFrame
        task.wait(0.5)

        for _, v in ipairs(workspace:GetDescendants()) do
            if v:IsA("TouchInterest") then
                local part = v.Parent
                if part and part:IsA("BasePart") then
                    safeFireTouch(part)
                    break
                end
            end
        end
    end
})

--// =========================
--// TAB 2: NURE'S ZONE CONTENT
--// =========================

Tab2:Button({
    Title = "Auto Win",
    Description = "",
    Callback = function()
        local hrp = getHRP()
        if not hrp then return end

        local targetCFrame = CFrame.new(
            595.243896, 582.230713, -344.577911,
            1, 0, 0,
            0, 1, 0,
            0, 0, 1
        )

        hrp.CFrame = targetCFrame
        task.wait(0.3)

        fireTouchNearby(hrp)
    end
})

Tab2:Button({
    Title = "Escape Chase",
    Description = "",
    Callback = function()
        local hrp = getHRP()
        if not hrp then return end

        local firstCFrame = CFrame.new(
            3386.39282, 147.723251, 7.59275055,
            0.999984741, -0.00552510377, 4.19676435e-05,
            0.00552371796, 0.999855816, 0.0160555579,
            -0.000130670203, -0.016055081, 0.999871075
        )

        local secondCFrame = CFrame.new(
            3868.31982, 153.007477, 17.1698914,
            1, 0, 0,
            0, 1, 0,
            0, 0, 1
        )

        hrp.CFrame = firstCFrame
        task.wait(0.3)

        fireTouchNearby(hrp)
        task.wait(0.3)

        local tweenInfo = TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
        local tween = TweenService:Create(hrp, tweenInfo, {CFrame = secondCFrame})
        tween:Play()
        tween.Completed:Wait()

        fireTouchNearby(hrp)
    end
})

--// =========================
--// TAB 3: YOKI TOWN CONTENT
--// =========================

Tab3:Button({
    Title = "Talk",
    Callback = function()
        local hrp = getHRP()
        if not hrp then return end
        
        local targetPos = Vector3.new(-326.42, 20.26, 3653.01)
        hrp.CFrame = CFrame.new(targetPos)
        task.wait(0.3)
        
        for _, prompt in ipairs(workspace:GetDescendants()) do
            if prompt:IsA("ProximityPrompt") and prompt.Parent:IsA("BasePart") then
                if (prompt.Parent.Position - hrp.Position).Magnitude <= 10 then
                    safeFirePrompt(prompt)
                    task.wait(0.3)
                end
            end
        end
    end
})

Tab3:Button({
    Title = "Paint room",
    Callback = function()
        local hrp = getHRP()
        if not hrp then return end

        local house3Pos = Vector3.new(-200.45, 22.23, 3769.16)
        hrp.CFrame = CFrame.new(house3Pos)
    end
})

local folderName = "Collected Decals"
local folder = workspace:FindFirstChild(folderName)
if not folder then
    folder = Instance.new("Folder")
    folder.Name = folderName
    folder.Parent = workspace
end

local positions = {
    Vector3.new(-675.72, 3069.53, 5001.65),
    Vector3.new(593.04, 3069.58, 4421.64),
    Vector3.new(-264.07, 3069.53, 4214.51),
    Vector3.new(-393.77, 3069.58, 3890.38),
    Vector3.new(-7.12, 3067.82, 4712.61),
}

Tab3:Button({
    Title = "Collect image",
    Description = "Paint First Before This.",
    Callback = function()
        local hrp = getHRP()
        if not hrp then return end

        for _, pos in ipairs(positions) do
            hrp.CFrame = CFrame.new(pos)
            task.wait(1.5)

            hrp = getHRP()
            if not hrp then return end

            local cloneDone = false
            local waitTime = 0
            local maxWaitTime = 10

            while not cloneDone and waitTime < maxWaitTime do
                local nearestImageMesh = nil
                local nearestDist = math.huge

                for _, mp in ipairs(workspace:GetDescendants()) do
                    if mp:IsA("MeshPart") and mp.Name == "Image" then
                        local dist = (mp.Position - pos).Magnitude
                        if dist < 30 and dist < nearestDist then
                            nearestImageMesh = mp
                            nearestDist = dist
                        end
                    end
                end

                if nearestImageMesh then
                    local alreadyCloned = false

                    for _, clonedMesh in ipairs(folder:GetChildren()) do
                        if clonedMesh:IsA("MeshPart")
                            and clonedMesh.Name == nearestImageMesh.Name
                            and (clonedMesh.Position - nearestImageMesh.Position).Magnitude < 1 then
                            alreadyCloned = true
                            break
                        end
                    end

                    if not alreadyCloned then
                        local clone = nearestImageMesh:Clone()
                        clone.Parent = folder
                    end

                    cloneDone = true
                end

                if not cloneDone then
                    task.wait(0.5)
                    waitTime = waitTime + 0.5
                end
            end
        end

        Window:Notify({
            Title = "Success",
            Content = "Collected Image MeshParts!",
            Duration = 3
        })
    end
})

Tab3:Button({
    Title = "Get key",
    Callback = function()
        local hrp = getHRP()
        if not hrp then return end
        
        local targetCFrame = CFrame.new(
            -401.576477, 3068.81299, 3863.99707,
            0.247046828, 0, 0.969003558,
            0, 1, 0,
            -0.969003558, 0, 0.247046828
        )
        hrp.CFrame = targetCFrame
        task.wait(0.3)
        
        for _, prompt in ipairs(workspace:GetDescendants()) do
            if prompt:IsA("ProximityPrompt") and prompt.Parent:IsA("MeshPart") then
                if (prompt.Parent.Position - hrp.Position).Magnitude <= 10 then
                    safeFirePrompt(prompt)
                    task.wait(0.3)
                end
            end
        end
    end
})

Tab3:Button({
    Title = "Teleport room candle",
    Callback = function()
        local hrp = getHRP()
        if hrp then
            hrp.CFrame = CFrame.new(-386.92, 19.30, 3781.05)
        end
    end
})

Tab3:Button({
    Title = "Auto lights up",
    Description = "",
    Callback = function()
        local hrp = getHRP()
        if not hrp then return end

        local cloneFolder = workspace:FindFirstChild("Collected Decals")
        if not cloneFolder then
            Window:Notify({
                Title = "Error",
                Content = "Collect Images First!",
                Duration = 3
            })
            return
        end

        local collectedTextureIDs = {}
        local foundCount = 0
        for _, meshPart in ipairs(cloneFolder:GetChildren()) do
            local decal = meshPart:FindFirstChildOfClass("Decal")
            if decal and decal.Texture ~= "" then
                collectedTextureIDs[decal.Texture] = true
                foundCount = foundCount + 1
            end
        end

        if foundCount == 0 then
            Window:Notify({
                Title = "Error",
                Content = "No collected images found in folder!",
                Duration = 3
            })
            return
        end

        local matchedCandles = {}

        for _, model in ipairs(workspace:GetDescendants()) do
            local nameAsNum = tonumber(model.Name)
            if model:IsA("Model") and nameAsNum and nameAsNum >= 1 and nameAsNum <= 9 then
                local imagePart = model:FindFirstChild("Image") or model:FindFirstChildOfClass("MeshPart")
                if imagePart then
                    local decal = imagePart:FindFirstChildOfClass("Decal")
                    if decal and collectedTextureIDs[decal.Texture] then
                        table.insert(matchedCandles, imagePart)
                    end
                end
            end
        end

        for _, imagePart in ipairs(matchedCandles) do
            hrp.Anchored = false
            hrp.CFrame = imagePart.CFrame + Vector3.new(0, 3, 0)
            task.wait(0.2)

            for i = 1, 5 do
                for _, prompt in ipairs(workspace:GetDescendants()) do
                    if prompt:IsA("ProximityPrompt") and prompt.Parent and prompt.Parent:IsA("BasePart") then
                        local dist = (prompt.Parent.Position - imagePart.Position).Magnitude
                        if dist <= 12 then
                            safeFirePrompt(prompt)
                        end
                    end
                end
                task.wait(0.016)
            end
        end

        hrp.Anchored = false
        local finalPos = CFrame.new(150.69, 3072.50, 3868.33)
        hrp.CFrame = finalPos
    end
})

Tab3:Button({
    Title = "Bring orb",
    Description = "",
    Callback = function()
        local hrp = getHRP()
        if not hrp then return end

        local targetOrb = nil
        for _, desc in ipairs(workspace:GetDescendants()) do
            if desc.Name == "Orb" and desc:IsA("BasePart") then
                targetOrb = desc
                break
            end
        end

        if targetOrb then
            hrp.CFrame = targetOrb.CFrame
            task.wait(0.5)

            local prompt = targetOrb:FindFirstChildOfClass("ProximityPrompt")
            if prompt then
                safeFirePrompt(prompt)
            end
            task.wait(0.3)
        else
            warn("Orb BasePart not found in workspace!")
        end

        local targetPos = Vector3.new(-326.42, 20.26, 3653.01)
        hrp.CFrame = CFrame.new(targetPos)
        task.wait(0.5)

        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("ProximityPrompt") then
                local parentPart = obj.Parent
                if parentPart and parentPart:IsA("BasePart") then
                    local distance = (hrp.Position - parentPart.Position).Magnitude
                    if distance <= 10 then
                        safeFirePrompt(obj)
                        task.wait(0.1)
                    end
                end
            end
        end
    end
})

--// =========================
--// TAB 4: BROKEN SHIP STAGE CONTENT
--// =========================

Tab4:Button({
    Title = "Enter to The Ship",
    Callback = function()
        local hrp = getHRP()
        if not hrp then return end

        local targetCFrame = CFrame.new(
            -1248.15002, 86.0981903, 6297.76123,
            1, 0, 0,
            0, 1, 0,
            0, 0, 1
        )

        hrp.CFrame = targetCFrame
        task.wait(0.4)

        local char = player.Character
        if not char then return end

        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return end

        for _, touch in ipairs(workspace:GetDescendants()) do
            if touch:IsA("TouchTransmitter")
                and touch.Parent
                and touch.Parent:IsA("BasePart") then

                if (touch.Parent.Position - root.Position).Magnitude <= 10 then
                    safeFireTouch(touch.Parent)
                    break
                end
            end
        end
    end
})

Tab4:Button({
    Title = "Auto Candles",
    Description = "Look down before click.",
    Callback = function()
        local Players = game:GetService("Players")
        local player = Players.LocalPlayer
        local character = player.Character or player.CharacterAdded:Wait()
        local hrp = character:FindFirstChild("HumanoidRootPart")

        if not hrp then
            Window:Notify({
                Title = "Error",
                Content = "HumanoidRootPart not found!",
                Duration = 3
            })
            return
        end

        local originalCFrame = hrp.CFrame
        local candleTargets = {}

        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("ProximityPrompt") then
                if obj.ObjectText == "Candle" or obj.Name == "{0x498599697431}" then
                    local parentPart = obj.Parent

                    if parentPart and parentPart:IsA("BasePart") then
                        table.insert(candleTargets, {
                            Part = parentPart,
                            Prompt = obj
                        })
                    end
                end
            end
        end

        if #candleTargets == 0 then
            Window:Notify({
                Title = "Error",
                Content = "No candles found!",
                Duration = 3
            })
            return
        end

        Window:Notify({
            Title = "Candle TP",
            Content = "Found " .. #candleTargets .. " candle(s)!",
            Duration = 2
        })

        local function getNearbyHumanoidModel(targetPart)
            local targetPosition = targetPart.Position

            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("Model") then
                    local humanoid = obj:FindFirstChildOfClass("Humanoid")
                    local rootPart = obj:FindFirstChild("HumanoidRootPart")

                    if humanoid and rootPart then
                        if obj ~= character then
                            local distance = (rootPart.Position - targetPosition).Magnitude

                            if distance <= 29 then
                                return obj
                            end
                        end
                    end
                end
            end

            return nil
        end

        task.spawn(function()
            for _, candle in ipairs(candleTargets) do
                if not hrp or not hrp.Parent then
                    break
                end

                local targetPart = candle.Part
                local prompt = candle.Prompt

                if not targetPart or not targetPart.Parent then
                    continue
                end

                if not prompt or not prompt.Parent then
                    continue
                end

                local nearbyHumanoid = getNearbyHumanoidModel(targetPart)

                while nearbyHumanoid and nearbyHumanoid.Parent do
                    hrp.Anchored = false

                    if hrp and hrp.Parent then
                        hrp.CFrame = originalCFrame
                    end

                    task.wait(0.5)

                    nearbyHumanoid = getNearbyHumanoidModel(targetPart)
                end

                if getNearbyHumanoidModel(targetPart) then
                    hrp.Anchored = false
                    if hrp and hrp.Parent then
                        hrp.CFrame = originalCFrame
                    end
                    continue
                end

                hrp.CFrame = targetPart.CFrame + Vector3.new(0, 3, 0)

                task.wait(0.2)

                if getNearbyHumanoidModel(targetPart) then
                    hrp.Anchored = false
                    if hrp and hrp.Parent then
                        hrp.CFrame = originalCFrame
                    end
                    continue
                end

                hrp.Anchored = true

                if prompt.Enabled then
                    local holdDuration = prompt.HoldDuration

                    prompt:InputHoldBegin()

                    if holdDuration > 0 then
                        task.wait(holdDuration)
                    else
                        task.wait(0.1)
                    end

                    prompt:InputHoldEnd()

                    task.wait(0.3)
                end

                hrp.Anchored = false

                task.wait(0.1)
            end

            hrp.Anchored = false

            task.wait(0.1)

            if hrp and hrp.Parent then
                hrp.CFrame = originalCFrame
            end

            Window:Notify({
                Title = "Done",
                Content = "Finished Candles!",
                Duration = 3
            })
        end)
    end
})

Tab4:Button({
    Title = "End Vent Chase",
    Callback = function()
        local player = game:GetService("Players").LocalPlayer
        local character = player.Character or player.CharacterAdded:Wait()
        local hrp = character:FindFirstChild("HumanoidRootPart")
        local tweenService = game:GetService("TweenService")
        
        if not hrp then return end

        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
        hrp.CFrame = CFrame.new(-6318.81, 419.04, 6261.62)
        
        task.wait(0.1)

        local targetCFrame = CFrame.new(
            -6318.50488, 418.510345, 6367.32715,
            -1, 8.63294626e-05, -0.000172640299,
             8.63145615e-05, 1, 8.63294626e-05,
             0.000172647749, 8.63145615e-05, -1
        )

        local distance = (hrp.Position - targetCFrame.Position).Magnitude
        local speed = 50
        local duration = math.clamp(distance / speed, 0.5, 3)

        local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
        local tween = tweenService:Create(hrp, tweenInfo, {CFrame = targetCFrame})
        
        tween:Play()
        tween.Completed:Wait()
    end
})

Tab4:Button({
    Title = "Finish",
    Callback = function()
        local hrp = getHRP()
        if not hrp then return end

        local targetCF = CFrame.new(
            -9612.39062, 450.222809, 7150.53125,
             0.999415755, -0.0341785066, -3.39340841e-05,
             0.0341785066,  0.999413788,  0.00198511523,
            -3.39340841e-05, -0.00198511523, 0.999998033
        )

        hrp.CFrame = targetCF
        task.wait(0.3)

        local nearest, dist = nil, math.huge
        for _, part in ipairs(workspace:GetDescendants()) do
            if part:IsA("BasePart") then
                local tt = part:FindFirstChildOfClass("TouchTransmitter")
                if tt then
                    local d = (part.Position - hrp.Position).Magnitude
                    if d < dist then
                        dist = d
                        nearest = part
                    end
                end
            end
        end

        if nearest then
            safeFireTouch(nearest)
        end
    end
})
