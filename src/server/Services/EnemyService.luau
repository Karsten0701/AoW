--[[
	EnemyService: beheert het spawnen, bewegen, vechten en sterven van enemy units.
	Units lopen van hun spawn-punt naar de vijandelijke base.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Knit = require(ReplicatedStorage.Packages.knit)
local Janitor = require(ReplicatedStorage.Packages.janitor)
local EnemyData = require(ReplicatedStorage.Shared.Config.EnemyData)
local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local EnemyService = Knit.CreateService({
	Name = "EnemyService",
	Client = {
		EnemySpawned = Knit.CreateSignal(),
		EnemyDied = Knit.CreateSignal(),
		EnemyDamaged = Knit.CreateSignal(),
	},
})

export type ActiveEnemy = {
	Model: Model,
	Owner: Player,
	EnemyName: string,
	Health: number,
	MaxHealth: number,
	Damage: number,
	AttackSpeed: number,
	WalkSpeed: number,
	KillReward: number,
	XpReward: number,
	LastAttackTime: number,
	Target: ActiveEnemy?,
	Janitor: any,
}

local activeEnemies: { ActiveEnemy } = {}
local enemyModelsFolder: Folder = nil

function EnemyService:KnitInit()
	local assets = ReplicatedStorage:WaitForChild("Assets")
	enemyModelsFolder = assets:WaitForChild("Enemies")
end

function EnemyService:KnitStart()
	RunService.Heartbeat:Connect(function(dt)
		self:_updateEnemies(dt)
	end)
end

function EnemyService:GetEnemyModelFolder(ageName: string): Folder?
	return enemyModelsFolder:FindFirstChild(ageName)
end

function EnemyService:SpawnEnemy(player: Player, enemyName: string, spawnPosition: Vector3, direction: number): ActiveEnemy?
	local data = EnemyData[enemyName]
	if not data then
		warn(`[EnemyService] Onbekende enemy: {enemyName}`)
		return nil
	end

	local ageFolder = enemyModelsFolder:FindFirstChild(data.Age)
	if not ageFolder then
		warn(`[EnemyService] Age folder niet gevonden: {data.Age}`)
		return nil
	end

	local template = ageFolder:FindFirstChild(enemyName)
	if not template then
		warn(`[EnemyService] Enemy model niet gevonden: {data.Age}/{enemyName}`)
		return nil
	end

	local model = template:Clone()
	model.Name = `{player.Name}_{enemyName}_{tick()}`

	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		humanoid = Instance.new("Humanoid")
		humanoid.Parent = model
	end

	humanoid.MaxHealth = data.Health
	humanoid.Health = data.Health
	humanoid.WalkSpeed = data.WalkSpeed

	local rootPart = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
	if rootPart then
		rootPart.CFrame = CFrame.new(spawnPosition) * CFrame.Angles(0, direction > 0 and 0 or math.pi, 0)
	end

	model:SetAttribute("Owner", player.UserId)
	model:SetAttribute("Direction", direction)
	model:SetAttribute("EnemyName", enemyName)

	local enemiesFolder = workspace:FindFirstChild("Enemies")
	if not enemiesFolder then
		enemiesFolder = Instance.new("Folder")
		enemiesFolder.Name = "Enemies"
		enemiesFolder.Parent = workspace
	end
	model.Parent = enemiesFolder

	local janitor = Janitor.new()

	local enemy: ActiveEnemy = {
		Model = model,
		Owner = player,
		EnemyName = enemyName,
		Health = data.Health,
		MaxHealth = data.Health,
		Damage = data.Damage,
		AttackSpeed = data.AttackSpeed,
		WalkSpeed = data.WalkSpeed,
		KillReward = data.KillReward,
		XpReward = data.XpReward,
		LastAttackTime = 0,
		Target = nil,
		Janitor = janitor,
	}

	janitor:Add(model)

	table.insert(activeEnemies, enemy)

	self.Client.EnemySpawned:FireAll(player, enemyName, model)

	if humanoid then
		self:_moveEnemy(enemy, direction)
	end

	return enemy
end

function EnemyService:_moveEnemy(enemy: ActiveEnemy, direction: number)
	local humanoid = enemy.Model:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	local rootPart = enemy.Model:FindFirstChild("HumanoidRootPart") or enemy.Model.PrimaryPart
	if not rootPart then
		return
	end

	-- Loop continu in de gegeven richting
	local moveVector = Vector3.new(direction, 0, 0)
	task.spawn(function()
		while enemy.Health > 0 and enemy.Model.Parent do
			local targetPos = rootPart.Position + moveVector * 100
			humanoid:MoveTo(targetPos)
			humanoid.MoveToFinished:Wait()
		end
	end)
end

function EnemyService:_updateEnemies(dt: number)
	local now = tick()
	local toRemove = {}

	for i, enemy in activeEnemies do
		if not enemy.Model.Parent or enemy.Health <= 0 then
			table.insert(toRemove, i)
			continue
		end

		-- Zoek naar vijanden (units van andere spelers) in de buurt
		local rootPart = enemy.Model:FindFirstChild("HumanoidRootPart") or enemy.Model.PrimaryPart
		if not rootPart then
			continue
		end

		local closestDist = math.huge
		local closestEnemy: ActiveEnemy? = nil

		for _, other in activeEnemies do
			if other == enemy then
				continue
			end
			if other.Owner == enemy.Owner then
				continue
			end
			if other.Health <= 0 or not other.Model.Parent then
				continue
			end

			local otherRoot = other.Model:FindFirstChild("HumanoidRootPart") or other.Model.PrimaryPart
			if not otherRoot then
				continue
			end

			local dist = (rootPart.Position - otherRoot.Position).Magnitude
			if dist < closestDist then
				closestDist = dist
				closestEnemy = other
			end
		end

		-- Als een vijand dichtbij genoeg is, val aan
		if closestEnemy and closestDist <= GameConfig.BaseAttackRange then
			if now - enemy.LastAttackTime >= enemy.AttackSpeed then
				enemy.LastAttackTime = now
				self:DamageEnemy(closestEnemy, enemy.Damage, enemy.Owner)

				-- Stop met lopen tijdens gevecht
				local humanoid = enemy.Model:FindFirstChildOfClass("Humanoid")
				if humanoid then
					humanoid:MoveTo(rootPart.Position)
				end
			end
		end
	end

	-- Verwijder dode enemies (van achter naar voren om index-problemen te voorkomen)
	for i = #toRemove, 1, -1 do
		local idx = toRemove[i]
		local enemy = activeEnemies[idx]
		enemy.Janitor:Destroy()
		table.remove(activeEnemies, idx)
	end
end

function EnemyService:DamageEnemy(enemy: ActiveEnemy, damage: number, attacker: Player)
	enemy.Health = math.max(0, enemy.Health - damage)

	local humanoid = enemy.Model:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.Health = enemy.Health
	end

	self.Client.EnemyDamaged:FireAll(enemy.Model, enemy.Health, enemy.MaxHealth)

	if enemy.Health <= 0 then
		self:_onEnemyDied(enemy, attacker)
	end
end

function EnemyService:_onEnemyDied(enemy: ActiveEnemy, killer: Player)
	self.Client.EnemyDied:FireAll(enemy.Model, killer)

	-- Geef de killer goud en XP via GameService
	local GameService = Knit.GetService("GameService")
	GameService:RewardKill(killer, enemy.KillReward, enemy.XpReward)
end

function EnemyService:GetActiveEnemies(): { ActiveEnemy }
	return activeEnemies
end

function EnemyService:GetActiveEnemyCount(player: Player): number
	local count = 0
	for _, enemy in activeEnemies do
		if enemy.Owner == player and enemy.Health > 0 then
			count += 1
		end
	end
	return count
end

return EnemyService
