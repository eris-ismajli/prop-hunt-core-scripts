local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

-- Track parts to animate
local animatedParts = {}

-- Function to start animating a part
local function startAnimating(part)
	if animatedParts[part] then return end -- Prevent duplicate animations

	animatedParts[part] = true
	local originalPosition = part.Position
	local spinSpeed = math.rad(10)

	local heartbeatConnection
	heartbeatConnection = RunService.Heartbeat:Connect(function(deltaTime)
		if not animatedParts[part] then
			-- Stop animation and reset position
			part.Position = originalPosition
			heartbeatConnection:Disconnect() -- Stop further Heartbeat connection
			return
		end

		-- Spinning Logic
		part.CFrame *= CFrame.Angles(spinSpeed * deltaTime * 60, 0, 0)
	end)
end

-- Function to stop animating a part
local function stopAnimating(part)
	animatedParts[part] = nil
end

-- Listen for parts being tagged or untagged
CollectionService:GetInstanceAddedSignal("ActiveRound"):Connect(startAnimating)
CollectionService:GetInstanceRemovedSignal("ActiveRound"):Connect(stopAnimating)

-- Initialize existing tagged parts
for _, part in ipairs(CollectionService:GetTagged("ActiveRound")) do
	startAnimating(part)
end
