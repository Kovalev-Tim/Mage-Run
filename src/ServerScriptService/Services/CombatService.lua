local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MageConfig = require(ReplicatedStorage.Shared.Config.MageConfig)
local CompanionConfig = require(ReplicatedStorage.Shared.Config.CompanionConfig)
local UpgradeConfig = require(ReplicatedStorage.Shared.Config.UpgradeConfig)
local CombatService = {}
local cooldowns = {}
local dataService, runService, enemyService, remotes

local function getDamageMultiplier(data)
	local petBonus = 0
	for _, id in data.Companions.Equipped do
		local pet = CompanionConfig[id]
		if pet then petBonus += pet.DamageBonus end
	end
	local enchantment = data.Upgrades.Enchantments and data.Upgrades.Enchantments.Damage or 0
	return (1 + (data.Upgrades.SkillMastery or 0) * UpgradeConfig.SkillMastery.DamagePerLevel + petBonus) * (1 + enchantment * UpgradeConfig.Enchantments.Damage.BonusPerLevel)
end

function CombatService:Start(dependencies)
	dataService, runService, enemyService, remotes = dependencies.PlayerDataService, dependencies.RunService, dependencies.EnemyService, dependencies.Remotes
	remotes.CastSkill.OnServerEvent:Connect(function(player, slot)
		if slot ~= "Q" and slot ~= "E" then return end
		self:CastSkill(player, slot)
	end)
	game:GetService("Players").PlayerRemoving:Connect(function(player) cooldowns[player] = nil end)
end

function CombatService:CastSkill(player, slot)
	local data, run = dataService:Get(player), runService:Get(player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not data or not run or not root or not humanoid or humanoid.Health <= 0 then return end
	local archetype = MageConfig[data.MageArchetype] or MageConfig.Pyromancer
	local skill = archetype[slot]
	if not skill then return end
	local now = os.clock()
	cooldowns[player] = cooldowns[player] or {}
	if now - (cooldowns[player][slot] or 0) < skill.Cooldown then return end
	cooldowns[player][slot] = now
	local multiplier = getDamageMultiplier(data)
	local enemies = enemyService:GetEnemies(player)
	local hitModels = {}
	for _, enemy in enemies do
		if enemy.PrimaryPart and (enemy.PrimaryPart.Position - root.Position).Magnitude <= skill.Radius then
			table.insert(hitModels, enemy)
		end
	end
	if #hitModels == 0 then
		remotes.Hit:FireClient(player, { Effect = skill.Effect, SkillName = skill.Name, Color = archetype.Color, Radius = skill.Radius, SourcePosition = root.Position, TargetPosition = root.Position + root.CFrame.LookVector * 12, NoHit = true })
		return
	end
	for index, enemy in hitModels do
		local targetPosition = enemy.PrimaryPart.Position
		local damage = math.floor(skill.Damage * multiplier + 0.5)
		enemyService:Damage(player, damage, enemy)
		remotes.Hit:FireClient(player, {
			Damage = damage,
			Effect = index == 1 and skill.Effect or nil,
			SkillName = index == 1 and skill.Name or nil,
			Color = archetype.Color,
			Radius = skill.Radius,
			SourcePosition = root.Position + Vector3.new(0, 1, 0),
			TargetPosition = targetPosition,
		})
	end
end

return CombatService
