local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

local skillRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Generator"):WaitForChild("SkillCheckResultEvent")
local playerGui = player:WaitForChild("PlayerGui")

local lastGenModel = nil
local lastGenPoint = nil
local wasEnabled = false

-- Import getGenerators from espGene
local getGenerators = getGenerators or (function() 
    local gens = {}
    local map = workspace:FindFirstChild("Map")
    if map then
        for _, v in pairs(map:GetDescendants()) do
            if v.Name == "Generator" then
                table.insert(gens, v)
            end
        end
    end
    return gens
end)

local function getClosestGeneratorPoint(root)
    local gens = getGenerators()
    local closestGen, closestPoint, closestDist = nil, nil, math.huge

    for _, gen in ipairs(gens) do
        for i = 1, 4 do
            local point = gen:FindFirstChild("GeneratorPoint" .. i)
            if point then
                local dist = (root.Position - point.Position).Magnitude
                if dist < closestDist then
                    closestDist = dist
                    closestGen = gen
                    closestPoint = point
                end
            end
        end
    end
    return closestGen, closestPoint, closestDist
end

-- Main throttled loop
RunService.Heartbeat:Connect(function()
    local enabled = _G.FeatureState and _G.FeatureState.autoGene
    local role = _G.RoleData and (_G.RoleData.IsLobby and "SPECTATOR" or string.upper(_G.RoleData.TeamName or ""))
    
    -- Only survivors + enabled
    if not enabled or role ~= "SURVIVORS" then 
        if wasEnabled then
            wasEnabled = false
            print("[autoGene]: OFF")
        end
        return 
    end
    
    if not wasEnabled then
        wasEnabled = true
        print("[autoGene]: ON (Survivors only)")
    end

    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local genModel, genPoint, dist = getClosestGeneratorPoint(root)
    
    -- Update last point if close
    if genPoint and dist < 8 then
        lastGenModel = genModel
        lastGenPoint = genPoint
    end

    -- Auto skillcheck
    local gui = playerGui:FindFirstChild("SkillCheckPromptGui")
    if gui then
        local check = gui:FindFirstChild("Check")
        if check and check.Visible and lastGenPoint and (root.Position - lastGenPoint.Position).Magnitude < 8 then
            skillRemote:FireServer("success", 1, lastGenModel, lastGenPoint)
            check.Visible = false  -- Hide instantly
        end
    end
end)

-- Global toggle (called from main.lua)
local function startAutoGene()
    if not _G.FeatureState then _G.FeatureState = {} end
    _G.FeatureState.autoGene = true
    print("[autoGene]: Ready (waiting for Survivors role)")
end

local function stopAutoGene()
    _G.FeatureState.autoGene = false
    print("[autoGene]: OFF")
end

_G.autoGene = {}
_G.autoGene.Start = startAutoGene
_G.autoGene.Stop = stopAutoGene

print("[autoGene]: Loaded - Integrate to main.lua for Survivors toggle")
return _G.autoGene

