--[[
	GameService: het hart van de game loop.
	Beheert economy, age progressie, unit aankoop en passief inkomen.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.knit)
local EnemyData = require(ReplicatedStorage.Shared.Config.EnemyData)
local AgeData = require(ReplicatedStorage.Shared.Config.AgeData)
local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local GameService = Knit.CreateService({
	Name = "GameService",
	Client = {
		GoldChanged = Knit.CreateSignal(),
		XpChanged = Knit.CreateSignal(),
		AgeChanged = Knit.CreateSignal(),
		SpawnResult = Knit.CreateSignal(),
	},
})

-- Bijhoudt of een spawn op cooldown staat per speler per enemy type
local spawnCooldowns: { [Player]: { [string]: number } } = {}

function GameService:KnitStart()
	-- Passief inkomen loop
	task.spawn(function()
		while true do
			task.wait(1)
			self:_tickPassiveIncome()
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		spawnCooldowns[player] = nil
	end)
end

function GameService:_tickPassiveIncome()
	local DataService = Knit.GetService("DataService")

	for _, player in Players:GetPlayers() do
		local data = DataService:GetData(player)
		if not data then
			continue
		end

		local currentAge = AgeData.Ages[data.CurrentAge]
		local multiplier = if currentAge then currentAge.PassiveIncomeMultiplier else 1
		local income = GameConfig.PassiveIncomePerSecond * multiplier

		DataService:IncrementData(player, "Gold", income)
		self.Client.GoldChanged:Fire(player, data.Gold)
	end
end

function GameService:RewardKill(player: Player, goldReward: number, xpReward: number)
	local DataService = Knit.GetService("DataService")
	local data = DataService:GetData(player)
	if not data then
		return
	end

	DataService:IncrementData(player, "Gold", goldReward)
	DataService:IncrementData(player, "TotalGoldEarned", goldReward)
	DataService:IncrementData(player, "TotalKills", 1)
	DataService:IncrementData(player, "Xp", xpReward)

	self.Client.GoldChanged:Fire(player, data.Gold)
	self.Client.XpChanged:Fire(player, data.Xp)

	self:_checkAgeUp(player)
end

function GameService:_checkAgeUp(player: Player)
	local DataService = Knit.GetService("DataService")
	local data = DataService:GetData(player)
	if not data then
		return
	end

	local currentAge = AgeData.Ages[data.CurrentAge]
	if not currentAge then
		return
	end

	local currentOrder = currentAge.Order
	local xpRequired = GameConfig.AgeUpXpRequired[currentOrder]
	if not xpRequired then
		return
	end

	if data.Xp >= xpRequired then
		local nextAge = nil
		for _, age in AgeData.AgeOrder do
			if age.Order == currentOrder + 1 then
				nextAge = age
				break
			end
		end

		if nextAge then
			DataService:UpdateData(player, "CurrentAge", nextAge.Name)
			DataService:IncrementData(player, "Xp", -xpRequired)

			-- Track hoogste age
			local highestAge = AgeData.Ages[data.HighestAge]
			if highestAge and nextAge.Order > highestAge.Order then
				DataService:UpdateData(player, "HighestAge", nextAge.Name)
			end

			self.Client.AgeChanged:Fire(player, nextAge.Name)
		end
	end
end

function GameService:_getSpawnPosition(player: Player): (Vector3, number)?
	-- Zoek de speler's base / spawn punt in de map
	local map = workspace:FindFirstChild("Map")
	if not map then
		return nil
	end

	local bases = map:FindFirstChild("Bases")
	if not bases then
		return nil
	end

	local base = bases:FindFirstChild(tostring(player.UserId)) or bases:FindFirstChild("Default")
	if not base then
		-- Gebruik het eerste beschikbare base
		for _, child in bases:GetChildren() do
			if child:IsA("BasePart") then
				base = child
				break
			end
		end
	end

	if not base then
		return nil
	end

	-- Direction: 1 = rechts (standaard), -1 = links
	local direction: number = base:GetAttribute("Direction") or 1

	local spawnPos = base.Position + Vector3.new(direction * GameConfig.SpawnOffsetFromBase, 0, 0)

	return spawnPos, direction
end

function GameService.Client:RequestSpawnEnemy(player: Player, enemyName: string)
	local DataService = Knit.GetService("DataService")
	local EnemyService = Knit.GetService("EnemyService")

	local data = DataService:GetData(player)
	if not data then
		GameService.Client.SpawnResult:Fire(player, false, "Data niet beschikbaar.")
		return
	end

	local enemyInfo = EnemyData[enemyName]
	if not enemyInfo then
		GameService.Client.SpawnResult:Fire(player, false, "Onbekende unit.")
		return
	end

	-- Check of de speler in de juiste age zit
	local playerAge = AgeData.Ages[data.CurrentAge]
	local enemyAge = AgeData.Ages[enemyInfo.Age]
	if not playerAge or not enemyAge then
		GameService.Client.SpawnResult:Fire(player, false, "Age data fout.")
		return
	end
	if enemyAge.Order > playerAge.Order then
		GameService.Client.SpawnResult:Fire(player, false, "Je hebt deze age nog niet ontgrendeld!")
		return
	end

	-- Check goud
	if data.Gold < enemyInfo.Cost then
		GameService.Client.SpawnResult:Fire(player, false, "Niet genoeg goud!")
		return
	end

	-- Check cooldown
	local now = tick()
	if not spawnCooldowns[player] then
		spawnCooldowns[player] = {}
	end
	local lastSpawn = spawnCooldowns[player][enemyName] or 0
	if now - lastSpawn < enemyInfo.SpawnCooldown then
		local remaining = math.ceil(enemyInfo.SpawnCooldown - (now - lastSpawn))
		GameService.Client.SpawnResult:Fire(player, false, `Cooldown: {remaining}s`)
		return
	end

	-- Check max enemies op veld
	local activeCount = EnemyService:GetActiveEnemyCount(player)
	if activeCount >= GameConfig.MaxEnemiesOnField then
		GameService.Client.SpawnResult:Fire(player, false, "Maximaal aantal units bereikt!")
		return
	end

	-- Zoek spawn positie
	local spawnPos, direction = GameService:_getSpawnPosition(player)
	if not spawnPos then
		GameService.Client.SpawnResult:Fire(player, false, "Geen spawn punt gevonden.")
		return
	end

	-- Trek goud af
	DataService:IncrementData(player, "Gold", -enemyInfo.Cost)
	GameService.Client.GoldChanged:Fire(player, data.Gold)

	-- Set cooldown
	spawnCooldowns[player][enemyName] = now

	-- Spawn de enemy
	EnemyService:SpawnEnemy(player, enemyName, spawnPos, direction)

	GameService.Client.SpawnResult:Fire(player, true, "Unit gespawned!")
end

function GameService.Client:GetAvailableEnemies(player: Player): { string }
	local DataService = Knit.GetService("DataService")
	local data = DataService:GetData(player)
	if not data then
		return {}
	end

	local playerAge = AgeData.Ages[data.CurrentAge]
	if not playerAge then
		return {}
	end

	local available = {}
	for _, age in AgeData.AgeOrder do
		if age.Order > playerAge.Order then
			break
		end
		for _, enemyName in age.UnlocksEnemies do
			table.insert(available, enemyName)
		end
	end

	return available
end

function GameService.Client:GetCurrentGold(player: Player): number
	local DataService = Knit.GetService("DataService")
	local data = DataService:GetData(player)
	return if data then data.Gold else 0
end

function GameService.Client:GetCurrentAge(player: Player): string
	local DataService = Knit.GetService("DataService")
	local data = DataService:GetData(player)
	return if data then data.CurrentAge else "Prehistoric"
end

function GameService.Client:GetCurrentXp(player: Player): number
	local DataService = Knit.GetService("DataService")
	local data = DataService:GetData(player)
	return if data then data.Xp else 0
end

return GameService
