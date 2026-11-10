local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EggConfig = require(ReplicatedStorage.Shared.Config.EggConfig)
local CompanionConfig = require(ReplicatedStorage.Shared.Config.CompanionConfig)
local MonetizationConfig = require(ReplicatedStorage.Shared.Config.MonetizationConfig)
local EggService = {}
local dataService, remotes, mapBuilder, petService
local pendingEgg = {}
local tripleHatchOwners = {}

local function rollPet(egg, luckLevel)
	local totalWeight = 0
	for _, entry in egg.Pets do
		if CompanionConfig[entry.Id] then totalWeight += entry.Weight * (entry.Weight <= 25 and (1 + luckLevel * 0.08) or 1) end
	end
	if totalWeight <= 0 then return nil end
	local roll = math.random() * totalWeight
	for _, entry in egg.Pets do
		if CompanionConfig[entry.Id] then
			roll -= entry.Weight * (entry.Weight <= 25 and (1 + luckLevel * 0.08) or 1)
			if roll <= 0 then return entry.Id end
		end
	end
	return nil
end

local function ownsTripleHatch(player)
	if tripleHatchOwners[player] then return true, nil end
	local passId = MonetizationConfig.TripleHatchPassId
	if not passId or passId <= 0 then return false, "unconfigured" end
	local ok, owns = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, passId)
	if not ok then return false, "check_failed" end
	return owns, nil
end

function EggService:Start(dependencies)
	dataService, remotes, mapBuilder, petService = dependencies.PlayerDataService, dependencies.Remotes, dependencies.MapBuilder, dependencies.PetService
	for _, prompt in mapBuilder:GetEggPrompts() do
		prompt.Triggered:Connect(function(player)
			local eggId = prompt:GetAttribute("EggId")
			local egg = EggConfig[eggId]
			if not egg or not dataService:IsReady(player) then return end
			pendingEgg[player] = { EggId = eggId, Prompt = prompt, ExpiresAt = os.clock() + 30 }
			remotes.OpenEgg:FireClient(player, { EggId = eggId })
		end)
	end
	remotes.HatchEgg.OnServerEvent:Connect(function(player, eggId, count)
		self:Hatch(player, eggId, count)
	end)
	Players.PlayerRemoving:Connect(function(player)
		pendingEgg[player], tripleHatchOwners[player] = nil, nil
	end)
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
		if passId == MonetizationConfig.TripleHatchPassId and purchased then
			tripleHatchOwners[player] = true
			remotes.Message:FireClient(player, "Triple Hatch unlocked! Choose three eggs to open them.")
		end
	end)
end

function EggService:Hatch(player, eggId, count)
	local data, egg, request = dataService:Get(player), EggConfig[eggId], pendingEgg[player]
	if not data or not egg then return end
	if not request or request.EggId ~= eggId or request.ExpiresAt < os.clock() then
		pendingEgg[player] = nil
		remotes.Message:FireClient(player, "Interact with an egg stand to open eggs")
		return
	end
	if count ~= 1 and count ~= 3 then return end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local promptPart = request.Prompt and request.Prompt.Parent
	if not root or not promptPart or not promptPart:IsA("BasePart") or (root.Position - promptPart.Position).Magnitude > request.Prompt.MaxActivationDistance + 5 then
		pendingEgg[player] = nil
		remotes.Message:FireClient(player, "Move closer to the egg stand to hatch")
		return
	end
	local totalCost = egg.Cost * count
	if data.Valor < totalCost then
		remotes.Message:FireClient(player, string.format("%s x%d costs %d Valor", egg.DisplayName, count, totalCost))
		return
	end
	if count == 3 then
		local owns, reason = ownsTripleHatch(player)
		if not owns then
			local passId = MonetizationConfig.TripleHatchPassId
			if reason == "unconfigured" then
				remotes.Message:FireClient(player, "Triple Hatch is unavailable until its gamepass ID is configured")
			elseif reason == "check_failed" then
				remotes.Message:FireClient(player, "Could not verify gamepass ownership. Please try again.")
			else
				local prompted = pcall(MarketplaceService.PromptGamePassPurchase, MarketplaceService, player, passId)
				remotes.Message:FireClient(player, prompted and "Purchase the Triple Hatch pass, then choose three eggs again" or "Could not open the gamepass purchase prompt")
			end
			return
		end
	end
	local results = {}
	for _ = 1, count do
		local luckLevel = data.Upgrades.Enchantments and data.Upgrades.Enchantments.Luck or 0
		local petId = rollPet(egg, luckLevel)
		if not petId then return end
		table.insert(results, petId)
	end
	data.Valor -= totalCost
	for _, petId in results do
		table.insert(data.Companions.Owned, petId)
		local capacity = 3 + ((data.Upgrades.Enchantments and data.Upgrades.Enchantments.PetCapacity) or 0)
		if #data.Companions.Equipped < capacity then table.insert(data.Companions.Equipped, petId) end
	end
	pendingEgg[player] = nil
	dataService:UpdateAttributes(player)
	petService:RefreshPlayer(player)
	remotes.HatchResult:FireClient(player, { EggId = eggId, Pets = results, Cost = totalCost })
end

return EggService
