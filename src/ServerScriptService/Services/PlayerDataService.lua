local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local Template = require(script.Parent.DataTemplate)

local PlayerDataService = {}
local profiles = {}
local readyEvent = Instance.new("BindableEvent")
PlayerDataService.Ready = readyEvent.Event

local function mergeDefaults(target, defaults)
    for key, value in pairs(defaults) do
        if target[key] == nil then
            target[key] = table.clone(value)
        elseif type(value) == "table" and type(target[key]) == "table" then
            mergeDefaults(target[key], value)
        end
    end
end

function PlayerDataService:Get(player)
    local profile = profiles[player]
    if profile and profile:IsActive() then
        return profile.Data
    end
    return nil
end

function PlayerDataService:IsReady(player)
    return self:Get(player) ~= nil
end

function PlayerDataService:UpdateAttributes(player)
    local data = self:Get(player)
    if not data then return end
	player:SetAttribute("Valor", data.Valor or 0)
	player:SetAttribute("MagicPower", data.MagicPower or 0)
    player:SetAttribute("Level", data.Level)
    player:SetAttribute("XP", data.XP)
	player:SetAttribute("SkillMasteryLevel", data.Upgrades and data.Upgrades.SkillMastery or 0)
	local enchantments = data.Upgrades and data.Upgrades.Enchantments or {}
	player:SetAttribute("DamageEnchantmentLevel", enchantments.Damage or 0)
	player:SetAttribute("LuckEnchantmentLevel", enchantments.Luck or 0)
	player:SetAttribute("PetCapacityLevel", enchantments.PetCapacity or 0)
	player:SetAttribute("HighestZoneUnlocked", data.HighestZoneUnlocked or 1)
	player:SetAttribute("PetCollection", table.concat(data.Companions and data.Companions.Owned or {}, ", "))
	player:SetAttribute("EquippedPets", table.concat(data.Companions and data.Companions.Equipped or {}, ","))
	player:SetAttribute("MageArchetype", data.MageArchetype or "Pyromancer")
end

function PlayerDataService:Start()
    local packageFolder = ServerScriptService:FindFirstChild("Packages")
    local profileModule = packageFolder and packageFolder:FindFirstChild("ProfileStore")
    assert(profileModule, "Missing ServerScriptService.Packages.ProfileStore. Follow TRANSFER-TO-STUDIO.md.")
    local ProfileStore = require(profileModule)
    local store = ProfileStore.New("RiftRun_PlayerData_v1", Template)

    local function loadPlayer(player)
        local profile = store:StartSessionAsync("Player_" .. player.UserId, {
            Cancel = function() return player.Parent ~= Players end,
        })
        if not profile then
            if player.Parent == Players then
                player:Kick("Your data could not be loaded. Please rejoin in a moment.")
            end
            return
        end
        profile:AddUserId(player.UserId)
        profile:Reconcile()
        mergeDefaults(profile.Data, Template)
		profile.Data.Upgrades.Power = nil
		profile.Data.UnlockedMages = profile.Data.UnlockedMages or { "Pyromancer" }
		if profile.Data.MageArchetype and not table.find(profile.Data.UnlockedMages, profile.Data.MageArchetype) then
			table.insert(profile.Data.UnlockedMages, profile.Data.MageArchetype)
		end
		profile.Data.Valor = math.max(profile.Data.Valor or 0, profile.Data.BattleCups or 0, profile.Data.Essence or 0)
		profile.Data.BattleCups, profile.Data.Essence = nil, nil
		profile.Data.MagicPower = profile.Data.MagicPower or 0
		profile.Data.SchemaVersion = Template.SchemaVersion
        profiles[player] = profile
        profile.OnSessionEnd:Connect(function()
            profiles[player] = nil
            if player.Parent == Players then
                player:Kick("Your data session ended. Please rejoin.")
            end
        end)
        if player.Parent ~= Players then
            profiles[player] = nil
            profile:EndSession()
            return
        end
        self:UpdateAttributes(player)
        readyEvent:Fire(player)
    end

    Players.PlayerAdded:Connect(loadPlayer)
    for _, player in Players:GetPlayers() do task.spawn(loadPlayer, player) end
    Players.PlayerRemoving:Connect(function(player)
        local profile = profiles[player]
        profiles[player] = nil
        if profile then profile:EndSession() end
    end)
    game:BindToClose(function()
        for player, profile in pairs(profiles) do
            profiles[player] = nil
            profile:EndSession()
        end
    end)
end

return PlayerDataService
