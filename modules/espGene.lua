local RunService = game:GetService("RunService")
local espGenObjects = {}
local wasEnabled = false
-- local progressEnabled = false  -- DELETED: Use global instead

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

    -- ✅ ANTI-SPAM: Hanya buat jika belum ada
    if not data then
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
        label.Text = (_G.FeatureState and _G.FeatureState.generatorProgress) and (percent .. "%") or ""

        label.TextColor3 = color
        label.Parent = bill

        data = {
            highlight = h,
            billboard = bill,
            label = label
        }
        espGenObjects[obj] = data
    end

    -- Update color & text
    data.highlight.FillColor = color
    data.label.Text = (_G.FeatureState and _G.FeatureState.generatorProgress) and (percent .. "%") or ""
    data.label.TextColor3 = color
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

local generatorsCache = {}
local lastCacheUpdate = 0

local function getGenerators()
    local now = tick()
    -- ✅ CACHE 1 detik (tidak cari ulang terus)
    if now - lastCacheUpdate > 1 then
        generatorsCache = {}
        local map = workspace:FindFirstChild("Map")
        if map then
            for _, v in pairs(map:GetDescendants()) do
                if v.Name == "Generator" then
                    table.insert(generatorsCache, v)
                end
            end
        end
        lastCacheUpdate = now
    end
    return generatorsCache
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
    print("🔋 ESP Generator: ON")
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
    print("🔋 ESP Generator: OFF")
end

local function startProgressFeature()
    if not _G.FeatureState then
        _G.FeatureState = {}
    end
    _G.FeatureState.generatorProgress = true
    
    -- Force update all generators
    task.spawn(function()
        for _, gen in pairs(getGenerators()) do
            if espGenObjects[gen] then
                local data = espGenObjects[gen]
                local progress = getGeneratorProgress(gen)
                local percent = math.floor(progress * 100)
                data.label.Text = percent .. "%"
                data.label.TextColor3 = Color3.fromRGB(0,255,0)
            end
        end
    end)
    
    print("⚡ Generator Progress: ON")
end

local function stopProgressFeature()
    if not _G.FeatureState then
        _G.FeatureState = {}
    end
    _G.FeatureState.generatorProgress = false
    
    -- Force hide text
    task.spawn(function()
        for obj, data in pairs(espGenObjects) do
            if data.label then
                data.label.Text = ""
            end
        end
    end)
    
    print("⚡ Generator Progress: OFF")
end

-- ==============================================
-- INIT AFTER LOAD
-- ==============================================
task.spawn(function()
    task.wait(1) -- Wait for environment to be ready
    
RunService.Heartbeat:Connect(function()  -- ✅ THROTTLE: 30fps bukannya 60fps
        local espEnabled = _G.FeatureState and _G.FeatureState.espGenerator
        local progressEnabledCheck = _G.FeatureState and _G.FeatureState.generatorProgress

        if espEnabled ~= wasEnabled then
            wasEnabled = espEnabled
            if espEnabled then
                applyESPToGenerators()
            else
                removeESPFromGenerators()
            end
        end

        if not espEnabled then return end

        -- ✅ CACHE GENERATORS (tidak cari ulang setiap frame)
        local gens = getGenerators()
        for _, gen in pairs(gens) do
            if gen.Parent then  -- Masih exist
                local progress = getGeneratorProgress(gen)
                local percent = math.floor(progress * 100)
                local color = Color3.fromRGB(255,255,255):Lerp(Color3.fromRGB(0,255,0), progress)

                createGenESP(gen, color, percent)
            else
                removeGenESP(gen)  -- Cleanup hilang
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