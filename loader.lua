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

local function safeLoadModule(path)
    -- SIMPEL: Local ONLY (fastest, no error)
    pcall(function()
        local content = readfile(path)
        loadstring(content)()
        print("✅ Loaded local: " .. formatModuleName(path))
    end)
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
