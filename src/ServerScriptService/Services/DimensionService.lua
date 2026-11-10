local DimensionService = {}
local maps, runService, remotes

function DimensionService:Start(dependencies)
	maps, runService, remotes = dependencies.MapBuilder, dependencies.RunService, dependencies.Remotes
	for _, prompt in maps:GetDimensionPrompts() do
		prompt.Triggered:Connect(function(player)
			local destinationName = prompt:GetAttribute("PortalDestination")
			if destinationName ~= "Rebirth" and destinationName ~= "Hub" then return end
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if not root then return end
			runService:Exit(player)
			character:PivotTo(maps:GetDimensionCFrame(destinationName, player))
			root.AssemblyLinearVelocity, root.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
			player:SetAttribute("InRebirthDimension", destinationName == "Rebirth")
			remotes.Message:FireClient(player, destinationName == "Rebirth" and "Entered the Rebirth Dimension" or "Returned to the Archmage Hub")
		end)
	end
end

return DimensionService
