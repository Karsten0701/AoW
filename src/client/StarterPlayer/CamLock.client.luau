--[[
	2D side-view camera die op de Cam part gebaseerd is.
	Je kunt de camera horizontaal bewegen:
	- A / D (of pijltjes links/rechts)
	- Muis aan de linker- of rechterkant van het scherm
	- Op telefoon: aanraken aan de linker- of rechterkant van het scherm
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- Wacht tot de Cam part en bounds bestaan
local map = workspace:WaitForChild("Map")
local camPart = map:WaitForChild("Cam")

-- Aanname: je hebt een folder `Bounds` in `Map` met twee parts: `Left` en `Right`
local boundsFolder = map:WaitForChild("Bounds")
local leftBound = boundsFolder:WaitForChild("Left")
local rightBound = boundsFolder:WaitForChild("Right")

-- Neem volledige controle over de camera
camera.CameraType = Enum.CameraType.Scriptable

-- Config
local moveSpeed = 30 -- studs per seconde links/rechts
local mouseEdgePercent = 0.25 -- links/rechts zone van het scherm voor muis

-- Interne state
local keyboardDir = 0 -- -1 = links, 1 = rechts
local pointerDir = 0 -- muis / touch richting

-- Helpers om input richting te berekenen
local function updateKeyboardDirection(input, began)
	local code = input.KeyCode
	local dirChange = 0

	if code == Enum.KeyCode.A or code == Enum.KeyCode.Left then
		dirChange = -1
	elseif code == Enum.KeyCode.D or code == Enum.KeyCode.Right then
		dirChange = 1
	end

	if dirChange ~= 0 then
		if began then
			keyboardDir = dirChange
		else
			-- Alleen richting resetten als de losgelaten toets overeenkomt
			if keyboardDir == dirChange then
				keyboardDir = 0
			end
		end
	end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	if input.UserInputType == Enum.UserInputType.Keyboard then
		updateKeyboardDirection(input, true)
	end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
	if input.UserInputType == Enum.UserInputType.Keyboard then
		updateKeyboardDirection(input, false)
	end
end)

-- Bepaal richting op basis van muis of touch
local function updatePointerDirection()
	pointerDir = 0

	local viewportSize = camera.ViewportSize
	local halfWidth = viewportSize.X * 0.5

	-- Touch (telefoon / tablet)
	if UserInputService.TouchEnabled then
		local touches = UserInputService:GetTouches()
		if #touches > 0 then
			-- Neem de eerste touch
			local touchPos = touches[1].Position
			if touchPos.X < halfWidth then
				pointerDir = -1
			elseif touchPos.X > halfWidth then
				pointerDir = 1
			end
			return
		end
	end

	-- Muis (desktop)
	if UserInputService.MouseEnabled then
		local mousePos = UserInputService:GetMouseLocation()
		local leftZone = viewportSize.X * mouseEdgePercent
		local rightZone = viewportSize.X * (1 - mouseEdgePercent)

		if mousePos.X <= leftZone then
			pointerDir = -1
		elseif mousePos.X >= rightZone then
			pointerDir = 1
		end
	end
end

-- Horizontale offset vanaf de basis-Cam positie
local horizontalOffset = 0

-- Bereken limieten langs de lokale RightVector van de Cam part
local rightDir = camPart.CFrame.RightVector
local baseDot = rightDir:Dot(camPart.Position)
local leftDot = rightDir:Dot(leftBound.Position)
local rightDot = rightDir:Dot(rightBound.Position)

local minDot = math.min(leftDot, rightDot)
local maxDot = math.max(leftDot, rightDot)

local minOffset = minDot - baseDot
local maxOffset = maxDot - baseDot

-- Update camera elke frame
RunService.RenderStepped:Connect(function(dt)
	if not camPart or not camPart.Parent then
		return
	end

	updatePointerDirection()

	-- Combineer input; keyboard heeft voorrang
	local moveDir = keyboardDir ~= 0 and keyboardDir or pointerDir

	-- Werk offset bij
	if moveDir ~= 0 then
		horizontalOffset += moveDir * moveSpeed * dt
	end

	-- Clamp de offset zodat de camera niet voorbij de bounds gaat
	horizontalOffset = math.clamp(horizontalOffset, minOffset, maxOffset)

	-- Base CFrame van de Cam part
	local baseCFrame = camPart.CFrame

	-- Beweeg het doelpunt (waar de camera naar kijkt) langs de lokale X-as
	local offsetVector = baseCFrame.RightVector * horizontalOffset
	local targetPosition = baseCFrame.Position + offsetVector

	-- Plaats de camera 20 studs achter het doelpunt langs de kijkrichting
	local distance = 20
	local camPosition = targetPosition - baseCFrame.LookVector * distance

	camera.CFrame = CFrame.new(camPosition, targetPosition)
end)
