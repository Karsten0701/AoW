--[[
	HudController: bouwt en beheert de volledige game UI.
	- Goud display (linksboven)
	- Age & XP bar (bovenin midden)
	- Unit spawn buttons (onderin)
	- Spawn feedback berichten
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.knit)
local EnemyData = require(ReplicatedStorage.Shared.Config.EnemyData)

local HudController = Knit.CreateController({
	Name = "HudController",
})

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local screenGui: ScreenGui
local goldLabel: TextLabel
local ageLabel: TextLabel
local xpBar: Frame
local xpBarFill: Frame
local xpLabel: TextLabel
local unitsContainer: ScrollingFrame
local feedbackLabel: TextLabel

local function createCorner(parent: GuiObject, radius: number)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = parent
	return corner
end

local function createStroke(parent: GuiObject, color: Color3, thickness: number)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = thickness
	stroke.Parent = parent
	return stroke
end

local function buildUI()
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "GameHud"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = playerGui

	-- ╔═══════════════════════════════╗
	-- ║  GOUD DISPLAY (linksboven)    ║
	-- ╚═══════════════════════════════╝
	local goldFrame = Instance.new("Frame")
	goldFrame.Name = "GoldFrame"
	goldFrame.Size = UDim2.new(0, 220, 0, 50)
	goldFrame.Position = UDim2.new(0, 15, 0, 15)
	goldFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	goldFrame.BackgroundTransparency = 0.2
	goldFrame.Parent = screenGui
	createCorner(goldFrame, 10)
	createStroke(goldFrame, Color3.fromRGB(255, 200, 50), 2)

	local goldIcon = Instance.new("TextLabel")
	goldIcon.Name = "GoldIcon"
	goldIcon.Size = UDim2.new(0, 40, 1, 0)
	goldIcon.Position = UDim2.new(0, 5, 0, 0)
	goldIcon.BackgroundTransparency = 1
	goldIcon.Text = "G"
	goldIcon.TextColor3 = Color3.fromRGB(255, 215, 0)
	goldIcon.TextSize = 28
	goldIcon.Font = Enum.Font.GothamBold
	goldIcon.Parent = goldFrame

	goldLabel = Instance.new("TextLabel")
	goldLabel.Name = "GoldLabel"
	goldLabel.Size = UDim2.new(1, -50, 1, 0)
	goldLabel.Position = UDim2.new(0, 45, 0, 0)
	goldLabel.BackgroundTransparency = 1
	goldLabel.Text = "0"
	goldLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	goldLabel.TextSize = 24
	goldLabel.Font = Enum.Font.GothamBold
	goldLabel.TextXAlignment = Enum.TextXAlignment.Left
	goldLabel.Parent = goldFrame

	-- ╔═══════════════════════════════╗
	-- ║  AGE & XP BAR (boven midden)  ║
	-- ╚═══════════════════════════════╝
	local ageFrame = Instance.new("Frame")
	ageFrame.Name = "AgeFrame"
	ageFrame.Size = UDim2.new(0, 350, 0, 60)
	ageFrame.Position = UDim2.new(0.5, -175, 0, 15)
	ageFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	ageFrame.BackgroundTransparency = 0.2
	ageFrame.Parent = screenGui
	createCorner(ageFrame, 10)
	createStroke(ageFrame, Color3.fromRGB(100, 180, 255), 2)

	ageLabel = Instance.new("TextLabel")
	ageLabel.Name = "AgeLabel"
	ageLabel.Size = UDim2.new(1, -20, 0, 25)
	ageLabel.Position = UDim2.new(0, 10, 0, 3)
	ageLabel.BackgroundTransparency = 1
	ageLabel.Text = "Prehistoric Age"
	ageLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
	ageLabel.TextSize = 18
	ageLabel.Font = Enum.Font.GothamBold
	ageLabel.TextXAlignment = Enum.TextXAlignment.Center
	ageLabel.Parent = ageFrame

	xpBar = Instance.new("Frame")
	xpBar.Name = "XpBar"
	xpBar.Size = UDim2.new(1, -20, 0, 16)
	xpBar.Position = UDim2.new(0, 10, 0, 32)
	xpBar.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	xpBar.Parent = ageFrame
	createCorner(xpBar, 6)

	xpBarFill = Instance.new("Frame")
	xpBarFill.Name = "Fill"
	xpBarFill.Size = UDim2.new(0, 0, 1, 0)
	xpBarFill.BackgroundColor3 = Color3.fromRGB(80, 200, 120)
	xpBarFill.Parent = xpBar
	createCorner(xpBarFill, 6)

	xpLabel = Instance.new("TextLabel")
	xpLabel.Name = "XpLabel"
	xpLabel.Size = UDim2.new(1, 0, 1, 0)
	xpLabel.BackgroundTransparency = 1
	xpLabel.Text = "0 / 100 XP"
	xpLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	xpLabel.TextSize = 12
	xpLabel.Font = Enum.Font.GothamBold
	xpLabel.ZIndex = 2
	xpLabel.Parent = xpBar

	-- ╔═══════════════════════════════╗
	-- ║  UNIT SPAWN BUTTONS (onderin) ║
	-- ╚═══════════════════════════════╝
	local bottomBar = Instance.new("Frame")
	bottomBar.Name = "BottomBar"
	bottomBar.Size = UDim2.new(1, -30, 0, 110)
	bottomBar.Position = UDim2.new(0, 15, 1, -125)
	bottomBar.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
	bottomBar.BackgroundTransparency = 0.3
	bottomBar.Parent = screenGui
	createCorner(bottomBar, 12)
	createStroke(bottomBar, Color3.fromRGB(80, 80, 80), 1)

	unitsContainer = Instance.new("ScrollingFrame")
	unitsContainer.Name = "UnitsContainer"
	unitsContainer.Size = UDim2.new(1, -20, 1, -10)
	unitsContainer.Position = UDim2.new(0, 10, 0, 5)
	unitsContainer.BackgroundTransparency = 1
	unitsContainer.ScrollBarThickness = 4
	unitsContainer.ScrollBarImageColor3 = Color3.fromRGB(150, 150, 150)
	unitsContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
	unitsContainer.AutomaticCanvasSize = Enum.AutomaticSize.X
	unitsContainer.ScrollingDirection = Enum.ScrollingDirection.X
	unitsContainer.Parent = bottomBar

	local listLayout = Instance.new("UIListLayout")
	listLayout.FillDirection = Enum.FillDirection.Horizontal
	listLayout.Padding = UDim.new(0, 10)
	listLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	listLayout.Parent = unitsContainer

	-- ╔═══════════════════════════════╗
	-- ║  FEEDBACK LABEL               ║
	-- ╚═══════════════════════════════╝
	feedbackLabel = Instance.new("TextLabel")
	feedbackLabel.Name = "FeedbackLabel"
	feedbackLabel.Size = UDim2.new(0, 300, 0, 40)
	feedbackLabel.Position = UDim2.new(0.5, -150, 1, -150)
	feedbackLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	feedbackLabel.BackgroundTransparency = 0.3
	feedbackLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	feedbackLabel.TextSize = 16
	feedbackLabel.Font = Enum.Font.GothamMedium
	feedbackLabel.Text = ""
	feedbackLabel.TextTransparency = 1
	feedbackLabel.BackgroundTransparency = 1
	feedbackLabel.Parent = screenGui
	createCorner(feedbackLabel, 8)
end

local function createUnitButton(enemyName: string)
	local info = EnemyData[enemyName]
	if not info then
		return
	end

	local btn = Instance.new("TextButton")
	btn.Name = enemyName
	btn.Size = UDim2.new(0, 90, 0, 90)
	btn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
	btn.AutoButtonColor = true
	btn.Text = ""
	btn.Parent = unitsContainer
	createCorner(btn, 8)
	createStroke(btn, Color3.fromRGB(100, 100, 120), 1)

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, -6, 0, 18)
	nameLabel.Position = UDim2.new(0, 3, 0, 5)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = info.DisplayName
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextSize = 12
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	nameLabel.Parent = btn

	local costLabel = Instance.new("TextLabel")
	costLabel.Size = UDim2.new(1, -6, 0, 16)
	costLabel.Position = UDim2.new(0, 3, 0, 50)
	costLabel.BackgroundTransparency = 1
	costLabel.Text = `G {info.Cost}`
	costLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
	costLabel.TextSize = 13
	costLabel.Font = Enum.Font.GothamBold
	costLabel.Parent = btn

	local statsLabel = Instance.new("TextLabel")
	statsLabel.Size = UDim2.new(1, -6, 0, 14)
	statsLabel.Position = UDim2.new(0, 3, 0, 68)
	statsLabel.BackgroundTransparency = 1
	statsLabel.Text = `HP:{info.Health} DMG:{info.Damage}`
	statsLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
	statsLabel.TextSize = 10
	statsLabel.Font = Enum.Font.Gotham
	statsLabel.Parent = btn

	btn.MouseButton1Click:Connect(function()
		local GameController = Knit.GetController("GameController")
		GameController:RequestSpawn(enemyName)
	end)

	btn.MouseEnter:Connect(function()
		btn.BackgroundColor3 = Color3.fromRGB(60, 60, 75)
	end)
	btn.MouseLeave:Connect(function()
		btn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
	end)

	return btn
end

local function refreshUnitButtons(enemies: { string })
	for _, child in unitsContainer:GetChildren() do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end

	for _, enemyName in enemies do
		createUnitButton(enemyName)
	end
end

local function showFeedback(message: string, success: boolean)
	feedbackLabel.Text = message
	feedbackLabel.TextColor3 = if success
		then Color3.fromRGB(80, 220, 120)
		else Color3.fromRGB(255, 80, 80)
	feedbackLabel.TextTransparency = 0
	feedbackLabel.BackgroundTransparency = 0.3

	task.delay(2, function()
		feedbackLabel.TextTransparency = 1
		feedbackLabel.BackgroundTransparency = 1
	end)
end

local function updateXpBar(currentXp: number, xpRequired: number?)
	if xpRequired and xpRequired > 0 then
		local ratio = math.clamp(currentXp / xpRequired, 0, 1)
		xpBarFill.Size = UDim2.new(ratio, 0, 1, 0)
		xpLabel.Text = `{math.floor(currentXp)} / {xpRequired} XP`
	else
		xpBarFill.Size = UDim2.new(1, 0, 1, 0)
		xpLabel.Text = "MAX AGE"
	end
end

function HudController:KnitStart()
	buildUI()

	local GameController = Knit.GetController("GameController")

	-- Callbacks koppelen
	GameController.OnGoldChanged = function(newGold)
		goldLabel.Text = tostring(math.floor(newGold))
	end

	GameController.OnXpChanged = function(newXp)
		local xpRequired = GameController:GetXpRequired()
		updateXpBar(newXp, xpRequired)
	end

	GameController.OnAgeChanged = function(newAge)
		local ageInfo = GameController:GetAgeInfo(newAge)
		if ageInfo then
			ageLabel.Text = ageInfo.DisplayName
		end
	end

	GameController.OnSpawnResult = function(success, message)
		showFeedback(message, success)
	end

	GameController.OnEnemiesUpdated = function(enemies)
		refreshUnitButtons(enemies)
	end
end

return HudController
