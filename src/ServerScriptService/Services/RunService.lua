local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ZoneConfig = require(ReplicatedStorage.Shared.Config.ZoneConfig)
local CompanionConfig = require(ReplicatedStorage.Shared.Config.CompanionConfig)
local MageConfig = require(ReplicatedStorage.Shared.Config.MageConfig)
local UpgradeConfig = require(ReplicatedStorage.Shared.Config.UpgradeConfig)
local RunService = {}
local active = {}
local remotes, maps, dataService, enemies

local function getDamage(player)
	local data = dataService:Get(player)
	if not data then return 0 end
	local archetype = MageConfig[data.MageArchetype] or MageConfig.Pyromancer
	local companionBonus = 0
	for _, id in data.Companions.Equipped do
		local companion = CompanionConfig[id]
		if companion then companionBonus += companion.DamageBonus end
	end
	local enchantmentLevel = data.Upgrades.Enchantments and data.Upgrades.Enchantments.Damage or 0
	local enchantmentBonus = enchantmentLevel * UpgradeConfig.Enchantments.Damage.BonusPerLevel
	return math.floor(archetype.M1.Damage * (1 + companionBonus) * (1 + enchantmentBonus) + 0.5)
end

local function startAutoCombat(player)
	local combatRun = active[player]
	local combatZone = combatRun and combatRun.Zone
	task.spawn(function()
		while active[player] == combatRun and combatRun.Zone == combatZone and player.Parent do
			local run, character = active[player], player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			local enemy = enemies:GetCurrent(player)
			local data = dataService:Get(player)
			local archetype = data and (MageConfig[data.MageArchetype] or MageConfig.Pyromancer)
			if run and enemy and root and archetype and enemy.PrimaryPart and (root.Position - enemy.PrimaryPart.Position).Magnitude <= 12 then
				local targetPosition = enemy.PrimaryPart.Position
				local damage = getDamage(player)
				enemies:Damage(player, damage, enemy)
				remotes.Hit:FireClient(player, { Damage = damage, Automatic = true, AttackName = archetype.M1.Name, Effect = archetype.M1.Effect, Color = archetype.Color, SourcePosition = root.Position + Vector3.new(0, 1.5, 0), TargetPosition = targetPosition })
			end
			task.wait(archetype and archetype.M1.Cooldown or 0.9)
		end
	end)
end

function RunService:Start(dependencies)
	dataService, maps, enemies, remotes = dependencies.PlayerDataService, dependencies.MapBuilder, dependencies.EnemyService, dependencies.Remotes
	for zoneId, trigger in maps:GetZoneParts() do
		trigger.Touched:Connect(function(hit)
			local character = hit:FindFirstAncestorOfClass("Model")
			local player = character and Players:GetPlayerFromCharacter(character)
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if not player or not root then return end
			local boundary = ZoneConfig[zoneId].Start
			if zoneId == 1 then
				if root.Position.Z < boundary - 1 then self:EnterZone(player, 1) end
			elseif root.Position.Z < boundary - 1 then
				self:EnterZone(player, zoneId)
			elseif root.Position.Z > boundary + 1 then
				self:EnterZone(player, zoneId - 1)
			end
		end)
	end
	for zoneId, prompt in maps:GetReturnPrompts() do
		prompt.Triggered:Connect(function(player) self:ReturnToSpawn(player, zoneId) end)
	end
	dataService.Ready:Connect(function(player)
		local playerSlot = maps:AssignSlot(player)
		if not playerSlot then player:Kick("This server is full. Please join another server."); return end
		player:SetAttribute("PlayerSlot", playerSlot)
		player.CharacterAdded:Connect(function(character)
			task.defer(function()
				local root = character:WaitForChild("HumanoidRootPart", 10)
				if root and character.Parent then
					maps:ConfigureCharacter(player, character, (dataService:Get(player) or {}).HighestZoneUnlocked or 1)
					character:PivotTo(maps:GetHubSpawnCFrame(player))
				end
			end)
			local humanoid = character:WaitForChild("Humanoid", 10)
			if humanoid then
				humanoid.Died:Connect(function()
					active[player] = nil
					enemies:Clear(player)
					remotes.State:FireClient(player, { InRun = false })
					remotes.Message:FireClient(player, "You were defeated. Returning to the hub...")
					task.delay(4, function()
						if player.Parent and player.Character == character then player:LoadCharacter() end
					end)
				end)
			end
		end)
		player:LoadCharacter()
	end)
	Players.PlayerRemoving:Connect(function(player)
		active[player] = nil
		enemies:Clear(player)
		maps:ReleaseSlot(player)
	end)
end

function RunService:EnterZone(player, zoneId)
	if not dataService:IsReady(player) or not ZoneConfig[zoneId] then return end
	local data = dataService:Get(player)
	local run = active[player]
	if not run then
		if zoneId ~= 1 then remotes.Message:FireClient(player, "Enter Zone 1 to begin the corridor"); return end
		run = { Zone = 0, Cleared = {}, TotalEnemies = 0 }
		active[player] = run
	end
	if zoneId < run.Zone then
		self:RetreatToZone(player, zoneId)
		return
	end
	if zoneId == run.Zone then return end
	if zoneId ~= run.Zone + 1 and run.Zone ~= 0 then
		remotes.Message:FireClient(player, "Clear the current zone before moving on")
		return
	end
	if zoneId > (data.HighestZoneUnlocked or 1) then
		remotes.Message:FireClient(player, "Clear the previous zone to unlock this area")
		return
	end
	if run.Zone > 0 and not run.Cleared[run.Zone] then
		remotes.Message:FireClient(player, "Defeat every enemy to unlock the next zone")
		return
	end
	run.Zone = zoneId
	player:SetAttribute("CurrentZone", zoneId)
	if run.Cleared[zoneId] then
		maps:SetGateProgress(player, zoneId + 1)
		run.TotalEnemies = 0
		enemies:Clear(player)
		remotes.State:FireClient(player, { InRun = true, ZoneCleared = true, Zone = zoneId, ZoneName = ZoneConfig[zoneId].DisplayName, Total = 0, Remaining = 0 })
		return
	end
	run.TotalEnemies = #ZoneConfig[zoneId].EnemyIds
	run.Cleared[zoneId] = false
	enemies:SpawnFor(player, zoneId)
	remotes.State:FireClient(player, { InRun = true, Zone = zoneId, ZoneName = ZoneConfig[zoneId].DisplayName, Total = run.TotalEnemies, Remaining = run.TotalEnemies })
	startAutoCombat(player)
end

function RunService:RetreatToZone(player, zoneId)
	local run = active[player]
	if not run or zoneId >= run.Zone or not ZoneConfig[zoneId] then return end
	local exitedZone = run.Zone
	-- Retreating cancels the live encounter without awarding a clear. Re-entering
	-- the incomplete zone later will summon its enemies again.
	enemies:Clear(player)
	run.Zone = zoneId
	run.TotalEnemies = 0
	maps:SetGateProgress(player, zoneId + 1)
	player:SetAttribute("CurrentZone", zoneId)
	local previous = ZoneConfig[zoneId]
	remotes.State:FireClient(player, {
		InRun = true,
		Zone = zoneId,
		ZoneName = previous.DisplayName,
		ZoneCleared = run.Cleared[zoneId] == true,
		Total = 0,
		Remaining = 0,
		RetreatedFrom = exitedZone,
	})
	remotes.Message:FireClient(player, "You retreated. The current zone's enemies were cleared; re-enter to fight them again.")
end

function RunService:ReturnToSpawn(player, zoneId)
	local run = active[player]
	if not run or not run.Cleared[zoneId] then
		remotes.Message:FireClient(player, "Clear this zone to activate the return portal")
		return
	end
	self:Exit(player)
	local character = player.Character
	if character then
		character:PivotTo(maps:GetHubSpawnCFrame(player))
		local root = character:FindFirstChild("HumanoidRootPart")
		if root then root.AssemblyLinearVelocity, root.AssemblyAngularVelocity = Vector3.zero, Vector3.zero end
	end
	player:SetAttribute("CurrentZone", nil)
	remotes.Message:FireClient(player, "Returned to the starting platform")
end

function RunService:ZoneCleared(player)
	local run, data = active[player], dataService:Get(player)
	if not run or not data or run.Cleared[run.Zone] then return end
	run.Cleared[run.Zone] = true
	local zone = ZoneConfig[run.Zone]
	data.ClearedZones = data.ClearedZones or {}
	local firstClear = not data.ClearedZones[tostring(run.Zone)]
	data.ClearedZones[tostring(run.Zone)] = true
	local reward = firstClear and zone.CupReward or math.floor(zone.CupReward * 0.2)
	data.Valor += reward
	data.HighestZoneUnlocked = math.max(data.HighestZoneUnlocked or 1, math.min(run.Zone + 1, #ZoneConfig))
	maps:SetGateProgress(player, run.Zone + 1)
	dataService:UpdateAttributes(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + 20) end
	remotes.Reward:FireClient(player, { Valor = reward, ZoneClear = true, ZoneName = zone.DisplayName, NextZone = data.HighestZoneUnlocked })
	remotes.State:FireClient(player, { InRun = true, ZoneCleared = true, Zone = run.Zone, ZoneName = zone.DisplayName, UnlockedZone = data.HighestZoneUnlocked })
end

function RunService:Get(player) return active[player] end
function RunService:Exit(player)
	if not active[player] then return end
	active[player] = nil
	enemies:Clear(player)
	maps:SetGateProgress(player, 1)
	remotes.State:FireClient(player, { InRun = false })
end
return RunService
