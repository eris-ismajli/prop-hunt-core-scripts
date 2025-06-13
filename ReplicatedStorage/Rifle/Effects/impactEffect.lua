--####################################################
--Impact Effect
--#####################################################

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local environmentImpactTemplate = ReplicatedStorage.Blaster.Objects.EnvironmentImpact
local characterImpactTemplate = ReplicatedStorage.Blaster.Objects.CharacterImpact

local function impactEffect(position: Vector3, normal: Vector3, isCharacter: boolean, isProp: boolean)
	local impact
	-- If it's a character and not a prop (has no forcefield)
	if isCharacter and not isProp then
		impact = characterImpactTemplate:Clone()
		impact.CFrame = CFrame.lookAt(position, position + normal) -- Adjusted for better orientation
		impact.Parent = Workspace

		task.spawn(function()
			impact.ShotEffect.Enabled = true
			task.wait(0.2)
			impact.ShotEffect.Enabled = false
		end)
		-- If it's a prop (could be a character with a forcefield or non-character object)
	elseif isCharacter and isProp then
		impact = environmentImpactTemplate:Clone()
		impact.CFrame = CFrame.lookAt(position, position + normal)
		impact.Parent = Workspace

		impact.ImpactEffect:Emit(0.5) -- Emit environment effect
	else
		impact = environmentImpactTemplate:Clone()
		impact.CFrame = CFrame.lookAt(position, position + normal)
		impact.Parent = Workspace

		impact.ImpactEffect:Emit(0.5) -- Emit environment effect for non-character hit
	end

	-- Destroy the impact after 0.5 seconds to clean up
	task.delay(0.5, function()
		impact:Destroy()
	end)
end

return impactEffect
