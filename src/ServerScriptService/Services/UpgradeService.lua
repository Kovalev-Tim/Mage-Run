local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UpgradeConfig = require(ReplicatedStorage.Shared.Config.UpgradeConfig)
local UpgradeService = {}
local dataService
local remotes, mapBuilder

function UpgradeService:Start(dependencies)
    dataService = dependencies.PlayerDataService
    remotes = dependencies.Remotes
    mapBuilder = dependencies.MapBuilder
    remotes.Upgrade.OnServerEvent:Connect(function(player, upgradeId)
        if upgradeId == "SkillMastery" then self:BuySkillMastery(player)
        else self:BuyEnchantment(player, upgradeId) end
    end)
    mapBuilder:GetMeditationUpgradePrompt().Triggered:Connect(function(player)
        self:BuySkillMastery(player)
    end)
end

function UpgradeService:BuyEnchantment(player, enchantmentId)
    local data = dataService:Get(player)
    local config = UpgradeConfig.Enchantments[enchantmentId]
    if not data or not config then return end
    data.Upgrades.Enchantments = data.Upgrades.Enchantments or {}
    local level = data.Upgrades.Enchantments[enchantmentId] or 0
    if level >= config.MaxLevel then remotes.Message:FireClient(player, config.DisplayName .. " is maxed"); return end
    local cost = math.floor(config.BaseCost * config.CostMultiplier ^ level + 0.5)
    if data.Valor < cost then remotes.Message:FireClient(player, "Need " .. cost .. " Valor to upgrade " .. config.DisplayName); return end
    data.Valor -= cost
    data.Upgrades.Enchantments[enchantmentId] = level + 1
    dataService:UpdateAttributes(player)
    remotes.Message:FireClient(player, config.DisplayName .. " upgraded to level " .. (level + 1))
end

function UpgradeService:BuySkillMastery(player)
    local data = dataService:Get(player)
    if not data then return end
    if not mapBuilder:IsAtMeditationPool(player) then
        remotes.Message:FireClient(player, "Use the Meditation Pool focus stone to upgrade Skill Mastery")
        return
    end
    local config = UpgradeConfig.SkillMastery
    local level = data.Upgrades.SkillMastery or 0
    if level >= config.MaxLevel then
        remotes.Message:FireClient(player, "Skill Mastery is already at maximum")
        return
    end
    local cost = math.floor(config.BaseCost * (config.CostMultiplier ^ level) + 0.5)
    if data.Valor < cost then
        remotes.Message:FireClient(player, "Not enough Valor • upgrade costs " .. cost)
        return
    end
    data.Valor -= cost
    data.Upgrades.SkillMastery = level + 1
    dataService:UpdateAttributes(player)
    remotes.Message:FireClient(player, string.format("Skill Mastery level %d • Q/E damage +%d%%", level + 1, (level + 1) * config.DamagePerLevel * 100))
end

return UpgradeService
