local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Knit = require(ReplicatedStorage.Packages.knit)
local Janitor = require(ReplicatedStorage.Packages.janitor)

local GuiController = Knit.CreateController({ Name = "GuiController" })

local _janitor = Janitor.new()
local player = Players.LocalPlayer

local UNIT_BUTTONS = {
	Miner = "Miner",
	Unit1 = "Swordman",
	Unit2 = "Archer",
}

local STATE_BUTTONS = {
	Retreat = "Retreating",
	Defend = "Defending",
	Attacking = "Attacking",
}

local function connectClick(guiObject, callback)
	if guiObject:IsA("GuiButton") then
		return guiObject.Activated:Connect(callback)
	end
	return guiObject.InputBegan:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			callback()
		end
	end)
end

function GuiController:KnitInit()
	print("[AoW] GuiController KnitInit")
	local playerGui = player:WaitForChild("PlayerGui")

	-- StarterGui wordt door Roblox gekopieerd naar PlayerGui; wacht tot GameGui er is
	local gui = playerGui:WaitForChild("GameGui", 10)
	if not gui then
		local list = {}
		for _, c in playerGui:GetChildren() do
			table.insert(list, c.Name)
		end
		warn("[AoW] GameGui not in PlayerGui after 10s. Children:", table.concat(list, ", "))
		self._currency = nil
		self._states = nil
		self._units = nil
		return
	end

	local bg = gui:WaitForChild("BG", 2)
	if not bg then
		local list = {}
		for _, c in gui:GetChildren() do
			table.insert(list, c.Name)
		end
		warn("[AoW] BG not found in GameGui. Children:", table.concat(list, ", "))
		self._currency = nil
		self._states = nil
		self._units = nil
		return
	end

	self._currency = bg:FindFirstChild("Currency")
	self._states = bg:FindFirstChild("States")
	self._units = bg:FindFirstChild("Units")
	if not self._currency or not self._states or not self._units then
		warn(
			"[AoW] Missing BG children. Currency:",
			self._currency ~= nil,
			"States:",
			self._states ~= nil,
			"Units:",
			self._units ~= nil
		)
	end
	print(
		"[AoW] GUI refs – Currency:",
		self._currency ~= nil,
		"States:",
		self._states ~= nil,
		"Units:",
		self._units ~= nil
	)
end

function GuiController:KnitStart()
	print("[AoW] GuiController KnitStart")
	if not self._currency or not self._states or not self._units then
		warn("[AoW] GuiController: GUI refs missing, skipping button bindings")
		return
	end

	local GameController = Knit.GetController("GameController")

	for btnName, unitName in UNIT_BUTTONS do
		local btn = self._units:FindFirstChild(btnName)
		if btn then
			_janitor:Add(connectClick(btn, function()
				local ok = GameController:QueueUnit(unitName)
				print("[AoW] Unit button", btnName, "->", unitName, ok and "queued" or "failed (cost?)")
			end))
			print("[AoW] Bound unit button:", btnName)
		else
			warn("[AoW] Unit button not found:", btnName)
		end
	end

	for btnName, stateName in STATE_BUTTONS do
		local btn = self._states:FindFirstChild(btnName)
		if btn then
			_janitor:Add(connectClick(btn, function()
				GameController:SetState(stateName)
				print("[AoW] State set:", stateName)
			end))
		end
	end

	_janitor:Add(RunService.Heartbeat:Connect(function()
		self:_updateCurrency(GameController)
		self:_updateProduction(GameController)
		self:_updateStates(GameController)
	end))
end

function GuiController:_updateCurrency(gc)
	if not self._currency then
		return
	end
	local values = {
		Gold = gc:GetGold(),
		Gems = gc:GetGems(),
		Units = gc:GetTotalUnits(),
	}

	for name, value in values do
		local frame = self._currency:FindFirstChild(name)
		if not frame then
			continue
		end

		local label = frame:FindFirstChild("Gold")
		if label then
			label.Text = tostring(math.floor(value))
		end
	end
end

function GuiController:_updateProduction(gc)
	if not self._units then
		return
	end
	for btnName, unitName in UNIT_BUTTONS do
		local btn = self._units:FindFirstChild(btnName)
		if not btn then
			continue
		end

		local textLabel = btn:FindFirstChild("TextLabel")
		local bar = btn:FindFirstChild("Bar")
		local timerLabel = btn:FindFirstChild("Timer")

		local count, progress = gc:GetProductionQueueInfo(unitName)

		-- Label: "Miner" of "Miner x3"
		if textLabel then
			if count > 1 then
				textLabel.Text = string.format("%s x%d", unitName, count)
			else
				textLabel.Text = unitName
			end
		end

		-- Timer tekst (laatste productie)
		if timerLabel then
			if count == 0 or progress <= 0 then
				timerLabel.Visible = false
			else
				timerLabel.Visible = true
				local remainingFound, remaining = gc:GetProductionTimeLeft(unitName)
				if remainingFound then
					timerLabel.Text = string.format("%.1fs", remaining)
				else
					timerLabel.Visible = false
				end
			end
		end

		-- Cooldown bar: size Y van 1 -> 0
		if bar and bar:IsA("Frame") then
			if count == 0 or progress <= 0 then
				bar.Visible = false
				bar.Size = UDim2.new(bar.Size.X.Scale, bar.Size.X.Offset, 1, 0)
			else
				bar.Visible = true
				local fill = 0 + math.clamp(progress, 0, 1)
				bar.Size = UDim2.new(bar.Size.X.Scale, bar.Size.X.Offset, fill, 0)
			end
		end
	end
end

function GuiController:_updateStates(gc)
	if not self._states then
		return
	end
	local activeState = gc:GetActiveState()

	for btnName, stateName in STATE_BUTTONS do
		local btn = self._states:FindFirstChild(btnName)
		if not btn then
			continue
		end

		btn.BackgroundTransparency = (stateName == activeState) and 0 or 0.5
	end
end

return GuiController
