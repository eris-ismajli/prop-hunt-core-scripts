local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")

-- Adjustable launch force
local FORWARD_FORCE = 120
local UPWARD_FORCE = 120
local DEBOUNCE_TIME = 10

-- Function to setup a launch pad
local function setupLaunchPad(model)
	local isDebounced = false

	local touchPart = model:WaitForChild("Touch_Part")
	local launchCooldown = model:WaitForChild("LaunchCooldown")
	local Sound = touchPart:WaitForChild("LaunchSound")
	local cooldown = launchCooldown.Billboard.Cooldown

	touchPart.Touched:Connect(function(hit)
		if isDebounced then return end

		local character = hit.Parent
		local humanoid = character:FindFirstChild("Humanoid")
		local hrp = character:FindFirstChild("HumanoidRootPart")
		if not (humanoid and hrp) then return end

		isDebounced = true
		Sound:Play()
		cooldown.Visible = true

		-- Enable particle effect
		local trail = hrp:FindFirstChild("SmokeEffect")
		if trail and trail:IsA("ParticleEmitter") then
			trail.Enabled = true
			task.delay(1.5, function()
				if trail then
					trail.Enabled = false
				end
			end)
		end

		local velocity = Instance.new("BodyVelocity")
		velocity.Velocity = hrp.CFrame.LookVector * FORWARD_FORCE + Vector3.new(0, UPWARD_FORCE, 0)
		velocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
		velocity.Parent = hrp
		Debris:AddItem(velocity, 0.25)

		for i = DEBOUNCE_TIME, 0, -1 do
			cooldown.Text = tostring(i)
			task.wait(1)
		end

		cooldown.Visible = false
		isDebounced = false
	end)
end

-- Set up existing launch pads at runtime
for _, model in CollectionService:GetTagged("LaunchScript") do
	setupLaunchPad(model)
end

-- Also listen for launch pads added later (e.g. when a map loads)
CollectionService:GetInstanceAddedSignal("LaunchScript"):Connect(function(model)
	setupLaunchPad(model)
end)
