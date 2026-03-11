m = {}

m.PlayerTemplate = {
	Gold = 0,
	Gems = 0,
	Level = 1,
	Experience = 0,
}

m.GameTemplate = {
	Gold = 250,
	Gems = 0,
	Level = 1,
	Experience = 0,
	PassiveGoldInterval = 10, -- 10 seconds
	PassiveGoldAmount = 50,
	Units = {
		["Miner"] = 2,
		["Swordman"] = 0,
		["Archer"] = 0,
		["Mage"] = 0,
		["Priest"] = 0,
		["Thief"] = 0,
	},
	States = {
		["Attacking"] = false,
		["Defending"] = true,
		["Retreating"] = false,
	},
}

return m
