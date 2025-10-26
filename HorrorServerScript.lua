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

local forceWalkEvent = remoteFolder:FindFirstChild("ForceWalk") or Instance.new("RemoteEvent")
forceWalkEvent.Name = "ForceWalk"
forceWalkEvent.Parent = remoteFolder

local grantControlEvent = remoteFolder:FindFirstChild("GrantControl") or Instance.new("RemoteEvent")
grantControlEvent.Name = "GrantControl"
grantControlEvent.Parent = remoteFolder

local transformToFakeHumanEvent = remoteFolder:FindFirstChild("TransformToFakeHuman") or Instance.new("RemoteEvent")
transformToFakeHumanEvent.Name = "TransformToFakeHuman"
transformToFakeHumanEvent.Parent = remoteFolder

-- Track ghost players and active possessions
local ghostPlayers = {}
local activePossessions = {} -- {ghostPlayer = targetPlayer}

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
			prompt.MaxActivationDistance = 60 -- 60 studs away!
			prompt.RequiresLineOfSight = false
			prompt.Parent = rootPart

			print("Added proximity prompt to " .. targetPlayer.Name)

			-- Handle possession start (when someone starts holding E)
			prompt.PromptButtonHoldBegan:Connect(function(playerWhoTriggered)
				-- FIX: Can't possess yourself
				if playerWhoTriggered ~= targetPlayer then
					print(playerWhoTriggered.Name .. " started possessing " .. targetPlayer.Name)
					activePossessions[playerWhoTriggered.UserId] = targetPlayer.UserId
					-- Tell the target player they're being possessed
					startPossessionEvent:FireClient(targetPlayer, playerWhoTriggered.Name)
				end
			end)

			-- Handle possession cancel (when they release E)
			prompt.PromptButtonHoldEnded:Connect(function(playerWhoTriggered)
				if playerWhoTriggered ~= targetPlayer then
					print("Possession interrupted!")
					activePossessions[playerWhoTriggered.UserId] = nil
					-- Tell the target player to stop effects
					cancelPossessionEvent:FireClient(targetPlayer)
				end
			end)

			-- Handle possession complete (held for full 30 seconds)
			prompt.Triggered:Connect(function(playerWhoTriggered)
				-- FIX: Can't possess yourself
				if playerWhoTriggered ~= targetPlayer then
					print(playerWhoTriggered.Name .. " successfully possessed " .. targetPlayer.Name .. " - forcing them to walk!")

					-- Tell target to walk toward ghost at 5 walkspeed
					forceWalkEvent:FireClient(targetPlayer, playerWhoTriggered)

					-- Start monitoring for when they touch
					task.spawn(function()
						local ghostChar = playerWhoTriggered.Character
						local targetChar = targetPlayer.Character

						if not ghostChar or not targetChar then return end

						local ghostRoot = ghostChar:FindFirstChild("HumanoidRootPart")
						local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")

						if not ghostRoot or not targetRoot then return end

						-- Wait for them to get close (touch distance)
						while (ghostRoot.Position - targetRoot.Position).Magnitude > 5 do
							task.wait(0.1)
							-- Check if either character died
							if not ghostChar.Parent or not targetChar.Parent then return end
							-- Update references in case they changed
							ghostRoot = ghostChar:FindFirstChild("HumanoidRootPart")
							targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
							if not ghostRoot or not targetRoot then return end
						end

						-- They touched! Grant 60 seconds of control
						print(playerWhoTriggered.Name .. " touched " .. targetPlayer.Name .. " - granting 60 seconds!")
						grantControlEvent:FireClient(playerWhoTriggered, targetPlayer)

						-- After 60 seconds, KILL the possessed player
						task.wait(60)
						print("60 seconds up! Killing " .. targetPlayer.Name)

						-- KILL THE POSSESSED PLAYER
						local targetHumanoid = targetChar:FindFirstChildOfClass("Humanoid")
						if targetHumanoid then
							targetHumanoid.Health = 0
							print(targetPlayer.Name .. " has been killed!")
						end

						-- Transform ghost to FAKE HUMAN
						print(playerWhoTriggered.Name .. " transforming to FAKE HUMAN!")
						transformToFakeHumanEvent:FireClient(playerWhoTriggered)

						-- Clean up possession
						activePossessions[playerWhoTriggered.UserId] = nil
					end)
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
		activePossessions[player.UserId] = nil
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

		-- IMPORTANT: Tell the client to disable their own prompt
		-- (We'll handle this on the client side)
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
print("60 stud range - forced walk - fake human!")
print("======================================")
