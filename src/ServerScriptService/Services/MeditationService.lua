local Players = game:GetService("Players")
local RunServiceEngine = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MeditationConfig = require(ReplicatedStorage.Shared.Config.MeditationConfig)
local MeditationService = {}
local dataService, mapBuilder, runService, remotes
local meditators = {}

function MeditationService:Start(dependencies)
	dataService, mapBuilder, runService, remotes = dependencies.PlayerDataService, dependencies.MapBuilder, dependencies.RunService, dependencies.Remotes
	Players.PlayerRemoving:Connect(function(player) meditators[player] = nil end)
	local elapsed = 0
	RunServiceEngine.Heartbeat:Connect(function(dt)
		elapsed += dt
		if elapsed < 1 then return end
		local tick = elapsed
		elapsed = 0
		for _, player in Players:GetPlayers() do
			local data = dataService:Get(player)
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			local run = runService:Get(player)
			local fighting = run and not run.Cleared[run.Zone]
			local still = root and root.AssemblyLinearVelocity.Magnitude <= MeditationConfig.MovementLimit
			local eligible = data and root and humanoid and humanoid.Health > 0 and still and not fighting and mapBuilder:IsAtMeditationPool(player)
			local state = meditators[player]
			if not eligible then
				if state then
					meditators[player] = nil
					if player.Parent then remotes.Message:FireClient(player, "Meditation paused • stand still in the pool to resume") end
				end
			else
				if not state then
					state = { Elapsed = 0 }
					meditators[player] = state
					remotes.Message:FireClient(player, "Meditation started automatically • stay in the pool to gain Magic Power")
				end
				state.Elapsed += tick
				if state.Elapsed >= MeditationConfig.RewardInterval then
					state.Elapsed -= MeditationConfig.RewardInterval
					data.MagicPower += MeditationConfig.MagicPowerPerInterval
					dataService:UpdateAttributes(player)
					remotes.Reward:FireClient(player, { MagicPower = MeditationConfig.MagicPowerPerInterval, Meditation = true, TotalMagicPower = data.MagicPower })
				end
			end
		end
	end)
end

return MeditationService
