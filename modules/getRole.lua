-- getRole.lua

if _G.RoleData then return end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

_G.RoleData = {
    TeamName = "",
    IsLobby = false
}

local UpdateEvent = Instance.new("BindableEvent")
_G.RoleUpdate = UpdateEvent.Event

local function getTeamName(plr)
    if plr.Team then
        return plr.Team.Name:lower()
    end
    return ""
end

-- BUAT DUA VARIABEL PENYIMPAN
local lastStatus = nil
local lastTeam = nil

RunService.Heartbeat:Connect(function()
    local team = getTeamName(player)
    local lobby = (team == "spectator")

    _G.RoleData.TeamName = team
    _G.RoleData.IsLobby = lobby

    -- 👇 KUNCINYA DISINI
    -- Hanya jalan kalau STATUS ATAU TEAM BENAR-BENAR BERUBAH
    if lastStatus ~= lobby or lastTeam ~= team then
        lastStatus = lobby
        lastTeam = team
        
        UpdateEvent:Fire()
    end
end)