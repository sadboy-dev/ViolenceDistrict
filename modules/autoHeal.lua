-- Auto Heal Module
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local healRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Healing"):WaitForChild("SkillCheckResultEvent")

local lastHealTarget = nil
local wasEnabled = false

local function getHealth(plr)
    if not plr.Character then return 100 end
    local hum = plr.Character:FindFirstChild("Humanoid")
    if hum then return hum.Health end
    local h = plr.Character:FindFirstChild("Health")
    if h and h.Value then return h.Value end
    return 100
end

local function getClosestLowHealthTeammate(root)
local closest, closestDist = nil, math.huge
    -- Priority: Lowest HP first
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player and plr.Team == player.Team and plr.Character then
            local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local hp = getHealth(plr)
if hp <= 50 then
                    local dist = (root.Position - hrp.Position).Magnitude
                    if dist < closestDist then
                        closest = plr
                        closestDist = dist
                    end
                end
            end
        end
    end
    return closest
end

RunService.Heartbeat:Connect(function()
    if not _G.FeatureState or not _G.FeatureState.autoHeal then return end
    
    local role = _G.RoleData and string.upper(_G.RoleData.TeamName or "") or ""
    if role ~= "SURVIVORS" then return end
    -- Role safe

    local char = player.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChild("Humanoid")
    if not root or not hum then return end

    local isMoving = hum.MoveDirection.Magnitude > 0.05
    if isMoving then 
        lastHealTarget = nil
        return 
    end

    lastHealTarget = getClosestLowHealthTeammate(root)

    local gui = playerGui:FindFirstChild("SkillCheckPromptGui")
    if gui then
        local check = gui:FindFirstChild("Check")
        if check and check.Visible then
            if lastHealTarget then
                local hp = getHealth(lastHealTarget)
if hp <= 50 then
                    local targetChar = lastHealTarget.Character
                    if targetChar then
                        healRemote:FireServer("success", 1, targetChar)
                        check.Visible = false
                        print("❤️ Auto Heal Success!")
                    end
                end
            end
            print("💉 Heal check detected") -- Debug log
            -- No target: do nothing, don't fire gen remote
        end
    end
end)

local function startAutoHeal()
    if not _G.FeatureState then _G.FeatureState = {} end
    _G.FeatureState.autoHeal = true
    print("❤️ Auto Heal: Ready")
end

local function stopAutoHeal()
    _G.FeatureState.autoHeal = false
    lastHealTarget = nil
    print("❤️ Auto Heal: OFF")
end

_G.autoHeal = {}
_G.autoHeal.Start = startAutoHeal
_G.autoHeal.Stop = stopAutoHeal

return _G.autoHeal
