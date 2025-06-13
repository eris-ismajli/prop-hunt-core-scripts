local castRays = require(script.Parent.castRays)
local laserBeamEffect = require(script.Parent.Parent.Effects.laserBeamEffect)
local impactEffect = require(script.Parent.Parent.Effects.impactEffect)

local function drawRayResults(position: Vector3, rayResults: { castRays.RayResult })
	for _, rayResult in rayResults do
		laserBeamEffect(position, rayResult.position)

		if rayResult.instance then
			local isProp = false
			local hum = rayResult.taggedHumanoid

			if hum and hum.Parent then
				local char = hum.Parent
				isProp = char:FindFirstChild("ForceField") ~= nil
			end
			impactEffect(rayResult.position, rayResult.normal, hum ~= nil, isProp)
		end
	end
end

return drawRayResults
