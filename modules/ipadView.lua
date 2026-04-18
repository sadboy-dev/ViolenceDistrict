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

local screenGui = nil
local crosshairLabel = nil

local function cleanupCrosshair()
    if crosshairLabel then
        crosshairLabel:Destroy()
        crosshairLabel = nil
    end
    if screenGui then
        screenGui:Destroy()
        screenGui = nil
    end
end

local function createCrosshair()
    cleanupCrosshair()
    
    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "IpadCrosshair"
    screenGui.IgnoreGuiInset = true
    screenGui.Parent = game.CoreGui -- Always on top
    
    crosshairLabel = Instance.new("Frame")
    crosshairLabel.AnchorPoint = Vector2.new(0.5, 0.5)
    crosshairLabel.Size = UDim2.new(0, 6, 0, 6)
    crosshairLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
    crosshairLabel.BackgroundTransparency = 1
    crosshairLabel.BorderSizePixel = 0
    crosshairLabel.BackgroundColor3 = Color3.FromRGB(255,255,0)
    crosshairLabel.Parent = screenGui
end

local function restoreFOV()
    if workspace.CurrentCamera and originalFOV then
        workspace.CurrentCamera.FieldOfView = originalFOV
    end
end

-- LOOP DENGAN CEK TOGGLE (FIX DOUBLE)
RunService.Heartbeat:Connect(function()
    local enabled = _G.FeatureState and _G.FeatureState.ipadView
    
    if enabled ~= wasEnabled then
        wasEnabled = enabled
        task.wait(0.1)  -- Stabil switch
        if enabled then
            cacheOriginalFOV()
            workspace.CurrentCamera.FieldOfView = IPAD_FOV
            createCrosshair()
        else
            restoreFOV()
            cleanupCrosshair()
        end
        return
    end
    
    if enabled and workspace.CurrentCamera and workspace.CurrentCamera.FieldOfView ~= IPAD_FOV then
        workspace.CurrentCamera.FieldOfView = IPAD_FOV
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
    print("📱 Ipad View: ON")
end

local function stopBoost()
    _G.FeatureState.ipadView = false
    restoreFOV()
    print("📱 Ipad View: OFF")
end

_G.ipadView = startBoost
_G.stopIpadView = stopBoost

return startBoost