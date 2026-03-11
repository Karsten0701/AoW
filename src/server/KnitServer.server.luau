--[[
	Server bootstrap: laadt alle Knit services en start het framework.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Knit = require(ReplicatedStorage.Packages.knit)

-- Laad alle services
local servicesFolder = ServerScriptService.Server.Services
for _, module in servicesFolder:GetChildren() do
	if module:IsA("ModuleScript") then
		require(module)
	end
end

Knit.Start():andThen(function()
	print("[Server] Knit gestart!")
end):catch(function(err)
	warn(`[Server] Knit fout: {err}`)
end)
