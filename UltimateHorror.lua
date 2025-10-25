-- ULTIMATE ROBLOX HORROR NIGHTMARE SCRIPT
-- Place this in StarterPlayer > StarterPlayerScripts as a LocalScript
-- WARNING: Extremely scary - includes stalking shadow entity, reality distortion, psychological horror
-- The entity will hunt you down. If it catches you, your SOUL will be ripped from your body!
-- You'll become a GHOST and can possess other players by holding E for 30 seconds!
-- Press "H" to trigger the NIGHTMARE MODE

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
local camera = workspace.CurrentCamera
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for RemoteEvents from server
local remoteFolder = ReplicatedStorage:WaitForChild("HorrorRemotes", 10)
local becomeGhostEvent, startPossessionEvent, completePossessionEvent, cancelPossessionEvent
local forceWalkEvent, grantControlEvent, transformToFakeHumanEvent

if remoteFolder then
	becomeGhostEvent = remoteFolder:WaitForChild("BecomeGhost", 5)
	startPossessionEvent = remoteFolder:WaitForChild("StartPossession", 5)
	completePossessionEvent = remoteFolder:WaitForChild("CompletePossession", 5)
	cancelPossessionEvent = remoteFolder:WaitForChild("CancelPossession", 5)
	forceWalkEvent = remoteFolder:WaitForChild("ForceWalk", 5)
	grantControlEvent = remoteFolder:WaitForChild("GrantControl", 5)
	transformToFakeHumanEvent = remoteFolder:WaitForChild("TransformToFakeHuman", 5)
else
	warn("HorrorRemotes folder not found! Make sure server script is loaded.")
end

local isNightmareActive = false
local shadowEntity = nil
local isGhost = false
local isPossessing = false
local possessedPlayer = nil
local isFakeHuman = false
local isBeingForced = false
local forceWalkConnection = nil

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

-- Create ghost form after death
local function becomeGhost()
	isGhost = true
	isNightmareActive = false -- End nightmare mode

	print("=================================")
	print("YOU ARE NOW A GHOST")
	print("Haunt other players and POSSESS them!")
	print("=================================")

	-- Clean up nightmare elements
	if shadowEntity then
		shadowEntity:Destroy()
		shadowEntity = nil
	end

	-- Change lighting to ghost realm atmosphere (client-side)
	Lighting.Brightness = 0.3
	Lighting.Ambient = Color3.fromRGB(50, 50, 70)
	Lighting.ColorShift_Top = Color3.fromRGB(100, 100, 150)

	-- Clean up horror GUI but keep minimal atmosphere
	local nightmareGui = playerGui:FindFirstChild("NightmareGui")
	if nightmareGui then
		-- Remove most elements but keep vignette for atmosphere
		local vignette = nightmareGui:FindFirstChild("Vignette")
		for _, child in pairs(nightmareGui:GetChildren()) do
			if child ~= vignette then
				child:Destroy()
			end
		end
	end

	-- IMPORTANT: Make sure your own prompt stays disabled even as a ghost
	task.spawn(function()
		task.wait(1)
		if humanoidRootPart then
			local prompt = humanoidRootPart:FindFirstChild("PossessionPrompt")
			if prompt then
				prompt.Enabled = false
				print("Ensured your prompt is disabled as a ghost")
			end
		end
	end)

	-- Tell server we became a ghost (server will handle visual transformation and prompts)
	if becomeGhostEvent then
		becomeGhostEvent:FireServer()
	else
		warn("Cannot become ghost - RemoteEvent not found!")
	end

	-- Add ghostly sound (client-side only)
	local ghostSound = Instance.new("Sound")
	ghostSound.Name = "GhostlyWhisper"
	ghostSound.SoundId = "rbxassetid://5396480890"
	ghostSound.Volume = 0.5
	ghostSound.Looped = true
	ghostSound.Parent = camera
	ghostSound:Play()

	print("You are now in the spirit realm...")
	print("Hunt other players as a ghost!")
	print("You can still only possess OTHER players!")
end

-- Listen for server events telling us someone is trying to possess us
if startPossessionEvent then
	startPossessionEvent.OnClientEvent:Connect(function(ghostPlayerName)
		beginPossessionEffects(ghostPlayerName)
	end)
end

if cancelPossessionEvent then
	cancelPossessionEvent.OnClientEvent:Connect(function()
		endPossessionEffects()
	end)
end

if completePossessionEvent then
	completePossessionEvent.OnClientEvent:Connect(function(targetPlayer)
		completePossession(targetPlayer)
	end)
end

-- Handle forced walk toward ghost
if forceWalkEvent then
	forceWalkEvent.OnClientEvent:Connect(function(ghostPlayer)
		forceWalkTowardGhost(ghostPlayer)
	end)
end

-- Handle 60 second control grant
if grantControlEvent then
	grantControlEvent.OnClientEvent:Connect(function(targetPlayer)
		grantControlOfPlayer(targetPlayer)
	end)
end

-- Handle transformation to fake human
if transformToFakeHumanEvent then
	transformToFakeHumanEvent.OnClientEvent:Connect(function()
		transformToFakeHuman()
	end)
end

-- Start possession effects on target player (they see this)
local function beginPossessionEffects(ghostPlayerName)
	-- This runs on the target player's client when someone tries to possess them
	print(ghostPlayerName .. " is trying to possess you!")

	-- Create possession warning GUI
	local possessionGui = Instance.new("ScreenGui")
	possessionGui.Name = "PossessionWarning"
	possessionGui.DisplayOrder = 100
	possessionGui.Parent = playerGui

	local warningText = Instance.new("TextLabel")
	warningText.Size = UDim2.new(0.8, 0, 0.2, 0)
	warningText.Position = UDim2.new(0.1, 0, 0.4, 0)
	warningText.BackgroundTransparency = 1
	warningText.Text = "YOU'RE GETTING POSSESSED BY " .. ghostPlayerName:upper()
	warningText.Font = Enum.Font.SourceSansBold
	warningText.TextScaled = true
	warningText.TextColor3 = Color3.fromRGB(255, 0, 0)
	warningText.TextStrokeTransparency = 0
	warningText.ZIndex = 100
	warningText.Parent = possessionGui

	-- Freeze player
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = 0
		humanoid.JumpPower = 0
	end

	-- Trippy visual effects
	task.spawn(function()
		local originalFOV = camera.FieldOfView
		local startTime = tick()

		while tick() - startTime < 30 and possessionGui.Parent do
			-- Crazy FOV changes
			camera.FieldOfView = originalFOV + math.sin(tick() * 10) * 30

			-- Random camera rotations
			camera.CFrame = camera.CFrame * CFrame.Angles(
				math.rad(math.random(-5, 5)),
				math.rad(math.random(-5, 5)),
				math.rad(math.random(-5, 5))
			)

			-- Flicker text
			warningText.TextColor3 = Color3.fromRGB(
				math.random(200, 255),
				math.random(0, 50),
				math.random(0, 50)
			)

			task.wait()
		end

		camera.FieldOfView = originalFOV
	end)

	-- Color correction for trippy effect
	local colorCorrection = Instance.new("ColorCorrectionEffect")
	colorCorrection.Name = "PossessionEffect"
	colorCorrection.Parent = Lighting

	task.spawn(function()
		local startTime = tick()
		while tick() - startTime < 30 and colorCorrection.Parent do
			colorCorrection.Saturation = math.sin(tick() * 3) * 2
			colorCorrection.TintColor = Color3.fromRGB(
				math.random(200, 255),
				math.random(0, 100),
				math.random(0, 100)
			)
			task.wait()
		end
	end)
end

-- End possession effects if interrupted
local function endPossessionEffects()
	-- Remove GUI
	local possessionGui = playerGui:FindFirstChild("PossessionWarning")
	if possessionGui then
		possessionGui:Destroy()
	end

	-- Restore movement
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = 16
		humanoid.JumpPower = 50
	end

	-- Remove effects
	local colorCorrection = Lighting:FindFirstChild("PossessionEffect")
	if colorCorrection then
		colorCorrection:Destroy()
	end
end

-- Complete the possession (ghost takes control)
local function completePossession(targetPlayer)
	isPossessing = true
	possessedPlayer = targetPlayer

	print("=================================")
	print("POSSESSION COMPLETE!")
	print("You now control " .. targetPlayer.Name)
	print("=================================")

	-- Hide ghost body
	for _, part in pairs(character:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Transparency = 1
		end
	end

	-- Switch camera to possessed player
	if targetPlayer.Character then
		camera.CameraSubject = targetPlayer.Character:FindFirstChildOfClass("Humanoid")

		-- Create control notification
		local controlGui = Instance.new("ScreenGui")
		controlGui.Name = "ControlNotification"
		controlGui.Parent = playerGui

		local notifText = Instance.new("TextLabel")
		notifText.Size = UDim2.new(1, 0, 0.1, 0)
		notifText.Position = UDim2.new(0, 0, 0.9, 0)
		notifText.BackgroundTransparency = 1
		notifText.Text = "CONTROLLING: " .. targetPlayer.Name
		notifText.Font = Enum.Font.SourceSansBold
		notifText.TextScaled = true
		notifText.TextColor3 = Color3.fromRGB(255, 0, 0)
		notifText.TextStrokeTransparency = 0.5
		notifText.Parent = controlGui
	end

	-- Note: Full control transfer would require server-side implementation
	-- In a real game, you'd use RemoteEvents to transfer inputs to the possessed player
end

-- Force player to walk toward ghost (super scary!)
local function forceWalkTowardGhost(ghostPlayer)
	isBeingForced = true
	print("=================================")
	print("YOU'RE BEING FORCED TOWARD THE GHOST!")
	print("=================================")

	-- Stop trippy effects
	endPossessionEffects()

	-- Create TERRIFYING approach GUI
	local forceGui = Instance.new("ScreenGui")
	forceGui.Name = "ForceWalkGui"
	forceGui.DisplayOrder = 150
	forceGui.Parent = playerGui

	-- Darkening vignette
	local vignette = Instance.new("ImageLabel")
	vignette.Size = UDim2.new(1, 0, 1, 0)
	vignette.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	vignette.BackgroundTransparency = 0.3
	vignette.BorderSizePixel = 0
	vignette.ZIndex = 1
	vignette.Parent = forceGui

	-- Warning text
	local warningText = Instance.new("TextLabel")
	warningText.Size = UDim2.new(1, 0, 0.15, 0)
	warningText.Position = UDim2.new(0, 0, 0.42, 0)
	warningText.BackgroundTransparency = 1
	warningText.Text = "YOU CAN'T RESIST..."
	warningText.Font = Enum.Font.SourceSansBold
	warningText.TextScaled = true
	warningText.TextColor3 = Color3.fromRGB(255, 255, 255)
	warningText.TextStrokeTransparency = 0
	warningText.ZIndex = 2
	warningText.Parent = forceGui

	-- Pulsing text effect
	task.spawn(function()
		while forceGui.Parent and isBeingForced do
			warningText.TextTransparency = 0.3 + math.sin(tick() * 3) * 0.3
			task.wait()
		end
	end)

	-- Force walk at 5 walkspeed
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = 5
	end

	-- Pathfinding to ghost
	forceWalkConnection = RunService.Heartbeat:Connect(function()
		-- Get fresh character references
		local currentChar = player.Character
		if not currentChar or not isBeingForced then
			if forceWalkConnection then forceWalkConnection:Disconnect() end
			return
		end

		if not ghostPlayer or not ghostPlayer.Character then
			if forceWalkConnection then forceWalkConnection:Disconnect() end
			return
		end

		local ghostRoot = ghostPlayer.Character:FindFirstChild("HumanoidRootPart")
		local currentRoot = currentChar:FindFirstChild("HumanoidRootPart")
		local currentHumanoid = currentChar:FindFirstChildOfClass("Humanoid")

		if not ghostRoot or not currentRoot or not currentHumanoid then return end

		-- Move toward ghost
		currentHumanoid:MoveTo(ghostRoot.Position)

		-- Check if we're close (will be handled by server for touch)
		local distance = (currentRoot.Position - ghostRoot.Position).Magnitude
		if distance < 5 then
			-- We've reached them!
			isBeingForced = false
			if forceWalkConnection then
				forceWalkConnection:Disconnect()
				forceWalkConnection = nil
			end
			if forceGui then
				forceGui:Destroy()
			end
		end
	end)

	-- Scary visual effects during approach
	task.spawn(function()
		local startTime = tick()
		while isBeingForced and forceGui.Parent do
			-- Flicker screen
			vignette.BackgroundTransparency = 0.3 + math.random(-10, 10) / 100

			-- Change warning messages
			local messages = {
				"YOU CAN'T RESIST...",
				"WALKING TOWARD YOUR DOOM...",
				"IT'S CONTROLLING YOU...",
				"NO ESCAPE...",
				"CLOSER... CLOSER..."
			}
			warningText.Text = messages[math.random(1, #messages)]

			-- Camera slight shake
			camera.CFrame = camera.CFrame * CFrame.Angles(
				math.rad(math.random(-1, 1)),
				math.rad(math.random(-1, 1)),
				0
			)

			task.wait(1)
		end
	end)
end

-- Grant 60 seconds of control to ghost
local function grantControlOfPlayer(targetPlayer)
	print("=================================")
	print("YOU HAVE 60 SECONDS OF CONTROL!")
	print("=================================")

	-- Clean up any previous effects
	isBeingForced = false
	if forceWalkConnection then
		forceWalkConnection:Disconnect()
	end

	local forceGui = playerGui:FindFirstChild("ForceWalkGui")
	if forceGui then
		forceGui:Destroy()
	end

	-- Switch camera to target
	if targetPlayer.Character then
		camera.CameraSubject = targetPlayer.Character:FindFirstChildOfClass("Humanoid")

		-- Create countdown GUI
		local controlGui = Instance.new("ScreenGui")
		controlGui.Name = "ControlGui"
		controlGui.Parent = playerGui

		local timerText = Instance.new("TextLabel")
		timerText.Size = UDim2.new(0.3, 0, 0.1, 0)
		timerText.Position = UDim2.new(0.35, 0, 0.05, 0)
		timerText.BackgroundTransparency = 0.5
		timerText.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		timerText.Text = "CONTROL: 60s"
		timerText.Font = Enum.Font.SourceSansBold
		timerText.TextScaled = true
		timerText.TextColor3 = Color3.fromRGB(255, 0, 0)
		timerText.Parent = controlGui

		-- Countdown
		task.spawn(function()
			for i = 60, 0, -1 do
				if not controlGui.Parent then break end
				timerText.Text = "CONTROL: " .. i .. "s"
				task.wait(1)
			end

			if controlGui.Parent then
				controlGui:Destroy()
			end

			-- Reset camera after control ends
			camera.CameraSubject = character:FindFirstChildOfClass("Humanoid")
		end)
	end
end

-- Transform to FAKE HUMAN with special abilities
local function transformToFakeHuman()
	isFakeHuman = true
	isGhost = false -- No longer a ghost

	print("=================================")
	print("YOU ARE NOW A FAKE HUMAN!")
	print("Press Z to spread arms 100 studs")
	print("Press F to twist head 360 degrees")
	print("=================================")

	-- Reset to normal appearance
	for _, part in pairs(character:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Transparency = 0
			part.Material = Enum.Material.Plastic
			part.CanCollide = true

			-- Remove ghost effects
			local effect = part:FindFirstChild("GhostEffect")
			if effect then
				effect:Destroy()
			end
		end
	end

	-- Normal human stats
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = 16
		humanoid.JumpPower = 50
	end

	-- IMPORTANT: Still keep your own prompt disabled as a fake human
	task.spawn(function()
		task.wait(1)
		if humanoidRootPart then
			local prompt = humanoidRootPart:FindFirstChild("PossessionPrompt")
			if prompt then
				prompt.Enabled = false
				print("Ensured your prompt is disabled as fake human")
			end
		end
	end)

	-- Create "chill" aura for nearby players (50 studs)
	task.spawn(function()
		while isFakeHuman do
			-- Get fresh character reference
			local currentChar = player.Character
			if currentChar then
				local currentRoot = currentChar:FindFirstChild("HumanoidRootPart")
				if currentRoot then
					for _, otherPlayer in pairs(Players:GetPlayers()) do
						if otherPlayer ~= player and otherPlayer.Character then
							local otherRoot = otherPlayer.Character:FindFirstChild("HumanoidRootPart")
							if otherRoot then
								local distance = (currentRoot.Position - otherRoot.Position).Magnitude
								if distance < 50 then
									-- They feel the chill!
									applyChillEffect(otherPlayer, distance)
								end
							end
						end
					end
				end
			end
			task.wait(0.5)
		end
	end)

	-- Create abilities GUI
	local abilityGui = Instance.new("ScreenGui")
	abilityGui.Name = "FakeHumanAbilities"
	abilityGui.Parent = playerGui

	local abilityText = Instance.new("TextLabel")
	abilityText.Size = UDim2.new(0.4, 0, 0.15, 0)
	abilityText.Position = UDim2.new(0.3, 0, 0.85, 0)
	abilityText.BackgroundTransparency = 0.7
	abilityText.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	abilityText.Text = "FAKE HUMAN\nZ: Spread Arms | F: Twist Head"
	abilityText.Font = Enum.Font.SourceSansBold
	abilityText.TextScaled = true
	abilityText.TextColor3 = Color3.fromRGB(255, 255, 255)
	abilityText.Parent = abilityGui
end

-- Apply chill effect to nearby players (35% scary, no monster)
local function applyChillEffect(targetPlayer, distance)
	-- Calculate intensity based on distance (closer = more intense)
	local intensity = 1 - (distance / 50) -- 0 to 1

	-- This would fire to the target player's client
	-- For now, we'll keep it local and just log
	-- In full implementation, use RemoteEvent to target player

	-- Create subtle scary effects (no monster!)
	if targetPlayer == player then
		-- We're feeling the chill ourselves
		local chillGui = playerGui:FindFirstChild("ChillEffect")
		if not chillGui then
			chillGui = Instance.new("ScreenGui")
			chillGui.Name = "ChillEffect"
			chillGui.Parent = playerGui

			local frame = Instance.new("Frame")
			frame.Size = UDim2.new(1, 0, 1, 0)
			frame.BackgroundColor3 = Color3.fromRGB(150, 200, 255) -- Cold blue tint
			frame.BackgroundTransparency = 0.85 + (intensity * 0.1) -- More opaque when closer
			frame.BorderSizePixel = 0
			frame.Parent = chillGui
		end
	end
end

-- Possession and death sequence
local function possessionAndDeath(sounds, scareFrame, whisperText)
	print("=================================")
	print("YOU'VE BEEN CAUGHT...")
	print("=================================")

	-- Trigger possession jumpscare
	sounds.scream:Play()
	scareFrame.ImageTransparency = 0
	scareFrame.BackgroundTransparency = 1
	shakeCamera(40, 2)

	-- Strobe effect
	for i = 1, 8 do
		scareFrame.ImageTransparency = 0
		task.wait(0.06)
		scareFrame.ImageTransparency = 1
		task.wait(0.06)
	end

	-- Possession message
	whisperText.Text = "I OWN YOU NOW"
	whisperText.TextTransparency = 0
	whisperText.Position = UDim2.new(0.1, 0, 0.45, 0)
	whisperText.TextScaled = true
	scareFrame.ImageTransparency = 0

	task.wait(1.5)

	-- Black out screen
	scareFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	scareFrame.BackgroundTransparency = 0
	scareFrame.ImageTransparency = 1
	whisperText.TextTransparency = 1

	task.wait(0.5)

	-- POSSESSION: Make player jump really high
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		print("POSSESSED - FORCED JUMP")

		-- Extreme upward velocity
		local bodyVelocity = Instance.new("BodyVelocity")
		bodyVelocity.MaxForce = Vector3.new(0, math.huge, 0)
		bodyVelocity.Velocity = Vector3.new(0, 300, 0) -- Shoot up super fast
		bodyVelocity.Parent = humanoidRootPart

		-- Remove after a moment to let gravity take over
		task.wait(1)
		bodyVelocity:Destroy()

		-- Wait for the fall
		task.wait(3)

		-- Instead of dying, transform into ghost!
		print("=================================")
		print("YOUR SOUL HAS LEFT YOUR BODY")
		print("=================================")

		-- Immediately become ghost without dying
		task.wait(1)
		becomeGhost()
	end

	return true
end

-- Shadow entity AI - stalks the player from behind
local function updateShadowEntity(entity, bodyPosition, sounds, proximityWarning, heartbeatFrame, scareFrame, whisperText)
	local lastJumpscareTime = 0
	local catchDistance = 8 -- Distance at which entity catches you
	local aggressionLevel = 20 -- Starting distance

	task.spawn(function()
		while isNightmareActive and entity do
			-- Get more aggressive over time (closer starting distance)
			aggressionLevel = math.max(8, aggressionLevel - 0.1)

			-- Position behind player at varying distances
			local distance = math.random(aggressionLevel, 50)
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

			-- CHECK IF CAUGHT - This triggers possession
			if distanceToPlayer < catchDistance then
				-- PLAYER HAS BEEN CAUGHT!
				possessionAndDeath(sounds, scareFrame, whisperText)
				return -- Stop stalking
			end

			-- Occasionally lunge closer to try to catch player
			if distanceToPlayer < 15 and tick() - lastJumpscareTime > 20 then
				lastJumpscareTime = tick()
				-- Lunge at player
				bodyPosition.Position = humanoidRootPart.Position + humanoidRootPart.CFrame.LookVector * -5

				-- Warning scare
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
	updateShadowEntity(shadowEntity, bodyPosition, sounds, proximityWarning, heartbeatFrame, scareFrame, whisperText)

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

	-- Note: Ghost transformation happens in possessionAndDeath() function
	-- No need to monitor for death since we don't actually die
end

-- Fake Human Ability: Spread Arms 100 studs (DEFINED BEFORE INPUT HANDLER)
local function spreadArms()
	print("SPREADING ARMS 100 STUDS!")

	-- Get fresh character reference
	local currentChar = player.Character
	if not currentChar then return end

	local leftArm = currentChar:FindFirstChild("Left Arm") or currentChar:FindFirstChild("LeftUpperArm")
	local rightArm = currentChar:FindFirstChild("Right Arm") or currentChar:FindFirstChild("RightUpperArm")
	local torso = currentChar:FindFirstChild("Torso") or currentChar:FindFirstChild("UpperTorso")

	if not leftArm or not rightArm or not torso then
		warn("Could not find arms or torso!")
		return
	end

	-- Store original positions
	local leftOriginalCFrame = leftArm.CFrame
	local rightOriginalCFrame = rightArm.CFrame

	-- Create stretchy arm parts
	local leftStretch = Instance.new("Part")
	leftStretch.Size = Vector3.new(100, 1, 1)
	leftStretch.CFrame = torso.CFrame * CFrame.new(-50, 0, 0)
	leftStretch.BrickColor = leftArm.BrickColor
	leftStretch.Material = Enum.Material.Plastic
	leftStretch.Anchored = true
	leftStretch.CanCollide = false
	leftStretch.Parent = workspace

	local rightStretch = Instance.new("Part")
	rightStretch.Size = Vector3.new(100, 1, 1)
	rightStretch.CFrame = torso.CFrame * CFrame.new(50, 0, 0)
	rightStretch.BrickColor = rightArm.BrickColor
	rightStretch.Material = Enum.Material.Plastic
	rightStretch.Anchored = true
	rightStretch.CanCollide = false
	rightStretch.Parent = workspace

	-- Hide actual arms
	leftArm.Transparency = 1
	rightArm.Transparency = 1

	-- Tween the stretchy arms outward
	TweenService:Create(leftStretch, TweenInfo.new(0.5), {
		CFrame = torso.CFrame * CFrame.new(-50, 0, 0)
	}):Play()

	TweenService:Create(rightStretch, TweenInfo.new(0.5), {
		CFrame = torso.CFrame * CFrame.new(50, 0, 0)
	}):Play()

	-- Hold for 2 seconds then retract
	task.wait(2)

	leftStretch:Destroy()
	rightStretch:Destroy()
	leftArm.Transparency = 0
	rightArm.Transparency = 0

	print("Arms retracted!")
end

-- Fake Human Ability: Twist Head 360 degrees
local function twistHead()
	print("TWISTING HEAD 360 DEGREES!")

	-- Get fresh character reference
	local currentChar = player.Character
	if not currentChar then return end

	local head = currentChar:FindFirstChild("Head")
	if not head then
		warn("Could not find head!")
		return
	end

	local neck = head:FindFirstChild("Neck") or currentChar:FindFirstChild("Neck")

	-- Spin head on all axes
	task.spawn(function()
		local startTime = tick()
		local duration = 2

		while tick() - startTime < duration do
			local progress = (tick() - startTime) / duration
			local angle = progress * 360

			-- Rotate on all axes (X, Y, Z)
			head.CFrame = head.CFrame * CFrame.Angles(
				math.rad(10), -- X rotation
				math.rad(10), -- Y rotation
				math.rad(10)  -- Z rotation
			)

			task.wait()
		end

		print("Head twist complete!")
	end)
end

-- Activation input (NOW DEFINED AFTER FUNCTIONS)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == Enum.KeyCode.H then
		print("=================================")
		print("INITIATING NIGHTMARE PROTOCOL...")
		print("=================================")
		task.wait(1)
		activateNightmare()
	end

	-- FAKE HUMAN ABILITIES
	if isFakeHuman then
		-- Z: Spread arms 100 studs
		if input.KeyCode == Enum.KeyCode.Z then
			spreadArms()
		end

		-- F: Twist head 360 degrees
		if input.KeyCode == Enum.KeyCode.F then
			twistHead()
		end
	end
end)

-- Disable proximity prompt on your own character
local function disableOwnProximityPrompt()
	-- Wait for prompt to be added by server
	task.wait(2)

	if character and humanoidRootPart then
		local prompt = humanoidRootPart:FindFirstChild("PossessionPrompt")
		if prompt then
			prompt.Enabled = false
			print("Disabled your own proximity prompt")
		end
	end
end

-- Handle character respawn
player.CharacterAdded:Connect(function(newCharacter)
	character = newCharacter
	humanoidRootPart = character:WaitForChild("HumanoidRootPart")

	-- IMPORTANT: Disable the prompt on your own character so you can't possess yourself
	disableOwnProximityPrompt()

	-- Reset ghost state on respawn
	if isGhost then
		isGhost = false
		isPossessing = false
		possessedPlayer = nil
		isFakeHuman = false
		isBeingForced = false

		-- Disconnect force walk
		if forceWalkConnection then
			forceWalkConnection:Disconnect()
			forceWalkConnection = nil
		end

		-- Clean up ghost sounds
		local ghostSound = camera:FindFirstChild("GhostlyWhisper")
		if ghostSound then
			ghostSound:Destroy()
		end

		-- Clean up all GUIs
		local forceGui = playerGui:FindFirstChild("ForceWalkGui")
		if forceGui then forceGui:Destroy() end

		local controlGui = playerGui:FindFirstChild("ControlGui")
		if controlGui then controlGui:Destroy() end

		local abilityGui = playerGui:FindFirstChild("FakeHumanAbilities")
		if abilityGui then abilityGui:Destroy() end

		local chillGui = playerGui:FindFirstChild("ChillEffect")
		if chillGui then chillGui:Destroy() end

		-- Reset camera
		camera.CameraSubject = character:FindFirstChildOfClass("Humanoid")

		print("You have returned to the living world...")
	end
end)

-- Disable prompt on initial character load
disableOwnProximityPrompt()

-- Continuously monitor and disable your own prompt (in case it gets re-enabled)
task.spawn(function()
	while task.wait(3) do
		-- Always get fresh character reference
		local currentChar = player.Character
		if currentChar then
			local currentRoot = currentChar:FindFirstChild("HumanoidRootPart")
			if currentRoot then
				local prompt = currentRoot:FindFirstChild("PossessionPrompt")
				if prompt and prompt.Enabled then
					prompt.Enabled = false
					print("Re-disabled your own proximity prompt")
				end
			end
		end
	end
end)

print("======================================")
print("ULTIMATE HORROR SCRIPT LOADED")
print("Press 'H' to begin the nightmare...")
print("")
print("WARNING: This will be terrifying")
print("A shadow entity will hunt you down")
print("If it catches you, you will be POSSESSED")
print("Your soul will be ripped from your body")
print("You'll become a GHOST to haunt others!")
print("Possess other players by holding E for 30s")
print("They'll trip out while you take control")
print("Try to survive... if you can")
print("======================================")
