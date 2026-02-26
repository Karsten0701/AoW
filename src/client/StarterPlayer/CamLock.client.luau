--[[
	Locks de camera op de positie en view van de Cam part in Workspace.Map
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- Wacht tot de Cam part bestaat
local camPart = workspace:WaitForChild("Map"):WaitForChild("Cam")

-- Neem volledige controle over de camera
camera.CameraType = Enum.CameraType.Scriptable

-- Update camera elke frame met de positie en oriëntatie van de Cam part
RunService.RenderStepped:Connect(function()
	camera.CFrame = camPart.CFrame
end)
