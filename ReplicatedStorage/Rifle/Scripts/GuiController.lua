local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Constants = require(ReplicatedStorage.Blaster.Constants)
local InputCategorizer = require(script.Parent.InputCategorizer)
local disconnectAndClear = require(ReplicatedStorage.Utility.disconnectAndClear)
local playSoundFromSource = require(ReplicatedStorage.Blaster.Utility.playSoundFromSource)

local player = Players.LocalPlayer
local reticleGuiTemplate = script.ReticleGui
local hitmarkerSound = script.Hitmarker
local audioTarget = SoundService.Audio.Busses.UI.AudioCompressor

local GuiController = {}
GuiController.__index = GuiController

function GuiController.new(blaster: Tool)
	local reticleGui = reticleGuiTemplate:Clone()
	reticleGui.Enabled = false
	reticleGui.Parent = player.PlayerGui

	local scaleTweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	local transparencyTweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	local hitmarkerScaleTween = TweenService:Create(reticleGui.Hitmarker.UIScale, scaleTweenInfo, { Scale = 1 })
	local hitmarkerTransparencyTween =
		TweenService:Create(reticleGui.Hitmarker, transparencyTweenInfo, { GroupTransparency = 1 })

	local self = {
		blaster = blaster,
		reticleGui = reticleGui,
		hitmarkerScaleTween = hitmarkerScaleTween,
		hitmarkerTransparencyTween = hitmarkerTransparencyTween,
		enabled = false,
		connections = {},
	}
	setmetatable(self, GuiController)
	return self
end

function GuiController:showHitmarker()
	-- Slightly delay the hitmarker sound so it doesn't overlap the shooting sound
	task.delay(Constants.HITMARKER_SOUND_DELAY, function()
		playSoundFromSource(hitmarkerSound, audioTarget)
	end)

	if self.hitmarkerScaleTween.PlaybackState == Enum.PlaybackState.Playing then
		self.hitmarkerScaleTween:Cancel()
	end
	if self.hitmarkerTransparencyTween.PlaybackState == Enum.PlaybackState.Playing then
		self.hitmarkerTransparencyTween:Cancel()
	end

	self.reticleGui.Hitmarker.GroupTransparency = 0
	self.reticleGui.Hitmarker.UIScale.Scale = 2

	self.hitmarkerScaleTween:Play()
	self.hitmarkerTransparencyTween:Play()
end

function GuiController:playReticleShootAnimation(reticle)
	-- Define tween settings
	local tweenOutInfo = TweenInfo.new(0.1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
	local tweenInInfo = TweenInfo.new(0.1, Enum.EasingStyle.Sine, Enum.EasingDirection.In)

	-- How far each piece moves outward (in pixels)
	local offset = 6

	-- Define original positions of each reticle part
	local originalPositions = {
		Top = UDim2.new(0.5, 0, 0, 0),
		Right = UDim2.new(1, 0, 0.5, 0),
		Bottom = UDim2.new(0.5, 0, 1, 0),
		Left = UDim2.new(0, 0, 0.5, 0),
	}

	for sideName, defaultPos in pairs(originalPositions) do
		local side = reticle:FindFirstChild(sideName)
		if side then
			-- Determine expanded position based on side
			local expandedPos
			if sideName == "Top" then
				expandedPos = defaultPos - UDim2.fromOffset(0, offset)
			elseif sideName == "Bottom" then
				expandedPos = defaultPos + UDim2.fromOffset(0, offset)
			elseif sideName == "Left" then
				expandedPos = defaultPos - UDim2.fromOffset(offset, 0)
			elseif sideName == "Right" then
				expandedPos = defaultPos + UDim2.fromOffset(offset, 0)
			end

			-- Tween out (expand)
			local tweenOut = TweenService:Create(side, tweenOutInfo, { Position = expandedPos })

			-- Tween back in (return to original)
			local tweenIn = TweenService:Create(side, tweenInInfo, { Position = defaultPos })

			-- Play both in sequence
			tweenOut:Play()
			tweenOut.Completed:Connect(function()
				tweenIn:Play()
			end)
		end
	end
end


function GuiController:enable()
	if self.enabled then
		return
	end
	self.enabled = true
	self.reticleGui.Enabled = true

	UserInputService.MouseIconEnabled = false
end

function GuiController:disable()
	if not self.enabled then
		return
	end
	self.enabled = false
	self.reticleGui.Enabled = false

	UserInputService.MouseIconEnabled = true
end

function GuiController:destroy()
	self:disable()
	disconnectAndClear(self.connections)
	self.reticleGui:Destroy()
end

return GuiController