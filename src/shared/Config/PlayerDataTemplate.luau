--[[
	Template voor speler data die opgeslagen wordt via ProfileStore.
	Dit is de standaard data voor een nieuwe speler.
]]

local PlayerDataTemplate = {
	Gold = 100,
	Xp = 0,
	CurrentAge = "Prehistoric",
	TotalKills = 0,
	TotalGoldEarned = 0,
	GamesPlayed = 0,
	Wins = 0,
	Losses = 0,
	HighestAge = "Prehistoric",
}

return PlayerDataTemplate
