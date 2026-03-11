local Formation = {}

local MAX_PER_ROW = 8
local UNIT_SPACING = 4
local ROW_SPACING = 10

local CLASS_PRIORITY = {
	Melee = 1,
	Ranged = 2,
	Healer = 3,
}

function Formation.Calculate(units, centerPos, faceDir)
	local forward = Vector3.new(faceDir.X, 0, faceDir.Z)
	if forward.Magnitude < 0.001 then
		forward = Vector3.new(0, 0, -1)
	end
	forward = forward.Unit
	local right = Vector3.new(-forward.Z, 0, forward.X)

	-- Build sorted index list by class priority (Melee front, Ranged middle, Healer back)
	local sorted = {}
	for i = 1, #units do
		sorted[i] = i
	end

	table.sort(sorted, function(a, b)
		local pa = CLASS_PRIORITY[units[a].Data.Class] or 99
		local pb = CLASS_PRIORITY[units[b].Data.Class] or 99
		return pa < pb
	end)

	local positions = {}

	for slot, unitIdx in ipairs(sorted) do
		local row = math.floor((slot - 1) / MAX_PER_ROW)
		local col = (slot - 1) % MAX_PER_ROW

		local rowStart = row * MAX_PER_ROW + 1
		local rowEnd = math.min(rowStart + MAX_PER_ROW - 1, #sorted)
		local countInRow = rowEnd - rowStart + 1

		local offset = (col - (countInRow - 1) / 2) * UNIT_SPACING

		positions[unitIdx] = centerPos
			- forward * (row * ROW_SPACING)
			+ right * offset
	end

	return positions
end

return Formation
