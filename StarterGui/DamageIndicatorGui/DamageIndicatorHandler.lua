local localPlayer = game.Players.LocalPlayer
local playerCharacter = localPlayer.Character or localPlayer.CharacterAdded:Wait()
local camera = workspace.CurrentCamera
local rep = game:GetService("ReplicatedStorage")

local gui = script.Parent
local indicator = script:WaitForChild("DamageIndicator")

local remote = rep:WaitForChild("DamageIndicatorReplicatedStorage"):WaitForChild("DamageEvent")

local tweenService = game:GetService("TweenService")
local indicatorFadeTI = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
local timeAfterIndicatorExpires = 4.5
local minVisibleDistance = 45
local midVisibleDistance = 75
local maxVisibleDistance = 105

local remoteConnection

function getCentreCF(object:Instance)
	local instanceCF = object.CFrame
	local pos = instanceCF.Position
	local lookAt = instanceCF.LookVector * Vector3.new(1, 0, 1)
	local centreCF = CFrame.new(pos, pos + (lookAt))
	return centreCF
end

function calculateAngle(centre:CFrame, point:Vector3)
	local damageDir = centre:PointToObjectSpace(point)
	local theta = math.atan2(damageDir.Z, damageDir.X)
	local angleInDegrees = math.deg(theta) + 90
	return angleInDegrees
end


function damageDealt(originOfDamage: Vector3)
	local centreCF = getCentreCF(camera)
	local distance = (originOfDamage - camera.CFrame.Position).Magnitude

	local transparency = math.clamp((distance - minVisibleDistance) / (maxVisibleDistance - minVisibleDistance), 0, 1)

	local angleInDegrees = calculateAngle(centreCF, originOfDamage)

	local newIndicator = indicator:Clone()
	newIndicator.DamageIndicatorImage.ImageTransparency = transparency
	newIndicator.Visible = true
	newIndicator.Rotation = angleInDegrees
	newIndicator.Parent = gui

	task.spawn(function()
		while newIndicator and newIndicator.Parent == gui do
			local centreCF = getCentreCF(camera)
			local angleInDegrees = calculateAngle(centreCF, originOfDamage)
			newIndicator.Rotation = angleInDegrees

			-- Update transparency based on distance
			local distance = (originOfDamage - camera.CFrame.Position).Magnitude
			transparency = math.clamp((distance - minVisibleDistance) / (maxVisibleDistance - minVisibleDistance), 0, 1)
			newIndicator.DamageIndicatorImage.ImageTransparency = transparency

			game:GetService("RunService").Heartbeat:Wait()
		end
	end)

	task.wait(timeAfterIndicatorExpires)

	local indicatorFadeTween = tweenService:Create(newIndicator.DamageIndicatorImage, indicatorFadeTI, { ImageTransparency = 1 })
	indicatorFadeTween:Play()
	indicatorFadeTween.Completed:Wait()

	newIndicator:Destroy()
	
end

if rep.InRound.Value == true and rep.Modes.Classic.Value == true then
	if not remoteConnection then
		remoteConnection = remote.OnClientEvent:Connect(damageDealt)
	end
else
	if remoteConnection then
		remoteConnection:Disconnect()
		remoteConnection = nil
	end
end

rep.InRound.Changed:Connect(function()
	if rep.InRound.Value == true and rep.Modes.Classic.Value == true then
		if not remoteConnection then
			remoteConnection = remote.OnClientEvent:Connect(damageDealt)
		end
	else
		if remoteConnection then
			remoteConnection:Disconnect()
			remoteConnection = nil
		end
	end
end)



