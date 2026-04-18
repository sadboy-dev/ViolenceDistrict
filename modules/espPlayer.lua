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

    if plr.Character and _G.FeatureState and _G.FeatureState.espPlayer then
        setupESP(plr.Character)
    end

    plr.CharacterAdded:Connect(function(char)
        task.wait(0.5)
        if _G.FeatureState and _G.FeatureState.espPlayer then
            setupESP(char)
        end
    end)
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
            if h then
                local role = getPlayerRole(plr)
                
                -- Debug: cek nilai role yang dikembalikan
                local colorSet = false
                
                if role == "KILLER" then
                    h.FillColor = Color3.fromRGB(255, 0, 0)
                    colorSet = true
                elseif role == "SURVIVORS" then
                    h.FillColor = Color3.fromRGB(0, 170, 255)
                    colorSet = true
                elseif role == "SPECTATOR" then
                    h.FillColor = Color3.fromRGB(255, 255, 255)
                    colorSet = true
                else
                    h.FillColor = Color3.fromRGB(128, 128, 128)
                    print("[ESP DEBUG] Role tidak dikenali: '" .. role .. "' dari player: " .. plr.Name)
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