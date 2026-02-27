--[[
	Globale game instellingen voor Age of War.
]]

local GameConfig = {
	-- Startgeld bij een nieuwe speler
	StartingGold = 100,

	-- Passief inkomen per seconde
	PassiveIncomePerSecond = 2,

	-- Tijd (seconden) voordat vijanden automatisch spawnen
	EnemyAutoSpawnInterval = 8,

	-- Maximaal aantal vijanden tegelijk op het veld per speler
	MaxEnemiesOnField = 20,

	-- Walkspeed van vijandige bots (kan per enemy overschreven worden)
	DefaultEnemyWalkSpeed = 8,

	-- Afstand waarop vijanden elkaars base aanvallen
	BaseAttackRange = 5,

	-- Base HP per speler
	BaseHealth = 500,

	-- Tijd tussen auto-save cycles (seconden)
	AutoSaveInterval = 60,

	-- XP nodig om naar de volgende age te gaan
	AgeUpXpRequired = { 100, 300, 600, 1200, 2500 },

	-- Spawn positie offset (studs vanaf de base richting het midden van het veld)
	SpawnOffsetFromBase = 10,

	-- Pad naar enemy models in ReplicatedStorage
	EnemyModelsPath = { "Assets", "Enemies" },
}

return GameConfig
