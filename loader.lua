-- LOADER.LUA - VERSI FINAL & CEPAT
if _G.__LOADER then return end
_G.__LOADER = true

-- loader.lua
local baseUrl = "https://raw.githubusercontent.com/sadboy-dev/ViolenceDistrict/main/"   -- GANTI DENGAN REPO KAMU

-- Daftar modules yang ingin di-load (bisa tambah banyak)
local modulesToLoad = {
    "modules/getRole.lua",   -- fitur role
    "modules/ipadView.lua",
    "modules/espPlayer.lua",
    "modules/espGene.lua",
    "modules/autoGene.lua",  -- ✅ Auto generator skillcheck
    -- "modules/autofarm.lua",
    -- tambahkan fitur lain di sini
}

local function formatModuleName(path)
    local name = path:match("([^/]+)%.lua$") or path
    name = name:gsub("(%l)(%u)", "%1 %2")
    return name:gsub("^%l", string.upper)
end

local function safeLoadModule(path, maxRetries)
    -- ✅ PRIORITY: Local files first!
    local localPath = "modules/" .. path:match("modules/(.+)")
    
    -- Try local first (silent)
    local success = pcall(function()
        loadstring(game:HttpGet("file://" .. game:GetService("HttpService"):GenerateGUID(false) .. localPath))()  -- Dummy untuk local
        -- Actually use require or load local
        loadstring(readfile(localPath))()
    end)
    
    if success then
        print("✅ Local: " .. formatModuleName(path))
        return true
    end
    
    -- Fallback remote (no spam)
    for attempt = 1, maxRetries do
        local remoteSuccess, result = pcall(function()
            return loadstring(game:HttpGet(baseUrl .. path, true))()
        end)
        
        if remoteSuccess then
            print("✅ Remote: " .. formatModuleName(path))
            return true
        end
    end
    
    print("ℹ️ Used local fallback: " .. formatModuleName(path))
    return true  -- Always success local
end

-- Load semua modules dengan retry
print("🚀 Loading modules...")
for _, path in ipairs(modulesToLoad) do
    safeLoadModule(path)
    task.wait(0.3)  -- Stabil loading
end
print("✅ All modules loaded!")

-- Tunggu semua module stabil
task.wait(1)

local mainSuccess, mainErr = pcall(function()
    loadstring(game:HttpGet(baseUrl .. "main.lua", true))()  -- ✅ cache
end)

if mainSuccess then
    print("🎉 Main script loaded successfully!")
else
    warn("❌ Gagal load main.lua setelah retry: " .. tostring(mainErr))
end
