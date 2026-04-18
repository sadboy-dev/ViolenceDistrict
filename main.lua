-- main.lua
if not _G.RoleData or not _G.RoleUpdate then
    error("❌ getRole.lua belum terdeteksi! Pastikan loader berjalan benar.")
end

-- Tabel global untuk menyimpan status ON/OFF semua fitur
_G.FeatureState = _G.FeatureState or {
    ipadView = false,
    espPlayer = false,
    espGenerator = false,
    generatorProgress = false,
    autoGene = false,
    autoHeal = false,
    ai = false,
    aimBot = false,
    -- Tambahkan fitur baru di sini
}

local function formatFeatureName(name)
    return name:gsub("(%l)(%u)", "%1 %2"):gsub("^%l", string.upper)
end

-- Simpan role sebelumnya
local roleOld = _G.RoleData.IsLobby and "SPECTATOR" or string.upper(_G.RoleData.TeamName or "")

-- =============================================
-- FUNCTION KHUSUS
-- =============================================

-- Reset / matikan SEMUA fitur sekaligus
function _G.ResetAllFeatures()
    for featureName, _ in pairs(_G.FeatureState) do
        _G.FeatureState[featureName] = false
    end
end

-- Fungsi utama untuk sortir fitur berdasarkan role
function _G.SortFeaturesByRole()
    local currentRole = _G.RoleData.IsLobby and "SPECTATOR" or string.upper(_G.RoleData.TeamName or "")
    print("👥 Role: " .. currentRole)
    _G.ResetAllFeatures()  -- Matikan semua fitur dulu setiap role berubah

    if currentRole == "SURVIVORS" then
        _G.Toggle("ipadView", true)
        _G.Toggle("espPlayer", true)
        _G.Toggle("espGenerator", true)
        _G.Toggle("generatorProgress", true)
        _G.Toggle("autoGene", true)
        _G.Toggle("autoHeal", true)
        _G.Toggle("ai", true)
        _G.Toggle("aimBot", true)

    elseif currentRole == "KILLER" then
        _G.Toggle("espPlayer", true)
        _G.Toggle("generatorProgress", true)
        _G.Toggle("ai", true)

    elseif currentRole == "SPECTATOR" then
        _G.Toggle("ipadView", true)
        _G.Toggle("espPlayer", true)
        _G.Toggle("espGenerator", true)
        _G.Toggle("generatorProgress", true)
        _G.Toggle("ai", true)
    else
        print("⚠️ Unknown role: " .. currentRole)
    end
end

-- Fungsi global untuk toggle fitur (bisa dipanggil dari script lain)
function _G.Toggle(featureName, enabled)
    if _G.FeatureState[featureName] ~= nil then
        _G.FeatureState[featureName] = enabled
        print("✨ " .. formatFeatureName(featureName) .. ": " .. (enabled and "ON" or "OFF"))
    else
        warn("❌ Fitur tidak ditemukan: " .. featureName)
    end
end

-- =============================================
-- LISTENER ROLE CHANGE
-- =============================================

_G.RoleUpdate:Connect(function()
    local newRole = _G.RoleData.IsLobby and "SPECTATOR" or string.upper(_G.RoleData.TeamName or "")

    -- Hanya proses jika role benar-benar berubah
    if newRole ~= roleOld then
        roleOld = newRole   -- Update role lama
        _G.SortFeaturesByRole()
    end
end)

-- Jalankan sorting pertama kali saat main.lua di-load
_G.SortFeaturesByRole()