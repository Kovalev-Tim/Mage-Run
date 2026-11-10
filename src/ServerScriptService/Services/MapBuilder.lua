local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PhysicsService = game:GetService("PhysicsService")
local MageConfig = require(ReplicatedStorage.Shared.Config.MageConfig)
local EggConfig = require(ReplicatedStorage.Shared.Config.EggConfig)
local ZoneConfig = require(ReplicatedStorage.Shared.Config.ZoneConfig)
local MapBuilder = {}
local root
local playerSlots = {}
local zoneParts = {}
local portalPrompts = {}
local returnPrompts = {}
local archetypeButtons = {}
local gateCollisionGroups = {}
local meditationUpgradePrompt
local meditationCenter = Vector3.new(0, 0, 44)
local meditationRadius = 14

local function part(parent, name, size, cframe, color, material)
	local item = Instance.new("Part")
	item.Name, item.Size, item.CFrame = name, size, cframe
	item.Anchored, item.Color, item.Material = true, color, material or Enum.Material.SmoothPlastic
	item.TopSurface, item.BottomSurface = Enum.SurfaceType.Studs, Enum.SurfaceType.Inlet
	item.Parent = parent
	return item
end

function MapBuilder:Start()
	root = Workspace:FindFirstChild("RiftRunWorld") or Instance.new("Folder")
	root.Name = "RiftRunWorld"
	root:ClearAllChildren()
	root.Parent = Workspace
	playerSlots, zoneParts, portalPrompts, returnPrompts, archetypeButtons, gateCollisionGroups = {}, {}, {}, {}, {}, {}
	meditationUpgradePrompt = nil
	local hub = Instance.new("Folder")
	hub.Name, hub.Parent = "Hub", root
	part(hub, "SharedHubFloor", Vector3.new(190, 4, 760), CFrame.new(0, -2, -270), Color3.fromRGB(78, 109, 93), Enum.Material.Grass)
	part(hub, "StartingPlatform", Vector3.new(180, 1, 70), CFrame.new(0, 0.5, 50), Color3.fromRGB(119, 111, 103), Enum.Material.Cobblestone)
	part(hub, "CorridorLeftWall", Vector3.new(2, 14, 600), CFrame.new(-43, 7, -285), Color3.fromRGB(48, 58, 67), Enum.Material.Slate)
	part(hub, "CorridorRightWall", Vector3.new(2, 14, 600), CFrame.new(43, 7, -285), Color3.fromRGB(48, 58, 67), Enum.Material.Slate)
	local zonesFolder = Instance.new("Folder")
	zonesFolder.Name, zonesFolder.Parent = "CorridorZones", hub
	local barriers = Instance.new("Folder")
	barriers.Name, barriers.Parent = "ZoneBarriers", hub
	local returns = Instance.new("Folder")
	returns.Name, returns.Parent = "ZoneReturnPortals", hub
	for slot = 1, 6 do
		pcall(function() PhysicsService:RegisterCollisionGroup("RiftPlayer" .. slot) end)
	end
	for _, zone in ZoneConfig do
		local center = (zone.Start + zone.Finish) / 2
		local length = zone.Start - zone.Finish
		part(zonesFolder, "ZoneFloor_" .. zone.Id, Vector3.new(84, 1, length), CFrame.new(0, 0.5, center), zone.Color, zone.Material)
		local marker = part(zonesFolder, "ZoneMarker_" .. zone.Id, Vector3.new(84, 0.18, 1), CFrame.new(0, 1.1, zone.Start), zone.Color, Enum.Material.Neon)
		marker.CanCollide = false
		local trigger = part(zonesFolder, "ZoneTrigger_" .. zone.Id, Vector3.new(80, 16, 3), CFrame.new(0, 8, zone.Start), zone.Color)
		trigger.Transparency, trigger.CanCollide, trigger.CanTouch = 1, false, true
		trigger:SetAttribute("ZoneId", zone.Id)
		zoneParts[zone.Id] = trigger
		if zone.Id > 1 then
			local gateGroup = "RiftGate" .. zone.Id
			pcall(function() PhysicsService:RegisterCollisionGroup(gateGroup) end)
			gateCollisionGroups[zone.Id] = gateGroup
			local gate = part(barriers, "ZoneBarrier_" .. zone.Id, Vector3.new(82, 13, 1.2), CFrame.new(0, 6.5, zone.Start + 1.5), Color3.fromRGB(255, 76, 86), Enum.Material.ForceField)
			gate.Transparency, gate.CanCollide, gate.CanTouch = 0.42, true, false
			gate.CollisionGroup = gateGroup
			gate:SetAttribute("ZoneGateId", zone.Id)
			for slot = 1, 6 do
				pcall(function() PhysicsService:CollisionGroupSetCollidable("RiftPlayer" .. slot, gateGroup, true) end)
			end
		end
		local returnModel = Instance.new("Model")
		returnModel.Name, returnModel.Parent = string.format("ZoneReturn_%02d", zone.Id), returns
		returnModel:SetAttribute("ReturnPortalZone", zone.Id)
		local returnZ, returnX = zone.Finish + 12, 30
		local archColor = zone.Color:Lerp(Color3.fromRGB(205, 228, 255), 0.25)
		local leftPillar = part(returnModel, "ReturnLeftPillar", Vector3.new(1.5, 8, 1.5), CFrame.new(returnX - 4.5, 4, returnZ), archColor, Enum.Material.Slate)
		local rightPillar = part(returnModel, "ReturnRightPillar", Vector3.new(1.5, 8, 1.5), CFrame.new(returnX + 4.5, 4, returnZ), archColor, Enum.Material.Slate)
		part(returnModel, "ReturnLintel", Vector3.new(10, 1.5, 1.5), CFrame.new(returnX, 8.25, returnZ), archColor, Enum.Material.Slate)
		local field = part(returnModel, "ReturnField", Vector3.new(7.5, 6.5, 0.35), CFrame.new(returnX, 4, returnZ), archColor, Enum.Material.Neon)
		field.Transparency, field.CanCollide, field.CanTouch = 0.22, false, false
		local pad = part(returnModel, "ReturnPad", Vector3.new(7, 0.5, 5), CFrame.new(returnX, 0.75, returnZ + 3), Color3.fromRGB(40, 50, 69), Enum.Material.Slate)
		pad:SetAttribute("ReturnPortalZone", zone.Id)
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name, prompt.ActionText, prompt.ObjectText = "ReturnToSpawn_" .. zone.Id, "Return to Spawn", "Zone Clear Portal"
		prompt.HoldDuration, prompt.MaxActivationDistance, prompt.Parent = 0, 12, pad
		prompt:SetAttribute("ReturnPortalZone", zone.Id)
		returnPrompts[zone.Id] = prompt
		local plaque = part(zonesFolder, "ZoneName_" .. zone.Id, Vector3.new(24, 5, 1), CFrame.new(0, 5, zone.Start - 3), Color3.fromRGB(40, 48, 58), Enum.Material.Slate)
		plaque.CanCollide = false
		local board = Instance.new("SurfaceGui")
		board.Face, board.SizingMode, board.Parent = Enum.NormalId.Back, Enum.SurfaceGuiSizingMode.PixelsPerStud, plaque
		local label = Instance.new("TextLabel")
		label.Size, label.BackgroundTransparency = UDim2.fromScale(1, 1), 1
		local zoneType = zone.BossIndex and "  •  BOSS ZONE" or ""
		label.Text, label.TextColor3, label.TextScaled = string.format("ZONE %d  •  %s%s", zone.Id, zone.DisplayName, zoneType), zone.Color, true
		label.Font, label.Parent = Enum.Font.GothamBlack, board
	end
	for slot = 1, 6 do
		local playerGroup = "RiftPlayer" .. slot
		pcall(function() PhysicsService:CollisionGroupSetCollidable(playerGroup, "Default", true) end)
		for otherSlot = 1, 6 do
			pcall(function() PhysicsService:CollisionGroupSetCollidable(playerGroup, "RiftPlayer" .. otherSlot, true) end)
		end
	end
	local stands = Instance.new("Folder")
	stands.Name, stands.Parent = "HubStands", hub
	local function addStandSign(x, z, message, color, sideFacing)
		local signCFrame
		if sideFacing then
			local position = Vector3.new(x - 6, 5, z)
			signCFrame = CFrame.lookAt(position, position + Vector3.new(-1, 0, 0))
		else
			signCFrame = CFrame.lookAt(Vector3.new(x, 5.5, z - 7), Vector3.new(x, 5.5, 15))
		end
		local signSize = sideFacing and Vector3.new(10, 6, 1) or Vector3.new(16, 7, 1)
		local signPart = part(stands, "StandSign", signSize, signCFrame, Color3.fromRGB(39, 45, 54), Enum.Material.Slate)
		signPart.CanCollide = false
		local sign = Instance.new("SurfaceGui")
		sign.Face, sign.SizingMode, sign.Parent = Enum.NormalId.Front, Enum.SurfaceGuiSizingMode.PixelsPerStud, signPart
		local text = Instance.new("TextLabel")
		text.Size, text.BackgroundTransparency = UDim2.fromScale(1, 1), 1
		text.Text, text.TextColor3, text.TextStrokeTransparency = message, color, 0.15
		text.TextScaled, text.TextWrapped, text.Font, text.Parent = true, true, Enum.Font.GothamBold, sign
	end
	local archetypeOrder = { "Pyromancer", "Rootweaver", "Starseer", "Frostcaller", "Stormkeeper", "Tidecaller", "Sunweaver", "Umbramancer", "Voidcaller" }
	part(stands, "MageGallery", Vector3.new(39, 1, 48), CFrame.new(68.5, 0.5, 43), Color3.fromRGB(54, 58, 73), Enum.Material.Slate)
	local mageDisplays = Instance.new("Folder")
	mageDisplays.Name, mageDisplays.Parent = "MageDisplays", stands
	for index, archetypeId in archetypeOrder do
		local archetype = MageConfig[archetypeId]
		local column, row = (index - 1) % 3, math.floor((index - 1) / 3)
		local x, mageZ = 53 + column * 12, 25 + row * 12
		local pedestal = part(stands, "MageStand_" .. archetypeId, Vector3.new(9, 1.5, 9), CFrame.new(x, 1.75, mageZ), archetype.Color, Enum.Material.Slate)
		local figure = Instance.new("Model")
		figure.Name = "MageDisplay_" .. archetypeId
		figure:SetAttribute("MageId", archetypeId)
		local robe = archetype.Color:Lerp(Color3.fromRGB(28, 31, 42), 0.48)
		local torso = part(figure, "Robe", Vector3.new(1.8, 2.2, 1.2), CFrame.lookAt(Vector3.new(x, 4.3, mageZ + 1), Vector3.new(x, 4.3, mageZ + 15)), robe, Enum.Material.Slate)
		local head = part(figure, "Head", Vector3.new(1.4, 1.4, 1.4), CFrame.new(x, 6.05, mageZ + 1.05), Color3.fromRGB(230, 196, 160), Enum.Material.SmoothPlastic)
		head.Shape = Enum.PartType.Ball
		part(figure, "EyeLeft", Vector3.new(0.16, 0.16, 0.1), CFrame.new(x - 0.27, 6.1, mageZ + 1.7), Color3.fromRGB(28, 30, 36), Enum.Material.SmoothPlastic)
		part(figure, "EyeRight", Vector3.new(0.16, 0.16, 0.1), CFrame.new(x + 0.27, 6.1, mageZ + 1.7), Color3.fromRGB(28, 30, 36), Enum.Material.SmoothPlastic)
		local brim = part(figure, "HatBrim", Vector3.new(0.25, 2.2, 2.2), CFrame.new(x, 6.85, mageZ + 1) * CFrame.Angles(0, 0, math.rad(90)), archetype.Color, Enum.Material.SmoothPlastic)
		brim.Shape = Enum.PartType.Cylinder
		local hat = Instance.new("WedgePart")
		hat.Name, hat.Size, hat.CFrame = "MageHat", Vector3.new(1.5, 1.5, 1.5), CFrame.new(x, 7.55, mageZ + 1)
		hat.Anchored, hat.CanCollide, hat.Color, hat.Material = true, false, archetype.Color, Enum.Material.SmoothPlastic
		hat.Parent = figure
		local staff = part(figure, "Staff", Vector3.new(4.4, 0.25, 0.25), CFrame.new(x + 1.9, 4.8, mageZ + 1) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(109, 75, 49), Enum.Material.Wood)
		staff.Shape = Enum.PartType.Cylinder
		local mageOrb = part(figure, "StaffFocus", Vector3.new(0.9, 0.9, 0.9), CFrame.new(x + 1.9, 7.15, mageZ + 1), archetype.Color, Enum.Material.Neon)
		mageOrb.Shape = Enum.PartType.Ball
		part(figure, "LeftArm", Vector3.new(0.55, 1.7, 0.65), CFrame.new(x - 1.15, 4.4, mageZ + 1), robe, Enum.Material.Slate)
		part(figure, "RightArm", Vector3.new(0.55, 1.7, 0.65), CFrame.new(x + 1.15, 4.4, mageZ + 1), robe, Enum.Material.Slate)
		part(figure, "LeftBoot", Vector3.new(0.65, 1, 0.8), CFrame.new(x - 0.48, 3.15, mageZ + 1), Color3.fromRGB(48, 42, 39), Enum.Material.SmoothPlastic)
		part(figure, "RightBoot", Vector3.new(0.65, 1, 0.8), CFrame.new(x + 0.48, 3.15, mageZ + 1), Color3.fromRGB(48, 42, 39), Enum.Material.SmoothPlastic)
		for _, piece in figure:GetChildren() do
			if piece:IsA("BasePart") then piece.CanCollide = false end
		end
		figure.Parent = mageDisplays
		local costText = (archetype.CupCost or 0) == 0 and "FREE" or string.format("%d VALOR", archetype.CupCost)
		local buttonPosition = Vector3.new(x - 4.4, 2.6, mageZ)
		local button = part(stands, "MageButton_" .. archetypeId, Vector3.new(8, 1.4, 0.55), CFrame.lookAt(buttonPosition, buttonPosition + Vector3.new(-1, 0, 0)), Color3.fromRGB(33, 39, 52), Enum.Material.Slate)
		button.CanCollide = false
		local surface = Instance.new("SurfaceGui")
		surface.Face, surface.SizingMode, surface.Parent = Enum.NormalId.Front, Enum.SurfaceGuiSizingMode.PixelsPerStud, button
		local buttonText = Instance.new("TextLabel")
		buttonText.Size, buttonText.BackgroundTransparency = UDim2.fromScale(1, 1), 1
		buttonText.Text = string.format("%s  •  %s", string.upper(archetype.DisplayName), costText)
		buttonText.TextColor3, buttonText.TextScaled, buttonText.Font = archetype.Color, true, Enum.Font.GothamBlack
		buttonText.Parent = surface
		local click = Instance.new("ClickDetector")
		click.MaxActivationDistance, click.Parent = 18, button
		click:SetAttribute("ArchetypeId", archetypeId)
		table.insert(archetypeButtons, click)
	end
	local eggDisplays = Instance.new("Folder")
	eggDisplays.Name, eggDisplays.Parent = "EggDisplays", stands
	local eggOrder = { "ArchmageEgg", "CrystalEgg", "AstralEgg" }
	for index, eggId in eggOrder do
		local eggConfig = EggConfig[eggId]
		local x, eggZ = -76 + (index - 1) * 17, 67
		local eggStand = part(stands, "EggStand_" .. eggId, Vector3.new(10, 1.5, 8), CFrame.new(x, 1.75, eggZ), Color3.fromRGB(119, 95, 75), Enum.Material.WoodPlanks)
		local eggModel = part(eggDisplays, eggId, Vector3.new(4.2, 5.2, 4.2), CFrame.new(x, 5.6, eggZ), eggConfig.Color, Enum.Material.Neon)
		eggModel.Shape = Enum.PartType.Ball
		eggModel.CanCollide = false
		for spot = 1, 3 do
			local angle = math.rad((spot - 1) * 120)
			local speck = part(eggDisplays, "EggMark_" .. eggId .. "_" .. spot, Vector3.new(0.45, 0.45, 0.45), CFrame.new(x + math.cos(angle) * 1.25, 5.7 + math.sin(angle) * 1.2, eggZ + 1.85), Color3.new(1, 1, 1), Enum.Material.Neon)
			speck.Shape = Enum.PartType.Ball
			speck.CanCollide = false
		end
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name, prompt.ActionText, prompt.ObjectText = "Buy" .. eggId, "Hatch • " .. eggConfig.Cost .. " Valor", eggConfig.DisplayName
		prompt.HoldDuration, prompt.MaxActivationDistance, prompt.Parent = 0, 12, eggStand
		prompt:SetAttribute("EggId", eggId)
		addStandSign(x, eggZ, string.format("%s\n%d VALOR", string.upper(eggConfig.DisplayName), eggConfig.Cost), eggConfig.Color)
	end
	local meditation = Instance.new("Folder")
	meditation.Name, meditation.Parent = "MeditationPool", hub
	local basin = part(meditation, "PoolBasin", Vector3.new(1.1, 32, 32), CFrame.new(meditationCenter.X, 1.55, meditationCenter.Z) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(58, 69, 83), Enum.Material.Slate)
	basin.Shape = Enum.PartType.Cylinder
	local water = part(meditation, "ArcaneWater", Vector3.new(0.16, 25, 25), CFrame.new(meditationCenter.X, 2.2, meditationCenter.Z) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(89, 189, 231), Enum.Material.Glass)
	water.Shape, water.Transparency, water.CanCollide, water.CanTouch = Enum.PartType.Cylinder, 0.28, false, false
	local runeRing = part(meditation, "MeditationRunes", Vector3.new(0.25, 36, 36), CFrame.new(meditationCenter.X, 1.2, meditationCenter.Z) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(105, 91, 213), Enum.Material.Neon)
	runeRing.Shape, runeRing.Transparency, runeRing.CanCollide, runeRing.CanTouch = Enum.PartType.Cylinder, 0.35, false, false
	local focusStone = part(meditation, "FocusStone", Vector3.new(2.2, 4, 2.2), CFrame.new(meditationCenter.X, 4.2, meditationCenter.Z), Color3.fromRGB(177, 146, 255), Enum.Material.Neon)
	focusStone.CanCollide = false
	local upgradePrompt = Instance.new("ProximityPrompt")
	upgradePrompt.Name, upgradePrompt.ActionText, upgradePrompt.ObjectText = "MeditationUpgradePrompt", "Upgrade Skill Mastery", "Focus Stone"
	upgradePrompt.KeyboardKeyCode, upgradePrompt.HoldDuration, upgradePrompt.MaxActivationDistance = Enum.KeyCode.F, 0, 13
	upgradePrompt.Parent = focusStone
	meditationUpgradePrompt = upgradePrompt
	local poolSignPart = part(meditation, "MeditationSign", Vector3.new(20, 5, 1), CFrame.lookAt(Vector3.new(0, 5.5, 21), Vector3.new(0, 5.5, 36)), Color3.fromRGB(36, 46, 63), Enum.Material.Slate)
	poolSignPart.CanCollide = false
	local poolSign = Instance.new("SurfaceGui")
	poolSign.Face, poolSign.SizingMode, poolSign.Parent = Enum.NormalId.Front, Enum.SurfaceGuiSizingMode.PixelsPerStud, poolSignPart
	local poolLabel = Instance.new("TextLabel")
	poolLabel.Size, poolLabel.BackgroundTransparency = UDim2.fromScale(1, 1), 1
	poolLabel.Text = "MEDITATION POOL\nStand still to gain Magic Power automatically\nPress F to upgrade Skill Mastery"
	poolLabel.TextColor3, poolLabel.TextScaled, poolLabel.TextWrapped = Color3.fromRGB(175, 219, 255), true, true
	poolLabel.Font, poolLabel.Parent = Enum.Font.GothamBlack, poolSign
	local function createPortal(parent, prefix, center, color, action, object, destination)
		part(parent, prefix .. "LeftPillar", Vector3.new(3, 14, 3), CFrame.new(center.X - 9, 8, center.Z), color, Enum.Material.Slate)
		local right = part(parent, prefix .. "RightPillar", Vector3.new(3, 14, 3), CFrame.new(center.X + 9, 8, center.Z), color, Enum.Material.Slate)
		part(parent, prefix .. "Lintel", Vector3.new(21, 3, 3), CFrame.new(center.X, 14, center.Z), color, Enum.Material.Slate)
		local field = part(parent, prefix .. "Field", Vector3.new(14, 10, 0.6), CFrame.new(center.X, 7, center.Z), color, Enum.Material.Neon)
		field.Transparency, field.CanCollide, field.CanTouch = 0.3, false, false
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name, prompt.ActionText, prompt.ObjectText = prefix .. "Prompt", action, object
		prompt.HoldDuration, prompt.MaxActivationDistance, prompt.Parent = 0, 14, right
		prompt:SetAttribute("PortalDestination", destination)
		table.insert(portalPrompts, prompt)
		return left, right, field
	end
	createPortal(hub, "RebirthGate", Vector3.new(0, 0, 78), Color3.fromRGB(182, 91, 255), "Enter", "Rebirth Dimension", "Rebirth")
	local dimension = Instance.new("Folder")
	dimension.Name, dimension.Parent = "RebirthDimension", root
	part(dimension, "DimensionFloor", Vector3.new(140, 1, 130), CFrame.new(500, 0.5, 0), Color3.fromRGB(39, 37, 62), Enum.Material.Slate)
	for index = 1, 5 do
		local x = 445 + index * 22
		local crystal = part(dimension, "VoidCrystal_" .. index, Vector3.new(4, 12 + (index % 3) * 3, 4), CFrame.new(x, 7, -20 - (index % 2) * 25), Color3.fromRGB(104, 69, 179), Enum.Material.Neon)
		crystal.CanCollide = false
	end
	createPortal(dimension, "ReturnGate", Vector3.new(500, 0, -45), Color3.fromRGB(109, 205, 255), "Return", "Archmage Hub", "Hub")
	Workspace:SetAttribute("RiftRunWorldReady", true)
end

function MapBuilder:GetHubSpawnCFrame(player)
	local slot = player and tonumber(player:GetAttribute("PlayerSlot")) or 1
	local x = -20 + (slot - 1) * 8
	return CFrame.lookAt(Vector3.new(x, 5, 69), Vector3.new(0, 5, 8))
end
function MapBuilder:GetZoneParts() return zoneParts end
function MapBuilder:GetReturnPrompts() return returnPrompts end
function MapBuilder:SetGateProgress(player, highestZone)
	local slot = player and tonumber(player:GetAttribute("PlayerSlot"))
	if not slot then return end
	local playerGroup = "RiftPlayer" .. slot
	highestZone = highestZone or 1
	player:SetAttribute("GateOpenThrough", highestZone)
	for zoneId, gateGroup in gateCollisionGroups do
	local isOpen = zoneId <= highestZone
		pcall(function() PhysicsService:CollisionGroupSetCollidable(playerGroup, gateGroup, not isOpen) end)
	end
end
function MapBuilder:ConfigureCharacter(player, character, highestZone)
	local slot = player and tonumber(player:GetAttribute("PlayerSlot"))
	if not slot or not character then return end
	local group = "RiftPlayer" .. slot
	local function assign(item)
		if item:IsA("BasePart") then item.CollisionGroup = group end
	end
	for _, item in character:GetDescendants() do assign(item) end
	character.DescendantAdded:Connect(assign)
	-- Gates are per-run. Historical unlocks still count toward progression, but
	-- players must clear each zone again before its next barrier opens.
	self:SetGateProgress(player, 1)
end
function MapBuilder:GetArchetypeButtons() return archetypeButtons end
function MapBuilder:HasArchetypeStand(archetypeId)
	return root.Hub.HubStands:FindFirstChild("MageStand_" .. archetypeId) ~= nil
end
function MapBuilder:GetEggPrompts()
	local prompts = {}
	for _, stand in root.Hub.HubStands:GetChildren() do
		if string.sub(stand.Name, 1, 9) == "EggStand_" then
			local prompt = stand:FindFirstChildWhichIsA("ProximityPrompt")
			if prompt then table.insert(prompts, prompt) end
		end
	end
	return prompts
end
function MapBuilder:GetDimensionPrompts() return portalPrompts end
function MapBuilder:GetMeditationUpgradePrompt() return meditationUpgradePrompt end
function MapBuilder:IsAtMeditationPool(player)
	local character = player and player.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return false end
	local offset = Vector3.new(rootPart.Position.X - meditationCenter.X, 0, rootPart.Position.Z - meditationCenter.Z)
	return offset.Magnitude <= meditationRadius
end
function MapBuilder:GetMeditationRadius() return meditationRadius end
function MapBuilder:GetMeditationCenter() return meditationCenter end
function MapBuilder:GetDimensionCFrame(destination, player)
	if destination == "Rebirth" then return CFrame.new(500, 5, 28) end
	return self:GetHubSpawnCFrame(player)
end
function MapBuilder:AssignSlot(player)
	for slot = 1, 6 do
		if not playerSlots[slot] then
			playerSlots[slot] = player.UserId
			return slot
		end
	end
	return nil
end
function MapBuilder:ReleaseSlot(player)
	for slot = 1, 6 do
		if playerSlots[slot] == player.UserId then
			playerSlots[slot] = nil
			return
		end
	end
end
function MapBuilder:CorridorPosition(zoneId, enemyIndex, playerSlot)
	local zone = ZoneConfig[zoneId]
	local step = (zone.Start - zone.Finish) / (#zone.EnemyIds + 1)
	local x = -30 + ((playerSlot - 1) % 6) * 12
	return Vector3.new(x, 3, zone.Start - step * enemyIndex)
end
function MapBuilder:ZoneName(zoneId) return ZoneConfig[zoneId] and ZoneConfig[zoneId].DisplayName or "Corridor" end
function MapBuilder:ClampEnemyPosition(zoneId, position)
	local zone = ZoneConfig[zoneId]
	return Vector3.new(math.clamp(position.X, -38, 38), position.Y, math.clamp(position.Z, zone.Finish + 3, zone.Start - 3))
end
return MapBuilder
