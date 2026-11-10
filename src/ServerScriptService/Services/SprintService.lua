local Players = game:GetService("Players")
local SprintService = {}
local remotes
local WALK_SPEED, SPRINT_SPEED = 16, 24

local function setCharacterSpeed(player, sprinting)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.Health > 0 then humanoid.WalkSpeed = sprinting and SPRINT_SPEED or WALK_SPEED end
end

function SprintService:Start(dependencies)
	remotes = dependencies.Remotes
	remotes.Sprint.OnServerEvent:Connect(function(player, sprinting)
		if typeof(sprinting) ~= "boolean" then return end
		setCharacterSpeed(player, sprinting)
	end)
	local function bindPlayer(player)
		player.CharacterAdded:Connect(function()
			setCharacterSpeed(player, false)
		end)
	end
	Players.PlayerAdded:Connect(bindPlayer)
	for _, player in Players:GetPlayers() do bindPlayer(player) end
end

return SprintService
