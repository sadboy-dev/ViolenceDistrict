local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local IPAD_FOV = 100
local originalFOV = nil
local wasEnabled = false

local function cacheOriginalFOV()
    if not originalFOV and workspace.CurrentCamera then
        originalFOV = workspace.CurrentCamera.FieldOfView
    end
end

local function applyFOV()
    if workspace.CurrentCamera then
        cacheOriginalFOV()
        workspace.CurrentCamera.FieldOfView = IPAD_FOV
    end
end

local function restoreFOV()
    if workspace.CurrentCamera and originalFOV then
        workspace.CurrentCamera.FieldOfView = originalFOV
    end
end

-- LOOP DENGAN CEK TOGGLE
RunService.RenderStepped:Connect(function()
    if _G.FeatureState and _G.FeatureState.ipadView then
        if not wasEnabled then
            wasEnabled = true
            cacheOriginalFOV()
        end
        if workspace.CurrentCamera and workspace.CurrentCamera.FieldOfView ~= IPAD_FOV then
            workspace.CurrentCamera.FieldOfView = IPAD_FOV
        end
    elseif wasEnabled then
        wasEnabled = false
        restoreFOV()
    end
end)

-- APPLY SAAT SPAWN (HANYA JIKA ON)
if player then
    player.CharacterAdded:Connect(function()
        task.wait(0.5)
        if _G.FeatureState and _G.FeatureState.ipadView then
            applyFOV()
        end
    end)
end

-- FUNCTION GLOBAL
local function startBoost()
    if not _G.FeatureState then
        _G.FeatureState = {}
    end
    _G.FeatureState.ipadView = true
    applyFOV()
    print("[FEATURED]: Ipad View -> ON")
end

local function stopBoost()
    _G.FeatureState.ipadView = false
    restoreFOV()
    print("[FEATURED]: Ipad View -> OFF")
end

_G.ipadView = startBoost
_G.stopIpadView = stopBoost

return startBoost