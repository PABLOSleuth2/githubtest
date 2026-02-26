local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer

local character = nil
local defaultIds = {}
local isRecording = false
local recordingConnection = nil
local currentSequence = nil
local startTime = 0
local recordInterval = 0

local function getStorageFolder()
    local folder = ReplicatedStorage:FindFirstChild("SavedAnims")
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = "SavedAnims"
        folder.Parent = ReplicatedStorage
    end
    return folder
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end 
    if input.KeyCode == Enum.KeyCode.LeftBracket then
        local folder = ReplicatedStorage:FindFirstChild("SavedAnims")
        if folder then
            folder:ClearAllChildren()
        end
    end
end)

local function getNotificationContainer()
    local gui = player.PlayerGui:FindFirstChild("AnimCaptureNotifs")
    if not gui then
        gui = Instance.new("ScreenGui")
        gui.Name = "AnimCaptureNotifs"
        gui.ResetOnSpawn = false
        gui.Parent = player.PlayerGui
        
        local container = Instance.new("Frame")
        container.Name = "ListContainer"
        container.Size = UDim2.new(0, 300, 1, -20)
        container.Position = UDim2.new(1, -320, 0, 0)
        container.BackgroundTransparency = 1
        container.Parent = gui
        
        local layout = Instance.new("UIListLayout")
        layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
        layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
        layout.Padding = UDim.new(0, 10)
        layout.Parent = container
    end
    return gui.ListContainer
end

local function sendNotification(message)
    local container = getNotificationContainer()
    
    local wrapper = Instance.new("Frame")
    wrapper.Size = UDim2.new(0, 300, 0, 60)
    wrapper.BackgroundTransparency = 1
    wrapper.Parent = container
    
    local visFrame = Instance.new("Frame")
    visFrame.Size = UDim2.new(1, 0, 1, 0)
    visFrame.Position = UDim2.new(1, 50, 0, 0)
    visFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    visFrame.Parent = wrapper
    
    Instance.new("UICorner", visFrame).CornerRadius = UDim.new(0, 8)
    local stroke = Instance.new("UIStroke", visFrame)
    stroke.Color = Color3.fromRGB(80, 220, 80)
    stroke.Thickness = 2
    
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, -20, 1, 0)
    textLabel.Position = UDim2.new(0, 10, 0, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = message
    textLabel.TextColor3 = Color3.new(1, 1, 1)
    textLabel.Font = Enum.Font.GothamBold
    textLabel.TextSize = 14
    textLabel.TextWrapped = true
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.Parent = visFrame
    
    local tweenInfoIn = TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    local tweenIn = TweenService:Create(visFrame, tweenInfoIn, {Position = UDim2.new(0, 0, 0, 0)})
    tweenIn:Play()
    
    task.delay(3.5, function()
        local tweenInfoOut = TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
        local tweenOut = TweenService:Create(visFrame, tweenInfoOut, {Position = UDim2.new(1, 50, 0, 0)})
        tweenOut:Play()
        
        tweenOut.Completed:Wait()
        wrapper:Destroy()
    end)
end

local function showStartupWarning()
    local playerGui = player:WaitForChild("PlayerGui")
    if playerGui:FindFirstChild("AnimCaptureStartup") then return end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "AnimCaptureStartup"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = playerGui

    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 500, 0, 420)
    mainFrame.Position = UDim2.new(0.5, -250, 0.5, -210)
    mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    mainFrame.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = mainFrame

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(60, 60, 60)
    stroke.Thickness = 2
    stroke.Parent = mainFrame

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 50)
    title.Position = UDim2.new(0, 0, 0, 10)
    title.Text = "⚠️ WARNING & TUTORIAL"
    title.TextColor3 = Color3.fromRGB(255, 80, 80)
    title.Font = Enum.Font.GothamBlack
    title.TextSize = 24
    title.BackgroundTransparency = 1
    title.Parent = mainFrame

    local bodyText = Instance.new("TextLabel")
    bodyText.Size = UDim2.new(1, -40, 1, -140)
    bodyText.Position = UDim2.new(0, 20, 0, 70)
    bodyText.Text = "This script turns off looping when running a custom animation to extract the absolute truth of the track.\n\n" ..
                    "It dynamically scrapes your character's default animations and ignores them.\n\n" ..
                    "TUTORIAL:\n" ..
                    "1. Run a custom animation (dance, emotes, etc.) and wait until it finishes.\n" ..
                    "2. When prompted, click YES to save using saveinstance().\n" ..
                    "3. Open Roblox Studio, spawn an R15/R6 Dummy.\n" ..
                    "4. Paste the KeyframeSequence into ServerStorage, then load it. Boom!\n\n" ..
                    "Press [ to clear all animations in the folder."
    bodyText.TextColor3 = Color3.fromRGB(220, 220, 220)
    bodyText.Font = Enum.Font.Gotham
    bodyText.TextSize = 14
    bodyText.TextXAlignment = Enum.TextXAlignment.Left
    bodyText.TextYAlignment = Enum.TextYAlignment.Top
    bodyText.TextWrapped = true
    bodyText.BackgroundTransparency = 1
    bodyText.Parent = mainFrame

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 200, 0, 45)
    closeBtn.Position = UDim2.new(0.5, -100, 1, -60)
    closeBtn.BackgroundColor3 = Color3.fromRGB(80, 120, 255)
    closeBtn.Text = "UNDERSTOOD"
    closeBtn.TextColor3 = Color3.new(1, 1, 1)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 16
    closeBtn.Parent = mainFrame

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 8)
    btnCorner.Parent = closeBtn

    closeBtn.MouseButton1Click:Connect(function()
        title.Text = "⚙️ SELECT FRAMERATE"
        bodyText.Text = "Pick the framerate cap\n\n" ..
                        "30 FPS (Recommended):\nDrops file size by 75%. Mathematically stable and prevents Studio lag.\n\n" ..
                        "UNCAPPED (Using your current FPS):\nCaptures raw physical data every engine tick. Creates massive file sizes."

        closeBtn.Visible = false

        local fps30Btn = Instance.new("TextButton")
        fps30Btn.Size = UDim2.new(0, 210, 0, 45)
        fps30Btn.Position = UDim2.new(0, 30, 1, -60)
        fps30Btn.BackgroundColor3 = Color3.fromRGB(40, 200, 40)
        fps30Btn.Text = "30 FPS (OPTIMIZED)"
        fps30Btn.TextColor3 = Color3.new(1, 1, 1)
        fps30Btn.Font = Enum.Font.GothamBold
        fps30Btn.TextSize = 14
        fps30Btn.Parent = mainFrame
        Instance.new("UICorner", fps30Btn).CornerRadius = UDim.new(0, 8)

        local uncappedBtn = Instance.new("TextButton")
        uncappedBtn.Size = UDim2.new(0, 210, 0, 45)
        uncappedBtn.Position = UDim2.new(1, -240, 1, -60)
        uncappedBtn.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
        uncappedBtn.Text = "UNCAPPED (HEARTBEAT)"
        uncappedBtn.TextColor3 = Color3.new(1, 1, 1)
        uncappedBtn.Font = Enum.Font.GothamBold
        uncappedBtn.TextSize = 13
        uncappedBtn.Parent = mainFrame
        Instance.new("UICorner", uncappedBtn).CornerRadius = UDim.new(0, 8)

        fps30Btn.MouseButton1Click:Connect(function()
            recordInterval = 1 / 30
            screenGui:Destroy()
        end)

        uncappedBtn.MouseButton1Click:Connect(function()
            recordInterval = 0
            screenGui:Destroy()
        end)
    end)
end

local function showConfirmGui(sequence)
    local playerGui = player:WaitForChild("PlayerGui")
    if playerGui:FindFirstChild("AnimSavePrompt") then playerGui.AnimSavePrompt:Destroy() end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "AnimSavePrompt"
    screenGui.Parent = playerGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 480, 0, 160)
    frame.Position = UDim2.new(0.5, -240, 0.5, -80)
    frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    frame.Parent = screenGui

    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)
    local stroke = Instance.new("UIStroke", frame)
    stroke.Color = Color3.fromRGB(100, 100, 100)
    stroke.Thickness = 1.5

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 60)
    title.Text = "Custom Anim Finished!\nSave physical data?"
    title.TextColor3 = Color3.new(1, 1, 1)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 18
    title.BackgroundTransparency = 1
    title.Parent = frame

    local yesBtn = Instance.new("TextButton")
    yesBtn.Size = UDim2.new(0, 140, 0, 45)
    yesBtn.Position = UDim2.new(0, 20, 1, -65)
    yesBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
    yesBtn.Text = "YES (SaveInstance)"
    yesBtn.TextColor3 = Color3.new(1, 1, 1)
    yesBtn.Font = Enum.Font.GothamBold
    yesBtn.Parent = frame
    Instance.new("UICorner", yesBtn).CornerRadius = UDim.new(0, 6)

    local laterBtn = Instance.new("TextButton")
    laterBtn.Size = UDim2.new(0, 140, 0, 45)
    laterBtn.Position = UDim2.new(0.5, -70, 1, -65)
    laterBtn.BackgroundColor3 = Color3.fromRGB(94, 0, 255)
    laterBtn.Text = "LATER (Queue it)"
    laterBtn.TextColor3 = Color3.new(1, 1, 1)
    laterBtn.Font = Enum.Font.GothamBold
    laterBtn.Parent = frame
    Instance.new("UICorner", laterBtn).CornerRadius = UDim.new(0, 6)

    local noBtn = Instance.new("TextButton")
    noBtn.Size = UDim2.new(0, 140, 0, 45)
    noBtn.Position = UDim2.new(1, -160, 1, -65)
    noBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    noBtn.Text = "NO (Trash it)"
    noBtn.TextColor3 = Color3.new(1, 1, 1)
    noBtn.Font = Enum.Font.GothamBold
    noBtn.Parent = frame
    Instance.new("UICorner", noBtn).CornerRadius = UDim.new(0, 6)

    yesBtn.MouseButton1Click:Connect(function()
        local storageFolder = getStorageFolder()
        sequence.Parent = storageFolder
        
        pcall(function()
            saveinstance(game.ReplicatedStorage.SavedAnims)
        end)
        screenGui:Destroy()
    end)

    laterBtn.MouseButton1Click:Connect(function()
        local storageFolder = getStorageFolder()
        sequence.Parent = storageFolder
        screenGui:Destroy()
    end)

    noBtn.MouseButton1Click:Connect(function()
        sequence:Destroy()
        screenGui:Destroy()
    end)
end

local function captureFrame(currentTime, activeMotors)
    if not character then return end 

    local relativeTime = currentTime - startTime
    local keyframe = Instance.new("Keyframe")
    keyframe.Time = relativeTime
    keyframe.Name = "Frame_" .. math.floor(relativeTime * 1000)
    keyframe.Parent = currentSequence

    local poses = {}
    local function getPose(part)
        if poses[part] then return poses[part] end
        local newPose = Instance.new("Pose")
        newPose.Name = part.Name
        newPose.Weight = 1
        newPose.EasingStyle = Enum.PoseEasingStyle.Linear
        newPose.EasingDirection = Enum.PoseEasingDirection.In
        poses[part] = newPose
        return newPose
    end

    for _, motor in ipairs(activeMotors) do
        local part0 = motor.Part0
        local part1 = motor.Part1
        if part0 and part1 then
            local pose0 = getPose(part0)
            local pose1 = getPose(part1)
            pose1.CFrame = motor.Transform
            pose1.Parent = pose0
        end
    end

    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if rootPart and poses[rootPart] then
        poses[rootPart].Parent = keyframe
    end
end

local function onCharacterAdded(newChar)
    character = newChar
    local humanoid = character:WaitForChild("Humanoid")
    local animator = humanoid:WaitForChild("Animator")
    isRecording = false
    defaultIds = {} 

    local animateScript = character:WaitForChild("Animate", 5)
    if animateScript then
        for _, desc in ipairs(animateScript:GetDescendants()) do
            if desc:IsA("Animation") then
                local numId = string.match(desc.AnimationId, "%d+")
                if numId then defaultIds[numId] = true end
                defaultIds[desc.AnimationId] = true
            end
        end
    end

    animator.AnimationPlayed:Connect(function(track)
        local animId = track.Animation.AnimationId
        local numId = string.match(animId, "%d+")
        
        if (numId and defaultIds[numId]) or defaultIds[animId] then return end
        
        if isRecording then 
            return 
        end
        
        isRecording = true

        sendNotification("Custom animation is detected, recording rn...")

        local wasOriginallyLooped = track.Looped
        
        track:Stop()
        track.Looped = false
        track.TimePosition = 0 
        track:Play()

        currentSequence = Instance.new("KeyframeSequence")
        currentSequence.Name = character.Name .. "_Dump_" .. (numId or "Custom")
        currentSequence.Loop = wasOriginallyLooped 
        
        RunService.Heartbeat:Wait()
        startTime = workspace.DistributedGameTime
        
        local activeMotors = {}
        for _, desc in ipairs(character:GetDescendants()) do
            if desc:IsA("Motor6D") and desc.Part0 and desc.Part1 then
                table.insert(activeMotors, desc)
            end
        end
        
        local lastCaptureTime = 0
        
        recordingConnection = RunService.Heartbeat:Connect(function()
            local currentTime = workspace.DistributedGameTime
            if recordInterval == 0 or (currentTime - lastCaptureTime) >= recordInterval then
                captureFrame(currentTime, activeMotors)
                lastCaptureTime = currentTime
            end
        end)

        local stopConnection
        
        local function onAnimationEnded()
            if not isRecording then return end 
            
            if stopConnection then 
                stopConnection:Disconnect() 
                stopConnection = nil
            end
            
            if recordingConnection then
                recordingConnection:Disconnect()
                recordingConnection = nil
            end
            
            if wasOriginallyLooped then
                track.Looped = true
            end
            
            isRecording = false
            showConfirmGui(currentSequence)
        end

        stopConnection = track.Stopped:Connect(onAnimationEnded)
        
        if not track.IsPlaying then
            onAnimationEnded()
        end
    end)
end

player.CharacterAdded:Connect(onCharacterAdded)

if player.Character then
    onCharacterAdded(player.Character)
end

showStartupWarning()
