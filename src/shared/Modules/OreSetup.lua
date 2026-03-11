local ReplicatedStorage = game:GetService("ReplicatedStorage")

local OreSetup = {}

local SIZES = { "Large", "Medium", "Small" }

function OreSetup.Initialize(oresFolder)
	local hitboxes = {}

	local assets = ReplicatedStorage:FindFirstChild("Assets")
	if not assets then
		warn("[AoW] OreSetup: ReplicatedStorage.Assets not found")
		return hitboxes
	end
	local oresAssets = assets:FindFirstChild("Ores")
	if not oresAssets then
		warn("[AoW] OreSetup: ReplicatedStorage.Assets.Ores not found")
		return hitboxes
	end

	for _, oreModel in oresFolder:GetChildren() do
		if not oreModel:IsA("Model") then continue end

		local hitbox = oreModel:FindFirstChild("Hitbox")
		if not hitbox then
			continue
		end

		local oreType
		if string.find(oreModel.Name, "Gem") then
			oreType = "Gem"
		elseif string.find(oreModel.Name, "Gold") then
			oreType = "Gold"
		else
			continue
		end

		local size = SIZES[math.random(1, #SIZES)]
		local templateName = oreType .. "Ore_" .. size
		local template = oresAssets:FindFirstChild(templateName)

		if template then
			local visual = template:Clone()
			visual:PivotTo(oreModel:GetPivot())
			visual.Parent = oreModel
		else
			warn("[AoW] OreSetup: template not found", templateName)
		end

		table.insert(hitboxes, {
			Model = oreModel,
			Hitbox = hitbox,
			Position = hitbox.Position,
			OreType = oreType,
			BeingMined = false,
		})
	end

	print("[AoW] OreSetup: initialized", #hitboxes, "ores from", #oresFolder:GetChildren(), "children in Ores folder")
	return hitboxes
end

return OreSetup
