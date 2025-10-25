-- HORROR NIGHTMARE SERVER SCRIPT
-- Place this in ServerScriptService
-- Handles multiplayer ghost and possession mechanics
-- EVERYONE can see proximity prompts on EVERYONE and possess them!

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Create RemoteEvents folder if it doesn't exist
local remoteFolder = ReplicatedStorage:FindFirstChild("HorrorRemotes")
if not remoteFolder then
	remoteFolder = Instance.new("Folder")
	remoteFolder.Name = "HorrorRemotes"
	remoteFolder.Parent = ReplicatedStorage
end

-- Create RemoteEvents
local becomeGhostEvent = remoteFolder:FindFirstChild("BecomeGhost") or Instance.new("RemoteEvent")
becomeGhostEvent.Name = "BecomeGhost"
becomeGhostEvent.Parent = remoteFolder

local startPossessionEvent = remoteFolder:FindFirstChild("StartPossession") or Instance.new("RemoteEvent")
startPossessionEvent.Name = "StartPossession"
startPossessionEvent.Parent = remoteFolder

local completePossessionEvent = remoteFolder:FindFirstChild("CompletePossession") or Instance.new("RemoteEvent")
completePossessionEvent.Name = "CompletePossession"
completePossessionEvent.Parent = remoteFolder

local cancelPossessionEvent = remoteFolder:FindFirstChild("CancelPossession") or Instance.new("RemoteEvent")
cancelPossessionEvent.Name = "CancelPossession"
cancelPossessionEvent.Parent = remoteFolder

-- Track ghost players
local ghostPlayers = {}

-- Function to add a proximity prompt to a player for everyone to see
local function addProximityPromptToPlayer(targetPlayer)
	if not targetPlayer.Character then return end

	local humanoid = targetPlayer.Character:FindFirstChildOfClass("Humanoid")
	local rootPart = targetPlayer.Character:FindFirstChild("HumanoidRootPart")

	if humanoid and humanoid.Health > 0 and rootPart then
		-- Check if prompt already exists
		if not rootPart:FindFirstChild("PossessionPrompt") then
			local prompt = Instance.new("ProximityPrompt")
			prompt.Name = "PossessionPrompt"
			prompt.ActionText = "Possess"
			prompt.ObjectText = targetPlayer.Name
			prompt.HoldDuration = 30 -- 30 seconds to possess
			prompt.MaxActivationDistance = 10
			prompt.RequiresLineOfSight = false
			prompt.Parent = rootPart

			print("Added proximity prompt to " .. targetPlayer.Name)

			-- Handle possession start (when someone starts holding E)
			prompt.PromptButtonHoldBegan:Connect(function(playerWhoTriggered)
				if playerWhoTriggered ~= targetPlayer then
					print(playerWhoTriggered.Name .. " started possessing " .. targetPlayer.Name)
					-- Tell the target player they're being possessed
					startPossessionEvent:FireClient(targetPlayer, playerWhoTriggered.Name)
				end
			end)

			-- Handle possession cancel (when they release E)
			prompt.PromptButtonHoldEnded:Connect(function(playerWhoTriggered)
				if playerWhoTriggered ~= targetPlayer then
					print("Possession interrupted!")
					-- Tell the target player to stop effects
					cancelPossessionEvent:FireClient(targetPlayer)
				end
			end)

			-- Handle possession complete (held for full 30 seconds)
			prompt.Triggered:Connect(function(playerWhoTriggered)
				if playerWhoTriggered ~= targetPlayer then
					print(playerWhoTriggered.Name .. " successfully possessed " .. targetPlayer.Name)
					-- Tell the ghost they successfully possessed
					completePossessionEvent:FireClient(playerWhoTriggered, targetPlayer)
					-- Tell the target to stop trippy effects
					cancelPossessionEvent:FireClient(targetPlayer)
				end
			end)
		end
	end
end

-- Function to add proximity prompts to ALL players
local function addProximityPromptsToAllPlayers()
	for _, player in pairs(Players:GetPlayers()) do
		addProximityPromptToPlayer(player)
	end
end

-- Handle player becoming a ghost
becomeGhostEvent.OnServerEvent:Connect(function(player)
	print(player.Name .. " is becoming a ghost!")
	ghostPlayers[player.UserId] = true

	-- Make the player's character ghostly server-side
	if player.Character then
		for _, part in pairs(player.Character:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Transparency = 0.7
				part.Material = Enum.Material.ForceField
				part.CanCollide = false

				-- Add ghostly particles
				if not part:FindFirstChild("GhostEffect") then
					local effect = Instance.new("ParticleEmitter")
					effect.Name = "GhostEffect"
					effect.Texture = "rbxasset://textures/particles/smoke_main.dds"
					effect.Color = ColorSequence.new(Color3.fromRGB(200, 200, 255))
					effect.Size = NumberSequence.new(0.5)
					effect.Transparency = NumberSequence.new(0.6)
					effect.Lifetime = NumberRange.new(1, 2)
					effect.Rate = 10
					effect.Speed = NumberRange.new(1)
					effect.Parent = part
				end
			elseif part:IsA("Decal") or part:IsA("Texture") then
				part.Transparency = 0.7
			end
		end

		-- Give ghost abilities
		local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = 30
			humanoid.JumpPower = 100
		end
	end
end)

-- Handle player leaving ghost mode (respawn, etc.)
local function removeGhostState(player)
	if ghostPlayers[player.UserId] then
		ghostPlayers[player.UserId] = nil
		print(player.Name .. " is no longer a ghost")
	end
end

-- When a new player joins
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		-- Wait for character to load
		task.wait(1)

		-- Add proximity prompt to this new player
		addProximityPromptToPlayer(player)

		-- Check if they were a ghost before respawning
		local rootPart = character:FindFirstChild("HumanoidRootPart")
		if rootPart and rootPart.Transparency < 0.5 then
			-- They respawned normally, remove ghost state
			removeGhostState(player)
		end
	end)
end)

-- Handle player leaving
Players.PlayerRemoving:Connect(function(player)
	removeGhostState(player)
end)

-- Add prompts to all existing players when server starts
task.wait(2) -- Wait for players to load
addProximityPromptsToAllPlayers()

-- Continuously ensure all players have prompts
task.spawn(function()
	while true do
		task.wait(5)
		addProximityPromptsToAllPlayers()
	end
end)

print("======================================")
print("HORROR SERVER SCRIPT LOADED")
print("ALL players can possess ALL players!")
print("Proximity prompts on everyone!")
print("======================================")
