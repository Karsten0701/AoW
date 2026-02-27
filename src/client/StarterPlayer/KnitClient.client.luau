--[[
	Client bootstrap: laadt alle Knit controllers en start het framework.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Knit = require(ReplicatedStorage.Packages.knit)

-- Laad alle controllers
local controllersFolder = Players.LocalPlayer
	:WaitForChild("PlayerScripts")
	:WaitForChild("Controllers")

for _, module in controllersFolder:GetChildren() do
	if module:IsA("ModuleScript") then
		require(module)
	end
end

Knit.Start():andThen(function()
	print("[Client] Knit gestart!")
end):catch(function(err)
	warn(`[Client] Knit fout: {err}`)
end)
