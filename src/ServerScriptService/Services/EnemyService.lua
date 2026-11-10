local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunServiceEngine = game:GetService("RunService")
local EnemyConfig = require(ReplicatedStorage.Shared.Config.EnemyConfig)
local ZoneConfig = require(ReplicatedStorage.Shared.Config.ZoneConfig)
local EnemyService = {}
local current = {}
local runService, economy, remotes, maps
local CHASE_SPEED = 10

local function radiusOf(model)
	local body = model and model.PrimaryPart
	return body and math.max(body.Size.X, body.Size.Z) * 0.5 + 0.35 or 2.35
end

local function makeEnemy(player, zoneId, id, index)
	local config = EnemyConfig[id]
	local model = Instance.new("Model")
	model.Name = id
	model:SetAttribute("OwnerUserId", player.UserId)
	model:SetAttribute("EnemyId", id)
	model:SetAttribute("Health", config.Health)
	model:SetAttribute("MaxHealth", config.Health)
	model:SetAttribute("EnemyIndex", index)
	model:SetAttribute("ZoneId", zoneId)
	model:SetAttribute("IsBoss", config.IsBoss == true)
	local body = Instance.new("Part")
	local bodySize = config.IsBoss and Vector3.new(7, 9, 7) or Vector3.new(4, 5, 4)
	body.Name, body.Shape, body.Size = "Body", Enum.PartType.Block, bodySize
	local spawn = maps:CorridorPosition(zoneId, index, tonumber(player:GetAttribute("PlayerSlot")) or 1)
	body.Position, body.Anchored = Vector3.new(spawn.X, bodySize.Y * 0.5 + 1, spawn.Z), true
	body.Material, body.Color, body.CanCollide, body.CanTouch, body.CanQuery = Enum.Material.SmoothPlastic, config.Color, false, false, true
	body.Parent = model
	model.PrimaryPart = body
	if config.IsBoss then
		local aura = Instance.new("Part")
		aura.Name, aura.Shape, aura.Size = "BossAura", Enum.PartType.Cylinder, Vector3.new(0.28, 10, 10)
		aura.CFrame = CFrame.new(body.Position - Vector3.new(0, bodySize.Y * 0.5 - 0.2, 0)) * CFrame.Angles(0, 0, math.rad(90))
		aura.Anchored, aura.CanCollide, aura.CanTouch, aura.CanQuery = true, false, false, false
		aura.Material, aura.Color, aura.Transparency, aura.Parent = Enum.Material.Neon, config.Color, 0.28, model
		local crown = Instance.new("Part")
		crown.Name, crown.Shape, crown.Size = "BossCrown", Enum.PartType.Ball, Vector3.new(2.2, 1.8, 2.2)
		crown.Position = body.Position + Vector3.new(0, bodySize.Y * 0.5 + 0.6, 0)
		crown.Anchored, crown.CanCollide, crown.CanTouch, crown.CanQuery = true, false, false, false
		crown.Material, crown.Color, crown.Parent = Enum.Material.Neon, Color3.fromRGB(255, 211, 99), model
	end
	local billboard = Instance.new("BillboardGui")
	billboard.Name, billboard.Size = "EnemyBillboard", config.IsBoss and UDim2.fromOffset(220, 58) or UDim2.fromOffset(170, 48)
	billboard.StudsOffset, billboard.AlwaysOnTop, billboard.Parent = Vector3.new(0, bodySize.Y * 0.5 + 1.3, 0), true, body
	local label = Instance.new("TextLabel")
	label.Name, label.Size, label.BackgroundTransparency = "NameLabel", UDim2.fromScale(1, 1), 1
	label.TextColor3, label.TextStrokeTransparency = Color3.new(1, 1, 1), 0.2
	label.Font, label.TextScaled = Enum.Font.GothamBold, true
	label.Text = string.format("%s%s  %d/%d", config.IsBoss and "BOSS • " or "", config.Name, config.Health, config.Health)
	label.Parent = billboard
	model.Parent = workspace:FindFirstChild("RiftRunWorld")
	return model
end

function EnemyService:Start(dependencies)
	runService, economy, remotes, maps = dependencies.RunService, dependencies.EconomyService, dependencies.Remotes, dependencies.MapBuilder
	RunServiceEngine.Heartbeat:Connect(function(dt)
		for player, models in pairs(current) do
			local run = runService:Get(player)
			local character = player.Character
			local target = character and character:FindFirstChild("HumanoidRootPart")
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if run and target and target.Parent and humanoid and humanoid.Health > 0 then
				local living = {}
				for _, candidate in models do
					if candidate and candidate.PrimaryPart and (candidate:GetAttribute("Health") or 0) > 0 then table.insert(living, candidate) end
				end
				for _, model in living do
					local body = model and model.PrimaryPart
					if body and body.Parent and (model:GetAttribute("Health") or 0) > 0 then
						local delta = Vector3.new(target.Position.X - body.Position.X, 0, target.Position.Z - body.Position.Z)
						local distance = delta.Magnitude
						local config = EnemyConfig[model:GetAttribute("EnemyId")]
						local now = os.clock()
						local special = config.SpecialAttack
						local usedSpecial = false
						if special and distance <= special.Range and now >= (model:GetAttribute("NextSpecialAttackAt") or 0) then
							model:SetAttribute("NextSpecialAttackAt", now + special.Cooldown)
							humanoid:TakeDamage(special.Damage)
							remotes.Hit:FireClient(player, { IncomingDamage = special.Damage, EnemyName = config.Name, SpecialAttackName = special.Name, SpecialPosition = body.Position, SpecialColor = config.Color, SpecialRadius = special.Range })
							usedSpecial = true
						end
						if not usedSpecial and distance <= config.AttackRange and now >= (model:GetAttribute("NextAttackAt") or 0) then
							model:SetAttribute("NextAttackAt", now + config.AttackCooldown)
							humanoid:TakeDamage(config.Damage)
							remotes.Hit:FireClient(player, { IncomingDamage = config.Damage, EnemyName = config.Name })
						end
						local direction = distance > 0.01 and delta.Unit or Vector3.zero
						local step = distance > 3.5 and math.min(CHASE_SPEED * dt, distance - 3.5) or 0
						local repulsion = Vector3.zero
						for _, other in living do
							if other ~= model and other.PrimaryPart and other.PrimaryPart.Parent then
								local away = Vector3.new(body.Position.X - other.PrimaryPart.Position.X, 0, body.Position.Z - other.PrimaryPart.Position.Z)
								local gap = radiusOf(model) + radiusOf(other) + 1.1
								if away.Magnitude < gap + 2 then
									if away.Magnitude < 0.01 then away = Vector3.new(math.sin(model:GetAttribute("EnemyIndex") * 2.4), 0, math.cos(model:GetAttribute("EnemyIndex") * 2.4)) end
									repulsion += away.Unit * (gap + 2 - away.Magnitude)
								end
							end
						end
						local steering = direction
						if repulsion.Magnitude > 0.01 then
							local combined = direction + repulsion.Unit * 1.6
							steering = combined.Magnitude > 0.01 and combined.Unit or repulsion.Unit
						end
						local proposed = body.Position + steering * step
						for _, other in living do
							if other ~= model and other.PrimaryPart and other.PrimaryPart.Parent then
								local otherPosition = other.PrimaryPart.Position
								local away = Vector3.new(proposed.X - otherPosition.X, 0, proposed.Z - otherPosition.Z)
								local gap = radiusOf(model) + radiusOf(other) + 0.3
								if away.Magnitude < gap then
									if away.Magnitude < 0.01 then away = Vector3.new(math.sin(model:GetAttribute("EnemyIndex") * 2.4), 0, math.cos(model:GetAttribute("EnemyIndex") * 2.4)) end
									proposed += away.Unit * (gap - away.Magnitude)
								end
							end
						end
						local clamped = maps:ClampEnemyPosition(run.Zone, proposed)
						local nextPosition = Vector3.new(clamped.X, body.Position.Y, clamped.Z)
						if (nextPosition - body.Position).Magnitude > 0.01 then
							model:PivotTo(CFrame.lookAt(nextPosition, Vector3.new(target.Position.X, nextPosition.Y, target.Position.Z)))
						end
					end
				end
			end
		end
	end)
end

function EnemyService:SpawnFor(player, zoneId)
	self:Clear(player)
	local run, zone = runService:Get(player), ZoneConfig[zoneId]
	if not run or not zone then return end
	local models = {}
	for index, id in zone.EnemyIds do models[index] = makeEnemy(player, zoneId, id, index) end
	current[player] = models
	self:SendProgress(player)
end

function EnemyService:GetEnemies(player)
	local enemies = {}
	for _, model in current[player] or {} do
		if model and model.Parent and (model:GetAttribute("Health") or 0) > 0 then table.insert(enemies, model) end
	end
	return enemies
end

function EnemyService:GetCurrent(player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local closest, closestDistance
	for _, model in self:GetEnemies(player) do
		local distance = root and (root.Position - model.PrimaryPart.Position).Magnitude or math.huge
		if not closestDistance or distance < closestDistance then closest, closestDistance = model, distance end
	end
	return closest
end

function EnemyService:CountAlive(player) return #self:GetEnemies(player) end

function EnemyService:SendProgress(player)
	local run = runService:Get(player)
	if not run then return end
	local target = self:GetCurrent(player)
	local payload = { ZoneId = run.Zone, ZoneName = maps:ZoneName(run.Zone), Remaining = self:CountAlive(player), Total = run.TotalEnemies or 0 }
	if target then
		local config = EnemyConfig[target:GetAttribute("EnemyId")]
		payload.Name, payload.Health, payload.MaxHealth, payload.IsBoss = config.Name, target:GetAttribute("Health"), config.Health, config.IsBoss
	end
	remotes.Enemy:FireClient(player, payload)
end

function EnemyService:Damage(player, amount, model)
	model = model or self:GetCurrent(player)
	if not model or model:GetAttribute("OwnerUserId") ~= player.UserId or not model.PrimaryPart then return false end
	local alive = false
	for _, candidate in self:GetEnemies(player) do if candidate == model then alive = true; break end end
	if not alive then return false end
	local health = math.max(0, (model:GetAttribute("Health") or 0) - amount)
	model:SetAttribute("Health", health)
	local config = EnemyConfig[model:GetAttribute("EnemyId")]
	local label = model.PrimaryPart:FindFirstChild("EnemyBillboard") and model.PrimaryPart.EnemyBillboard:FindFirstChild("NameLabel")
	if label then label.Text = string.format("%s  %d/%d", config.Name, health, config.Health) end
	if health <= 0 then
		for index, candidate in current[player] or {} do if candidate == model then table.remove(current[player], index); break end end
		model:Destroy()
		economy:AwardEnemy(player, config)
		self:SendProgress(player)
		if self:CountAlive(player) == 0 then runService:ZoneCleared(player) end
	else self:SendProgress(player) end
	return true
end

function EnemyService:Clear(player)
	for _, model in current[player] or {} do if model then model:Destroy() end end
	current[player] = nil
end
return EnemyService
