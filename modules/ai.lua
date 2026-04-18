local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

local detectedActivities = {}

local HttpService = game:GetService("HttpService")
local filename = getgenv().AI_DATA_FILE or "ai_data.json"

-- Load existing data
local aiData = {}
pcall(function()
    local dataStr = readfile(filename)
    if dataStr and dataStr ~= "" then
        aiData = HttpService:JSONDecode(dataStr)
    end
end)
print("📂 AI data loaded:", #detectedActivities, "entries")
detectedActivities = aiData.activities or {}

local function logActivity(plr, activity, details)
    local entry = {
        time = tick(),
        player = plr.Name,
        activity = activity,
        details = details or {}
    }
    table.insert(detectedActivities, entry)
    print(string.format("🤖 AI DETECT: %s | %s | %s", plr.Name, activity, HttpService:JSONEncode(details)))
    
    -- Save to file (throttled)
    spawn(function()
        local fullData = {
            activities = detectedActivities,
            lastUpdate = tick()
        }
        pcall(function()
            writefile(filename, HttpService:JSONEncode(fullData))
        end)
        print("💾 AI data saved:", #detectedActivities, "entries to", filename)
    end)
end

local connections = {}

local function startAI()
    if _G.FeatureState and _G.FeatureState.ai then return end
    if not _G.FeatureState then _G.FeatureState = {} end
    _G.FeatureState.ai = true
    print("🤖 AI Activity Detector: ON")

    -- Hook all RemoteEvents
    pcall(function()
        local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
        if remotesFolder then
            for _, remote in pairs(remotesFolder:GetDescendants()) do
                if remote:IsA("RemoteEvent") then
                    local name = remote.Name:lower()
                    if name:find("vault") or name:find("jump") or name:find("skill") or name:find("gen") or name:find("heal") or name:find("block") or name:find("mori") or name:find("hook") or name:find("hooked") or name:find("mori") or name:find("struggle") or name:find("pallet") then
                        connections[remote] = remote.OnClientEvent:Connect(function(...)
                            logActivity(player, "RemoteEvent_" .. remote.Name, {args = {...}})
                        end)
                    end
                end
            end
        end
    end)

    -- Detect vaulting/jumping (assume pallet/window have collision changes or animations)
    RunService.Heartbeat:Connect(function()
        if not _G.FeatureState.ai then return end
        
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= player and plr.Character then
                local humanoid = plr.Character:FindFirstChild("Humanoid")
                local root = plr.Character:FindFirstChild("HumanoidRootPart")
                if humanoid and root then
                    -- Detect hooked/struggle (low Y position, specific animations)
                    local height = root.Position.Y
                    if height < -10 then -- Assume hook Y low
                        logActivity(plr, "Hooked", {height = height})
                    end
                    
                    -- Detect pallet block (near pallet + low speed)
                    local map = workspace:FindFirstChild("Map")
                    if map then
                        for _, obj in pairs(map:GetChildren()) do
                            if obj.Name:lower():find("pallet") then
                                local dist = (root.Position - obj.Position).Magnitude
                                if dist < 5 and humanoid.WalkSpeed < 5 then
                                    logActivity(plr, "Pallet Block", {distance = dist, speed = humanoid.WalkSpeed})
                                end
                            end
                        end
                    end
                    -- Detect vault speed (fast/slow based velocity Y)
                    local velY = root.Velocity.Y
                    local vaultThresholdFast = 30
                    local vaultThresholdSlow = 15
                    
                    if velY > vaultThresholdSlow then
                        local activity = velY > vaultThresholdFast and "Vault Fast" or "Vault Slow"
                        logActivity(plr, activity, {velocityY = velY})
                    end
                    
                    -- Detect near pallet/window (assume names "Pallet", "Window")
                    local map = workspace:FindFirstChild("Map")
                    if map then
                        for _, obj in pairs(map:GetChildren()) do
                            if obj.Name:lower():find("pallet") or obj.Name:lower():find("window") then
                                local dist = (root.Position - obj.Position).Magnitude
                                if dist < 10 then
                                    logActivity(plr, "Near " .. obj.Name, {distance = dist})
                                end
                            end
                        end
                    end
                end
            end
        end
    end)
end

local function stopAI()
    _G.FeatureState.ai = false
    for remote, conn in pairs(connections) do
        conn:Disconnect()
    end
    connections = {}
    print("🤖 AI: OFF")
end

_G.ai = {}
_G.ai.Start = startAI
_G.ai.Stop = stopAI
_G.ai.activities = detectedActivities
_G.ai.getActivities = function()
    return detectedActivities
end

_G.ai.exportData = function()
    local HttpService = game:GetService("HttpService")
    pcall(function()
        setclipboard(HttpService:JSONEncode(detectedActivities))
        print("📋 AI data copied to clipboard (" .. #detectedActivities .. " entries)")
    end)
end

return _G.ai

