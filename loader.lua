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
    "modules/autoGene.lua",
    "modules/ai.lua",
    "modules/autoHeal.lua",
    "modules/aimBot.lua",
    -- "modules/autofarm.lua",
    -- tambahkan fitur lain di sini
}

local function formatModuleName(path)
    local name = path:match("([^/]+)%.lua$") or path
    name = name:gsub("(%l)(%u)", "%1 %2")
    return name:gsub("^%l", string.upper)
end

-- Load semua modules terlebih dahulu
for _, path in ipairs(modulesToLoad) do
    local success, err = pcall(function()
        loadstring(game:HttpGet(baseUrl .. path))()
    end)
    
    if success then
        print("📦 " .. formatModuleName(path))
    else
        warn("❌ Loaded: " .. formatModuleName(path) .. " | Error: " .. tostring(err))
    end
    task.wait(0.4)  -- jeda agar stabil
end

local mainSuccess, mainErr = pcall(function()
    loadstring(game:HttpGet(baseUrl .. "main.lua"))()
end)

if not mainSuccess then
    warn("❌ Gagal memuat main.lua: " .. tostring(mainErr))
end