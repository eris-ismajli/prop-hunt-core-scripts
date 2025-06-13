-- Center-layout respawn panel (self-death only)
------------------------------------------------
local player        = game.Players.LocalPlayer
local propsCounter  = game.ReplicatedStorage:WaitForChild("Props")
local blur          = game.Lighting:WaitForChild("Blur")

-- ❶ Center-layout constants (scale only, no pixel offsets)
local FRAME_POS  = UDim2.fromScale(0.5 , 0.5 )
local FRAME_SIZE = UDim2.fromScale(0.5 , 0.5 )

local RANK_POS   = UDim2.fromScale(0.5 , 0.605)
local RANK_SIZE  = UDim2.fromScale(0.129, 0.246)

local TEXT_POS   = UDim2.fromScale(0.5 , 0.302)
local TEXT_SIZE  = UDim2.fromScale(0.706, 0.673)

local LVL_POS    = UDim2.fromScale(0.5 , 0.822)
local LVL_SIZE   = UDim2.fromScale(0.654, 0.116)

local RSTAT_POS  = UDim2.fromScale(0.5 , 0.917)
local RSTAT_SIZE = UDim2.fromScale(0.431, 0.078)

------------------------------------------------------------------
player.CharacterAdded:Connect(function(char)
	local hum          = char:WaitForChild("Humanoid")
	local gui          = player.PlayerGui:WaitForChild("Respawning")
	local frame        = gui.RespawningFrame
	local rankImage    = frame.Rank
	local respText     = frame.respawning
	local levelStatus  = frame.LevelStatus
	local rankStatus   = frame.RankStatus

	blur.Enabled            = false
	rankStatus.Transparency = 1
	gui.Enabled             = false

	hum.Died:Connect(function()
		local creatorTag = char:FindFirstChild("creator")
		local selfDeath  = not (creatorTag and creatorTag.Value)

		if not selfDeath then return end   -- killed by another player

		if player.Team == game.Teams.Props and propsCounter.Value < 1 then
			return                         -- no props left → no respawn screen
		end

		---------------------------------------------------------- show GUI
		game.Workspace.boom:Play()
		blur.Enabled = true

		frame.Position, frame.Size           = FRAME_POS , FRAME_SIZE
		rankImage.Position,  rankImage.Size  = RANK_POS  , RANK_SIZE
		respText.Position,  respText.Size    = TEXT_POS  , TEXT_SIZE
		levelStatus.Position,levelStatus.Size= LVL_POS   , LVL_SIZE
		rankStatus.Position, rankStatus.Size = RSTAT_POS , RSTAT_SIZE

		gui.Enabled = true
	end)
end)
