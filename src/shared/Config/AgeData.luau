--[[
	Definitie van alle Ages in het spel.
	Elke age ontgrendelt nieuwe units en geeft bonussen.
]]

export type AgeInfo = {
	Name: string,
	DisplayName: string,
	Order: number,
	UnlocksEnemies: { string },
	PassiveIncomeMultiplier: number,
	BaseHealthBonus: number,
}

local AgeData: { [string]: AgeInfo } = {
	Prehistoric = {
		Name = "Prehistoric",
		DisplayName = "Prehistoric Age",
		Order = 1,
		UnlocksEnemies = { "Enemy1", "Enemy2" },
		PassiveIncomeMultiplier = 1.0,
		BaseHealthBonus = 0,
	},
	Medieval = {
		Name = "Medieval",
		DisplayName = "Medieval Age",
		Order = 2,
		UnlocksEnemies = { "Enemy3", "Enemy4" },
		PassiveIncomeMultiplier = 1.5,
		BaseHealthBonus = 200,
	},
	Renaissance = {
		Name = "Renaissance",
		DisplayName = "Renaissance Age",
		Order = 3,
		UnlocksEnemies = { "Enemy5", "Enemy6" },
		PassiveIncomeMultiplier = 2.0,
		BaseHealthBonus = 500,
	},
	Industrial = {
		Name = "Industrial",
		DisplayName = "Industrial Age",
		Order = 4,
		UnlocksEnemies = { "Enemy7", "Enemy8" },
		PassiveIncomeMultiplier = 3.0,
		BaseHealthBonus = 1000,
	},
	Modern = {
		Name = "Modern",
		DisplayName = "Modern Age",
		Order = 5,
		UnlocksEnemies = { "Enemy9", "Enemy10" },
		PassiveIncomeMultiplier = 5.0,
		BaseHealthBonus = 2000,
	},
	Future = {
		Name = "Future",
		DisplayName = "Future Age",
		Order = 6,
		UnlocksEnemies = { "Enemy11", "Enemy12" },
		PassiveIncomeMultiplier = 8.0,
		BaseHealthBonus = 5000,
	},
}

-- Geordende lijst voor makkelijke iteratie
local AgeOrder: { AgeInfo } = {}
for _, age in AgeData do
	table.insert(AgeOrder, age)
end
table.sort(AgeOrder, function(a, b)
	return a.Order < b.Order
end)

return {
	Ages = AgeData,
	AgeOrder = AgeOrder,
}
