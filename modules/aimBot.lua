local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

local MAX_RANGE = 100
local UPDATE_RATE = 1/30 -- 30 FPS
local lastUpdate = 0

local targetPart = nil -- Torso/UpperTorso
local lastTarget = nil

local function getRole()
    return _G.RoleData and string.upper(_G.RoleData.TeamName or "") or ""
end

local function isValidTarget(targetPlayer)
    local role = getRole()
    if role == "SPECTATOR" then return false end
    
    local targetRole = targetPlayer.Team and string.upper(targetPlayer.Team.Name or "")
    
    -- Survivors aim Killer
    if role == "SURVIVORS" then
        return targetRole == "KILLER"
    end
    
    -- Killer aim Survivors (not hooked/knocked)
    if role == "KILLER" then
        if targetRole ~= "SURVIVORS" then return false end
        
        local char = targetPlayer.Character
        if not char then return false end
        
        -- Check hooked (low Y or hook object)
        local root = char:FindFirstChild("HumanoidRootPart")
        if root and root.Position.Y < -10 then return false end
        
        local hum = char:FindFirstChild("Humanoid")
        if hum and (hum.Health <= 0 or hum.PlatformStand) then return false end
        
        return true
    end
    
    return false
end

local function raycastClear(origin, targetPos)
    local direction = (targetPos - origin).Unit * MAX_RANGE
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {player.Character}
    
    local result = Workspace:Raycast(origin, direction, raycastParams)
    return not result or (result.Instance:IsDescendantOf(targetPart.Parent))
end

local function findTarget()
    local role = getRole()
    if role == "SPECTATOR" then return nil end
    
    local closestTarget = nil
    local closestDist = MAX_RANGE
    
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= player and isValidTarget(plr) then
            local char = plr.Character
            if char then
                targetPart = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") or char:FindFirstChild("HumanoidRootPart")
                if targetPart then
                    local dist = (camera.CFrame.Position - targetPart.Position).Magnitude
                    if dist < closestDist and raycastClear(camera.CFrame.Position, targetPart.Position) then
                        closestDist = dist
                        closestTarget = targetPart
                    end
                end
            end
        end
    end
    
    return closestTarget
end

local function updateAim()
    local now = tick()
    if now - lastUpdate < UPDATE_RATE then return end
    lastUpdate = now
    
    if not _G.FeatureState.aimBot then 
        if lastTarget then
            lastTarget = nil
        end
        return 
    end
    
    local target = findTarget()
    if target and target ~= lastTarget then
        lastTarget = target
        print("🎯 Aimbot locked:", target.Parent.Name)
    end
    
    if target then
        camera.CFrame = CFrame.lookAt(camera.CFrame.Position, target.Position)
    end
end

RunService.RenderStepped:Connect(updateAim)

-- Global toggle
local function startAimbot()
    if not _G.FeatureState then _G.FeatureState = {} end
    _G.FeatureState.aimBot = true
    print("🎯 Aimbot: ON")
end

local function stopAimbot()
    _G.FeatureState.aimBot = false
    lastTarget = nil
    print("🎯 Aimbot: OFF")
end

_G.aimBot = {}
_G.aimBot.Start = startAimbot
_G.aimBot.Stop = stopAimbot

return _G.aimBot
