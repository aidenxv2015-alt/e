-- ROBLOX JUMPSCARE SCRIPT
-- Place this in StarterPlayer > StarterPlayerScripts as a LocalScript
-- Press "1" to trigger the scariest jumpscare!

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local playerGui = player:WaitForChild("PlayerGui")

local isScareActive = false

-- Create the GUI elements for the jumpscare
local function createScareGui()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "JumpscareGui"
	screenGui.DisplayOrder = 10
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui

	-- Red blood overlay
	local redOverlay = Instance.new("Frame")
	redOverlay.Name = "RedOverlay"
	redOverlay.Size = UDim2.new(1, 0, 1, 0)
	redOverlay.BackgroundColor3 = Color3.fromRGB(139, 0, 0)
	redOverlay.BackgroundTransparency = 1
	redOverlay.BorderSizePixel = 0
	redOverlay.ZIndex = 1
	redOverlay.Parent = screenGui

	-- Scary face/eyes image
	local scaryImage = Instance.new("ImageLabel")
	scaryImage.Name = "ScaryFace"
	scaryImage.Size = UDim2.new(0.8, 0, 0.8, 0)
	scaryImage.Position = UDim2.new(0.1, 0, 0.1, 0)
	scaryImage.BackgroundTransparency = 1
	scaryImage.ImageTransparency = 1
	scaryImage.Image = "rbxassetid://7359076847" -- Scary red eyes asset
	scaryImage.ScaleType = Enum.ScaleType.Fit
	scaryImage.ZIndex = 3
	scaryImage.Parent = screenGui

	-- Glitch overlay
	local glitchOverlay = Instance.new("Frame")
	glitchOverlay.Name = "GlitchOverlay"
	glitchOverlay.Size = UDim2.new(1, 0, 1, 0)
	glitchOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	glitchOverlay.BackgroundTransparency = 1
	glitchOverlay.BorderSizePixel = 0
	glitchOverlay.ZIndex = 2
	glitchOverlay.Parent = screenGui

	-- Creepy text
	local scaryText = Instance.new("TextLabel")
	scaryText.Name = "ScaryText"
	scaryText.Size = UDim2.new(1, 0, 0.2, 0)
	scaryText.Position = UDim2.new(0, 0, 0.4, 0)
	scaryText.BackgroundTransparency = 1
	scaryText.TextTransparency = 1
	scaryText.Text = "I SEE YOU"
	scaryText.Font = Enum.Font.Creepster
	scaryText.TextScaled = true
	scaryText.TextColor3 = Color3.fromRGB(255, 0, 0)
	scaryText.TextStrokeTransparency = 0
	scaryText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	scaryText.ZIndex = 4
	scaryText.Parent = screenGui

	return screenGui, redOverlay, scaryImage, glitchOverlay, scaryText
end

-- Camera shake effect
local function shakeCamera(intensity, duration)
	local originalCFrame = camera.CFrame
	local startTime = tick()

	while tick() - startTime < duration do
		local shake = CFrame.new(
			math.random(-intensity, intensity) / 10,
			math.random(-intensity, intensity) / 10,
			math.random(-intensity, intensity) / 10
		) * CFrame.Angles(
			math.rad(math.random(-intensity, intensity)),
			math.rad(math.random(-intensity, intensity)),
			math.rad(math.random(-intensity, intensity))
		)

		camera.CFrame = camera.CFrame * shake
		task.wait()
	end
end

-- Create jumpscare sound
local function createScareSound()
	local sound = Instance.new("Sound")
	sound.Name = "JumpscareSound"
	sound.SoundId = "rbxassetid://5567523008" -- Creepy scream sound
	sound.Volume = 1
	sound.Parent = camera

	local ambientSound = Instance.new("Sound")
	ambientSound.Name = "CreepyAmbient"
	ambientSound.SoundId = "rbxassetid://1837849285" -- Creepy ambient
	ambientSound.Volume = 0.7
	ambientSound.Looped = false
	ambientSound.Parent = camera

	return sound, ambientSound
end

-- The main scare function
local function triggerJumpscare()
	if isScareActive then return end
	isScareActive = true

	-- Create GUI elements
	local scareGui, redOverlay, scaryImage, glitchOverlay, scaryText = createScareGui()

	-- Create sounds
	local screamSound, ambientSound = createScareSound()

	-- Store original lighting
	local originalBrightness = Lighting.Brightness
	local originalAmbient = Lighting.Ambient
	local originalColorShift_Top = Lighting.ColorShift_Top

	-- Phase 1: Everything goes dark (0.5 seconds)
	Lighting.Brightness = 0
	Lighting.Ambient = Color3.fromRGB(0, 0, 0)
	task.wait(0.5)

	-- Phase 2: RED FLASH + SCREAM (instant)
	redOverlay.BackgroundTransparency = 0
	screamSound:Play()

	-- Start camera shake
	task.spawn(function()
		shakeCamera(20, 3)
	end)

	task.wait(0.1)

	-- Phase 3: Scary face appears with glitch effect
	ambientSound:Play()
	Lighting.ColorShift_Top = Color3.fromRGB(255, 0, 0)

	-- Glitch flickering
	for i = 1, 8 do
		glitchOverlay.BackgroundTransparency = math.random(0, 50) / 100
		scaryImage.ImageTransparency = math.random(20, 80) / 100
		task.wait(0.05)
	end

	-- Face fully appears
	scaryImage.ImageTransparency = 0
	task.wait(0.3)

	-- Scary text appears
	scaryText.TextTransparency = 0
	task.wait(0.5)

	-- Text changes
	local scaryMessages = {
		"I SEE YOU",
		"YOU CAN'T ESCAPE",
		"IT'S TOO LATE",
		"BEHIND YOU"
	}

	for _, message in ipairs(scaryMessages) do
		scaryText.Text = message
		task.wait(0.4)
	end

	-- Phase 4: Fade out
	local fadeTime = 2

	TweenService:Create(redOverlay, TweenInfo.new(fadeTime), {BackgroundTransparency = 1}):Play()
	TweenService:Create(scaryImage, TweenInfo.new(fadeTime), {ImageTransparency = 1}):Play()
	TweenService:Create(glitchOverlay, TweenInfo.new(fadeTime), {BackgroundTransparency = 1}):Play()
	TweenService:Create(scaryText, TweenInfo.new(fadeTime), {TextTransparency = 1}):Play()

	task.wait(fadeTime)

	-- Restore lighting
	Lighting.Brightness = originalBrightness
	Lighting.Ambient = originalAmbient
	Lighting.ColorShift_Top = originalColorShift_Top

	-- Cleanup
	scareGui:Destroy()
	screamSound:Destroy()
	ambientSound:Destroy()

	isScareActive = false
end

-- Input detection
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == Enum.KeyCode.One then
		print("JUMPSCARE ACTIVATED!")
		triggerJumpscare()
	end
end)

print("Scary Jumpscare Script Loaded! Press '1' if you dare...")
