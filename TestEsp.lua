-- ETW Anti-Void + Big Platform Test
-- Separate test file; does not modify ETW.DRAMA.
-- UI: white text, cyan neon border, draggable mobile-friendly panel.
-- Note: platform is created locally by this client script. In some games,
-- client-created parts may not provide reliable server-side collision.

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local GUI_NAME = "ETW_AntiVoidPlatform_Test"
local old = PlayerGui:FindFirstChild(GUI_NAME)
if old then old:Destroy() end

local CYAN = Color3.fromRGB(0, 255, 255)
local WHITE = Color3.fromRGB(255, 255, 255)
local DARK = Color3.fromRGB(15, 18, 22)
local GREEN = Color3.fromRGB(0, 120, 80)
local RED = Color3.fromRGB(105, 35, 45)

local antiVoidEnabled = false
local platformEnabled = false
local platformPart = nil
local antiVoidLoop = nil

local gui = Instance.new("ScreenGui")
gui.Name = GUI_NAME
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = PlayerGui

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.Size = UDim2.new(0, 230, 0, 166)
panel.Position = UDim2.new(0.5, -115, 0.35, 0)
panel.BackgroundColor3 = DARK
panel.BackgroundTransparency = 0.08
panel.Active = true
panel.Draggable = true
panel.Parent = gui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 10)
local outline = Instance.new("UIStroke")
outline.Color = CYAN
outline.Thickness = 1.8
outline.Parent = panel

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, -40, 0, 30)
title.Position = UDim2.new(0, 10, 0, 4)
title.BackgroundTransparency = 1
title.Text = "ETW  |  VOID GUARD"
title.TextColor3 = WHITE
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = panel

local close = Instance.new("TextButton")
close.Size = UDim2.new(0, 26, 0, 24)
close.Position = UDim2.new(1, -32, 0, 6)
close.BackgroundColor3 = DARK
close.Text = "×"
close.TextColor3 = WHITE
close.Font = Enum.Font.GothamBold
close.TextSize = 18
close.Parent = panel
Instance.new("UICorner", close).CornerRadius = UDim.new(0, 5)
local closeStroke = Instance.new("UIStroke", close)
closeStroke.Color = CYAN
closeStroke.Thickness = 1

local function makeToggle(label, y, initial, callback)
    local button = Instance.new("TextButton")
    button.Name = label:gsub("%W", "") .. "Toggle"
    button.Size = UDim2.new(1, -20, 0, 38)
    button.Position = UDim2.new(0, 10, 0, y)
    button.BackgroundColor3 = initial and GREEN or RED
    button.TextColor3 = WHITE
    button.Font = Enum.Font.GothamBold
    button.TextSize = 13
    button.Text = label .. ": " .. (initial and "ON" or "OFF")
    button.AutoButtonColor = true
    button.Parent = panel
    Instance.new("UICorner", button).CornerRadius = UDim.new(0, 6)
    local stroke = Instance.new("UIStroke", button)
    stroke.Color = CYAN
    stroke.Thickness = 1
    local enabled = initial
    button.Activated:Connect(function()
        enabled = not enabled
        button.Text = label .. ": " .. (enabled and "ON" or "OFF")
        button.BackgroundColor3 = enabled and GREEN or RED
        callback(enabled)
    end)
    return button
end

local function createPlatform()
    if platformPart and platformPart.Parent then return end
    local part = Instance.new("Part")
    part.Name = "ETW_TestBigPlatform"
    part.Size = Vector3.new(90000, 10, 90000)
    part.Anchored = true
    part.CanCollide = true
    part.Transparency = 1
    part.Material = Enum.Material.Fabric
    part.Position = Vector3.new(0, -6, 0)
    part.Parent = workspace
    platformPart = part
end

local function removePlatform()
    if platformPart then
        platformPart:Destroy()
        platformPart = nil
    end
end

makeToggle("Anti-Void", 42, false, function(enabled)
    antiVoidEnabled = enabled
    if enabled then
        if antiVoidLoop then antiVoidLoop:Disconnect() end
        antiVoidLoop = game:GetService("RunService").Heartbeat:Connect(function()
            if not antiVoidEnabled then return end
            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if root and root.Position.Y < -50 then
                root.AssemblyLinearVelocity = Vector3.zero
                root.CFrame = CFrame.new(0, 50, 0)
            end
        end)
    elseif antiVoidLoop then
        antiVoidLoop:Disconnect()
        antiVoidLoop = nil
    end
end)

makeToggle("Big Platform", 88, false, function(enabled)
    platformEnabled = enabled
    if enabled then
        createPlatform()
    else
        removePlatform()
    end
end)

local note = Instance.new("TextLabel")
note.Size = UDim2.new(1, -20, 0, 24)
note.Position = UDim2.new(0, 10, 0, 134)
note.BackgroundTransparency = 1
note.Text = "White text  •  Cyan neon frame"
note.TextColor3 = WHITE
note.Font = Enum.Font.Gotham
note.TextSize = 10
note.Parent = panel

close.Activated:Connect(function()
    antiVoidEnabled = false
    platformEnabled = false
    if antiVoidLoop then antiVoidLoop:Disconnect(); antiVoidLoop = nil end
    removePlatform()
    gui:Destroy()
end)

gui.Destroying:Connect(function()
    antiVoidEnabled = false
    platformEnabled = false
    if antiVoidLoop then antiVoidLoop:Disconnect(); antiVoidLoop = nil end
    removePlatform()
end)
