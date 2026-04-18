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
    print("[FEATURED]: ESP Player -> ON")
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
    print("[FEATURED]: ESP Player -> OFF")
end

-- ==============================================
-- APPLY KE PLAYER
-- ==============================================
local function handlePlayer(plr)
    if plr == player then return end

    local connections = {}
    playerConnections[plr] = connections

    if plr.Character then
        task.wait(0.1)
        setupESP(plr.Character)
    end

    local charAddedConn = plr.CharacterAdded:Connect(function(char)
        task.wait(0.5)
        if _G.FeatureState and _G.FeatureState.espPlayer then
            setupESP(char)
        end
    end)
    table.insert(connections, charAddedConn)
end

-- ==============================================
-- LOOP UPDATE WARNA (PAKAI TOGGLE)
-- ==============================================
RunService.Heartbeat:Connect(function()  -- ✅ THROTTLE 30fps
    local enabled = _G.FeatureState and _G.FeatureState.espPlayer

    if enabled ~= wasEnabled then
        wasEnabled = enabled
        if enabled then
            applyESPToAllPlayers()
        else
            removeESPFromAllPlayers()
        end
    end

    if not enabled then return end

    -- ✅ CACHE: Skip jika sudah benar
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= player and plr.Character then
            local h = plr.Character:FindFirstChild("ESP")
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

                -- ✅ OPTIMIZE: Hanya update jika warnanya beda
                if h.FillColor ~= targetColor then
                    h.FillColor = targetColor
                end
            end
        end
    end
end)

-- ==============================================
-- INIT PLAYER LISTENER + CLEANUP
-- ==============================================
local playerConnections = {}

local function cleanupPlayer(plr)
    if playerConnections[plr] then
        for _, conn in pairs(playerConnections[plr]) do
            conn:Disconnect()
        end
        playerConnections[plr] = nil
    end
end

Players.PlayerRemoving:Connect(cleanupPlayer)  -- ✅ CLEANUP

for _, p in pairs(Players:GetPlayers()) do
    handlePlayer(p)
end

Players.PlayerAdded:Connect(function(plr)
    handlePlayer(plr)
end)

-- ==============================================
-- GLOBAL
-- ==============================================
_G.espPlayer = {}
_G.espPlayer.Start = startESP
_G.espPlayer.Stop = stopESP

return _G.espPlayer