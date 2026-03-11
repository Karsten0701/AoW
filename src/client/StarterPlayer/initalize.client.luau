-- Client scripts run in StarterPlayerScripts (LocalScripts)
print("[AoW] Client Init script running (StarterPlayerScripts)")

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ok, Knit = pcall(function()
	return require(ReplicatedStorage.Packages.knit)
end)
if not ok then
	warn("[AoW] Failed to require Knit:", Knit)
	return
end

local controllers = script.Parent:WaitForChild("Controllers")
if not controllers then
	warn("[AoW] No Controllers folder found under StarterPlayerScripts")
	return
end

local count = 0
for _ in controllers:GetChildren() do
	count += 1
end
print("[AoW] Loading", count, "controllers from", controllers:GetFullName())

Knit.AddControllers(controllers)

Knit.Start()
	:andThen(function()
		print("[AoW] Client started – Knit ready")
	end)
	:catch(function(err)
		warn("[AoW] Knit.Start failed:", err)
	end)
