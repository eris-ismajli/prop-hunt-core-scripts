local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Cache assets once for better performance
local VFXAttachment = ReplicatedStorage:WaitForChild("VFX"):WaitForChild("Attachment")
local CloudToolHandle = ReplicatedStorage:WaitForChild("CloudTool"):WaitForChild("Handle")
local Cloud = CloudToolHandle:WaitForChild("Cloud")
local Cloud1 = CloudToolHandle:WaitForChild("Cloud1")
local Health1 = ReplicatedStorage:WaitForChild("Health1")
local smoke = ReplicatedStorage:WaitForChild("SmokeEffect")

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		local hrp = character:WaitForChild("HumanoidRootPart")

		-- Clone and parent VFX
		VFXAttachment:Clone().Parent = hrp
		Cloud:Clone().Parent = hrp
		Cloud1:Clone().Parent = hrp
		Health1:Clone().Parent = character
		
		local clone = ReplicatedStorage.PlayerOutline:Clone()
		clone.Parent = character
		
		if not hrp:FindFirstChild("SmokeEffect") then
			smoke:Clone().Parent = hrp
		end

		-- Remove the default Health if it exists
		local existingHealth = character:FindFirstChild("Health")
		if existingHealth then
			existingHealth:Destroy()
		end
	end)
end)
