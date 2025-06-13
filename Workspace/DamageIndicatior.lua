-- Scripted by AdvancedDrone (fully optimized)
local Players   = game:GetService("Players")
local Debris    = game:GetService("Debris")

-- Pre-defined colors
local COLORS = {
	Color3.new(0, 1, 1),        -- cyan
	Color3.new(1, 1, 1),        -- white
	Color3.new(2/3, 1, 0)       -- lime
}
-- Single RNG for all calls
local RNG = Random.new()

-- Utility: spawn and clean up a damage effect
local function spawnDamageEffect(rootPart, damage)
	-- choose color
	local color = COLORS[RNG:NextInteger(1, #COLORS)]

	-- create part
	local effectPart = Instance.new("Part")
	effectPart.Name         = "DamageEffect"
	effectPart.Size         = Vector3.new(0, 0, 0)
	effectPart.CFrame       = rootPart.CFrame * CFrame.new(
		RNG:NextNumber(-5, 5),
		RNG:NextNumber(3, 5),
		RNG:NextNumber(-5, 5)
	)
	effectPart.Anchored     = true
	effectPart.CanCollide   = true
	effectPart.Transparency = 1
	effectPart.Parent       = workspace

	-- billboard GUI
	local billboard = Instance.new("BillboardGui")
	billboard.Adornee     = effectPart
	billboard.Size        = UDim2.fromScale(3, 3)
	billboard.AlwaysOnTop = false
	billboard.Parent      = effectPart

	local label = Instance.new("TextLabel")
	label.Size                 = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextStrokeTransparency = 0
	label.TextScaled            = true
	label.Font                  = Enum.Font.LuckiestGuy
	label.TextColor3            = color
	label.Text                  = tostring(damage)
	label.Parent                = billboard

	-- launch and cleanup
	-- 0.2s anchored, then falls
	task.delay(0.2, function()
		if effectPart and effectPart.Parent then
			effectPart.Anchored = false
		end
	end)

	-- auto-destroy after 2s
	Debris:AddItem(effectPart, 2)
end

-- Main connection
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		-- wait for essential parts
		local humanoid = character:WaitForChild("Humanoid", 5)
		local rootPart = character:WaitForChild("HumanoidRootPart", 5)
		if not humanoid or not rootPart then
			return
		end

		local lastHealth = humanoid.Health
		humanoid.HealthChanged:Connect(function(currentHealth)
			-- on damage and not dead
			if currentHealth < lastHealth
				and humanoid:GetState() ~= Enum.HumanoidStateType.Dead then
				local dmg = math.floor(lastHealth - currentHealth)
				spawnDamageEffect(rootPart, dmg)
			end
			lastHealth = currentHealth
		end)
	end)
end)
