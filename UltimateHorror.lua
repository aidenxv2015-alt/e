-- ULTIMATE ROBLOX HORROR NIGHTMARE SCRIPT
-- Place this in StarterPlayer > StarterPlayerScripts as a LocalScript
-- WARNING: Extremely scary - includes stalking shadow entity, reality distortion, psychological horror
-- Press "H" to trigger the NIGHTMARE MODE

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
local camera = workspace.CurrentCamera
local playerGui = player:WaitForChild("PlayerGui")

local isNightmareActive = false
local shadowEntity = nil

-- Creepy whisper messages that appear randomly
local whisperMessages = {
	"I'm watching you...",
	"Don't turn around...",
	"You're not alone...",
	"I'm getting closer...",
	"Can you hear me?",
	"Look behind you...",
	"I can see you breathing...",
	"You feel it too, don't you?",
	"It's almost time...",
	"Run.",
	"HE'S COMING",
	"There's something in the dark",
	"Did you hear that?",
	"Your heart is racing...",
	"I know where you are"
}

-- Create persistent GUI for horror effects
local function createHorrorGui()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "NightmareGui"
	screenGui.DisplayOrder = 10
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true
	screenGui.Parent = playerGui

	-- Vignette darkness that creeps in
	local vignette = Instance.new("ImageLabel")
	vignette.Name = "Vignette"
	vignette.Size = UDim2.new(1, 0, 1, 0)
	vignette.BackgroundTransparency = 1
	vignette.Image = "rbxassetid://6799184926" -- Dark vignette
	vignette.ImageTransparency = 1
	vignette.ImageColor3 = Color3.fromRGB(139, 0, 0)
	vignette.ZIndex = 1
	vignette.Parent = screenGui

	-- Static/noise overlay
	local staticOverlay = Instance.new("ImageLabel")
	staticOverlay.Name = "Static"
	staticOverlay.Size = UDim2.new(1, 0, 1, 0)
	staticOverlay.BackgroundTransparency = 1
	staticOverlay.Image = "rbxassetid://2708891598" -- TV static
	staticOverlay.ImageTransparency = 0.95
	staticOverlay.ZIndex = 5
	staticOverlay.Parent = screenGui

	-- Blood drip effect
	local bloodOverlay = Instance.new("ImageLabel")
	bloodOverlay.Name = "Blood"
	bloodOverlay.Size = UDim2.new(1, 0, 1, 0)
	bloodOverlay.Position = UDim2.new(0, 0, -1, 0)
	bloodOverlay.BackgroundTransparency = 1
	bloodOverlay.Image = "rbxassetid://305363164" -- Blood splatter
	bloodOverlay.ImageTransparency = 1
	bloodOverlay.ImageColor3 = Color3.fromRGB(139, 0, 0)
	bloodOverlay.ZIndex = 6
	bloodOverlay.Parent = screenGui

	-- Whisper text that fades in and out
	local whisperText = Instance.new("TextLabel")
	whisperText.Name = "Whisper"
	whisperText.Size = UDim2.new(0.8, 0, 0.15, 0)
	whisperText.Position = UDim2.new(0.1, 0, 0.1, 0)
	whisperText.BackgroundTransparency = 1
	whisperText.TextTransparency = 1
	whisperText.Text = ""
	whisperText.Font = Enum.Font.SourceSansSemibold
	whisperText.TextScaled = true
	whisperText.TextColor3 = Color3.fromRGB(255, 255, 255)
	whisperText.TextStrokeTransparency = 0.5
	whisperText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	whisperText.ZIndex = 7
	whisperText.Parent = screenGui

	-- Jump scare image holder
	local scareFrame = Instance.new("ImageLabel")
	scareFrame.Name = "ScareFrame"
	scareFrame.Size = UDim2.new(1, 0, 1, 0)
	scareFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	scareFrame.BackgroundTransparency = 1
	scareFrame.ImageTransparency = 1
	scareFrame.Image = "rbxassetid://7359076847" -- Scary eyes
	scareFrame.ScaleType = Enum.ScaleType.Crop
	scareFrame.ZIndex = 10
	scareFrame.Parent = screenGui

	-- Proximity warning
	local proximityWarning = Instance.new("TextLabel")
	proximityWarning.Name = "ProximityWarning"
	proximityWarning.Size = UDim2.new(1, 0, 0.1, 0)
	proximityWarning.Position = UDim2.new(0, 0, 0.85, 0)
	proximityWarning.BackgroundTransparency = 1
	proximityWarning.TextTransparency = 1
	proximityWarning.Text = "IT'S CLOSE..."
	proximityWarning.Font = Enum.Font.SourceSansBold
	proximityWarning.TextScaled = true
	proximityWarning.TextColor3 = Color3.fromRGB(255, 0, 0)
	proximityWarning.ZIndex = 8
	proximityWarning.Parent = screenGui

	-- Heartbeat visual
	local heartbeatFrame = Instance.new("Frame")
	heartbeatFrame.Name = "Heartbeat"
	heartbeatFrame.Size = UDim2.new(1, 0, 1, 0)
	heartbeatFrame.BackgroundColor3 = Color3.fromRGB(139, 0, 0)
	heartbeatFrame.BackgroundTransparency = 1
	heartbeatFrame.BorderSizePixel = 0
	heartbeatFrame.ZIndex = 9
	heartbeatFrame.Parent = screenGui

	return screenGui, vignette, staticOverlay, bloodOverlay, whisperText, scareFrame, proximityWarning, heartbeatFrame
end

-- Create ambient horror sounds
local function createHorrorSounds()
	local sounds = {}

	-- Heartbeat sound
	sounds.heartbeat = Instance.new("Sound")
	sounds.heartbeat.Name = "Heartbeat"
	sounds.heartbeat.SoundId = "rbxassetid://2865227271"
	sounds.heartbeat.Volume = 0
	sounds.heartbeat.Looped = true
	sounds.heartbeat.Parent = camera

	-- Whispers
	sounds.whispers = Instance.new("Sound")
	sounds.whispers.Name = "Whispers"
	sounds.whispers.SoundId = "rbxassetid://5396480890"
	sounds.whispers.Volume = 0.3
	sounds.whispers.Looped = true
	sounds.whispers.Parent = camera

	-- Ambient drone
	sounds.drone = Instance.new("Sound")
	sounds.drone.Name = "Drone"
	sounds.drone.SoundId = "rbxassetid://9120386436"
	sounds.drone.Volume = 0.4
	sounds.drone.Looped = true
	sounds.drone.Parent = camera

	-- Footsteps approaching
	sounds.footsteps = Instance.new("Sound")
	sounds.footsteps.Name = "Footsteps"
	sounds.footsteps.SoundId = "rbxassetid://3398620867"
	sounds.footsteps.Volume = 0
	sounds.footsteps.Looped = true
	sounds.footsteps.Parent = camera

	-- Scream for jumpscare
	sounds.scream = Instance.new("Sound")
	sounds.scream.Name = "Scream"
	sounds.scream.SoundId = "rbxassetid://5567523008"
	sounds.scream.Volume = 1
	sounds.scream.Parent = camera

	-- Distorted breathing
	sounds.breathing = Instance.new("Sound")
	sounds.breathing.Name = "Breathing"
	sounds.breathing.SoundId = "rbxassetid://2865228021"
	sounds.breathing.Volume = 0.5
	sounds.breathing.Looped = true
	sounds.breathing.Parent = camera

	return sounds
end

-- Create invisible shadow entity that stalks the player
local function createShadowEntity()
	local entity = Instance.new("Part")
	entity.Name = "ShadowEntity"
	entity.Size = Vector3.new(4, 7, 2)
	entity.Transparency = 0.7
	entity.Color = Color3.fromRGB(0, 0, 0)
	entity.Material = Enum.Material.ForceField
	entity.CanCollide = false
	entity.Anchored = false
	entity.CastShadow = false

	local bodyPosition = Instance.new("BodyPosition")
	bodyPosition.MaxForce = Vector3.new(40000, 40000, 40000)
	bodyPosition.P = 10000
	bodyPosition.Parent = entity

	-- Creepy particles
	local particles = Instance.new("ParticleEmitter")
	particles.Texture = "rbxasset://textures/particles/smoke_main.dds"
	particles.Color = ColorSequence.new(Color3.fromRGB(0, 0, 0))
	particles.Size = NumberSequence.new(2)
	particles.Transparency = NumberSequence.new(0.5)
	particles.Lifetime = NumberRange.new(1, 2)
	particles.Rate = 20
	particles.Speed = NumberRange.new(1)
	particles.Parent = entity

	-- Red glowing eyes
	local leftEye = Instance.new("Part")
	leftEye.Size = Vector3.new(0.3, 0.3, 0.3)
	leftEye.Shape = Enum.PartType.Ball
	leftEye.Color = Color3.fromRGB(255, 0, 0)
	leftEye.Material = Enum.Material.Neon
	leftEye.CanCollide = false
	leftEye.CastShadow = false

	local leftWeld = Instance.new("WeldConstraint")
	leftWeld.Part0 = entity
	leftWeld.Part1 = leftEye
	leftEye.Parent = entity
	leftWeld.Parent = leftEye

	local rightEye = leftEye:Clone()
	rightEye.Parent = entity

	entity.Parent = workspace

	return entity, bodyPosition
end

-- Camera effects
local function shakeCamera(intensity, duration)
	local startTime = tick()
	local connection

	connection = RunService.RenderStepped:Connect(function()
		if tick() - startTime > duration then
			connection:Disconnect()
			return
		end

		camera.CFrame = camera.CFrame * CFrame.new(
			math.random(-intensity, intensity) / 100,
			math.random(-intensity, intensity) / 100,
			math.random(-intensity, intensity) / 100
		) * CFrame.Angles(
			math.rad(math.random(-intensity, intensity) / 10),
			math.rad(math.random(-intensity, intensity) / 10),
			math.rad(math.random(-intensity, intensity) / 10)
		)
	end)
end

-- Distort camera FOV for disorientation
local function distortVision(duration)
	local originalFOV = camera.FieldOfView
	local startTime = tick()

	task.spawn(function()
		while tick() - startTime < duration do
			local targetFOV = originalFOV + math.sin(tick() * 5) * 20
			camera.FieldOfView = targetFOV
			task.wait()
		end
		camera.FieldOfView = originalFOV
	end)
end

-- Flicker lights
local function flickerLights(duration)
	local originalBrightness = Lighting.Brightness
	local originalAmbient = Lighting.Ambient
	local startTime = tick()

	task.spawn(function()
		while tick() - startTime < duration do
			if math.random() > 0.7 then
				Lighting.Brightness = 0
				Lighting.Ambient = Color3.fromRGB(0, 0, 0)
				task.wait(math.random(1, 10) / 100)
			else
				Lighting.Brightness = originalBrightness * math.random(30, 100) / 100
				Lighting.Ambient = originalAmbient
				task.wait(math.random(5, 30) / 100)
			end
		end

		Lighting.Brightness = originalBrightness
		Lighting.Ambient = originalAmbient
	end)
end

-- Show random whispers
local function showWhisper(whisperText)
	task.spawn(function()
		whisperText.Text = whisperMessages[math.random(1, #whisperMessages)]
		whisperText.Position = UDim2.new(
			math.random(10, 50) / 100,
			0,
			math.random(10, 80) / 100,
			0
		)

		TweenService:Create(whisperText, TweenInfo.new(1), {TextTransparency = 0}):Play()
		task.wait(3)
		TweenService:Create(whisperText, TweenInfo.new(1), {TextTransparency = 1}):Play()
	end)
end

-- Shadow entity AI - stalks the player from behind
local function updateShadowEntity(entity, bodyPosition, sounds, proximityWarning, heartbeatFrame)
	local lastJumpscareTime = 0

	task.spawn(function()
		while isNightmareActive and entity do
			-- Position behind player at varying distances
			local distance = math.random(20, 50)
			local offsetAngle = math.rad(math.random(-45, 45))

			-- Stay in shadows behind player
			local behindVector = -humanoidRootPart.CFrame.LookVector
			behindVector = CFrame.new(Vector3.new(0, 0, 0)) * CFrame.Angles(0, offsetAngle, 0) * behindVector

			local targetPosition = humanoidRootPart.Position + behindVector * distance + Vector3.new(0, 2, 0)
			bodyPosition.Position = targetPosition

			-- Face the player
			entity.CFrame = CFrame.new(entity.Position, humanoidRootPart.Position)

			-- Calculate distance to player
			local distanceToPlayer = (entity.Position - humanoidRootPart.Position).Magnitude

			-- Update heartbeat and footsteps based on proximity
			sounds.heartbeat.Volume = math.clamp((50 - distanceToPlayer) / 50, 0, 0.8)
			sounds.footsteps.Volume = math.clamp((40 - distanceToPlayer) / 40, 0, 0.6)

			-- Show proximity warning when close
			if distanceToPlayer < 30 then
				proximityWarning.TextTransparency = 0.3 + math.sin(tick() * 5) * 0.3

				-- Heartbeat visual pulse
				heartbeatFrame.BackgroundTransparency = 0.7 + math.sin(tick() * 8) * 0.3

				-- Camera shake when very close
				if distanceToPlayer < 20 then
					shakeCamera(2, 0.1)
				end
			else
				proximityWarning.TextTransparency = 1
				heartbeatFrame.BackgroundTransparency = 1
			end

			-- Occasionally get much closer for jump scare
			if distanceToPlayer < 15 and tick() - lastJumpscareTime > 30 then
				lastJumpscareTime = tick()
				bodyPosition.Position = humanoidRootPart.Position + humanoidRootPart.CFrame.LookVector * -5

				-- Jumpscare after a delay
				task.wait(0.5)
				sounds.scream:Play()
				shakeCamera(30, 1)
			end

			task.wait(0.5)
		end
	end)
end

-- Main nightmare sequence
local function activateNightmare()
	if isNightmareActive then return end
	isNightmareActive = true

	print("=================================")
	print("NIGHTMARE MODE ACTIVATED")
	print("THE HORROR HAS BEGUN...")
	print("=================================")

	-- Create all horror elements
	local gui, vignette, staticOverlay, bloodOverlay, whisperText, scareFrame, proximityWarning, heartbeatFrame = createHorrorGui()
	local sounds = createHorrorSounds()

	-- Store original lighting
	local originalBrightness = Lighting.Brightness
	local originalAmbient = Lighting.Ambient
	local originalColorShift = Lighting.ColorShift_Top
	local originalClockTime = Lighting.ClockTime

	-- Phase 1: Reality starts breaking down
	TweenService:Create(Lighting, TweenInfo.new(5), {
		ClockTime = 0,
		Brightness = 0.5,
		Ambient = Color3.fromRGB(10, 0, 15)
	}):Play()

	TweenService:Create(vignette, TweenInfo.new(5), {ImageTransparency = 0.3}):Play()

	task.wait(3)

	-- Start ambient sounds
	sounds.drone:Play()
	sounds.whispers:Play()
	sounds.breathing:Play()
	sounds.heartbeat:Play()
	sounds.footsteps:Play()

	-- Phase 2: The entity appears
	task.wait(2)
	shadowEntity, bodyPosition = createShadowEntity()
	shadowEntity.Position = humanoidRootPart.Position + humanoidRootPart.CFrame.LookVector * -30 + Vector3.new(0, 2, 0)

	-- Start entity stalking behavior
	updateShadowEntity(shadowEntity, bodyPosition, sounds, proximityWarning, heartbeatFrame)

	-- Phase 3: Random horror events
	task.spawn(function()
		while isNightmareActive do
			local eventRoll = math.random(1, 5)

			if eventRoll == 1 then
				-- Whisper appears
				showWhisper(whisperText)
			elseif eventRoll == 2 then
				-- Light flicker
				flickerLights(math.random(2, 5))
			elseif eventRoll == 3 then
				-- Vision distortion
				distortVision(math.random(3, 6))
			elseif eventRoll == 4 then
				-- Blood drip
				bloodOverlay.Position = UDim2.new(0, 0, -1, 0)
				bloodOverlay.ImageTransparency = 0
				TweenService:Create(bloodOverlay, TweenInfo.new(2), {
					Position = UDim2.new(0, 0, 0, 0)
				}):Play()
				task.wait(3)
				TweenService:Create(bloodOverlay, TweenInfo.new(2), {ImageTransparency = 1}):Play()
			elseif eventRoll == 5 then
				-- Static burst
				staticOverlay.ImageTransparency = 0.7
				task.wait(0.1)
				staticOverlay.ImageTransparency = 0.95
			end

			task.wait(math.random(5, 15))
		end
	end)

	-- Phase 4: Increase intensity over time
	task.spawn(function()
		local startTime = tick()
		while isNightmareActive do
			local elapsedTime = tick() - startTime

			-- Darkness increases
			local vignetteTarget = 0.3 + (elapsedTime / 120) * 0.5
			TweenService:Create(vignette, TweenInfo.new(2), {
				ImageTransparency = math.clamp(1 - vignetteTarget, 0.1, 1)
			}):Play()

			-- World becomes more red
			Lighting.ColorShift_Top = Color3.fromRGB(
				math.clamp(elapsedTime * 2, 0, 255),
				0,
				0
			)

			task.wait(5)
		end
	end)

	-- Ultimate jumpscare after 60 seconds
	task.wait(60)

	-- FINAL CLIMAX JUMPSCARE
	print("=================================")
	print("IT'S HERE")
	print("=================================")

	-- Everything goes black
	Lighting.Brightness = 0
	Lighting.Ambient = Color3.fromRGB(0, 0, 0)
	scareFrame.BackgroundTransparency = 0
	staticOverlay.ImageTransparency = 0.5

	task.wait(1)

	-- MASSIVE JUMPSCARE
	scareFrame.ImageTransparency = 0
	scareFrame.BackgroundTransparency = 1
	sounds.scream:Play()
	shakeCamera(50, 2)

	-- Strobe effect
	for i = 1, 10 do
		scareFrame.ImageTransparency = 0
		task.wait(0.05)
		scareFrame.ImageTransparency = 1
		task.wait(0.05)
	end

	scareFrame.ImageTransparency = 0
	whisperText.Text = "YOU ARE NOT SAFE"
	whisperText.TextTransparency = 0
	whisperText.TextScaled = true
	whisperText.Position = UDim2.new(0.1, 0, 0.45, 0)

	task.wait(3)

	-- Fade out
	TweenService:Create(scareFrame, TweenInfo.new(3), {ImageTransparency = 1, BackgroundTransparency = 1}):Play()
	TweenService:Create(whisperText, TweenInfo.new(3), {TextTransparency = 1}):Play()
	TweenService:Create(vignette, TweenInfo.new(3), {ImageTransparency = 1}):Play()

	task.wait(3)

	-- Cleanup
	isNightmareActive = false

	Lighting.Brightness = originalBrightness
	Lighting.Ambient = originalAmbient
	Lighting.ColorShift_Top = originalColorShift
	Lighting.ClockTime = originalClockTime

	for _, sound in pairs(sounds) do
		sound:Stop()
		sound:Destroy()
	end

	if shadowEntity then
		shadowEntity:Destroy()
	end

	gui:Destroy()

	print("The nightmare has ended... for now.")
end

-- Activation input
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == Enum.KeyCode.H then
		print("=================================")
		print("INITIATING NIGHTMARE PROTOCOL...")
		print("=================================")
		task.wait(1)
		activateNightmare()
	end
end)

print("======================================")
print("ULTIMATE HORROR SCRIPT LOADED")
print("Press 'H' to begin the nightmare...")
print("WARNING: This will be terrifying")
print("======================================")
