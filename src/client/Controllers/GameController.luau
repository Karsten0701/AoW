--[[
	GameController: client-side logica voor unit spawnen en game state bijhouden.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.knit)
local EnemyData = require(ReplicatedStorage.Shared.Config.EnemyData)
local AgeData = require(ReplicatedStorage.Shared.Config.AgeData)
local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local GameController = Knit.CreateController({
	Name = "GameController",
})

local gold = 0
local xp = 0
local currentAge = "Prehistoric"
local availableEnemies: { string } = {}

-- Callbacks die HudController kan instellen
GameController.OnGoldChanged = nil :: ((newGold: number) -> ())?
GameController.OnXpChanged = nil :: ((newXp: number) -> ())?
GameController.OnAgeChanged = nil :: ((newAge: string) -> ())?
GameController.OnSpawnResult = nil :: ((success: boolean, message: string) -> ())?
GameController.OnEnemiesUpdated = nil :: ((enemies: { string }) -> ())?

function GameController:KnitStart()
	local GameService = Knit.GetService("GameService")
	local DataService = Knit.GetService("DataService")

	-- Haal initiële data op
	local initialData = DataService:GetPlayerData()
	if initialData then
		gold = initialData.Gold
		xp = initialData.Xp
		currentAge = initialData.CurrentAge
	end

	-- Haal beschikbare enemies op
	availableEnemies = GameService:GetAvailableEnemies()

	if self.OnGoldChanged then
		self.OnGoldChanged(gold)
	end
	if self.OnXpChanged then
		self.OnXpChanged(xp)
	end
	if self.OnAgeChanged then
		self.OnAgeChanged(currentAge)
	end
	if self.OnEnemiesUpdated then
		self.OnEnemiesUpdated(availableEnemies)
	end

	-- Luister naar server signals
	GameService.GoldChanged:Connect(function(newGold)
		gold = newGold
		if self.OnGoldChanged then
			self.OnGoldChanged(newGold)
		end
	end)

	GameService.XpChanged:Connect(function(newXp)
		xp = newXp
		if self.OnXpChanged then
			self.OnXpChanged(newXp)
		end
	end)

	GameService.AgeChanged:Connect(function(newAge)
		currentAge = newAge
		if self.OnAgeChanged then
			self.OnAgeChanged(newAge)
		end

		-- Vernieuw beschikbare enemies bij age change
		availableEnemies = GameService:GetAvailableEnemies()
		if self.OnEnemiesUpdated then
			self.OnEnemiesUpdated(availableEnemies)
		end
	end)

	GameService.SpawnResult:Connect(function(success, message)
		if self.OnSpawnResult then
			self.OnSpawnResult(success, message)
		end
	end)
end

function GameController:RequestSpawn(enemyName: string)
	local GameService = Knit.GetService("GameService")
	GameService:RequestSpawnEnemy(enemyName)
end

function GameController:GetGold(): number
	return gold
end

function GameController:GetXp(): number
	return xp
end

function GameController:GetCurrentAge(): string
	return currentAge
end

function GameController:GetAvailableEnemies(): { string }
	return availableEnemies
end

function GameController:GetEnemyInfo(enemyName: string)
	return EnemyData[enemyName]
end

function GameController:GetAgeInfo(ageName: string)
	return AgeData.Ages[ageName]
end

function GameController:GetXpRequired(): number?
	local age = AgeData.Ages[currentAge]
	if age then
		return GameConfig.AgeUpXpRequired[age.Order]
	end
	return nil
end

return GameController
