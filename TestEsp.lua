-- ETW.DRAMA Combat Speed Test
-- Standalone test module based on rEm.lua's Speed Value + Run Speed logic.
-- This test intentionally contains only the speed controls, not AutoFarm/EAT/GRAB,
-- Auto-Sell, ESP, teleport, anti-ragdoll, or other rEm features.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Clean up a previous test copy.
local previous = playerGui:FindFirstChild("ETW_CombatSpeed_Test")
if previous then previous:Destroy() end

local DEFAULT_SPEED = 100
local MIN_SPEED = 0
-- No fixed maximum; user chooses the speed value in the input

local speedValue = DEFAULT_SPEED
local speedEnabled = false
local heartbeatConnection
local destroyed = false

local function getCharacterParts()
    local character = player.Character
    if not character then return nil, nil, nil end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local root = character:FindFirstChild("HumanoidRootPart")
    return character, humanoid, root
end

local function stopSpeed()
    speedEnabled = false
    if heartbeatConnection then
        heartbeatConnection:Disconnect()
        heartbeatConnection = nil
    end
end

local gui = Instance.new("ScreenGui")
gui.Name = "ETW_CombatSpeed_Test"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = playerGui

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.new(0, 235, 0, 142)
panel.BackgroundColor3 = Color3.fromRGB(5, 12, 17)
panel.BackgroundTransparency = 0.06
panel.Active = true
panel.Parent = gui

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 10)
panelCorner.Parent = panel

local panelStroke = Instance.new("UIStroke")
panelStroke.Color = Color3.fromRGB(0, 225, 245)
panelStroke.Thickness = 2
panelStroke.Parent = panel

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Parent = panel
title.BackgroundTransparency = 1
title.Position = UDim2.new(0, 10, 0, 7)
title.Size = UDim2.new(1, -20, 0, 22)
title.Font = Enum.Font.GothamBold
title.TextSize = 13
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Text = "COMBAT SPEED TEST"

local speedLabel = Instance.new("TextLabel")
speedLabel.Parent = panel
speedLabel.BackgroundTransparency = 1
speedLabel.Position = UDim2.new(0, 10, 0, 34)
speedLabel.Size = UDim2.new(1, -20, 0, 18)
speedLabel.Font = Enum.Font.GothamBold
speedLabel.TextSize = 12
speedLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
speedLabel.TextXAlignment = Enum.TextXAlignment.Left
speedLabel.Text = "Speed Value"

local speedBox = Instance.new("TextBox")
speedBox.Name = "SpeedValue"
speedBox.Parent = panel
speedBox.Position = UDim2.new(0, 10, 0, 54)
speedBox.Size = UDim2.new(1, -20, 0, 28)
speedBox.BackgroundColor3 = Color3.fromRGB(14, 29, 35)
speedBox.TextColor3 = Color3.fromRGB(255, 255, 255)
speedBox.PlaceholderColor3 = Color3.fromRGB(170, 190, 195)
speedBox.PlaceholderText = "Enter speed (no max)"
speedBox.Text = tostring(DEFAULT_SPEED)
speedBox.ClearTextOnFocus = false
speedBox.Font = Enum.Font.GothamBold
speedBox.TextSize = 12
speedBox.TextXAlignment = Enum.TextXAlignment.Center
local boxCorner = Instance.new("UICorner")
boxCorner.CornerRadius = UDim.new(0, 6)
boxCorner.Parent = speedBox
local boxStroke = Instance.new("UIStroke")
boxStroke.Color = Color3.fromRGB(0, 160, 180)
boxStroke.Thickness = 1
boxStroke.Parent = speedBox

local toggle = Instance.new("TextButton")
toggle.Name = "RunSpeedToggle"
toggle.Parent = panel
toggle.Position = UDim2.new(0, 10, 0, 91)
toggle.Size = UDim2.new(1, -20, 0, 34)
toggle.BackgroundColor3 = Color3.fromRGB(24, 35, 39)
toggle.TextColor3 = Color3.fromRGB(255, 255, 255)
toggle.Font = Enum.Font.GothamBold
toggle.TextSize = 12
toggle.Text = "RUN SPEED: OFF"
local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 7)
toggleCorner.Parent = toggle
local toggleStroke = Instance.new("UIStroke")
toggleStroke.Color = Color3.fromRGB(0, 225, 245)
toggleStroke.Thickness = 1.3
toggleStroke.Parent = toggle

-- Drag panel using touch or mouse; avoids deprecated Frame.Draggable.
do
    local dragging = false
    local dragInput
    local dragStart
    local startPosition

    panel.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPosition = panel.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType ~= Enum.UserInputType.MouseMovement
            and input.UserInputType ~= Enum.UserInputType.Touch then return end
        local delta = input.Position - dragStart
        panel.Position = UDim2.new(
            startPosition.X.Scale, startPosition.X.Offset + delta.X,
            startPosition.Y.Scale, startPosition.Y.Offset + delta.Y
        )
    end)
end

local function startSpeed()
    if heartbeatConnection then heartbeatConnection:Disconnect() end
    speedEnabled = true
    heartbeatConnection = RunService.Heartbeat:Connect(function(delta)
        if not speedEnabled then return end
        local _, humanoid, root = getCharacterParts()
        if not humanoid or not root or humanoid.Health <= 0 then return end

        -- Mirrors the movement calculation in rEm.lua.
        -- This moves the root in the Humanoid's current move direction.
        if humanoid.MoveDirection.Magnitude > 0 then
            root.Anchored = false
            local pos = root.Position + (humanoid.MoveDirection * speedValue * delta)
            root.CFrame = CFrame.new(pos, pos + root.CFrame.LookVector)
        end
    end)
end

speedBox.FocusLost:Connect(function()
    local value = tonumber(speedBox.Text)
    if not value then
        speedValue = DEFAULT_SPEED
    else
        speedValue = math.max(value, MIN_SPEED)
    end
    speedBox.Text = tostring(speedValue)
end)

toggle.Activated:Connect(function()
    if speedEnabled then
        stopSpeed()
    else
        local value = tonumber(speedBox.Text)
        if value then speedValue = math.max(value, MIN_SPEED) end
        speedBox.Text = tostring(speedValue)
        startSpeed()
    end
    toggle.Text = "RUN SPEED: " .. (speedEnabled and "ON" or "OFF")
    toggle.BackgroundColor3 = speedEnabled
        and Color3.fromRGB(0, 72, 82)
        or Color3.fromRGB(24, 35, 39)
end)

gui.Destroying:Connect(function()
    destroyed = true
    stopSpeed()
end)

player.CharacterRemoving:Connect(function()
    stopSpeed()
    toggle.Text = "RUN SPEED: OFF"
    toggle.BackgroundColor3 = Color3.fromRGB(24, 35, 39)
end)

print("ETW Combat Speed Test loaded. Default Speed Value = 100; Run Speed is OFF.")
