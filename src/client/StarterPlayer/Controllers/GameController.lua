local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.knit)
local Promise = require(ReplicatedStorage.Packages.promise)

local Templates = require(ReplicatedStorage.Shared.Data.PlayerTemplate)
local UnitData = require(ReplicatedStorage.Shared.Data.UnitData)

local GameController = Knit.CreateController({ Name = "GameController" })

local state = nil
local productionQueue = {}

local function findUnitData(unitName)
	for _, data in UnitData.Units do
		if data.Name == unitName then
			return data
		end
	end
	return nil
end

function GameController:GetGold()
	return state.Gold
end

function GameController:GetGems()
	return state.Gems
end

function GameController:GetTotalUnits()
	local UnitController = Knit.GetController("UnitController")
	return #UnitController:GetActiveUnits()
end

function GameController:AddGold(amount)
	state.Gold = math.floor(state.Gold + amount)
end

function GameController:AddGems(amount)
	state.Gems = math.floor(state.Gems + amount)
end

function GameController:CanAfford(gold, gems)
	return state.Gold >= gold and state.Gems >= gems
end

function GameController:GetActiveState()
	for s, active in state.States do
		if active then
			return s
		end
	end
	return "Defending"
end

function GameController:SetState(stateName)
	for s in state.States do
		state.States[s] = false
	end
	state.States[stateName] = true
end

function GameController:GetProductionTimeLeft(unitName)
	local closest = math.huge
	local found = false

	for _, item in productionQueue do
		if item.UnitName == unitName then
			local remaining = item.Duration - (os.clock() - item.StartTime)
			if remaining > 0 and remaining < closest then
				closest = remaining
				found = true
			end
		end
	end

	return found, found and closest or 0
end

function GameController:GetProductionQueueInfo(unitName)
	local count = 0
	local maxDuration = 0
	local latestEnd = 0

	for _, item in productionQueue do
		if item.UnitName == unitName then
			count += 1
			if item.Duration > maxDuration then
				maxDuration = item.Duration
			end
			local finishTime = item.StartTime + item.Duration
			if finishTime > latestEnd then
				latestEnd = finishTime
			end
		end
	end

	if count == 0 then
		return 0, 0
	end

	local remaining = latestEnd - os.clock()
	if remaining < 0 then
		remaining = 0
	end

	return count, remaining / maxDuration
end

function GameController:QueueUnit(unitName)
	local data = findUnitData(unitName)
	if not data then
		warn("[AoW] QueueUnit: unknown unit", unitName)
		return false
	end

	if not self:CanAfford(data.Cost.Gold, data.Cost.Gems) then
		print("[AoW] QueueUnit: cannot afford", unitName, "need", data.Cost.Gold, "gold,", data.Cost.Gems, "gems")
		return false
	end

	state.Gold -= data.Cost.Gold
	state.Gems -= data.Cost.Gems

	local entry = {
		UnitName = unitName,
		StartTime = os.clock(),
		Duration = data.Production.Time,
	}
	table.insert(productionQueue, entry)

	Promise.delay(data.Production.Time):andThen(function()
		local idx = table.find(productionQueue, entry)
		if idx then
			table.remove(productionQueue, idx)
		end

		local UnitController = Knit.GetController("UnitController")
		UnitController:SpawnUnit(unitName)
		print("[AoW] Production complete, spawned:", unitName)
	end)

	print("[AoW] Queued unit:", unitName, "time:", data.Production.Time, "s")
	return true
end

function GameController:KnitInit()
	print("[AoW] GameController KnitInit")
	local gt = Templates.GameTemplate

	state = {
		Gold = gt.Gold,
		Gems = gt.Gems,
		States = {},
	}

	for s, active in gt.States do
		state.States[s] = active
	end
	print("[AoW] Game state – Gold:", state.Gold, "Gems:", state.Gems)
end

function GameController:KnitStart()
	print("[AoW] GameController KnitStart")
	local UnitController = Knit.GetController("UnitController")

	for unitName, count in Templates.GameTemplate.Units do
		for _ = 1, count do
			UnitController:SpawnUnit(unitName)
			print("[AoW] Spawned initial unit:", unitName)
		end
	end

	task.spawn(function()
		while true do
			task.wait(Templates.GameTemplate.PassiveGoldInterval)
			self:AddGold(Templates.GameTemplate.PassiveGoldAmount)
		end
	end)
end

return GameController
