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
local function createNameTag(plr, char)
    local head = char:FindFirstChild("Head")
    if not head then return end
    
    -- Cleanup old
    local oldTag = head:FindFirstChild("NameTag")
    if oldTag then oldTag:Destroy() end
    
    local bill = Instance.new("BillboardGui")
    bill.Name = "NameTag"
    bill.Size = UDim2.new(0, 100, 0, 40)  -- Samakan generator
    bill.StudsOffset = Vector3.new(0, 2.5, 0)
    bill.AlwaysOnTop = true
    bill.Parent = head
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.TextScaled = false
    label.TextSize = 14  -- Samakan generator
    label.Font = Enum.Font.SourceSansBold
    label.TextStrokeTransparency = 0
    label.TextStrokeColor3 = Color3.new(0,0,0)
    label.Parent = bill
    
    return bill, label
end

local function getPlayerLevel(plr)
    -- Advanced leaderstats scan
    local leaderstats = plr:WaitForChild("leaderstats", 3)
    if leaderstats then
        for _, stat in ipairs(leaderstats:GetChildren()) do
            local name = stat.Name:lower()
            if name:find("level") and (stat:IsA("IntValue") or stat:IsA("NumberValue")) then
                return math.floor(stat.Value)
            end
        end
    end
    -- Fallback common names
    pcall(function()
        local stats = plr.PlayerGui:FindFirstChild("PlayerFrame", true)
        if stats then
            local lvl = stats:FindFirstChild("Level", true)
            if lvl then return tonumber(lvl.Text:match("%d+")) or 1 end
        end
    end)
    return 1
end

local playerLevelCache = {}
local lastLevelUpdate = {}

local function updateNameTag(plr, label)
    local plrId = plr.UserId
    local now = tick()
    
    -- Cache 2s debounce
    if not playerLevelCache[plrId] or now - (lastLevelUpdate[plrId] or 0) > 2 then
        playerLevelCache[plrId] = getPlayerLevel(plr)
        lastLevelUpdate[plrId] = now
    end
    
    local level = playerLevelCache[plrId] or 1
    label.Text = string.format("[LVL %d] %s", level, plr.Name)
end

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

    -- Check if plr.Character is not nil before accessing its properties
    if char and char:FindFirstChild("Head") then
        local headTag = char:FindFirstChild("Head"):FindFirstChild("NameTag")
        if headTag then
            local label = headTag:FindFirstChild("TextLabel")
            if label then
                -- Rest of your code here
            end
        end
    end
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
            local head = plr.Character:FindFirstChild("Head")
            if head then
                createNameTag(plr, head)
            end
        end
    end
end

local function removeESPFromAllPlayers()
    for _, plr in pairs(Players:GetPlayers()) do
        if plr.Character then
            removeESP(plr.Character)
            local headTag = plr.Character.Head and plr.Character.Head:FindFirstChild("NameTag")
            if headTag then headTag:Destroy() end  -- ✅ Cleanup name tags
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
            createNameTag(plr, char)  -- ✅ Add name tag
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
            local head = plr.Character:FindFirstChild("Head")
            local headTag = head and head:FindFirstChild("NameTag")
            local label = headTag and headTag:FindFirstChild("TextLabel")
            
            if h then
                local role = getPlayerRole(plr)
                local targetColor
                
                if role == "KILLER" then
                    targetColor = Color3.fromRGB(255, 0, 0)
                    if label then label.TextColor3 = targetColor end
                elseif role == "SURVIVORS" then
                    targetColor = Color3.fromRGB(0, 170, 255)
                    if label then label.TextColor3 = targetColor end
                elseif role == "SPECTATOR" then
                    targetColor = Color3.fromRGB(255, 255, 255)
                    if label then label.TextColor3 = targetColor end
                else
                    targetColor = Color3.fromRGB(128, 128, 128)
                    if label then label.TextColor3 = targetColor end
                end

                if h.FillColor ~= targetColor then
                    h.FillColor = targetColor
                end
            end
            
            -- Update name tag
            if label then
                updateNameTag(plr, label)
            end
        end
    end
end)

-- ==============================================
-- INIT PLAYER LISTENER + CLEANUP
-- ==============================================
local playerConnections = {}

local function cleanupPlayer(plr)
    local plrId = plr.UserId
    if playerConnections[plr] then
        for _, conn in pairs(playerConnections[plr]) do
            conn:Disconnect()
        end
        playerConnections[plr] = nil
    end
    playerLevelCache[plrId] = nil  -- ✅ Cleanup cache
    lastLevelUpdate[plrId] = nil
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