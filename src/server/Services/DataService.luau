--[[
	DataService: beheert player data met ProfileStore.
	Handelt laden, opslaan en sessies af.
]]

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.knit)
local ProfileStore = require(ServerScriptService.ServerPackages.profilestore)
local PlayerDataTemplate = require(ReplicatedStorage.Shared.Config.PlayerDataTemplate)

local DataService = Knit.CreateService({
	Name = "DataService",
	Client = {
		PlayerDataChanged = Knit.CreateSignal(),
	},
})

local PlayerStore = ProfileStore.New("PlayerData", PlayerDataTemplate)
local Profiles: { [Player]: any } = {}

function DataService:KnitStart()
	Players.PlayerAdded:Connect(function(player)
		self:_loadProfile(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		self:_releaseProfile(player)
	end)

	for _, player in Players:GetPlayers() do
		task.spawn(function()
			self:_loadProfile(player)
		end)
	end
end

function DataService:_loadProfile(player: Player)
	local profile = PlayerStore:StartSessionAsync(`Player_{player.UserId}`, {
		Cancel = function()
			return player:IsDescendantOf(Players) == false
		end,
	})

	if profile == nil then
		player:Kick("Data kon niet geladen worden. Probeer opnieuw.")
		return
	end

	profile:Reconcile()

	profile.OnSessionEnd:Connect(function()
		Profiles[player] = nil
		if player:IsDescendantOf(Players) then
			player:Kick("Je sessie is overgenomen door een andere server.")
		end
	end)

	if not player:IsDescendantOf(Players) then
		profile:EndSession()
		return
	end

	Profiles[player] = profile

	self.Client.PlayerDataChanged:Fire(player, profile.Data)
end

function DataService:_releaseProfile(player: Player)
	local profile = Profiles[player]
	if profile then
		profile:EndSession()
		Profiles[player] = nil
	end
end

function DataService:GetProfile(player: Player)
	return Profiles[player]
end

function DataService:GetData(player: Player): typeof(PlayerDataTemplate)?
	local profile = Profiles[player]
	if profile then
		return profile.Data
	end
	return nil
end

function DataService:UpdateData(player: Player, key: string, value: any)
	local profile = Profiles[player]
	if not profile then
		return
	end

	profile.Data[key] = value
	self.Client.PlayerDataChanged:Fire(player, profile.Data)
end

function DataService:IncrementData(player: Player, key: string, amount: number)
	local profile = Profiles[player]
	if not profile then
		return
	end

	local current = profile.Data[key]
	if type(current) == "number" then
		profile.Data[key] = current + amount
		self.Client.PlayerDataChanged:Fire(player, profile.Data)
	end
end

function DataService.Client:GetPlayerData(player: Player)
	return DataService:GetData(player)
end

return DataService
