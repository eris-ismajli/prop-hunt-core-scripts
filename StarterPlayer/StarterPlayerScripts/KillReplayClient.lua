--############################################################--
--  KillReplayClient  (Full Version · Bobbing + Laser Beams)
--############################################################--

--// SERVICES
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local Workspace         = game:GetService("Workspace")
local TweenService      = game:GetService("TweenService")
local Debris            = game:GetService("Debris")
local Lighting          = game:GetService("Lighting")

--// LOCAL PLAYER + REMOTES
local player            = Players.LocalPlayer
local cam               = Workspace.CurrentCamera
local KillReplayRemote  = ReplicatedStorage:WaitForChild("KillReplayRemote")

--// MODULES / CONSTANTS
local BlasterFolder     = ReplicatedStorage:WaitForChild("Blaster")
local Constants         = require(BlasterFolder:WaitForChild("Constants"))
local GuiController     = require(BlasterFolder.Scripts:WaitForChild("GuiController"))
local laserBeamEffect   = require(BlasterFolder.Effects:WaitForChild("laserBeamEffect"))

--// SOUNDS
local hitSound          = script.Hit
local reloadSound       = script.Reload
local shootSoundFolder  = script.Shoot

--// GUI + EFFECT PREFABS
local youGui            = ReplicatedStorage.YOU
local victimHighlight   = ReplicatedStorage.VictimHighlight

-----------------------------------------------------------------
--  Helper: Linear interpolation
-----------------------------------------------------------------
local function lerp(a, b, t)
	return a + (b - a) * t
end

-----------------------------------------------------------------
--  Helper: Spawn floating damage numbers
-----------------------------------------------------------------
local COLORS = {
	Color3.new(0, 1, 1),
	Color3.new(1, 1, 1),
	Color3.new(2/3, 1, 0)
}
local RNG = Random.new()

local function spawnDamageEffect(rootPart, damage)
	local color = COLORS[RNG:NextInteger(1, #COLORS)]

	local effectPart = Instance.new("Part")
	effectPart.Name               = "DamageEffect"
	effectPart.Size               = Vector3.zero
	effectPart.CFrame             = rootPart.CFrame * CFrame.new(
		RNG:NextNumber(-5, 5), RNG:NextNumber(3, 5), RNG:NextNumber(-5, 5))
	effectPart.Anchored           = true
	effectPart.CanCollide         = true
	effectPart.Transparency       = 1
	effectPart.Parent             = workspace

	local billboard = Instance.new("BillboardGui")
	billboard.Adornee             = effectPart
	billboard.Size                = UDim2.fromScale(3, 3)
	billboard.AlwaysOnTop         = true
	billboard.Parent              = effectPart

	local label = Instance.new("TextLabel")
	label.Size                    = UDim2.fromScale(1, 1)
	label.BackgroundTransparency  = 1
	label.TextStrokeTransparency  = 0
	label.TextScaled              = true
	label.Font                    = Enum.Font.LuckiestGuy
	label.TextColor3              = color
	label.Text                    = tostring(damage)
	label.Parent                  = billboard

	task.delay(0.2, function()
		if effectPart:IsDescendantOf(workspace) then
			effectPart.Anchored = false
		end
	end)

	Debris:AddItem(effectPart, 2)
end

-----------------------------------------------------------------
--  Helper: Play random shoot SFX
-----------------------------------------------------------------
local function playRandomShootSound()
	local sounds = shootSoundFolder:GetChildren()
	if #sounds > 0 then
		sounds[math.random(1, #sounds)]:Play()
	end
end

-----------------------------------------------------------------
--  Helper: Toggle character visibility
-----------------------------------------------------------------
local function setCharVisible(char, visible)
	for _, d in ipairs(char:GetDescendants()) do
		if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" then
			d.Transparency = visible and 0 or 1
			d.LocalTransparencyModifier = visible and 0 or 1
			d.CastShadow = visible
		elseif d:IsA("Decal") then
			d.Transparency = visible and 0 or 1
		end
	end
end
-----------------------------------------------------------------
--  Helper: Hit-marker tween
-----------------------------------------------------------------
local function playHitmarkerTween(reticleGui)
	local hitmarker = reticleGui and reticleGui:FindFirstChild("Hitmarker")
	local scale     = hitmarker and hitmarker:FindFirstChild("UIScale")
	if not (hitmarker and scale) then return end

	hitmarker.GroupTransparency = 0
	scale.Scale = 2

	TweenService:Create(scale, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Scale = 1 }):Play()
	TweenService:Create(hitmarker, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{ GroupTransparency = 1 }):Play()
end

-----------------------------------------------------------------
--  Helper: Fade a frame & all text / images inside
-----------------------------------------------------------------
local function fadeFrame(frame, fadeIn, duration)
	local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(frame, tweenInfo, { BackgroundTransparency = fadeIn and 0 or 1 }):Play()
	for _, desc in ipairs(frame:GetDescendants()) do
		if desc:IsA("TextLabel") or desc:IsA("TextButton") or desc:IsA("TextBox") then
			TweenService:Create(desc, tweenInfo,
				{ TextTransparency = fadeIn and 0 or 1,
					TextStrokeTransparency = fadeIn and 0 or 1 }):Play()
		elseif desc:IsA("ImageLabel") or desc:IsA("ImageButton") then
			TweenService:Create(desc, tweenInfo,
				{ ImageTransparency = fadeIn and 0 or 1 }):Play()
		end
	end
end

-----------------------------------------------------------------
--  Helper: Fade all kill-cam visuals (except dark fade)
-----------------------------------------------------------------
local function fadeKillCam(gui, transparency)
	for _, d in ipairs(gui:GetDescendants()) do
		if d:IsA("ImageLabel") or d:IsA("ImageButton") then
			d.ImageTransparency = transparency
		elseif (d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox"))
			and d.Parent.Name ~= "DarkFade" then
			d.TextTransparency  = transparency
		end
	end
end

-----------------------------------------------------------------
--  Helper: Temporarily disable & restore player ScreenGuis
-----------------------------------------------------------------
-- GUI names that should not be disabled or restored
local guisToIgnore = {
	Coin = true,
	RotateGui = true,
	Taunt = true,
	Respawning = true,
	GameEnded = true
}

-- Disable all relevant GUIs and return a table with their previous states
local function disableAllScreenGuis(player)
	local playerGui = player:FindFirstChild("PlayerGui")
	if not playerGui then return {} end

	local savedStates = {}

	for _, gui in ipairs(playerGui:GetChildren()) do
		if gui:IsA("ScreenGui") and gui.Name ~= "Respawning" and gui.Name ~= "GameEnded" then
			savedStates[gui] = gui.Enabled
			gui.Enabled = false
		end
	end

	return savedStates
end

-- Restore GUI states using the saved table
local function restoreAllScreenGuis(savedStates)
	if type(savedStates) ~= "table" then
		warn("[KillReplayClient] restoreAllScreenGuis: invalid savedStates")
		return
	end

	for gui, wasEnabled in pairs(savedStates) do
		if gui and gui:IsA("ScreenGui") and not guisToIgnore[gui.Name] then
			gui.Enabled = wasEnabled
		end
	end
end


local reloadSoundsFolder = script:WaitForChild("Reload")

local function playReloadSounds()
	local order = { "MagOut", "MagIn", "Charger" }
	local index = 1
	local GAP   = 0.3            -- seconds between clips

	local function playNext()
		local sound = reloadSoundsFolder:FindFirstChild(order[index])
		if not sound then return end

		sound.TimePosition = 0     -- restart from beginning

		sound.Ended:Once(function()
			index += 1
			if index <= #order then
				task.delay(GAP, playNext)   -- <-- small gap before next sound
			end
		end)

		sound:Play()
	end

	playNext()
end

local function enableAttachments(humanRoot)

	local attachments = humanRoot.Attachment

	for _, attachment in pairs(attachments:GetChildren()) do
		attachment.Enabled = true
	end
	task.wait(3)
	for _, attachment in pairs(attachments:GetChildren()) do
		attachment.Enabled = false
	end

end


local isKillcamPlaying = false
-----------------------------------------------------------------
--  MAIN ENTRY: Receive replay data & play it back
-----------------------------------------------------------------
KillReplayRemote.OnClientEvent:Connect(function(killerName, killerReplay, victimReplay, isFinalKill, victimName, serverStartTime, playbackTime)

	-----------------------------------------------------------------
	-- sanity checks
	-----------------------------------------------------------------
	if not (killerReplay and victimReplay) or #killerReplay == 0 or #victimReplay == 0 then
		return
	end

	if isKillcamPlaying then
		warn("[KillReplayClient] Replay already playing — force resetting.")
		-- Force cleanup
		cam.CameraType = Enum.CameraType.Custom
		ReplicatedStorage.KillcamEnded:FireServer()
		isKillcamPlaying = false
	end
	
	
	isKillcamPlaying = true

	local isVictim = (player.Name == victimName)
	-----------------------------------------------------------------
	-- Initial GUI/visual prep
	-----------------------------------------------------------------
	local savedGuiStates = disableAllScreenGuis(player)
	if Lighting.Blur.Enabled then Lighting.Blur.Enabled = false end

	-- Hide killer character while replay runs
	local killerPlayer = Players:FindFirstChild(killerName)
	if killerPlayer and killerPlayer.Character then
		setCharVisible(killerPlayer.Character, false)
		for _, guiName in ipairs({ "NameGUI", "RankGUI" }) do
			local head = killerPlayer.Character:FindFirstChild("Head")
			local gui  = head and head:FindFirstChild(guiName)
			if gui then gui.Enabled = false end
		end
	end

	-- Clone reticle GUI for replay HUD
	local reticleGuiClone = BlasterFolder.Scripts.GuiController.ReticleGui:Clone()
	reticleGuiClone.Parent = player:WaitForChild("PlayerGui")
	local reticle = reticleGuiClone:FindFirstChild("Reticle")

	-- Grab kill-cam GUI
	local killCamGui     = player.PlayerGui:WaitForChild("KillCam")
	local respawnLabel   = killCamGui.Fade.Respawning
	local darkFade       = killCamGui.DarkFade
	local loadingText    = darkFade.KillCam
	local blankFade      = killCamGui.BlankFade


	local respawnGui   = player:WaitForChild("PlayerGui"):WaitForChild("Respawning")
	local frame        = respawnGui.RespawningFrame
	local rankImage    = frame.Rank
	local respText     = frame.respawning      -- label that says “Respawning…”
	local levelStatus  = frame.LevelStatus
	local rankStatus   = frame.RankStatus

	--------------------------------------------------------------------
	--  Bottom-left layout (Hunters-style)
	--------------------------------------------------------------------

	killCamGui.Enabled   = true

	if isFinalKill then
		killCamGui.KillCamRecorder.Killer.Text = "FINAL KILL BY " .. killerName:upper()
		loadingText.Text = "FINAL KILL CAM"
		respawnLabel.Text = "FINAL KILL"

		respawnGui.Enabled = false          -- spectators don’t need the panel

	else
		-- ▼ victim path – show bottom-left panel
		killCamGui.KillCamRecorder.Killer.Text = "KILLED BY " .. killerName:upper()
		loadingText.Text = "KILL CAM"

		respawnGui.Enabled = true           -- make the GUI appear

		frame.Position     = UDim2.fromScale(0.108, 0.708)
		frame.Size         = UDim2.fromScale(0.267, 0.268)

		rankImage.Position = UDim2.fromScale(0.5,  0.605)
		rankImage.Size     = UDim2.fromScale(0.129, 0.246)

		respText.Position  = UDim2.fromScale(0.5,  0.302)
		respText.Size      = UDim2.fromScale(0.706, 0.673)

		levelStatus.Position = UDim2.fromScale(0.5,  0.822)
		levelStatus.Size     = UDim2.fromScale(0.654, 0.116)

		rankStatus.Position  = UDim2.fromScale(0.5,  0.917)
		rankStatus.Size      = UDim2.fromScale(0.431, 0.078)

		-- countdown timer (optional)
		task.spawn(function()
			for i = 10, 0, -1 do
				respawnLabel.Text = "RESPAWNING IN " .. i
				task.wait(1)
			end
		end)
	end
	fadeFrame(darkFade, true, 1)      -- dark in
	task.wait(1.5)
	fadeKillCam(killCamGui, 0)        -- reveal
	fadeFrame(darkFade, false, 1)     -- dark out
	
	if isFinalKill and playbackTime and tick() < playbackTime then
		local delayTime = playbackTime - tick()
		print("[KillReplayClient] Waiting", delayTime, "seconds to sync final killcam...")
		task.wait(delayTime)
	end

	-----------------------------------------------------------------
	-- Prepare victim clone & effects
	-----------------------------------------------------------------
	if not (killerReplay and victimReplay) or #killerReplay == 0 or #victimReplay == 0 then
		warn("[KillReplayClient] Missing or empty replays")
		isKillcamPlaying = false
		return
	end
	
	if isVictim then
		local success, err = pcall(function()
			local victimChar = player.Character or player.CharacterAdded:Wait()
			if victimChar then
				victimChar:Destroy()
			end
		end)
		if not success then
			warn("[KillReplayClient] Failed to destroy character:", err)
		end
	end
	local victimFolder = ReplicatedStorage:WaitForChild("ReplayVictims")
	local originalClone = victimFolder:FindFirstChild(victimName)
	if not originalClone then
		warn("[KillReplayClient] No victim clone found for " .. tostring(victimName))

		-- Failsafe cleanup so GUI doesn’t get stuck
		cam.CameraType = Enum.CameraType.Custom
		killCamGui.Enabled = false
		respawnGui.Enabled = false
		restoreAllScreenGuis(savedGuiStates)
		ReplicatedStorage.KillcamEnded:FireServer()
		isKillcamPlaying = false
		return
	end
	local victimClone = originalClone:Clone()
	local hrp              = victimClone:WaitForChild("HumanoidRootPart")
	local head             = victimClone:WaitForChild("Head")

	local shotEffectClone  = BlasterFolder.Objects.CharacterImpact.ShotEffect:Clone()
	shotEffectClone.Enabled = false
	shotEffectClone.Parent  = hrp

	local youGuiClone      = youGui:Clone()
	youGuiClone.you.Text   = victimName
	youGuiClone.Parent     = head

	victimHighlight:Clone().Parent = victimClone
	victimClone.Parent             = workspace

	local acc = victimClone:FindFirstChildOfClass("Accessory")
	if acc and acc:FindFirstChild("Handle") then
		acc.Handle.Transparency = 0
	end

	local humanoid = victimClone:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.PlatformStand       = true
		humanoid.BreakJointsOnDeath  = true
		humanoid:ChangeState(Enum.HumanoidStateType.Physics)
		humanoid.Health              = humanoid.MaxHealth
		humanoid.Died:Connect(function()
			if acc then acc:Destroy() end
			youGuiClone:Destroy()
			task.spawn(function()
				enableAttachments(hrp)
			end)
		end)
	end

	-----------------------------------------------------------------
	-- Prepare view-model clone & animations
	-----------------------------------------------------------------
	cam.CameraType = Enum.CameraType.Scriptable

	local viewmodelClone = BlasterFolder.ViewModels.AutoBlaster:Clone()
	viewmodelClone.Name  = "ReplayViewmodel"
	viewmodelClone.Parent = workspace

	local animator          = viewmodelClone.AnimationController.Animator
	local animationsFolder  = viewmodelClone.Animations
	local animationTracks = {
		Idle  = animator:LoadAnimation(animationsFolder:WaitForChild("Idle")),
		Equip = animator:LoadAnimation(animationsFolder:WaitForChild("Equip")),
		Shoot = animator:LoadAnimation(animationsFolder:WaitForChild("Shoot")),
		Reload = animator:LoadAnimation(animationsFolder:WaitForChild("Reload"))
	}
	animationTracks.Idle:Play()
	animationTracks.Equip:Play(0)

	-- Grab muzzle attachment once for later beams
	local muzzleAttachment = viewmodelClone:FindFirstChild("MuzzleAttachment", true)
		or viewmodelClone:FindFirstChild("Muzzle", true)

	-----------------------------------------------------------------
	-- STATE FOR WEAPON BOBBING
	-----------------------------------------------------------------
	local stride        = 0       -- phase along sine wave
	local bobbing       = 0       -- 0-1 blended intensity
	local currentSpeed  = 0       -- last moveSpeed from replay frame

	-----------------------------------------------------------------
	-- Playback counters
	-----------------------------------------------------------------
	local clientStartTime = tick()
	local syncedOffset    = clientStartTime - serverStartTime
	local killerIndex     = 1
	local victimIndex     = 1
	local lastShootTime   = 0
	local lastReloadTime  = -math.huge   -- ← add this
	local shootCooldown   = 60 / 300  -- 300 RPM

	-- range fallback if constants don’t have one
	local DEFAULT_RANGE   = 600

	-----------------------------------------------------------------
	-- RENDER-STEPPED LOOP
	-----------------------------------------------------------------
	local connection
	connection = RunService.RenderStepped:Connect(function(deltaTime)
		-------------------------------------------------------------
		-- 1. Update bobbing parameters each frame
		-------------------------------------------------------------
		local bobbingSpeed  = currentSpeed * Constants.VIEW_MODEL_BOBBING_SPEED
		local targetBobbing = math.min(bobbingSpeed, 1)

		stride  = (stride + bobbingSpeed * deltaTime) % (math.pi * 2)
		bobbing = lerp(bobbing, targetBobbing,
			math.min(deltaTime * Constants.VIEW_MODEL_BOBBING_TRANSITION_SPEED, 1))

		local x          = math.sin(stride)
		local y          = math.sin(stride * 2)
		local bobOffset  = Vector3.new(x, y, 0) *
			Constants.VIEW_MODEL_BOBBING_AMOUNT * bobbing

		-------------------------------------------------------------
		-- 2. Advance replay timeline
		-------------------------------------------------------------
		local now         = tick()
		local elapsed     = now - clientStartTime
		local targetTime  = killerReplay[1].time + elapsed


		-- advance killer timeline
		while killerIndex <= #killerReplay
			and killerReplay[killerIndex].time <= targetTime do

			local kFrame = killerReplay[killerIndex]

			-- 2a) camera orientation
			if kFrame.camCFrame then
				cam.CFrame = kFrame.camCFrame
			end

			-- 2b) update move speed for bobbing
			if kFrame.moveSpeed then
				currentSpeed = kFrame.moveSpeed
			end

			-- 2c) handle weapon actions
			-----------------------------------------------------------------
			-- inside the while killerIndex … loop
			-----------------------------------------------------------------
			-- INSIDE the action-handling block (replace the current snippet)

			local action       = kFrame.action
			local isShot       = (action == "Shoot" or action == "Hit")
			local isHit        = (action == "Hit")

			-- NEW ▼ track reload cooldown so it can’t spam
			local isReload = (action == "Reload")
			local RELOAD_COOLDOWN = 1.0          -- seconds

			--------------------------------------------------------------
			-- 1) visual beam for shots / hits
			--------------------------------------------------------------
			if isShot and muzzleAttachment then
				local startPos = muzzleAttachment.WorldPosition
				local endPos   = isHit and hrp.Position
					or startPos + cam.CFrame.LookVector *
					(Constants.LASER_BEAM_MAX_RANGE or DEFAULT_RANGE)
				laserBeamEffect(startPos, endPos)
			end

			--------------------------------------------------------------
			-- 2) firing animation / SFX  (cool-down based)
			--------------------------------------------------------------
			if isShot and (now - lastShootTime) >= shootCooldown then
				animationTracks.Shoot:Play(0)
				GuiController:playReticleShootAnimation(reticle)
				playRandomShootSound()
				lastShootTime = now
			end

			--------------------------------------------------------------
			-- 3) reload animation (one-off, separate cool-down)
			--------------------------------------------------------------
			if isReload and (now - lastReloadTime) >= RELOAD_COOLDOWN then
				animationTracks.Reload:Play(0)
				playReloadSounds() 
				lastReloadTime = now
			end

			--------------------------------------------------------------
			-- 4) hitmarker & damage
			--------------------------------------------------------------
			if isHit then
				playHitmarkerTween(reticleGuiClone)
				spawnDamageEffect(hrp, 15)
				humanoid:TakeDamage(15)
				task.spawn(function()
					shotEffectClone.Enabled = true
					playRandomShootSound()
					task.wait(0.2)
					shotEffectClone.Enabled = false
					hitSound:Play()
				end)
			end


			killerIndex += 1
		end

		-- advance victim timeline (root cframe)
		while victimIndex < #victimReplay
			and victimReplay[victimIndex + 1].time <= targetTime do
			victimIndex += 1
		end

		local v1 = victimReplay[victimIndex]
		local v2 = victimReplay[victimIndex + 1]

		if v1 and v2 and v1.rootCFrame and v2.rootCFrame then
			local t0, t1 = v1.time, v2.time
			local alpha = (targetTime - t0) / (t1 - t0)
			alpha = math.clamp(alpha, 0, 1)

			local interpolated = v1.rootCFrame:Lerp(v2.rootCFrame, alpha)
			victimClone:PivotTo(interpolated)
		elseif v1 and v1.rootCFrame then
			victimClone:PivotTo(v1.rootCFrame)
		end


		-------------------------------------------------------------
		-- 3. Pivot view-model with bobbing offset
		-------------------------------------------------------------
		viewmodelClone:PivotTo(
			cam.CFrame
				* Constants.VIEW_MODEL_OFFSET
				* CFrame.new(bobOffset)
		)

		-------------------------------------------------------------
		-- 4. Finish replay?
		-------------------------------------------------------------
		if killerIndex > #killerReplay and victimIndex >= #victimReplay then
			connection:Disconnect()

			-- Restore camera & UI
			task.spawn(function()
				player.CharacterAdded:Wait()
				cam.CameraType = Enum.CameraType.Custom
			end)
			viewmodelClone:Destroy()
			victimClone:Destroy()
			reticleGuiClone:Destroy()

			fadeFrame(blankFade, true, 1)
			task.wait(1)
			fadeKillCam(killCamGui, 1)
			fadeFrame(blankFade, false, 1)
			task.wait(1)
			killCamGui.Enabled = false
			respawnGui.Enabled = false

			-- re-enable killer character visibility
			if killerPlayer and killerPlayer.Character then
				setCharVisible(killerPlayer.Character, true)
				for _, guiName in ipairs({ "NameGUI", "RankGUI" }) do
					local head = killerPlayer.Character:FindFirstChild("Head")
					local gui  = head and head:FindFirstChild(guiName)
					if gui then gui.Enabled = true end
				end
			end

			-- restore HUD
			restoreAllScreenGuis(savedGuiStates)

			-- notify server
			ReplicatedStorage.KillcamEnded:FireServer()

			isKillcamPlaying = false
		end
	end)
end)
