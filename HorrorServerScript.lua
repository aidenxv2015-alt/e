-- HORROR NIGHTMARE SERVER SCRIPT
-- Place this in ServerScriptService
-- Handles multiplayer ghost and possession mechanics

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

-- Function to add proximity prompts to all living players for a ghost
local function addProximityPromptsForGhost(ghostPlayer)
	for _, targetPlayer in pairs(Players:GetPlayers()) do
		if targetPlayer ~= ghostPlayer and targetPlayer.Character then
			local humanoid = targetPlayer.Character:FindFirstChildOfClass("Humanoid")
			local rootPart = targetPlayer.Character:FindFirstChild("HumanoidRootPart")

			if humanoid and humanoid.Health > 0 and rootPart and not ghostPlayers[targetPlayer.UserId] then
				-- Check if prompt already exists for this ghost
				local promptName = "PossessionPrompt_" .. ghostPlayer.Name
				if not rootPart:FindFirstChild(promptName) then
					local prompt = Instance.new("ProximityPrompt")
					prompt.Name = promptName
					prompt.ActionText = "Possess"
					prompt.ObjectText = targetPlayer.Name
					prompt.HoldDuration = 30 -- 30 seconds to possess
					prompt.MaxActivationDistance = 10
					prompt.RequiresLineOfSight = false
					prompt.Parent = rootPart

					-- Handle possession start
					prompt.PromptButtonHoldBegan:Connect(function(playerWhoTriggered)
						if playerWhoTriggered == ghostPlayer and ghostPlayers[ghostPlayer.UserId] then
							print(ghostPlayer.Name .. " started possessing " .. targetPlayer.Name)
							startPossessionEvent:FireClient(targetPlayer, ghostPlayer.Name)
						end
					end)

					-- Handle possession cancel
					prompt.PromptButtonHoldEnded:Connect(function(playerWhoTriggered)
						if playerWhoTriggered == ghostPlayer then
							print("Possession interrupted!")
							cancelPossessionEvent:FireClient(targetPlayer)
						end
					end)

					-- Handle possession complete
					prompt.Triggered:Connect(function(playerWhoTriggered)
						if playerWhoTriggered == ghostPlayer and ghostPlayers[ghostPlayer.UserId] then
							print(ghostPlayer.Name .. " successfully possessed " .. targetPlayer.Name)
							completePossessionEvent:FireClient(ghostPlayer, targetPlayer)
							cancelPossessionEvent:FireClient(targetPlayer)
						end
					end)

					print("Added proximity prompt on " .. targetPlayer.Name .. " for ghost " .. ghostPlayer.Name)
				end
			end
		end
	end
end

-- Function to remove all proximity prompts created by a ghost
local function removeProximityPromptsForGhost(ghostPlayer)
	local promptName = "PossessionPrompt_" .. ghostPlayer.Name
	for _, targetPlayer in pairs(Players:GetPlayers()) do
		if targetPlayer.Character then
			local rootPart = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
			if rootPart then
				local prompt = rootPart:FindFirstChild(promptName)
				if prompt then
					prompt:Destroy()
				end
			end
		end
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

	-- Add proximity prompts to all living players
	addProximityPromptsForGhost(player)

	-- Continuously add prompts to new players
	task.spawn(function()
		while ghostPlayers[player.UserId] do
			task.wait(2)
			addProximityPromptsForGhost(player)
		end
	end)
end)

-- Handle player leaving ghost mode (respawn, etc.)
local function removeGhostState(player)
	if ghostPlayers[player.UserId] then
		ghostPlayers[player.UserId] = nil
		removeProximityPromptsForGhost(player)
		print(player.Name .. " is no longer a ghost")
	end
end

-- Handle player respawn
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		-- Wait a moment for character to load
		task.wait(1)

		-- If they were a ghost, remove ghost state
		if ghostPlayers[player.UserId] then
			-- Check if they still look like a ghost
			local rootPart = character:FindFirstChild("HumanoidRootPart")
			if rootPart and rootPart.Transparency < 0.5 then
				-- They respawned normally, remove ghost state
				removeGhostState(player)
			end
		end
	end)
end)

-- Handle player leaving
Players.PlayerRemoving:Connect(function(player)
	removeGhostState(player)
end)

-- Handle new players joining - add prompts for them from existing ghosts
Players.PlayerAdded:Connect(function(newPlayer)
	newPlayer.CharacterAdded:Connect(function()
		task.wait(1) -- Wait for character to fully load

		-- Add prompts from all existing ghosts
		for userId, _ in pairs(ghostPlayers) do
			local ghostPlayer = Players:GetPlayerByUserId(userId)
			if ghostPlayer then
				addProximityPromptsForGhost(ghostPlayer)
			end
		end
	end)
end)

-- Debug command to check ghost players
game:GetService("RunService").Heartbeat:Connect(function()
	-- Clean up invalid ghost players
	for userId, _ in pairs(ghostPlayers) do
		local player = Players:GetPlayerByUserId(userId)
		if not player then
			ghostPlayers[userId] = nil
		end
	end
end)

print("======================================")
print("HORROR SERVER SCRIPT LOADED")
print("Multiplayer ghost system active")
print("======================================")
