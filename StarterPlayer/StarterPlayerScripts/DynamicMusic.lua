
--  Props-only Music Controller  ·  Random Sneaky & Chase

local Players         = game:GetService("Players")
local lp = Players.LocalPlayer
local RunService      = game:GetService("RunService")
local TweenService    = game:GetService("TweenService")
local ContentProvider = game:GetService("ContentProvider")
local RandomGen       = Random.new()

--▼ Tuning
local MOVE_EPS, FADE_TIME  = 0.05, 0.6
local CHASE_COOLDOWN       = 6
local FALLBACK_VOL         = 0.8

--▼ Music folders
local sneakyFolder = workspace:WaitForChild("SneakyMusic")
local chaseFolder  = workspace:WaitForChild("ChaseMusic")

--───────────────────────────────────────────────────────
--  PRE-LOAD every Sound asset
--───────────────────────────────────────────────────────

do
	local ids = {}
	for _, folder in ipairs({ sneakyFolder, chaseFolder }) do
		for _, s in ipairs(folder:GetChildren()) do
			if s:IsA("Sound") then ids[#ids+1] = s.SoundId end
		end
	end
	if #ids > 0 then pcall(ContentProvider.PreloadAsync, ContentProvider, ids) end
end

--───────────────────────────────────────────────────────
--  Tween helpers & random pickers
--───────────────────────────────────────────────────────

local activeTween = {} -- [Sound] = Tween

local function cancelTween(s)
	local t = activeTween[s]
	if t and t.PlaybackState ~= Enum.PlaybackState.Completed then
		t:Cancel()
	end
	activeTween[s] = nil
end

local function fade(s, toVol, onDone)
	cancelTween(s)
	local t = TweenService:Create(s, TweenInfo.new(FADE_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Volume = toVol })
	if onDone then t.Completed:Once(onDone) end
	activeTween[s] = t
	t:Play()
end

local function fadeIn(s, targetVol)
	cancelTween(s)

	if not s.IsPlaying then
		s.Volume = 0
		if s.TimePosition > 0 then
			s:Resume()
		else
			s:Play()
		end
	elseif math.abs(s.Volume - targetVol) < 0.05 then
		return
	end

	fade(s, targetVol)
end

local function fadeOutPause(s)
	if s and s.IsPlaying then
		cancelTween(s)
		local t = TweenService:Create(s, TweenInfo.new(FADE_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Volume = 0 })
		t.Completed:Once(function()
			if s and s.Volume == 0 then s:Pause() end
			activeTween[s] = nil
		end)
		activeTween[s] = t
		t:Play()
	end
end

local function pickRandom(folder)
	local t = {}
	for _, s in ipairs(folder:GetChildren()) do
		if s:IsA("Sound") then t[#t+1] = s end
	end
	return (#t > 0) and t[RandomGen:NextInteger(1, #t)] or nil
end

--───────────────────────────────────────────────────────
--  Per-character watcher
--───────────────────────────────────────────────────────

local function createWatcher(char)
	local humanoid = char:WaitForChild("Humanoid")
	local moving, chaseActive, dead = false, false, false
	local lastHit, lastHealth = 0, humanoid.Health
	local sneakySound = pickRandom(sneakyFolder)
	local chaseSound

	humanoid.Died:Connect(function()
		dead = true
		fadeOutPause(sneakySound)
		fadeOutPause(chaseSound)
		sneakySound = nil
		chaseSound = nil
	end)

	local hConn = humanoid:GetPropertyChangedSignal("Health"):Connect(function()
		if dead then return end

		local hp = humanoid.Health
		if hp < lastHealth then                                -- took damage
			----------------------------------------------------------------
			--  ▶▶ new filter: was it inflicted by another player?
			----------------------------------------------------------------
			local tag    = char:FindFirstChild("creator")
			local killer = tag and tag.Value
			local fromPlayer = killer and killer:IsA("Player") and killer ~= lp

			if fromPlayer then
				------------------------------------------------------------
				-- same chase-start logic you already had
				------------------------------------------------------------
				lastHit = tick()
				fadeOutPause(sneakySound)

				if not chaseActive or not (chaseSound and chaseSound.IsPlaying) then
					chaseActive = true
					fadeOutPause(chaseSound)
					chaseSound = pickRandom(chaseFolder)
					if chaseSound then
						chaseSound.TimePosition = 0
						fadeIn(chaseSound,
							(chaseSound.Volume == 0) and FALLBACK_VOL or chaseSound.Volume)
					end
				end
			end
			-- if damage came from fall, NPC, or self-harm, do nothing
		end

		lastHealth = hp
	end)

	local sConn
	sConn = RunService.RenderStepped:Connect(function()
		if dead or not humanoid.Parent then hConn:Disconnect(); sConn:Disconnect(); return end

		if chaseActive and tick() - lastHit > CHASE_COOLDOWN then
			chaseActive = false
			fadeOutPause(chaseSound)
			chaseSound = nil
			if moving then
				if sneakySound then
					fadeIn(sneakySound, FALLBACK_VOL)
				else
					sneakySound = pickRandom(sneakyFolder)
					if sneakySound then
						fadeIn(sneakySound, FALLBACK_VOL)
					end
				end
			end
		end

		local nowMoving = humanoid.MoveDirection.Magnitude > MOVE_EPS
		if nowMoving and not moving then
			moving = true
			if not chaseActive and sneakySound and sneakySound.Volume < FALLBACK_VOL - 0.05 then
				fadeIn(sneakySound, FALLBACK_VOL)
			end
		elseif not nowMoving and moving then
			moving = false
			fadeOutPause(sneakySound)
		end
	end)

	return function()
		hConn:Disconnect()
		sConn:Disconnect()
		fadeOutPause(sneakySound)
		fadeOutPause(chaseSound)
	end
end

--───────────────────────────────────────────────────────
--  Attach / detach driven by Team changes
--───────────────────────────────────────────────────────

local propsTeam = game.Teams.Props
local charConn
local cleanup = {}

local function clearWatchers()
	for _, fn in ipairs(cleanup) do pcall(fn) end
	table.clear(cleanup)
end

local function detachAll()
	clearWatchers()
	if charConn then charConn:Disconnect(); charConn = nil end
end

local function attachWatchersForCurrentCharacter()
	clearWatchers()
	if lp.Character then
		cleanup[#cleanup + 1] = createWatcher(lp.Character)
	end
end

local function enableForProps()
	detachAll()
	attachWatchersForCurrentCharacter()
	charConn = lp.CharacterAdded:Connect(function(char)
		clearWatchers()
		if lp.Team == propsTeam then
			cleanup[#cleanup + 1] = createWatcher(char)
		end
	end)
end

if lp.Team == propsTeam then enableForProps() end

lp:GetPropertyChangedSignal("Team"):Connect(function()
	if lp.Team == propsTeam then
		enableForProps()
	else
		detachAll()
	end
end)
