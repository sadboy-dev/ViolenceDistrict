local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

local function getPlayerRole(plr)
    if not plr or not plr.Team then
        return ""
    end

    return string.upper(plr.Team.Name or "")
end

local wasEnabled = false

-- ==============================================
-- SETUP ESP
-- ==============================================
local function setupESP(char)
    if not char then return end

    local old = char:FindFirstChild("ESP")
    if old then old:Destroy() end

    local h = Instance.new("Highlight")
    h.Name = "ESP"
    h.FillTransparency = 0.5
    h.OutlineTransparency = 0
    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    h.Parent = char
end

local function createNameTag(plr, char)
    local head = char:FindFirstChild("Head")
    if not head then return end

    -- Cleanup old
    local oldTag = head:FindFirstChild("NameTag")
    if oldTag then oldTag:Destroy() end

    local bill = Instance.new("BillboardGui")
    bill.Name = "NameTag"
    bill.Size = UDim2.new(0, 100, 0, 40)
    bill.StudsOffset = Vector3.new(0, 2.5, 0)
    bill.AlwaysOnTop = true
    bill.Parent = head

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = plr.Name
    label.Font = Enum.Font.SourceSansBold
    label.TextSize = 14
    label.TextStrokeTransparency = 0
    label.TextColor3 = Color3.new(1,1,1)  -- Default white
    label.Parent = bill

    return bill, label
end

local function removeESP(char)
    if char then
        local h = char:FindFirstChild("ESP")
        if h then h:Destroy() end
    end
end

local function applyESPToAllPlayers()
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= player and plr.Character then
            setupESP(plr.Character)
        end
    end
end

local function removeESPFromAllPlayers()
    for _, plr in pairs(Players:GetPlayers()) do
        if plr.Character then
            removeESP(plr.Character)
            local head = plr.Character:FindFirstChild("Head")
            if head then
                local nameTag = head:FindFirstChild("NameTag")
                if nameTag then nameTag:Destroy() end
            end
        end
    end
end

local function startESP()
    if not _G.FeatureState then
        _G.FeatureState = {}
    end
    if _G.FeatureState.espPlayer then
        return
    end

    _G.FeatureState.espPlayer = true
    applyESPToAllPlayers()
    print("✅ ESP Player: ON")
end

local function stopESP()
    if not _G.FeatureState then
        _G.FeatureState = {}
    end
    if not _G.FeatureState.espPlayer then
        return
    end

    _G.FeatureState.espPlayer = false
    removeESPFromAllPlayers()
    print("❌ ESP Player: OFF")
end

-- ==============================================
-- APPLY KE PLAYER
-- ==============================================
local function handlePlayer(plr)
    if plr == player then return end

    local function onCharAdded(char)
        task.wait(0.5)
        if _G.FeatureState and _G.FeatureState.espPlayer then
            setupESP(char)
            local head = char:FindFirstChild("Head")
            if head then
                createNameTag(plr, char)
            end
        end
    end

    if plr.Character then
        onCharAdded(plr.Character)
    end

    plr.CharacterAdded:Connect(onCharAdded)
end

-- ==============================================
-- LOOP UPDATE WARNA (PAKAI TOGGLE)
-- ==============================================
RunService.RenderStepped:Connect(function()
    local enabled = _G.FeatureState and _G.FeatureState.espPlayer

    if enabled and not wasEnabled then
        wasEnabled = true
        applyESPToAllPlayers()
    elseif not enabled and wasEnabled then
        wasEnabled = false
        removeESPFromAllPlayers()
    end

    if not enabled then
        return
    end

    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= player and plr.Character then
            local h = plr.Character:FindFirstChild("ESP")
            local head = plr.Character:FindFirstChild("Head")
            local headTag = head and head:FindFirstChild("NameTag")
            local label = headTag and headTag:FindFirstChildOfClass("TextLabel")
            
            if h then
                local role = getPlayerRole(plr)
                local targetColor
                
                if role == "KILLER" then
                    targetColor = Color3.fromRGB(255, 0, 0)
                elseif role == "SURVIVORS" then
                    targetColor = Color3.fromRGB(0, 170, 255)
                elseif role == "SPECTATOR" then
                    targetColor = Color3.fromRGB(255, 255, 255)
                else
                    targetColor = Color3.fromRGB(128, 128, 128)
                end

                h.FillColor = targetColor
                if label then
                    label.TextColor3 = targetColor
                end
            end
        end
    end
end)

-- ==============================================
-- INIT PLAYER LISTENER
-- ==============================================
for _, p in pairs(Players:GetPlayers()) do
    handlePlayer(p)
end

Players.PlayerAdded:Connect(handlePlayer)

-- ==============================================
-- GLOBAL
-- ==============================================
_G.espPlayer = {}
_G.espPlayer.Start = startESP
_G.espPlayer.Stop = stopESP

return _G.espPlayer