-- rEm_PlayerStats_ESP_Test.lua
-- Standalone test of the player-statistics ESP extracted from rEm.lua.
-- Separate from ETW.DRAMA. Does not include EAT/GRAB, Auto-Sell, teleport,
-- speed, attack, anti-ragdoll, or the large platform feature.

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local enabled = false
local espObjects = {}
local screenGui

local function findNumericStat(targetPlayer, statName)
    local variants = {
        statName,
        string.gsub(statName, " ", ""),
        string.gsub(statName, " ", "_"),
    }

    local function checkObject(obj)
        for _, variant in ipairs(variants) do
            if string.lower(obj.Name) == string.lower(variant)
                and (obj:IsA("IntValue") or obj:IsA("NumberValue")) then
                return obj.Value
            end
        end
        return nil
    end

    for _, obj in ipairs(targetPlayer:GetDescendants()) do
        local value = checkObject(obj)
        if value ~= nil then return value end
    end

    for _, variant in ipairs(variants) do
        local value = targetPlayer:GetAttribute(variant)
        if value ~= nil then return value end

        if targetPlayer.Character then
            value = targetPlayer.Character:GetAttribute(variant)
            if value ~= nil then return value end
        end
    end

    local playerGui = targetPlayer:FindFirstChild("PlayerGui")
    if playerGui then
        for _, obj in ipairs(playerGui:GetDescendants()) do
            local value = checkObject(obj)
            if value ~= nil then return value end
        end
    end

    for _, obj in ipairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
        if string.find(string.lower(obj.Name), string.lower(targetPlayer.Name), 1, true) then
            for _, child in ipairs(obj:GetDescendants()) do
                local value = checkObject(child)
                if value ~= nil then return value end
            end
        end
    end

    return "?"
end

local function getStat(targetPlayer, nameList)
    for _, name in ipairs(nameList) do
        local value = findNumericStat(targetPlayer, name)
        if value ~= "?" then return value end
    end
    return "?"
end

local function createESP(targetPlayer)
    if targetPlayer == LocalPlayer or espObjects[targetPlayer] then return end

    local highlight = Instance.new("Highlight")
    highlight.Name = "rEmPlayerStatsHighlight"
    highlight.FillColor = Color3.fromRGB(0, 225, 245)
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.FillTransparency = 0.65
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "rEmPlayerStatsText"
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.new(0, 220, 0, 92)
    billboard.StudsOffset = Vector3.new(0, 4, 0)

    local label = Instance.new("TextLabel")
    label.Name = "Stats"
    label.Parent = billboard
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextStrokeTransparency = 0
    label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 12
    label.TextWrapped = true
    label.TextYAlignment = Enum.TextYAlignment.Bottom

    espObjects[targetPlayer] = {
        highlight = highlight,
        billboard = billboard,
        label = label,
    }
end

local function removeESP(targetPlayer)
    local entry = espObjects[targetPlayer]
    if not entry then return end
    entry.highlight:Destroy()
    entry.billboard:Destroy()
    espObjects[targetPlayer] = nil
end

local function updateESP()
    for targetPlayer, entry in pairs(espObjects) do
        if targetPlayer.Parent ~= Players then
            removeESP(targetPlayer)
        elseif enabled then
            local character = targetPlayer.Character
            local root = character and character:FindFirstChild("HumanoidRootPart")
            if character and root then
                entry.highlight.Parent = character
                entry.billboard.Parent = root

                local size = getStat(targetPlayer, {"Size"})
                local maxSize = getStat(targetPlayer, {"MaxSize", "Max Size", "Max", "Capacity"})
                local multi = getStat(targetPlayer, {"Size Multiplier", "Multiplier", "Multi"})
                local eat = getStat(targetPlayer, {"Eat Speed", "Eat Level"})
                local walkSpeed = 16
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                if humanoid then walkSpeed = math.floor(humanoid.WalkSpeed) end

                entry.label.Text = string.format(
                    "[%s]\nSize: %s / %s\nMulti: %s | Eat: %s\nWalkSpeed: %s",
                    targetPlayer.Name,
                    tostring(size),
                    tostring(maxSize),
                    tostring(multi),
                    tostring(eat),
                    tostring(walkSpeed)
                )
            else
                entry.highlight.Parent = nil
                entry.billboard.Parent = nil
            end
        else
            entry.highlight.Parent = nil
            entry.billboard.Parent = nil
        end
    end
end

for _, player in ipairs(Players:GetPlayers()) do createESP(player) end
Players.PlayerAdded:Connect(createESP)
Players.PlayerRemoving:Connect(removeESP)

-- Standalone toggle panel, draggable for mobile testing.
screenGui = Instance.new("ScreenGui")
screenGui.Name = "rEm_PlayerStats_ESP_Test"
screenGui.ResetOnSpawn = false
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.Parent = screenGui
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.new(0, 250, 0, 112)
panel.BackgroundColor3 = Color3.fromRGB(4, 10, 15)
panel.BackgroundTransparency = 0.08
panel.Active = true
panel.Draggable = true

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = panel

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(0, 225, 245)
stroke.Thickness = 2
stroke.Parent = panel

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Parent = panel
title.BackgroundTransparency = 1
title.Position = UDim2.new(0, 10, 0, 5)
title.Size = UDim2.new(1, -20, 0, 25)
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Text = "PLAYER STATS ESP TEST"

local toggle = Instance.new("TextButton")
toggle.Name = "Toggle"
toggle.Parent = panel
toggle.Position = UDim2.new(0, 10, 0, 36)
toggle.Size = UDim2.new(1, -20, 0, 34)
toggle.BackgroundColor3 = Color3.fromRGB(7, 37, 45)
toggle.TextColor3 = Color3.fromRGB(255, 255, 255)
toggle.Font = Enum.Font.GothamBold
toggle.TextSize = 13
toggle.Text = "PLAYER STATS ESP: OFF"

local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 8)
toggleCorner.Parent = toggle

local toggleStroke = Instance.new("UIStroke")
toggleStroke.Color = Color3.fromRGB(0, 225, 245)
toggleStroke.Thickness = 1.5
toggleStroke.Parent = toggle

toggle.Activated:Connect(function()
    enabled = not enabled
    toggle.Text = "PLAYER STATS ESP: " .. (enabled and "ON" or "OFF")
    toggle.BackgroundColor3 = enabled and Color3.fromRGB(0, 72, 82) or Color3.fromRGB(7, 37, 45)
    updateESP()
end)

-- Update visible ESP labels once per second; keep disabled entries detached.
task.spawn(function()
    while screenGui.Parent do
        if enabled then updateESP() end
        task.wait(1)
    end
end)

local camera = workspace.CurrentCamera
if camera and camera.ViewportSize.X < 400 then
    panel.Size = UDim2.new(0, math.max(220, camera.ViewportSize.X - 24), 0, 112)
end

screenGui.Destroying:Connect(function()
    enabled = false
    for player in pairs(espObjects) do
        removeESP(player)
    end
end)
