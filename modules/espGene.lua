local RunService = game:GetService("RunService")
local espGenObjects = {}
local wasEnabled = false
local progressEnabled = false

-- Safety check for RunService
if not RunService then
    warn("RunService not available, ESP Generator module may not work properly")
    return {}
end

local function removeGenESP(obj)
    if espGenObjects[obj] then
        local data = espGenObjects[obj]
        if data.highlight then data.highlight:Destroy() end
        if data.billboard then data.billboard:Destroy() end
        espGenObjects[obj] = nil
    end
end

local function createGenESP(obj, color, percent)
    if not (_G.FeatureState and _G.FeatureState.espGenerator) then return end

    local data = espGenObjects[obj]

    if data then
        data.highlight.FillColor = color
        if progressEnabled then
            data.label.Text = percent .. "%"
            data.label.TextColor3 = color
        else
            data.label.Text = ""
        end
        return
    end

    local h = Instance.new("Highlight")
    h.FillColor = color
    h.FillTransparency = 0.5
    h.Parent = obj

    local bill = Instance.new("BillboardGui")
    bill.Size = UDim2.new(0,100,0,40)
    bill.AlwaysOnTop = true
    bill.Parent = obj

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1,0,1,0)
    label.BackgroundTransparency = 1
    label.TextScaled = false
    label.TextSize = 14
    label.Font = Enum.Font.SourceSansBold
    label.TextStrokeTransparency = 0
    label.Text = progressEnabled and (percent .. "%") or ""
    label.TextColor3 = color
    label.Parent = bill

    espGenObjects[obj] = {
        highlight = h,
        billboard = bill,
        label = label
    }
end

local function getGeneratorProgress(gen)
    local progress = 0

    if gen:GetAttribute("Progress") then
        progress = gen:GetAttribute("Progress")
    elseif gen:GetAttribute("RepairProgress") then
        progress = gen:GetAttribute("RepairProgress")
    else
        for _, v in pairs(gen:GetDescendants()) do
            if v:IsA("NumberValue") or v:IsA("IntValue") then
                local name = v.Name:lower()
                if name:find("progress") or name:find("repair") or name:find("percent") then
                    progress = v.Value
                    break
                end
            end
        end
    end

    progress = (progress > 1) and progress / 100 or progress
    return math.clamp(progress, 0, 1)
end

local function getGenerators()
    local gens = {}
    local map = workspace:FindFirstChild("Map")
    if not map then return gens end

    for _, v in pairs(map:GetDescendants()) do
        if v.Name == "Generator" then
            table.insert(gens, v)
        end
    end

    return gens
end

local function applyESPToGenerators()
    if not (_G.FeatureState and _G.FeatureState.espGenerator) then return end

    for _, gen in pairs(getGenerators()) do
        local progress = getGeneratorProgress(gen)
        local percent = math.floor(progress * 100)
        local color = Color3.fromRGB(255,255,255):Lerp(Color3.fromRGB(0,255,0), progress)

        createGenESP(gen, color, percent)
    end
end

local function removeESPFromGenerators()
    for obj,_ in pairs(espGenObjects) do
        removeGenESP(obj)
    end
end

local function startESPGenerator()
    if not _G.FeatureState then
        _G.FeatureState = {}
    end
    if _G.FeatureState.espGenerator then
        return
    end

    _G.FeatureState.espGenerator = true
    applyESPToGenerators()
    print("[FEATURED]: ESP Generator -> ON")
end

local function stopESPGenerator()
    if not _G.FeatureState then
        _G.FeatureState = {}
    end
    if not _G.FeatureState.espGenerator then
        return
    end

    _G.FeatureState.espGenerator = false
    removeESPFromGenerators()
    print("[FEATURED]: ESP Generator -> OFF")
end

local function startProgressFeature()
    if not _G.FeatureState then
        _G.FeatureState = {}
    end
    if _G.FeatureState.generatorProgress then
        return
    end

    _G.FeatureState.generatorProgress = true
    progressEnabled = true

    -- Update existing ESP to show progress
    for _, gen in pairs(getGenerators()) do
        if espGenObjects[gen] then
            local data = espGenObjects[gen]
            local progress = getGeneratorProgress(gen)
            local percent = math.floor(progress * 100)
            data.label.Text = percent .. "%"
        end
    end

    print("[FEATURED]: Generator Progress -> ON")
end

local function stopProgressFeature()
    if not _G.FeatureState then
        _G.FeatureState = {}
    end
    if not _G.FeatureState.generatorProgress then
        return
    end

    _G.FeatureState.generatorProgress = false
    progressEnabled = false

    -- Update existing ESP to hide progress
    for _, gen in pairs(getGenerators()) do
        if espGenObjects[gen] then
            espGenObjects[gen].label.Text = ""
        end
    end

    print("[FEATURED]: Generator Progress -> OFF")
end

-- ==============================================
-- INIT AFTER LOAD
-- ==============================================
task.spawn(function()
    task.wait(1) -- Wait for environment to be ready
    
    RunService.RenderStepped:Connect(function()
        local espEnabled = _G.FeatureState and _G.FeatureState.espGenerator
        local progressEnabledCheck = _G.FeatureState and _G.FeatureState.generatorProgress

        if espEnabled and not wasEnabled then
            wasEnabled = true
            applyESPToGenerators()
        elseif not espEnabled and wasEnabled then
            wasEnabled = false
            removeESPFromGenerators()
        end

        if not espEnabled then
            return
        end

        for _, gen in pairs(getGenerators()) do
            local progress = getGeneratorProgress(gen)
            local percent = math.floor(progress * 100)
            local color = Color3.fromRGB(255,255,255):Lerp(Color3.fromRGB(0,255,0), progress)

            createGenESP(gen, color, percent)

            -- Update progress text if enabled
            if progressEnabledCheck and espGenObjects[gen] then
                espGenObjects[gen].label.Text = percent .. "%"
                espGenObjects[gen].label.TextColor3 = color
            end
        end
    end)
end)

-- ==============================================
-- GLOBAL CONTROL
-- ==============================================
_G.espGenerator = {}
_G.espGenerator.Start = startESPGenerator
_G.espGenerator.Stop = stopESPGenerator

_G.generatorProgress = {}
_G.generatorProgress.Start = startProgressFeature
_G.generatorProgress.Stop = stopProgressFeature

return _G.espGenerator