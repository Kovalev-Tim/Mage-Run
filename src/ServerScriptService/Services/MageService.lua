local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MageConfig = require(ReplicatedStorage.Shared.Config.MageConfig)
local MageService = {}
local dataService, remotes, mapBuilder

function MageService:Start(dependencies)
	dataService, remotes, mapBuilder = dependencies.PlayerDataService, dependencies.Remotes, dependencies.MapBuilder
	for _, button in mapBuilder:GetArchetypeButtons() do
		button.MouseClick:Connect(function(player)
			local data = dataService:Get(player)
			local archetypeId = button:GetAttribute("ArchetypeId")
			local archetype = MageConfig[archetypeId]
			if not data or not archetype then return end
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			local buttonPart = button.Parent
			if not root or not buttonPart or not buttonPart:IsA("BasePart") or (root.Position - buttonPart.Position).Magnitude > button.MaxActivationDistance + 2 then return end
			if not table.find(data.UnlockedMages, archetypeId) then
				local cost = archetype.CupCost or 0
				if data.Valor < cost then
					remotes.Message:FireClient(player, string.format("%s requires %d Valor", archetype.DisplayName, cost))
					return
				end
				data.Valor -= cost
				table.insert(data.UnlockedMages, archetypeId)
			end
			data.MageArchetype = archetypeId
			dataService:UpdateAttributes(player)
			remotes.Message:FireClient(player, string.format("%s ready • M1 %s • Q %s • E %s", archetype.DisplayName, archetype.M1.Name, archetype.Q.Name, archetype.E.Name))
		end)
	end
	for archetypeId in pairs(MageConfig) do
		assert(mapBuilder:HasArchetypeStand(archetypeId), "Missing mage stand for " .. archetypeId)
	end
end

return MageService
