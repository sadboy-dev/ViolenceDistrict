local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

local skillRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Generator"):WaitForChild("SkillCheckResultEvent")
local playerGui = player:WaitForChild("PlayerGui")

local lastGenModel = nil
local lastGenPoint = nil
local wasEnabled = false

-- getGenerators direct (fast)
local function getGenerators()
    local gens = {}
    pcall(function()
        local map = workspace:FindFirstChild("Map")
        if map then
            for _, v in pairs(map:GetDescendants()) do
                if v.Name == "Generator" then
                    table.insert(gens, v)
                end
            end
        end
    end)
    return gens
end

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

-- Heal detection
local function isHealing()
    -- Check tool
    for _, tool in pairs(char:GetChildren()) do
        if tool:IsA("Tool") and (tool.Name:lower():find("medkit") or tool.Name:lower():find("heal")) then
            return true
        end
    end
    
    -- Check near teammate low health (raycast simplified)
    local camera = workspace.CurrentCamera
    local ray = camera:ScreenPointToRay(workspace.CurrentCamera.ViewportSize.X/2, workspace.CurrentCamera.ViewportSize.Y/2)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {char}
    
    local result = workspace:Raycast(ray.Origin, ray.Direction * 50, raycastParams)
    if result and result.Instance then
        local hitChar = result.Instance:FindFirstAncestorOfClass("Model")
        if hitChar and hitChar ~= char and Players:GetPlayerFromCharacter(hitChar) then
            local hum = hitChar:FindFirstChild("Humanoid")
            if hum and hum.Health < hum.MaxHealth * 0.8 then -- 80% health
                return true
            end
        end
    end
    return false
end

-- Main throttled loop
RunService.Heartbeat:Connect(function()
    if not _G.FeatureState or not _G.FeatureState.autoGene then 
        return 
    end
    
    -- Fast role check
    local role = _G.RoleData and string.upper(_G.RoleData.TeamName or "") or ""
    if role ~= "SURVIVORS" then return end

    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    if isHealing() then return end -- Skip if healing

    local genModel, genPoint, dist = getClosestGeneratorPoint(root)
    
    if genPoint and dist < 8 then
        lastGenModel = genModel
        lastGenPoint = genPoint
    end

    local gui = playerGui:FindFirstChild("SkillCheckPromptGui")
    if gui then
        local check = gui:FindFirstChild("Check")
        if check and check.Visible and lastGenPoint and (root.Position - lastGenPoint.Position).Magnitude < 8 then
            skillRemote:FireServer("success", 1, lastGenModel, lastGenPoint)
            check.Visible = false
            print("🎯 Skillcheck success!")
        end
    end
end)

-- Global toggle (called from main.lua)
local function startAutoGene()
    if not _G.FeatureState then _G.FeatureState = {} end
    _G.FeatureState.autoGene = true
    print("🔧 Auto Gene: Ready")
end

local function stopAutoGene()
    _G.FeatureState.autoGene = false
    print("[autoGene]: OFF")
end

_G.autoGene = {}
_G.autoGene.Start = startAutoGene
_G.autoGene.Stop = stopAutoGene

return _G.autoGene

