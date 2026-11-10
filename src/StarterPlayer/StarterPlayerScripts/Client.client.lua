local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("RiftRunRemotes")
local castSkillRemote = remotes:WaitForChild("CastSkill")
local upgradeRemote = remotes:WaitForChild("Upgrade")
local sprintRemote = remotes:WaitForChild("Sprint")
local stateRemote = remotes:WaitForChild("State")
local enemyRemote = remotes:WaitForChild("Enemy")
local rewardRemote = remotes:WaitForChild("Reward")
local hitRemote = remotes:WaitForChild("Hit")
local messageRemote = remotes:WaitForChild("Message")
local petActionRemote = remotes:WaitForChild("PetAction")
local openEggRemote = remotes:WaitForChild("OpenEgg")
local hatchEggRemote = remotes:WaitForChild("HatchEgg")
local hatchResultRemote = remotes:WaitForChild("HatchResult")
local MageConfig = require(ReplicatedStorage.Shared.Config.MageConfig)
local UpgradeConfig = require(ReplicatedStorage.Shared.Config.UpgradeConfig)
local EggConfig = require(ReplicatedStorage.Shared.Config.EggConfig)
local CompanionConfig = require(ReplicatedStorage.Shared.Config.CompanionConfig)
local MonetizationConfig = require(ReplicatedStorage.Shared.Config.MonetizationConfig)

-- ===== Theme & widgets =====
local FONT = Enum.Font.FredokaOne
local WHITE, BLACK = Color3.new(1, 1, 1), Color3.new(0, 0, 0)
local PANEL, SLOT, GOLD = Color3.fromRGB(41, 42, 58), Color3.fromRGB(62, 64, 84), Color3.fromRGB(255, 214, 79)
local GREEN, RED, BLUE, GREY = Color3.fromRGB(70, 200, 105), Color3.fromRGB(232, 60, 72), Color3.fromRGB(52, 152, 245), Color3.fromRGB(88, 90, 104)
local LIGHT = Color3.fromRGB(196, 205, 230)

local gui = Instance.new("ScreenGui")
gui.Name, gui.ResetOnSpawn, gui.ZIndexBehavior, gui.Parent = "RiftRunHUD", false, Enum.ZIndexBehavior.Sibling, player:WaitForChild("PlayerGui")

local function rounded(instance, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius, corner.Parent = UDim.new(0, radius), instance
	return corner
end
local function outline(instance, thickness, color)
	local stroke = Instance.new("UIStroke")
	stroke.Thickness, stroke.Color, stroke.ApplyStrokeMode, stroke.Parent = thickness or 3, color or BLACK, Enum.ApplyStrokeMode.Border, instance
	return stroke
end
local function gloss(instance, top, bottom)
	local gradient = Instance.new("UIGradient")
	gradient.Color, gradient.Rotation, gradient.Parent = ColorSequence.new(top or WHITE, bottom or Color3.fromRGB(176, 176, 176)), 90, instance
end
local function padding(instance, amount)
	local pad = Instance.new("UIPadding")
	pad.PaddingTop, pad.PaddingBottom, pad.PaddingLeft, pad.PaddingRight, pad.Parent = UDim.new(0, amount), UDim.new(0, amount), UDim.new(0, amount), UDim.new(0, amount), instance
end
local function makeText(parent, value, size, position, color, textSize, alignX)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency, label.Size, label.Position = 1, size, position
	label.Text, label.TextColor3, label.Font, label.TextSize = value, color or WHITE, FONT, textSize or 20
	label.TextStrokeTransparency, label.TextWrapped = 0, true
	label.TextXAlignment, label.Parent = alignX or Enum.TextXAlignment.Center, parent
	return label
end
local function makeLabel(name, value, size, position, color)
	local item = Instance.new("TextLabel")
	item.Name, item.Size, item.Position = name, size, position
	item.BackgroundColor3, item.BackgroundTransparency = PANEL, 0.08
	item.TextColor3, item.Font, item.TextScaled, item.TextStrokeTransparency = color or WHITE, FONT, true, 0
	item.Text, item.Parent = value, gui
	rounded(item, 10)
	outline(item, 3)
	padding(item, 6)
	return item
end
local function makeButton(name, value, size, position, color, parent)
	local button = Instance.new("TextButton")
	button.Name, button.Size, button.Position = name, size, position
	button.BackgroundColor3, button.AutoButtonColor, button.Parent = color, false, parent or gui
	button.Text, button.TextColor3, button.TextScaled, button.Font, button.TextStrokeTransparency = value, WHITE, true, FONT, 0
	rounded(button, 8)
	outline(button, 3)
	gloss(button)
	padding(button, 4)
	local scale = Instance.new("UIScale")
	scale.Parent = button
	local function tweenScale(target, duration)
		TweenService:Create(scale, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = target }):Play()
	end
	button.MouseEnter:Connect(function() tweenScale(1.07, 0.12) end)
	button.MouseLeave:Connect(function() tweenScale(1, 0.14) end)
	button.MouseButton1Down:Connect(function() tweenScale(0.94, 0.06) end)
	button.MouseButton1Up:Connect(function() tweenScale(1.07, 0.08) end)
	return button
end
local function short(n)
	n = n or 0
	if n >= 1e6 then return string.format("%.1fM", n / 1e6) end
	if n >= 1e4 then return string.format("%.1fK", n / 1e3) end
	return tostring(math.floor(n))
end
local function parseIds(value, separator)
	local counts = {}
	for entry in string.gmatch(value or "", "[^" .. separator .. "]+") do
		local id = string.gsub(entry, "^%s*(.-)%s*$", "%1")
		if id ~= "" then counts[id] = (counts[id] or 0) + 1 end
	end
	return counts
end

-- ===== HUD (top center, bottom) =====
local zoneLabel = makeLabel("Zone", "ARCHMAGE'S CORRIDOR", UDim2.fromOffset(300, 48), UDim2.new(0.5, -150, 0, 12), Color3.fromRGB(190, 255, 218))
local enemyLabel = makeLabel("Enemy", "Walk into Zone 1 to summon enemies", UDim2.fromOffset(400, 44), UDim2.new(0.5, -200, 0, 66), WHITE)
local sprintHint = makeLabel("SprintHint", "HOLD SHIFT TO SPRINT", UDim2.fromOffset(230, 34), UDim2.new(0, 12, 1, -46), Color3.fromRGB(178, 221, 255))
local boltButton = makeButton("MageSkillQ", "FIREBALL  [Q]", UDim2.fromOffset(170, 72), UDim2.new(1, -360, 1, -100), Color3.fromRGB(214, 95, 57))
local waveButton = makeButton("MageSkillE", "FLAME WAVE  [E]", UDim2.fromOffset(170, 72), UDim2.new(1, -180, 1, -100), Color3.fromRGB(149, 77, 54))
local toast = makeLabel("Toast", "", UDim2.fromOffset(400, 46), UDim2.new(0.5, -200, 1, -58), Color3.fromRGB(255, 237, 176))
toast.Visible, toast.ZIndex = false, 10
local toastPosition = toast.Position
local toastTweenId = 0
local function showToast(message, duration)
	toastTweenId += 1
	local currentId = toastTweenId
	toast.Text, toast.Visible = tostring(message), true
	toast.Position, toast.TextTransparency, toast.BackgroundTransparency = UDim2.new(0.5, -200, 1, -42), 1, 1
	TweenService:Create(toast, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = toastPosition, TextTransparency = 0, BackgroundTransparency = 0.08 }):Play()
	task.delay(duration or 2, function()
		if currentId ~= toastTweenId then return end
		local fade = TweenService:Create(toast, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Position = UDim2.new(0.5, -200, 1, -42), TextTransparency = 1, BackgroundTransparency = 1 })
		fade:Play()
		fade.Completed:Wait()
		if currentId == toastTweenId then toast.Visible = false end
	end)
end

-- ===== Window (opened from the sidebar) =====
local window = Instance.new("Frame")
window.Name, window.AnchorPoint, window.Position, window.Size = "Window", Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.5), UDim2.fromScale(0.62, 0.68)
window.BackgroundColor3, window.Visible, window.Parent = PANEL, false, gui
rounded(window, 12)
outline(window, 4)
local windowLimit = Instance.new("UISizeConstraint")
windowLimit.MinSize, windowLimit.MaxSize, windowLimit.Parent = Vector2.new(480, 360), Vector2.new(720, 470), window
local windowScale = Instance.new("UIScale")
windowScale.Scale, windowScale.Parent = 0.92, window
local header = Instance.new("Frame")
header.Name, header.Size, header.BackgroundColor3, header.Parent = "Header", UDim2.new(1, 0, 0, 56), Color3.fromRGB(255, 170, 45), window
rounded(header, 10)
outline(header, 3)
gloss(header, Color3.fromRGB(255, 255, 255), Color3.fromRGB(222, 130, 30))
local title = makeText(header, "", UDim2.new(0.5, 0, 1, 0), UDim2.fromOffset(18, 0), WHITE, 34, Enum.TextXAlignment.Left)
local headerInfo = makeText(header, "", UDim2.new(0.45, 0, 1, 0), UDim2.new(1, -70, 0, 0), Color3.fromRGB(118, 255, 108), 20, Enum.TextXAlignment.Right)
headerInfo.AnchorPoint = Vector2.new(1, 0)
local closeButton = makeButton("Close", "X", UDim2.fromOffset(42, 42), UDim2.new(1, -52, 0.5, -21), RED, header)
local body = Instance.new("Frame")
body.Name, body.Size, body.Position, body.BackgroundTransparency, body.Parent = "Body", UDim2.new(1, -20, 1, -70), UDim2.fromOffset(10, 62), 1, window

local pages = {}
local function newPage(name)
	local page = Instance.new("Frame")
	page.Name, page.Size, page.BackgroundTransparency, page.Visible, page.Parent = name, UDim2.fromScale(1, 1), 1, false, body
	pages[name] = page
	return page
end
local function scrollList(parent, size, position)
	local scroll = Instance.new("ScrollingFrame")
	scroll.Size, scroll.Position, scroll.BackgroundColor3, scroll.BorderSizePixel = size, position, Color3.fromRGB(52, 54, 72), 0
	scroll.ScrollBarThickness, scroll.AutomaticCanvasSize, scroll.CanvasSize, scroll.Parent = 6, Enum.AutomaticSize.Y, UDim2.new(), parent
	rounded(scroll, 10)
	outline(scroll, 3)
	padding(scroll, 8)
	return scroll
end
local function listLayout(parent)
	local layout = Instance.new("UIListLayout")
	layout.Padding, layout.SortOrder, layout.Parent = UDim.new(0, 8), Enum.SortOrder.LayoutOrder, parent
end
local function card(parent, height)
	local frame = Instance.new("Frame")
	frame.Size, frame.BackgroundColor3, frame.Parent = UDim2.new(1, 0, 0, height), SLOT, parent
	rounded(frame, 10)
	outline(frame, 3)
	return frame
end

-- Stats page
local statsPage = newPage("Stats")
local statsCard = card(statsPage, 0)
statsCard.Size = UDim2.fromScale(1, 1)
padding(statsCard, 12)
local statsText = makeText(statsCard, "", UDim2.fromScale(1, 1), UDim2.new(), WHITE, 22, Enum.TextXAlignment.Left)
statsText.TextYAlignment = Enum.TextYAlignment.Top

-- Eggs page (static: derived from EggConfig)
local eggPage = newPage("Eggs")
local eggList = scrollList(eggPage, UDim2.fromScale(1, 1), UDim2.new())
listLayout(eggList)
local eggIds = {}
for id in pairs(EggConfig) do table.insert(eggIds, id) end
table.sort(eggIds, function(a, b) return EggConfig[a].Cost < EggConfig[b].Cost end)
for order, id in eggIds do
	local egg = EggConfig[id]
	local row = card(eggList, 92)
	row.LayoutOrder = order
	local orb = Instance.new("TextLabel")
	orb.Size, orb.Position, orb.BackgroundColor3, orb.Text, orb.TextSize = UDim2.fromOffset(64, 64), UDim2.fromOffset(12, 14), egg.Color, "🥚", 36
	orb.Parent = row
	rounded(orb, 32)
	outline(orb, 3)
	local totalWeight = 0
	for _, entry in egg.Pets do totalWeight += entry.Weight end
	local odds = {}
	for _, entry in egg.Pets do
		table.insert(odds, string.format("%s %d%%", entry.Id, math.floor(entry.Weight / totalWeight * 100 + 0.5)))
	end
	makeText(row, string.upper(egg.DisplayName), UDim2.new(1, -100, 0, 28), UDim2.fromOffset(88, 8), WHITE, 24, Enum.TextXAlignment.Left)
	makeText(row, "🏆 " .. egg.Cost .. " Valor", UDim2.new(1, -100, 0, 22), UDim2.fromOffset(88, 36), GOLD, 18, Enum.TextXAlignment.Left)
	makeText(row, table.concat(odds, "  •  "), UDim2.new(1, -100, 0, 22), UDim2.fromOffset(88, 60), LIGHT, 15, Enum.TextXAlignment.Left)
end

-- Enchantments page
local ENCHANT_ATTRIBUTE = { Damage = "DamageEnchantmentLevel", Luck = "LuckEnchantmentLevel", PetCapacity = "PetCapacityLevel" }
local enchantPage = newPage("Enchantments")
local enchantList = scrollList(enchantPage, UDim2.fromScale(1, 1), UDim2.new())
listLayout(enchantList)
local enchantCards = {}
for order, id in { "Damage", "Luck", "PetCapacity" } do
	local config = UpgradeConfig.Enchantments[id]
	local row = card(enchantList, 84)
	row.LayoutOrder = order
	local name = makeText(row, "", UDim2.new(1, -190, 0, 30), UDim2.fromOffset(14, 8), WHITE, 22, Enum.TextXAlignment.Left)
	makeText(row, config.Description, UDim2.new(1, -190, 0, 36), UDim2.fromOffset(14, 40), LIGHT, 15, Enum.TextXAlignment.Left)
	local buy = makeButton("Upgrade_" .. id, "UPGRADE", UDim2.fromOffset(160, 52), UDim2.new(1, -172, 0.5, -26), GREEN, row)
	buy.Activated:Connect(function() upgradeRemote:FireServer(id) end)
	enchantCards[id] = { Name = name, Button = buy }
end

-- Skill Mastery page
local skillPage = newPage("Upgrades")
local skillCard = card(skillPage, 200)
padding(skillCard, 12)
local skillBody = makeText(skillCard, "", UDim2.new(1, 0, 0, 100), UDim2.new(), WHITE, 22, Enum.TextXAlignment.Left)
skillBody.TextYAlignment = Enum.TextYAlignment.Top
makeText(skillCard, "Stand in the Meditation Pool to upgrade", UDim2.new(1, 0, 0, 22), UDim2.new(0, 0, 1, -82), LIGHT, 15, Enum.TextXAlignment.Left)
local skillButton = makeButton("SkillMasteryUpgrade", "UPGRADE", UDim2.new(1, 0, 0, 48), UDim2.new(0, 0, 1, -52), GREEN, skillCard)
skillButton.Activated:Connect(function() upgradeRemote:FireServer("SkillMastery") end)

-- Pets page
local petIds = {}
for petId in pairs(CompanionConfig) do table.insert(petIds, petId) end
table.sort(petIds, function(a, b) return CompanionConfig[a].Name < CompanionConfig[b].Name end)
local PET_ICONS = { Sproutling = "🌱", Pebbleback = "🪨", Wispling = "✨" }
local selectedPet = petIds[1]
local canEquip, canUnequip = false, false
local petPage = newPage("Pets")
local petLeft = Instance.new("Frame")
petLeft.Size, petLeft.BackgroundTransparency, petLeft.Parent = UDim2.new(1, -236, 1, 0), 1, petPage
local petScroll = scrollList(petLeft, UDim2.new(1, 0, 1, -54), UDim2.new())
local petGrid = Instance.new("UIGridLayout")
petGrid.CellSize, petGrid.CellPadding, petGrid.SortOrder, petGrid.Parent = UDim2.fromOffset(92, 108), UDim2.fromOffset(8, 8), Enum.SortOrder.LayoutOrder, petScroll
makeButton("EquipBest", "EQUIP BEST", UDim2.new(0.5, -4, 0, 46), UDim2.new(0, 0, 1, -46), BLUE, petLeft).Activated:Connect(function() petActionRemote:FireServer("EquipBest") end)
makeButton("UnequipAll", "UNEQUIP ALL", UDim2.new(0.5, -4, 0, 46), UDim2.new(0.5, 4, 1, -46), RED, petLeft).Activated:Connect(function() petActionRemote:FireServer("UnequipAll") end)
local detail = Instance.new("Frame")
detail.Size, detail.Position, detail.BackgroundColor3, detail.Parent = UDim2.new(0, 224, 1, 0), UDim2.new(1, -224, 0, 0), Color3.fromRGB(46, 47, 64), petPage
rounded(detail, 10)
outline(detail, 3)
local slot = Instance.new("Frame")
slot.Size, slot.Position, slot.BackgroundColor3, slot.Parent = UDim2.new(1, -24, 0, 90), UDim2.fromOffset(12, 12), SLOT, detail
rounded(slot, 8)
outline(slot, 2)
local detailIcon = makeText(slot, "", UDim2.fromScale(1, 1), UDim2.new(), WHITE, 56)
detailIcon.TextStrokeTransparency = 1
local detailName = makeText(detail, "", UDim2.new(1, -16, 0, 26), UDim2.fromOffset(8, 108), WHITE, 24)
local detailRole = makeText(detail, "", UDim2.new(1, -16, 0, 20), UDim2.fromOffset(8, 136), GOLD, 17)
local detailBonus = makeText(detail, "", UDim2.new(1, -16, 0, 40), UDim2.fromOffset(8, 158), Color3.fromRGB(118, 255, 108), 15)
local equipButton = makeButton("Equip", "EQUIP", UDim2.new(1, -24, 0, 40), UDim2.new(0, 12, 1, -88), GREEN, detail)
local unequipButton = makeButton("Unequip", "UNEQUIP", UDim2.new(1, -24, 0, 40), UDim2.new(0, 12, 1, -44), RED, detail)
equipButton.Activated:Connect(function() if canEquip then petActionRemote:FireServer("Equip", selectedPet) end end)
unequipButton.Activated:Connect(function() if canUnequip then petActionRemote:FireServer("Unequip", selectedPet) end end)

local TITLES = { Stats = "JOURNAL", Pets = "PETS", Eggs = "EGGS", Enchantments = "ENCHANTMENTS", Upgrades = "SKILLS" }
local activeTab, menuOpen, menuTransition = "Stats", false, 0

local function bonusLines(config)
	local lines = {}
	if (config.DamageBonus or 0) > 0 then table.insert(lines, string.format("+%d%% damage", math.floor(config.DamageBonus * 100 + 0.5))) end
	if (config.CupsBonus or 0) > 0 then table.insert(lines, string.format("+%d%% Valor", math.floor(config.CupsBonus * 100 + 0.5))) end
	return #lines > 0 and table.concat(lines, "\n") or "No stat bonus yet"
end

local function renderPets()
	for _, child in petScroll:GetChildren() do
		if child:IsA("GuiObject") then child:Destroy() end
	end
	local owned = parseIds(player:GetAttribute("PetCollection"), ",")
	local equipped = parseIds(player:GetAttribute("EquippedPets"), ",")
	local equippedTotal, ownedTotal = 0, 0
	for _, count in pairs(equipped) do equippedTotal += count end
	for _, count in pairs(owned) do ownedTotal += count end
	local capacity = 3 + (player:GetAttribute("PetCapacityLevel") or 0)
	headerInfo.Text = string.format("EQUIPPED %d/%d   OWNED %d", equippedTotal, capacity, ownedTotal)
	for order, petId in petIds do
		local config, count, equippedCount = CompanionConfig[petId], owned[petId] or 0, equipped[petId] or 0
		local selected = petId == selectedPet
		local item = Instance.new("TextButton")
		item.Name, item.LayoutOrder, item.Text, item.AutoButtonColor = petId, order, "", false
		item.BackgroundColor3 = count > 0 and Color3.fromRGB(88, 91, 118) or Color3.fromRGB(46, 47, 62)
		item.Parent = petScroll
		rounded(item, 8)
		outline(item, selected and 4 or 3, selected and GOLD or BLACK)
		local icon = makeText(item, count > 0 and (PET_ICONS[petId] or "✦") or "?", UDim2.new(1, 0, 0, 52), UDim2.fromOffset(0, 8), WHITE, 40)
		icon.TextStrokeTransparency = 1
		makeText(item, count > 0 and config.Name or "???", UDim2.new(1, 0, 0, 18), UDim2.fromOffset(0, 62), WHITE, 15)
		makeText(item, "x" .. count, UDim2.new(1, 0, 0, 20), UDim2.fromOffset(0, 82), count > 0 and Color3.fromRGB(118, 255, 108) or LIGHT, 16)
		if equippedCount > 0 then
			local badge = Instance.new("TextLabel")
			badge.Size, badge.Position, badge.BackgroundColor3 = UDim2.fromOffset(24, 24), UDim2.fromOffset(4, 4), GREEN
			badge.Text, badge.TextColor3, badge.Font, badge.TextSize, badge.TextStrokeTransparency = equippedCount > 1 and ("E" .. equippedCount) or "E", WHITE, FONT, 14, 0
			badge.Parent = item
			rounded(badge, 6)
			outline(badge, 2)
		end
		item.Activated:Connect(function()
			selectedPet = petId
			renderPets()
		end)
	end
	local config, count, equippedCount = CompanionConfig[selectedPet], owned[selectedPet] or 0, equipped[selectedPet] or 0
	detailIcon.Text = count > 0 and (PET_ICONS[selectedPet] or "✦") or "?"
	detailName.Text = count > 0 and config.Name or "Undiscovered"
	detailRole.Text = config.Role
	detailBonus.Text = bonusLines(config)
	canEquip = equippedCount < count and equippedTotal < capacity
	canUnequip = equippedCount > 0
	equipButton.BackgroundColor3 = canEquip and GREEN or GREY
	unequipButton.BackgroundColor3 = canUnequip and RED or GREY
end

local function renderStats()
	local mage = MageConfig[player:GetAttribute("MageArchetype") or "Pyromancer"] or MageConfig.Pyromancer
	statsText.Text = string.format("%s\nM1  %s   •   Q  %s   •   E  %s\n\nLevel  %d      XP  %d\n🏆 Valor  %d      🔮 Magic Power  %d\nHighest zone unlocked  %d", string.upper(mage.DisplayName), mage.M1.Name, mage.Q.Name, mage.E.Name, player:GetAttribute("Level") or 1, player:GetAttribute("XP") or 0, player:GetAttribute("Valor") or 0, player:GetAttribute("MagicPower") or 0, player:GetAttribute("HighestZoneUnlocked") or 1)
end
local function renderEnchantments()
	for id, entry in pairs(enchantCards) do
		local config = UpgradeConfig.Enchantments[id]
		local level = player:GetAttribute(ENCHANT_ATTRIBUTE[id]) or 0
		local maxed = level >= config.MaxLevel
		entry.Name.Text = string.format("%s  •  LV %d / %d", string.upper(config.DisplayName), level, config.MaxLevel)
		entry.Button.Text = maxed and "MAX" or string.format("UPGRADE  🏆 %s", short(math.floor(config.BaseCost * config.CostMultiplier ^ level + 0.5)))
		entry.Button.BackgroundColor3 = maxed and GREY or GREEN
	end
end
local function renderSkills()
	local config = UpgradeConfig.SkillMastery
	local level = player:GetAttribute("SkillMasteryLevel") or 0
	local maxed = level >= config.MaxLevel
	local cost = math.floor(config.BaseCost * config.CostMultiplier ^ level + 0.5)
	skillBody.Text = string.format("SKILL MASTERY\nLevel  %d / %d\nQ and E damage  +%d%%\n%s", level, config.MaxLevel, math.floor(level * config.DamagePerLevel * 100 + 0.5), maxed and "Fully mastered" or ("Next rank  🏆 " .. cost .. " Valor"))
	skillButton.Text = maxed and "MAX" or string.format("UPGRADE  🏆 %s", short(cost))
	skillButton.BackgroundColor3 = maxed and GREY or GREEN
end
local function renderPage(tabName)
	activeTab = tabName
	for name, page in pairs(pages) do page.Visible = name == tabName end
	title.Text, headerInfo.Text = TITLES[tabName] or "JOURNAL", ""
	if tabName == "Pets" then renderPets()
	elseif tabName == "Enchantments" then renderEnchantments()
	elseif tabName == "Upgrades" then renderSkills()
	elseif tabName == "Stats" then renderStats() end
end
local function setMenuVisible(visible)
	menuOpen = visible
	menuTransition += 1
	local transitionId = menuTransition
	if visible then
		window.Visible, windowScale.Scale = true, 0.92
		TweenService:Create(windowScale, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	else
		local tween = TweenService:Create(windowScale, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = 0.92 })
		tween:Play()
		task.spawn(function()
			tween.Completed:Wait()
			if transitionId == menuTransition then window.Visible = false end
		end)
	end
end
local function toggleWindow(tabName)
	if menuOpen and activeTab == tabName then setMenuVisible(false); return end
	renderPage(tabName)
	if not menuOpen then setMenuVisible(true) end
end
closeButton.Activated:Connect(function() setMenuVisible(false) end)

-- ===== Sidebar + currency (top left) =====
local sidebar = Instance.new("Frame")
sidebar.Name, sidebar.Size, sidebar.Position, sidebar.BackgroundTransparency, sidebar.Parent = "Sidebar", UDim2.fromOffset(148, 226), UDim2.fromOffset(12, 12), 1, gui
local sidebarGrid = Instance.new("UIGridLayout")
sidebarGrid.CellSize, sidebarGrid.CellPadding, sidebarGrid.SortOrder, sidebarGrid.Parent = UDim2.fromOffset(70, 70), UDim2.fromOffset(8, 8), Enum.SortOrder.LayoutOrder, sidebar
local function menuButton(order, tabName, icon, label, color)
	local button = makeButton(tabName .. "Menu", "", UDim2.new(), UDim2.new(), color, sidebar)
	button.LayoutOrder = order
	local iconLabel = makeText(button, icon, UDim2.fromScale(1, 0.58), UDim2.fromScale(0, 0.04), WHITE, 30)
	iconLabel.TextScaled, iconLabel.TextStrokeTransparency = true, 1
	local nameLabel = makeText(button, label, UDim2.fromScale(1, 0.3), UDim2.fromScale(0, 0.64), WHITE, 14)
	nameLabel.TextScaled = true
	button.Activated:Connect(function() toggleWindow(tabName) end)
end
menuButton(1, "Stats", "📜", "Journal", Color3.fromRGB(52, 152, 245))
menuButton(2, "Pets", "🐾", "Pets", Color3.fromRGB(255, 150, 40))
menuButton(3, "Eggs", "🥚", "Eggs", Color3.fromRGB(240, 190, 50))
menuButton(4, "Enchantments", "✨", "Enchants", Color3.fromRGB(160, 90, 235))
menuButton(5, "Upgrades", "🔮", "Skills", Color3.fromRGB(232, 60, 72))

local currencyValues = {}
local function currencyRow(order, icon, attribute, color)
	local row = Instance.new("Frame")
	row.Size, row.Position, row.BackgroundTransparency, row.Parent = UDim2.fromOffset(150, 38), UDim2.fromOffset(12, 246 + (order - 1) * 44), 1, gui
	local badge = Instance.new("TextLabel")
	badge.Size, badge.BackgroundColor3, badge.Text, badge.TextSize, badge.Parent = UDim2.fromOffset(38, 38), PANEL, icon, 22, row
	rounded(badge, 19)
	outline(badge, 3)
	local value = makeText(row, "0", UDim2.new(1, -46, 1, 0), UDim2.fromOffset(46, 0), color, 28, Enum.TextXAlignment.Left)
	value.TextScaled = true
	currencyValues[attribute] = value
end
currencyRow(1, "🏆", "Valor", Color3.fromRGB(118, 255, 108))
currencyRow(2, "🔮", "MagicPower", Color3.fromRGB(190, 150, 255))
currencyRow(3, "⭐", "Level", GOLD)

local function refresh()
	currencyValues.Valor.Text = short(player:GetAttribute("Valor"))
	currencyValues.MagicPower.Text = short(player:GetAttribute("MagicPower"))
	currencyValues.Level.Text = "Lv " .. (player:GetAttribute("Level") or 1)
	local mage = MageConfig[player:GetAttribute("MageArchetype") or "Pyromancer"] or MageConfig.Pyromancer
	boltButton.Text, waveButton.Text = string.upper(mage.Q.Name .. " [Q]"), string.upper(mage.E.Name .. " [E]")
	boltButton.BackgroundColor3, waveButton.BackgroundColor3 = mage.Color, mage.Color:Lerp(BLACK, 0.3)
	if menuOpen then renderPage(activeTab) end
end
for _, attribute in { "Valor", "MagicPower", "DamageEnchantmentLevel", "LuckEnchantmentLevel", "PetCapacityLevel", "Level", "XP", "SkillMasteryLevel", "HighestZoneUnlocked", "PetCollection", "EquippedPets", "MageArchetype" } do
	player:GetAttributeChangedSignal(attribute):Connect(refresh)
end
refresh()
renderPage("Stats")

-- ===== Egg choice + hatch animation =====
local eggModal = Instance.new("Frame")
eggModal.Name, eggModal.Size, eggModal.Position = "EggChoice", UDim2.fromOffset(430, 310), UDim2.new(0.5, -215, 0.5, -155)
eggModal.BackgroundColor3, eggModal.Visible, eggModal.Parent = PANEL, false, gui
rounded(eggModal, 14)
outline(eggModal, 4)
local eggModalScale = Instance.new("UIScale")
eggModalScale.Scale, eggModalScale.Parent = 0.94, eggModal
local eggTitle = makeText(eggModal, "CHOOSE HATCH AMOUNT", UDim2.new(1, -70, 0, 50), UDim2.fromOffset(18, 10), Color3.fromRGB(255, 230, 169), 30)
eggTitle.TextScaled = true
local eggDescription = makeText(eggModal, "", UDim2.new(1, -36, 0, 56), UDim2.fromOffset(18, 64), WHITE, 18)
eggDescription.TextStrokeTransparency = 1
local eggOneButton = makeButton("HatchOne", "OPEN 1 EGG", UDim2.new(1, -44, 0, 58), UDim2.fromOffset(22, 140), Color3.fromRGB(68, 190, 112), eggModal)
local tripleButtonText = MonetizationConfig.TripleHatchPassId > 0 and "OPEN 3 EGGS • GAMEPASS" or "OPEN 3 EGGS • GAMEPASS ID NEEDED"
local eggThreeButton = makeButton("HatchThree", tripleButtonText, UDim2.new(1, -44, 0, 58), UDim2.fromOffset(22, 208), Color3.fromRGB(123, 91, 183), eggModal)
local eggCloseButton = makeButton("CloseEggChoice", "X", UDim2.fromOffset(38, 38), UDim2.new(1, -48, 0, 10), RED, eggModal)
local selectedEggId
local hatchOverlay = Instance.new("Frame")
hatchOverlay.Name, hatchOverlay.Size, hatchOverlay.Position = "HatchAnimation", UDim2.fromScale(1, 1), UDim2.fromScale(0, 0)
hatchOverlay.BackgroundColor3, hatchOverlay.BackgroundTransparency, hatchOverlay.Visible, hatchOverlay.Parent = Color3.fromRGB(12, 16, 25), 0.18, false, gui
local hatchCard = Instance.new("Frame")
hatchCard.Size, hatchCard.Position, hatchCard.BackgroundColor3 = UDim2.fromOffset(430, 360), UDim2.new(0.5, -215, 0.5, -180), PANEL
hatchCard.Parent = hatchOverlay
rounded(hatchCard, 16)
outline(hatchCard, 4)
local hatchOrb = Instance.new("TextLabel")
hatchOrb.Name, hatchOrb.Size, hatchOrb.Position = "HatchEggOrb", UDim2.fromOffset(150, 150), UDim2.new(0.5, -75, 0, 28)
hatchOrb.BackgroundColor3, hatchOrb.Text = Color3.fromRGB(137, 116, 185), "✦"
hatchOrb.TextColor3, hatchOrb.TextScaled, hatchOrb.Font = WHITE, true, FONT
hatchOrb.Parent = hatchCard
rounded(hatchOrb, 75)
outline(hatchOrb, 4)
local hatchResultLabel = makeText(hatchCard, "", UDim2.new(1, -30, 0, 92), UDim2.fromOffset(15, 194), WHITE, 23)
local hatchContinue = makeButton("HatchContinue", "VIEW PET INVENTORY", UDim2.new(1, -42, 0, 54), UDim2.fromOffset(21, 292), Color3.fromRGB(70, 200, 105), hatchCard)
hatchContinue.Visible = false
local hatchAnimating = false

local hatchRequestInFlight = false
openEggRemote.OnClientEvent:Connect(function(payload)
	local egg = payload and EggConfig[payload.EggId]
	if not egg then return end
	selectedEggId = payload.EggId
	eggTitle.Text = "HATCH " .. string.upper(egg.DisplayName)
	eggDescription.Text = string.format("Choose how many eggs to open. Each egg costs %d Valor.", egg.Cost)
	eggOneButton.Text = string.format("OPEN 1 EGG  •  %d VALOR", egg.Cost)
	eggThreeButton.Text = MonetizationConfig.TripleHatchPassId > 0 and string.format("OPEN 3 EGGS  •  %d VALOR  •  GAMEPASS", egg.Cost * 3) or "OPEN 3 EGGS  •  GAMEPASS ID NEEDED"
	eggThreeButton.BackgroundColor3 = egg.Color
	eggModal.Visible, eggModalScale.Scale = true, 0.94
	TweenService:Create(eggModalScale, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
end)
eggOneButton.Activated:Connect(function()
	if selectedEggId and not hatchRequestInFlight then
		hatchRequestInFlight = true
		hatchEggRemote:FireServer(selectedEggId, 1)
	end
end)
eggThreeButton.Activated:Connect(function()
	if selectedEggId and not hatchRequestInFlight then
		hatchRequestInFlight = true
		hatchEggRemote:FireServer(selectedEggId, 3)
		task.delay(1, function() hatchRequestInFlight = false end)
	end
end)
eggCloseButton.Activated:Connect(function()
	local tween = TweenService:Create(eggModalScale, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = 0.94 })
	tween:Play()
	task.spawn(function() tween.Completed:Wait(); eggModal.Visible = false end)
end)
hatchResultRemote.OnClientEvent:Connect(function(payload)
	local egg = payload and EggConfig[payload.EggId]
	if not egg or hatchAnimating then return end
	hatchRequestInFlight, hatchAnimating = false, true
	eggModal.Visible, hatchOverlay.Visible = false, true
	hatchOverlay.BackgroundTransparency = 1
	hatchCard.Size = UDim2.fromOffset(400, 335)
	TweenService:Create(hatchOverlay, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 0.18 }):Play()
	TweenService:Create(hatchCard, TweenInfo.new(0.26, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = UDim2.fromOffset(430, 360) }):Play()
	hatchContinue.Visible = false
	hatchOrb.BackgroundColor3, hatchOrb.Text, hatchOrb.Rotation = egg.Color, "🥚", 0
	hatchOrb.Size, hatchResultLabel.Text = UDim2.fromOffset(150, 150), "THE EGG IS GLOWING..."
	task.spawn(function()
		for _, angle in { 18, -20, 24, -26, 30, -18, 0 } do
			local tween = TweenService:Create(hatchOrb, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), { Rotation = angle })
			tween:Play()
			tween.Completed:Wait()
		end
		local pop = TweenService:Create(hatchOrb, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = UDim2.fromOffset(210, 210), BackgroundColor3 = WHITE })
		pop:Play()
		pop.Completed:Wait()
		local names = {}
		for _, petId in payload.Pets do table.insert(names, CompanionConfig[petId] and CompanionConfig[petId].Name or petId) end
		hatchOrb.Text = "✧"
		hatchResultLabel.Text = "HATCHED!\n" .. table.concat(names, "  •  ")
		local settle = TweenService:Create(hatchOrb, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = UDim2.fromOffset(150, 150), BackgroundColor3 = egg.Color })
		settle:Play()
		settle.Completed:Wait()
		hatchContinue.Visible = true
	end)
end)
hatchContinue.Activated:Connect(function()
	hatchAnimating, hatchOverlay.Visible = false, false
	renderPage("Pets")
	if not menuOpen then setMenuVisible(true) end
end)

-- ===== Input =====
local function castSkill(slotName) castSkillRemote:FireServer(slotName) end
local sprinting = false
local function setSprinting(value)
	if sprinting == value then return end
	sprinting = value
	sprintRemote:FireServer(value)
	sprintHint.Text = value and "SPRINTING  •  RELEASE SHIFT" or "HOLD SHIFT TO SPRINT"
	local sprintColor = value and Color3.fromRGB(61, 137, 171) or PANEL
	TweenService:Create(sprintHint, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundColor3 = sprintColor }):Play()
end
boltButton.Activated:Connect(function() castSkill("Q") end)
waveButton.Activated:Connect(function() castSkill("E") end)
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.Q then castSkill("Q") end
	if input.KeyCode == Enum.KeyCode.E then castSkill("E") end
	if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then setSprinting(true) end
end)
UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then setSprinting(false) end
end)
UserInputService.WindowFocusReleased:Connect(function() setSprinting(false) end)
player.CharacterAdded:Connect(function() sprinting = false; sprintRemote:FireServer(false) end)

-- ===== Server events =====
local updateZoneReturnPortal = function() end
stateRemote.OnClientEvent:Connect(function(payload)
	if payload.ZoneCleared then
		zoneLabel.Text = string.upper((payload.ZoneName or "ZONE") .. " CLEARED!")
		enemyLabel.Text = "Return portal open  •  next zone unlocked — walk forward to continue"
		updateZoneReturnPortal(payload.Zone, true)
	elseif payload.InRun then
		zoneLabel.Text = string.upper(payload.ZoneName or "CORRIDOR")
		enemyLabel.Text = string.format("Defeat every enemy  •  %d / %d remaining", payload.Remaining or 0, payload.Total or 0)
		if payload.RetreatedFrom then updateZoneReturnPortal(payload.Zone, false) end
	else
		zoneLabel.Text, enemyLabel.Text = "ARCHMAGE'S CORRIDOR", "Walk into Zone 1 to summon enemies"
		updateZoneReturnPortal(nil, false)
	end
end)
enemyRemote.OnClientEvent:Connect(function(payload)
	if payload.Name then
		enemyLabel.Text = string.format("%s%s  •  %d / %d HP  •  %d remain", payload.IsBoss and "BOSS • " or "", payload.Name, payload.Health, payload.MaxHealth, payload.Remaining or 0)
	elseif payload.Remaining == 0 then enemyLabel.Text = "All enemies defeated — zone cleared!" end
end)
rewardRemote.OnClientEvent:Connect(function(payload)
	if payload.Meditation then
		showToast(string.format("Meditation  •  +%d Magic Power", payload.MagicPower or 0), 2.5)
	elseif payload.ZoneClear then
		showToast(string.format("%s cleared!  +%d Valor", payload.ZoneName, payload.Valor), 2.5)
	else
		showToast(string.format("+%d Valor   +%d XP", payload.Valor or 0, payload.XP or 0), 2)
	end
	refresh()
end)

-- ===== Effects (unchanged) =====
local function arcaneParticles(position, color, amount)
	local anchor = Instance.new("Part")
	anchor.Name, anchor.Size, anchor.CFrame = "ArcaneParticleAnchor", Vector3.new(0.2, 0.2, 0.2), CFrame.new(position)
	anchor.Anchored, anchor.CanCollide, anchor.CanTouch, anchor.CanQuery, anchor.Transparency = true, false, false, false, 1
	anchor.Parent = workspace
	local attachment = Instance.new("Attachment")
	attachment.Parent = anchor
	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	emitter.Color = ColorSequence.new(color, Color3.new(1, 1, 1))
	emitter.LightEmission, emitter.Lifetime, emitter.Speed = 0.9, NumberRange.new(0.28, 0.65), NumberRange.new(7, 17)
	emitter.SpreadAngle, emitter.RotSpeed = Vector2.new(180, 180), NumberRange.new(-180, 180)
	emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.9), NumberSequenceKeypoint.new(1, 0) })
	emitter.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.05), NumberSequenceKeypoint.new(1, 1) })
	emitter.Parent = attachment
	emitter:Emit(amount)
	Debris:AddItem(anchor, 1)
end

local function expandingRing(position, color, diameter, duration, delaySeconds)
	if delaySeconds and delaySeconds > 0 then task.wait(delaySeconds) end
	local center = Vector3.new(position.X, 1.24, position.Z)
	local segments, finalRadius = 12, diameter * 0.5
	local segmentLength = math.max(0.8, diameter * math.pi / segments * 1.08)
	for index = 1, segments do
		local angle = (index - 1) * math.pi * 2 / segments
		local radial = Vector3.new(math.cos(angle), 0, math.sin(angle))
		local tangent = Vector3.new(-math.sin(angle), 0, math.cos(angle))
		local startPosition = center + radial * 1.2
		local endPosition = center + radial * finalRadius
		local segment = Instance.new("Part")
		segment.Name, segment.Size = "ArcaneRuneWaveSegment", Vector3.new(0.22, 0.16, 0.35)
		segment.CFrame = CFrame.lookAt(startPosition, startPosition + tangent)
		segment.Anchored, segment.CanCollide, segment.CanTouch, segment.CanQuery = true, false, false, false
		segment.Material, segment.Color, segment.Transparency, segment.Parent = Enum.Material.Neon, color, 0.08, workspace
		TweenService:Create(segment, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			CFrame = CFrame.lookAt(endPosition, endPosition + tangent),
			Size = Vector3.new(0.22, 0.16, segmentLength),
			Transparency = 1,
		}):Play()
		Debris:AddItem(segment, duration + 0.1)
	end
end

local function arcaneImpact(position, color, radius, burstCount)
	local orb = Instance.new("Part")
	orb.Name, orb.Shape, orb.Size, orb.CFrame = "ArcaneImpact", Enum.PartType.Ball, Vector3.new(2, 2, 2), CFrame.new(position)
	orb.Anchored, orb.CanCollide, orb.CanTouch, orb.CanQuery = true, false, false, false
	orb.Material, orb.Color, orb.Transparency, orb.Parent = Enum.Material.Neon, color, 0.12, workspace
	local light = Instance.new("PointLight")
	light.Color, light.Brightness, light.Range, light.Parent = color, 2.5, 12, orb
	TweenService:Create(orb, TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = Vector3.new(8, 8, 8), Transparency = 1 }):Play()
	Debris:AddItem(orb, 0.32)
	arcaneParticles(position, color, burstCount or 18)
	if radius and radius > 0 then
		task.spawn(expandingRing, position, color, math.max(8, radius * 2), 0.36)
		task.spawn(expandingRing, position, Color3.new(1, 1, 1), math.max(5, radius * 1.35), 0.3, 0.06)
	end
end

local function arcaneProjectile(source, target, color, effect)
	local cylinder = string.find(effect, "Root") ~= nil
	local projectile = Instance.new("Part")
	projectile.Name, projectile.Shape = "ArcaneProjectile", cylinder and Enum.PartType.Cylinder or Enum.PartType.Ball
	local scale = effect == "Fireball" and 2.3 or 1.25
	projectile.Size = Vector3.new(scale, scale, scale)
	local direction = target - source
	if direction.Magnitude < 0.1 then direction = Vector3.new(0, 0, -1) end
	local unitDirection = direction.Unit
	local up = math.abs(unitDirection:Dot(Vector3.new(0, 1, 0))) > 0.98 and Vector3.new(0, 0, 1) or Vector3.new(0, 1, 0)
	local orientation = CFrame.lookAt(source, target, up)
	if cylinder then orientation *= CFrame.Angles(math.rad(90), 0, 0) end
	projectile.CFrame = orientation
	projectile.Anchored, projectile.CanCollide, projectile.CanTouch, projectile.CanQuery = true, false, false, false
	projectile.Material, projectile.Color = Enum.Material.Neon, color
	projectile.Parent = workspace
	local light = Instance.new("PointLight")
	light.Color, light.Brightness, light.Range, light.Parent = color, 1.6, 10, projectile
	local trailStart, trailEnd = Instance.new("Attachment"), Instance.new("Attachment")
	trailStart.Position, trailEnd.Position = Vector3.new(0, 0, -scale * 0.55), Vector3.new(0, 0, scale * 0.55)
	trailStart.Parent, trailEnd.Parent = projectile, projectile
	local trail = Instance.new("Trail")
	trail.Attachment0, trail.Attachment1, trail.Lifetime = trailStart, trailEnd, 0.22
	trail.Color, trail.LightEmission, trail.FaceCamera, trail.Parent = ColorSequence.new(color, Color3.new(1, 1, 1)), 1, true, projectile
	arcaneParticles(source, color, 8)
	local destination = CFrame.lookAt(target, target + unitDirection, up)
	if cylinder then destination *= CFrame.Angles(math.rad(90), 0, 0) end
	TweenService:Create(projectile, TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { CFrame = destination }):Play()
	task.delay(0.28, function() arcaneImpact(target, color, effect == "Fireball" and 12 or 0, effect == "Fireball" and 30 or 10) end)
	Debris:AddItem(projectile, 0.36)
end

hitRemote.OnClientEvent:Connect(function(payload)
	if payload.IncomingDamage then
		if payload.SpecialAttackName and payload.SpecialPosition then
			arcaneImpact(payload.SpecialPosition, payload.SpecialColor or Color3.fromRGB(255, 86, 74), payload.SpecialRadius, 34)
			showToast(string.format("%s casts %s!  -%d HP", payload.EnemyName or "Boss", payload.SpecialAttackName, payload.IncomingDamage), 2.2)
		else
			showToast(string.format("%s hit you for %d", payload.EnemyName or "Enemy", payload.IncomingDamage), 1.3)
		end
		return
	end
	local effect = payload.Effect or ""
	local color = payload.Color or Color3.fromRGB(157, 148, 255)
	local source = payload.SourcePosition or payload.TargetPosition
	local target = payload.TargetPosition or source
	if source and target then
		if string.find(effect, "Wave") then
			local diameter = math.max(12, (payload.Radius or 14) * 2)
			task.spawn(expandingRing, source, color, diameter, 0.48)
			task.spawn(expandingRing, source, Color3.new(1, 1, 1), diameter * 0.72, 0.38, 0.08)
			arcaneParticles(source, color, 24)
		elseif string.find(effect, "Burst") then
			arcaneImpact(source, color, payload.Radius or 12, 26)
		elseif effect ~= "" then
			local launch = effect == "Starfall" and target + Vector3.new(0, 20, 0) or source
			arcaneProjectile(launch, target, color, effect)
			if effect == "Starfall" then task.delay(0.28, function() arcaneImpact(target, color, payload.Radius or 10, 30) end) end
		end
	end
	if payload.Damage and payload.TargetPosition then
		local holder = Instance.new("Part")
		holder.Name, holder.Size, holder.CFrame = "DamageNumberAnchor", Vector3.new(0.1, 0.1, 0.1), CFrame.new(payload.TargetPosition)
		holder.Anchored, holder.CanCollide, holder.CanTouch, holder.CanQuery, holder.Transparency = true, false, false, false, 1
		holder.Parent = workspace
		local billboard = Instance.new("BillboardGui")
		billboard.Size, billboard.StudsOffset, billboard.AlwaysOnTop, billboard.Parent = UDim2.fromOffset(90, 36), Vector3.new(0, 2, 0), true, holder
		local number = Instance.new("TextLabel")
		number.Size, number.BackgroundTransparency = UDim2.fromScale(1, 1), 1
		number.Text, number.TextColor3, number.TextStrokeTransparency = tostring(payload.Damage), color, 0.2
		number.Font, number.TextScaled, number.Parent = Enum.Font.GothamBlack, true, billboard
		Debris:AddItem(holder, 0.7)
	end
	if payload.SkillName then showToast(payload.SkillName .. " • " .. tostring(payload.Damage or 0) .. " damage", 1.4) end
end)
messageRemote.OnClientEvent:Connect(function(message)
	hatchRequestInFlight = false
	showToast(message, 2.2)
end)

-- ===== World-side client visuals =====
local world = workspace:WaitForChild("RiftRunWorld")
local function refreshGateVisibility()
	local highest = player:GetAttribute("GateOpenThrough") or 1
	for _, item in world:GetDescendants() do
		local gateZone = item:GetAttribute("ZoneGateId")
		if gateZone and item:IsA("BasePart") then
			item.LocalTransparencyModifier = gateZone <= highest and 1 or 0
		end
	end
end
local function getReturnPortal(zoneId)
	local portals = world:FindFirstChild("ZoneReturnPortals")
	return portals and portals:FindFirstChild(string.format("ZoneReturn_%02d", zoneId))
end
local function setPortalVisible(zoneId, visible)
	local portal = getReturnPortal(zoneId)
	if not portal then return end
	for _, item in portal:GetDescendants() do
		if item:IsA("BasePart") then item.LocalTransparencyModifier = visible and 0 or 1 end
		if item:IsA("ProximityPrompt") then item.Enabled = visible end
	end
end
local function hideReturnPortals()
	local portals = world:FindFirstChild("ZoneReturnPortals")
	if not portals then return end
	for _, portal in portals:GetChildren() do
		for _, item in portal:GetDescendants() do
			if item:IsA("BasePart") then item.LocalTransparencyModifier = 1 end
			if item:IsA("ProximityPrompt") then item.Enabled = false end
		end
	end
end
updateZoneReturnPortal = function(zoneId, visible)
	if zoneId then setPortalVisible(zoneId, visible) else hideReturnPortals() end
end
hideReturnPortals()
refreshGateVisibility()
player:GetAttributeChangedSignal("GateOpenThrough"):Connect(refreshGateVisibility)
world.DescendantAdded:Connect(function(item)
	if item:GetAttribute("ZoneGateId") then refreshGateVisibility() end
end)
local function concealOthers(model)
	if not model:IsA("Model") or not model:GetAttribute("OwnerUserId") then return end
	local mine = model:GetAttribute("OwnerUserId") == player.UserId
	for _, item in model:GetDescendants() do
		if item:IsA("BasePart") then item.LocalTransparencyModifier = mine and 0 or 1 end
		if item:IsA("BillboardGui") then item.Enabled = mine end
	end
end
for _, model in world:GetChildren() do concealOthers(model) end
world.ChildAdded:Connect(function(model)
	model:GetAttributeChangedSignal("OwnerUserId"):Connect(function() concealOthers(model) end)
	concealOthers(model)
end)

-- Mage pads: color/label are per-player, so they are set locally (never replicated).
local magePads = {}
local PAD_RED, PAD_GREEN = Color3.fromRGB(255, 60, 60), Color3.fromRGB(70, 230, 110)
local function refreshPads()
	local unlocked = parseIds(player:GetAttribute("UnlockedMages"), ",")
	local current = player:GetAttribute("MageArchetype")
	for _, pad in magePads do
		local id = pad:GetAttribute("ArchetypeId")
		local owned = unlocked[id] ~= nil
		pad.Color, pad.Transparency = owned and PAD_GREEN or PAD_RED, id == current and 0 or 0.25
		local tag = pad:FindFirstChild("PadTag")
		local state = tag and tag:FindFirstChild("State")
		if state then
			local cost = MageConfig[id] and MageConfig[id].CupCost or 0
			state.Text = id == current and "EQUIPPED" or owned and "OWNED" or (cost == 0 and "FREE" or "🏆 " .. cost)
			state.TextColor3 = owned and PAD_GREEN or GOLD
		end
	end
end
local function trackPad(item)
	if item:IsA("BasePart") and item:GetAttribute("MagePad") and not table.find(magePads, item) then
		table.insert(magePads, item)
		task.defer(refreshPads)
	end
end
for _, item in world:GetDescendants() do trackPad(item) end
world.DescendantAdded:Connect(trackPad)
player:GetAttributeChangedSignal("UnlockedMages"):Connect(refreshPads)
player:GetAttributeChangedSignal("MageArchetype"):Connect(refreshPads)
