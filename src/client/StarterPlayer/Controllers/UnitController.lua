local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Knit = require(ReplicatedStorage.Packages.knit)
local Janitor = require(ReplicatedStorage.Packages.janitor)

local UnitData = require(ReplicatedStorage.Shared.Data.UnitData)
local OreSetup = require(ReplicatedStorage.Shared.Modules.OreSetup)
local Formation = require(ReplicatedStorage.Shared.Modules.Formation)

local UnitController = Knit.CreateController({ Name = "UnitController" })

local MINER_SPEED = 16
local MOVE_THRESHOLD = 1
local DEPOSIT_RANGE = 10

local STATE = {
	IDLE = "idle",
	FINDING_ORE = "finding_ore",
	WALKING_TO_ORE = "walking_to_ore",
	MINING = "mining",
	WALKING_TO_BASE = "walking_to_base",
	MOVING_TO_POS = "moving_to_pos",
	IN_FORMATION = "in_formation",
}

local activeUnits = {}
local formationTargets = {}
local formationDirty = true
local lastState = nil

local unitFolder, mapRef, oreHitboxes
local _janitor = Janitor.new()

-- ─── Helpers ─────────────────────────────────────────────────────

local function findUnitData(name)
	for _, d in UnitData.Units do
		if d.Name == name then
			return d
		end
	end
	return nil
end

local function getPos(inst)
	if inst:IsA("Model") then
		return inst:GetPivot().Position
	end
	return inst.Position
end

local function moveToward(model, target, speed, dt)
	local cur = model:GetPivot().Position
	local flat = Vector3.new(target.X - cur.X, 0, target.Z - cur.Z)
	local dist = flat.Magnitude

	if dist < MOVE_THRESHOLD then
		return true
	end

	local step = math.min(speed * dt, dist)
	local dir = flat.Unit
	local newPos = cur + dir * step

	model:PivotTo(CFrame.new(newPos, newPos + dir))
	return false
end

local function findNearestOre(pos)
	if not oreHitboxes or #oreHitboxes == 0 then
		return nil
	end
	local best, bestDist = nil, math.huge

	for _, ore in oreHitboxes do
		if ore.BeingMined then
			continue
		end

		local d = (ore.Position - pos).Magnitude
		if d < bestDist then
			best, bestDist = ore, d
		end
	end

	return best
end

-- ─── Miner AI ────────────────────────────────────────────────────

local function updateMiner(unit, dt)
	local speed = MINER_SPEED

	if unit.State == STATE.FINDING_ORE then
		local ore = findNearestOre(unit.Model:GetPivot().Position)
		if ore then
			ore.BeingMined = true
			unit.CurrentOre = ore
			unit.TargetPos = ore.Position
			unit.State = STATE.WALKING_TO_ORE
		end
	elseif unit.State == STATE.WALKING_TO_ORE then
		if moveToward(unit.Model, unit.TargetPos, speed, dt) then
			local isGold = unit.CurrentOre.OreType == "Gold"
			unit.Timer = isGold and unit.Data.Stats.GoldSpeed or unit.Data.Stats.GemSpeed
			unit.State = STATE.MINING
		end
	elseif unit.State == STATE.MINING then
		unit.Timer -= dt
		if unit.Timer <= 0 then
			unit.TargetPos = getPos(mapRef.Player.Spawn)
			unit.State = STATE.WALKING_TO_BASE
		end
	elseif unit.State == STATE.WALKING_TO_BASE then
		local spawnPos = getPos(mapRef.Player.Spawn)
		local dist = (unit.Model:GetPivot().Position - spawnPos).Magnitude

		if dist <= DEPOSIT_RANGE then
			local gc = Knit.GetController("GameController")

			if unit.CurrentOre then
				if unit.CurrentOre.OreType == "Gold" then
					gc:AddGold(unit.Data.Stats.GoldAmount)
				else
					gc:AddGems(unit.Data.Stats.GemAmount)
				end
				unit.CurrentOre.BeingMined = false
				unit.CurrentOre = nil
			end

			unit.State = STATE.FINDING_ORE
		else
			moveToward(unit.Model, spawnPos, speed, dt)
		end
	end
end

-- ─── Combat AI ───────────────────────────────────────────────────

local function updateCombatUnit(unit, dt)
	if unit.State ~= STATE.MOVING_TO_POS then
		return
	end

	local target = formationTargets[unit]
	if not target then
		return
	end

	if moveToward(unit.Model, target, unit.Data.Stats.Speed, dt) then
		unit.State = STATE.IN_FORMATION
	end
end

local function recalculateFormation()
	formationDirty = false

	local gc = Knit.GetController("GameController")
	local activeState = gc:GetActiveState()

	local combatUnits = {}
	for _, u in activeUnits do
		if u.Data.Class ~= "Worker" then
			table.insert(combatUnits, u)
		end
	end

	if #combatUnits == 0 then
		return
	end

	if activeState == "Defending" then
		local defendModel = mapRef.Player:FindFirstChild("Defend")
		if not defendModel then
			return
		end

		-- Defend kan een Model zijn; gebruik GetPivot voor positie en richting
		local defendCFrame = defendModel:GetPivot()
		local positions = Formation.Calculate(combatUnits, defendCFrame.Position, defendCFrame.LookVector)

		for i, u in ipairs(combatUnits) do
			formationTargets[u] = positions[i]
			u.State = STATE.MOVING_TO_POS
		end
	elseif activeState == "Retreating" then
		local retreat = mapRef.Player.Spawn:FindFirstChild("Retreat")
		local pos = retreat and getPos(retreat) or getPos(mapRef.Player.Spawn)

		for _, u in ipairs(combatUnits) do
			formationTargets[u] = pos
			u.State = STATE.MOVING_TO_POS
		end
	elseif activeState == "Attacking" then
		local enemyBase = mapRef.Enemy:FindFirstChild("EnemyBase")
		local pos = enemyBase and getPos(enemyBase) or getPos(mapRef.Enemy.Spawn)

		for _, u in ipairs(combatUnits) do
			formationTargets[u] = pos
			u.State = STATE.MOVING_TO_POS
		end
	end
end

-- ─── Public ──────────────────────────────────────────────────────

function UnitController:SpawnUnit(unitName)
	local data = findUnitData(unitName)
	if not data then
		warn("[AoW] SpawnUnit: no data for", unitName)
		return
	end

	local assets = ReplicatedStorage:FindFirstChild("Assets")
	if not assets then
		warn("[AoW] SpawnUnit: ReplicatedStorage.Assets not found")
		return
	end
	local unitsFolder = assets:FindFirstChild("Units")
	if not unitsFolder then
		warn("[AoW] SpawnUnit: ReplicatedStorage.Assets.Units not found")
		return
	end
	local template = unitsFolder:FindFirstChild(unitName)
	if not template then
		warn(
			"[AoW] SpawnUnit: no model for",
			unitName,
			"in Units. Available:",
			table.concat(
				(function()
					local t = {}
					for _, c in unitsFolder:GetChildren() do
						table.insert(t, c.Name)
					end
					return t
				end)(),
				", "
			)
		)
		return
	end

	if not unitFolder or not unitFolder.Parent then
		warn("[AoW] SpawnUnit: LocalUnits folder missing")
		return
	end

	local spawnPart = mapRef and mapRef.Player and mapRef.Player:FindFirstChild("Spawn")
	if not spawnPart then
		warn("[AoW] SpawnUnit: Map.Player.Spawn not found")
		return
	end

	local model = template:Clone()
	model.Parent = unitFolder

	local spawnPos = getPos(spawnPart)
	model:PivotTo(CFrame.new(spawnPos))

	local unit = {
		Model = model,
		Data = data,
		State = data.Class == "Worker" and STATE.FINDING_ORE or STATE.MOVING_TO_POS,
		TargetPos = nil,
		Timer = 0,
		CurrentOre = nil,
		Janitor = Janitor.new(),
	}

	unit.Janitor:Add(model)
	table.insert(activeUnits, unit)

	formationDirty = true
	print("[AoW] Spawned unit:", unitName, "at", spawnPos)
end

function UnitController:GetActiveUnits()
	return activeUnits
end

-- ─── Lifecycle ───────────────────────────────────────────────────

function UnitController:KnitInit()
	print("[AoW] UnitController KnitInit")
	mapRef = workspace:WaitForChild("Map")
	print("[AoW] Map ref:", mapRef:GetFullName())

	unitFolder = Instance.new("Folder")
	unitFolder.Name = "LocalUnits"
	unitFolder.Parent = workspace
	_janitor:Add(unitFolder)
	print("[AoW] LocalUnits folder created in workspace")

	local playerFolder = mapRef:FindFirstChild("Player")
	if not playerFolder then
		warn(
			"[AoW] Map.Player not found. Map children:",
			table.concat(
				(function()
					local t = {}
					for _, c in mapRef:GetChildren() do
						table.insert(t, c.Name)
					end
					return t
				end)(),
				", "
			)
		)
		oreHitboxes = {}
		return
	end

	local oresFolder = playerFolder:FindFirstChild("Ores")
	if not oresFolder then
		warn(
			"[AoW] Map.Player.Ores not found. Player children:",
			table.concat(
				(function()
					local t = {}
					for _, c in playerFolder:GetChildren() do
						table.insert(t, c.Name)
					end
					return t
				end)(),
				", "
			)
		)
		oreHitboxes = {}
		return
	end

	oreHitboxes = OreSetup.Initialize(oresFolder)
	print("[AoW] Ores initialized, hitboxes:", #oreHitboxes)
end

function UnitController:KnitStart()
	print("[AoW] UnitController KnitStart")
	_janitor:Add(RunService.Heartbeat:Connect(function(dt)
		local gc = Knit.GetController("GameController")
		local currentState = gc:GetActiveState()

		if currentState ~= lastState then
			lastState = currentState
			formationDirty = true
		end

		if formationDirty then
			recalculateFormation()
		end

		for i = #activeUnits, 1, -1 do
			local unit = activeUnits[i]

			if not unit.Model or not unit.Model.Parent then
				if unit.CurrentOre then
					unit.CurrentOre.BeingMined = false
				end
				formationTargets[unit] = nil
				unit.Janitor:Destroy()
				table.remove(activeUnits, i)
				formationDirty = true
				continue
			end

			if unit.Data.Class == "Worker" then
				updateMiner(unit, dt)
			else
				updateCombatUnit(unit, dt)
			end
		end
	end))
end

return UnitController
