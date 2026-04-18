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

local lastUpdateTime = 0
local UPDATE_DEBOUNCE = 0.1  -- 10x/detik max

RunService.Heartbeat:Connect(function()
    local now = tick()
    local team = getTeamName(player)
    local lobby = (team == "spectator")

    _G.RoleData.TeamName = team
    _G.RoleData.IsLobby = lobby

    -- ✅ DEBOUNCE: max 10x/detik
    if now - lastUpdateTime > UPDATE_DEBOUNCE and (lastStatus ~= lobby or lastTeam ~= team) then
        lastStatus = lobby
        lastTeam = team
        lastUpdateTime = now
        UpdateEvent:Fire()
    end
end)
