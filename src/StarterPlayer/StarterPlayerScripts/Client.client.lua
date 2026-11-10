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

local gui = Instance.new("ScreenGui")
gui.Name, gui.ResetOnSpawn, gui.Parent = "RiftRunHUD", false, player:WaitForChild("PlayerGui")
local function rounded(instance, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius, corner.Parent = UDim.new(0, radius), instance
end
local function makeLabel(name, text, size, position, color)
	local item = Instance.new("TextLabel")
	item.Name, item.Size, item.Position = name, size, position
	item.BackgroundColor3, item.BackgroundTransparency = Color3.fromRGB(35, 43, 52), 0.12
	item.TextColor3, item.Font, item.TextScaled = color or Color3.new(1, 1, 1), Enum.Font.GothamBold, true
	item.Text, item.Parent = text, gui
	rounded(item, 12)
	return item
end
local stats = makeLabel("Stats", "Loading profile...", UDim2.fromOffset(290, 72), UDim2.new(0, 18, 0, 18), Color3.fromRGB(255, 238, 166))
local sprintHint = makeLabel("SprintHint", "HOLD SHIFT TO SPRINT", UDim2.fromOffset(230, 34), UDim2.new(0, 18, 0, 98), Color3.fromRGB(178, 221, 255))
local zoneLabel = makeLabel("Zone", "ARCHMAGE'S CORRIDOR", UDim2.fromOffset(300, 48), UDim2.new(0.5, -150, 0, 18), Color3.fromRGB(190, 255, 218))
local enemyLabel = makeLabel("Enemy", "Walk into Zone 1 to summon enemies", UDim2.fromOffset(380, 50), UDim2.new(0.5, -190, 0, 74), Color3.new(1, 1, 1))
local function makeButton(name, text, size, position, color, parent)
	local button = Instance.new("TextButton")
	button.Name, button.Size, button.Position = name, size, position
	button.BackgroundColor3, button.TextColor3 = color, Color3.new(1, 1, 1)
	button.Text, button.TextScaled, button.Font = text, true, Enum.Font.GothamBlack
	button.Parent = parent or gui
	button:SetAttribute("BaseColor", color)
	rounded(button, 12)
	button.MouseEnter:Connect(function()
		local base = button:GetAttribute("BaseColor") or color
		TweenService:Create(button, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundColor3 = base:Lerp(Color3.new(1, 1, 1), 0.12) }):Play()
	end)
	button.MouseLeave:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundColor3 = button:GetAttribute("BaseColor") or color }):Play()
	end)
	return button
end
local boltButton = makeButton("MageSkillQ", "FIREBALL  [Q]", UDim2.fromOffset(170, 72), UDim2.new(1, -360, 1, -100), Color3.fromRGB(214, 95, 57))
local waveButton = makeButton("MageSkillE", "FLAME WAVE  [E]", UDim2.fromOffset(170, 72), UDim2.new(1, -180, 1, -100), Color3.fromRGB(149, 77, 54))
local upgradeButton = makeButton("UpgradeButton", "SKILL MASTERY", UDim2.fromOffset(190, 52), UDim2.new(0, 18, 1, -72), Color3.fromRGB(239, 174, 68))
local toast = makeLabel("Toast", "", UDim2.fromOffset(380, 46), UDim2.new(0.5, -190, 1, -58), Color3.fromRGB(255, 237, 176))
toast.Visible = false
local toastPosition = toast.Position
local toastTweenId = 0
local function showToast(message, duration)
	toastTweenId += 1
	local currentId = toastTweenId
	toast.Text, toast.Visible = tostring(message), true
	toast.Position, toast.TextTransparency, toast.BackgroundTransparency = UDim2.new(0.5, -190, 1, -42), 1, 1
	TweenService:Create(toast, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = toastPosition, TextTransparency = 0, BackgroundTransparency = 0.12 }):Play()
	task.delay(duration or 2, function()
		if currentId ~= toastTweenId then return end
		local fade = TweenService:Create(toast, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Position = UDim2.new(0.5, -190, 1, -42), TextTransparency = 1, BackgroundTransparency = 1 })
		fade:Play()
		fade.Completed:Wait()
		if currentId == toastTweenId then toast.Visible = false end
	end)
end

local menu = Instance.new("Frame")
menu.Name, menu.Size, menu.Position = "ProgressionMenu", UDim2.new(0.78, 0, 0.62, 0), UDim2.new(0.11, 0, 0.19, 0)
menu.BackgroundColor3, menu.BackgroundTransparency, menu.Visible, menu.Parent = Color3.fromRGB(31, 43, 54), 1, false, gui
rounded(menu, 20)
local menuScale = Instance.new("UIScale")
menuScale.Scale, menuScale.Parent = 0.94, menu
local menuOpen, menuTransition = false, 0
local function setMenuVisible(visible)
	menuOpen = visible
	menuTransition += 1
	local transitionId = menuTransition
	if visible then
		menu.Visible, menuScale.Scale, menu.BackgroundTransparency = true, 0.94, 1
		TweenService:Create(menuScale, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
		TweenService:Create(menu, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 0 }):Play()
	else
		local tween = TweenService:Create(menuScale, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = 0.94 })
		TweenService:Create(menu, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { BackgroundTransparency = 1 }):Play()
		tween:Play()
		task.spawn(function()
			tween.Completed:Wait()
			if transitionId == menuTransition then menu.Visible = false end
		end)
	end
end
local limit = Instance.new("UISizeConstraint")
limit.MinSize, limit.MaxSize, limit.Parent = Vector2.new(300, 300), Vector2.new(760, 520), menu
local title = Instance.new("TextLabel")
title.Size, title.Position, title.BackgroundTransparency = UDim2.new(1, -70, 0, 54), UDim2.fromOffset(20, 8), 1
title.Text, title.TextColor3, title.Font, title.TextScaled = "ARCHMAGE JOURNAL", Color3.fromRGB(255, 231, 165), Enum.Font.GothamBlack, true
title.Parent = menu
local closeButton = makeButton("Close", "×", UDim2.fromOffset(44, 44), UDim2.new(1, -54, 0, 10), Color3.fromRGB(92, 108, 119), menu)
local tabBar = Instance.new("Frame")
tabBar.Size, tabBar.Position, tabBar.BackgroundTransparency, tabBar.Parent = UDim2.new(1, -28, 0, 48), UDim2.fromOffset(14, 70), 1, menu
local layout = Instance.new("UIListLayout")
layout.FillDirection, layout.Padding, layout.Parent = Enum.FillDirection.Horizontal, UDim.new(0, 6), tabBar
local content = Instance.new("TextLabel")
content.Size, content.Position = UDim2.new(1, -32, 1, -138), UDim2.fromOffset(16, 124)
content.BackgroundColor3, content.TextColor3 = Color3.fromRGB(47, 61, 70), Color3.fromRGB(235, 241, 238)
content.TextWrapped, content.TextYAlignment = true, Enum.TextYAlignment.Top
content.Font, content.TextSize, content.Parent = Enum.Font.Gotham, 20, menu
rounded(content, 14)
local petInventory = Instance.new("ScrollingFrame")
petInventory.Name, petInventory.Size, petInventory.Position = "PetInventory", content.Size, content.Position
petInventory.BackgroundColor3, petInventory.BorderSizePixel, petInventory.ScrollBarThickness = Color3.fromRGB(47, 61, 70), 0, 8
petInventory.CanvasSize, petInventory.AutomaticCanvasSize, petInventory.Visible, petInventory.Parent = UDim2.new(), Enum.AutomaticSize.Y, false, menu
rounded(petInventory, 14)
local enchantmentPage = Instance.new("ScrollingFrame")
enchantmentPage.Name, enchantmentPage.Size, enchantmentPage.Position = "EnchantmentPage", content.Size, content.Position
enchantmentPage.BackgroundColor3, enchantmentPage.BorderSizePixel = Color3.fromRGB(47, 61, 70), 0
enchantmentPage.ScrollBarThickness, enchantmentPage.AutomaticCanvasSize = 8, Enum.AutomaticSize.Y
enchantmentPage.Visible, enchantmentPage.Parent = false, menu
rounded(enchantmentPage, 14)
local enchantmentLayout = Instance.new("UIListLayout")
enchantmentLayout.Padding, enchantmentLayout.Parent = UDim.new(0, 10), enchantmentPage
local enchantmentPadding = Instance.new("UIPadding")
enchantmentPadding.PaddingTop, enchantmentPadding.PaddingBottom = UDim.new(0, 10), UDim.new(0, 10)
enchantmentPadding.PaddingLeft, enchantmentPadding.PaddingRight, enchantmentPadding.Parent = UDim.new(0, 10), UDim.new(0, 10), enchantmentPage
local enchantmentCards = {}
for _, id in { "Damage", "Luck", "PetCapacity" } do
	local card = Instance.new("Frame")
	card.Name, card.Size, card.BackgroundColor3 = id, UDim2.new(1, -8, 0, 88), Color3.fromRGB(61, 76, 83)
	card.Parent = enchantmentPage
	rounded(card, 12)
	local detail = Instance.new("TextLabel")
	detail.Name, detail.Size, detail.Position = "Description", UDim2.new(1, -150, 1, -12), UDim2.fromOffset(12, 6)
	detail.BackgroundTransparency, detail.TextColor3, detail.TextXAlignment = 1, Color3.new(1, 1, 1), Enum.TextXAlignment.Left
	detail.TextWrapped, detail.Font, detail.TextSize, detail.Parent = true, Enum.Font.GothamBold, 15, card
	local buy = makeButton("Upgrade_" .. id, "UPGRADE", UDim2.fromOffset(120, 52), UDim2.new(1, -132, 0.5, -26), Color3.fromRGB(92, 164, 118), card)
	buy.Activated:Connect(function() upgradeRemote:FireServer(id) end)
	enchantmentCards[id] = { Detail = detail, Button = buy }
end
local petListLayout = Instance.new("UIListLayout")
petListLayout.Name, petListLayout.Padding, petListLayout.SortOrder = "PetInventoryLayout", UDim.new(0, 8), Enum.SortOrder.LayoutOrder
petListLayout.Parent = petInventory
local petListPadding = Instance.new("UIPadding")
petListPadding.Name, petListPadding.PaddingTop, petListPadding.PaddingBottom = "PetInventoryPadding", UDim.new(0, 10), UDim.new(0, 10)
petListPadding.PaddingLeft, petListPadding.PaddingRight, petListPadding.Parent = UDim.new(0, 10), UDim.new(0, 10), petInventory
local petInventorySummary = Instance.new("TextLabel")
petInventorySummary.Name, petInventorySummary.LayoutOrder, petInventorySummary.Size = "InventorySummary", 0, UDim2.new(1, -8, 0, 28)
petInventorySummary.BackgroundTransparency, petInventorySummary.TextColor3 = 1, Color3.fromRGB(255, 229, 165)
petInventorySummary.TextXAlignment, petInventorySummary.Font, petInventorySummary.TextSize = Enum.TextXAlignment.Left, Enum.Font.GothamBlack, 16
petInventorySummary.Parent = petInventory
local function parseIds(value, separator)
	local counts = {}
	for entry in string.gmatch(value or "", "[^" .. separator .. "]+") do
		local id = string.gsub(entry, "^%s*(.-)%s*$", "%1")
		if id ~= "" then counts[id] = (counts[id] or 0) + 1 end
	end
	return counts
end
local function petInventoryButton(parent, text, color, enabled, callback)
	local button = Instance.new("TextButton")
	button.Size, button.BackgroundColor3 = UDim2.fromOffset(94, 34), enabled and color or Color3.fromRGB(76, 82, 88)
	button.Text, button.TextColor3, button.TextSize = text, Color3.new(1, 1, 1), 14
	button.Font, button.AutoButtonColor, button.Active = Enum.Font.GothamBold, enabled, enabled
	button.Parent = parent
	rounded(button, 8)
	if enabled then button.Activated:Connect(callback) end
	return button
end
local function renderPetInventory()
	for _, child in petInventory:GetChildren() do
		if child ~= petListLayout and child ~= petListPadding and child ~= petInventorySummary then child:Destroy() end
	end
	local owned = parseIds(player:GetAttribute("PetCollection"), ",")
	local equipped = parseIds(player:GetAttribute("EquippedPets"), ",")
	local equippedTotal = 0
	for _, count in pairs(equipped) do equippedTotal += count end
	local capacity = 3 + (player:GetAttribute("PetCapacityLevel") or 0)
	petInventorySummary.Text = string.format("EQUIPPED %d / %d  •  PET INDEX", equippedTotal, capacity)
	local petIds = {}
	for petId in pairs(CompanionConfig) do table.insert(petIds, petId) end
	table.sort(petIds, function(a, b) return CompanionConfig[a].Name < CompanionConfig[b].Name end)
	for order, petId in petIds do
		local config, count, equippedCount = CompanionConfig[petId], owned[petId], equipped[petId] or 0
		local row = Instance.new("Frame")
		row.Name, row.LayoutOrder, row.Size = petId, order, UDim2.new(1, -8, 0, 76)
		row.BackgroundColor3, row.BackgroundTransparency, row.Parent = Color3.fromRGB(61, 76, 83), count > 0 and 1 or 0.18, petInventory
		rounded(row, 10)
		TweenService:Create(row, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 0 }):Play()
		local icon = Instance.new("TextLabel")
		icon.Size, icon.Position = UDim2.fromOffset(48, 48), UDim2.fromOffset(8, 14)
		icon.BackgroundTransparency, icon.TextSize = 1, 30
		icon.Text = ({ Sproutling = "🌱", Pebbleback = "🪨", Wispling = "✨" })[petId] or "✦"
		icon.Parent = row
		local details = Instance.new("TextLabel")
		details.Size, details.Position = UDim2.new(1, -265, 1, -8), UDim2.fromOffset(62, 4)
		details.BackgroundTransparency, details.TextColor3 = 1, Color3.new(1, 1, 1)
		details.TextXAlignment, details.TextYAlignment = Enum.TextXAlignment.Left, Enum.TextYAlignment.Center
		details.Font, details.TextSize = Enum.Font.GothamBold, 15
		details.TextWrapped = true
		details.Text = string.format("%s  •  %s%s\nOwned %d  •  Equipped %d\n+%d%% damage  •  +%d%% Valor", config.Name, config.Role, count == 0 and "  •  UNDISCOVERED" or "", count, equippedCount, (config.DamageBonus or 0) * 100, (config.CupsBonus or 0) * 100)
		details.Parent = row
		petInventoryButton(row, "EQUIP", Color3.fromRGB(62, 153, 104), equippedCount < count and equippedTotal < capacity, function()
		petActionRemote:FireServer("Equip", petId)
		end).Position = UDim2.new(1, -202, 0.5, -17)
		petInventoryButton(row, "UNEQUIP", Color3.fromRGB(167, 79, 74), equippedCount > 0, function()
		petActionRemote:FireServer("Unequip", petId)
		end).Position = UDim2.new(1, -102, 0.5, -17)
	end
end
local eggModal = Instance.new("Frame")
eggModal.Name, eggModal.Size, eggModal.Position = "EggChoice", UDim2.fromOffset(430, 310), UDim2.new(0.5, -215, 0.5, -155)
eggModal.BackgroundColor3, eggModal.Visible, eggModal.Parent = Color3.fromRGB(37, 47, 61), false, gui
rounded(eggModal, 18)
local eggModalScale = Instance.new("UIScale")
eggModalScale.Scale, eggModalScale.Parent = 0.94, eggModal
local eggTitle = Instance.new("TextLabel")
eggTitle.Size, eggTitle.Position, eggTitle.BackgroundTransparency = UDim2.new(1, -60, 0, 50), UDim2.fromOffset(18, 10), 1
eggTitle.Text, eggTitle.TextColor3, eggTitle.Font, eggTitle.TextScaled = "CHOOSE HATCH AMOUNT", Color3.fromRGB(255, 230, 169), Enum.Font.GothamBlack, true
eggTitle.Parent = eggModal
local eggDescription = Instance.new("TextLabel")
eggDescription.Size, eggDescription.Position, eggDescription.BackgroundTransparency = UDim2.new(1, -36, 0, 56), UDim2.fromOffset(18, 64), 1
eggDescription.TextColor3, eggDescription.TextWrapped, eggDescription.Font, eggDescription.TextSize = Color3.new(1, 1, 1), true, Enum.Font.Gotham, 18
eggDescription.Parent = eggModal
local eggOneButton = makeButton("HatchOne", "OPEN 1 EGG", UDim2.new(1, -44, 0, 58), UDim2.fromOffset(22, 140), Color3.fromRGB(68, 147, 112), eggModal)
local tripleButtonText = MonetizationConfig.TripleHatchPassId > 0 and "OPEN 3 EGGS • GAMEPASS" or "OPEN 3 EGGS • GAMEPASS ID NEEDED"
local eggThreeButton = makeButton("HatchThree", tripleButtonText, UDim2.new(1, -44, 0, 58), UDim2.fromOffset(22, 208), Color3.fromRGB(123, 91, 183), eggModal)
local eggCloseButton = makeButton("CloseEggChoice", "×", UDim2.fromOffset(38, 38), UDim2.new(1, -48, 0, 10), Color3.fromRGB(92, 108, 119), eggModal)
local selectedEggId
local hatchOverlay = Instance.new("Frame")
hatchOverlay.Name, hatchOverlay.Size, hatchOverlay.Position = "HatchAnimation", UDim2.fromScale(1, 1), UDim2.fromScale(0, 0)
hatchOverlay.BackgroundColor3, hatchOverlay.BackgroundTransparency, hatchOverlay.Visible, hatchOverlay.Parent = Color3.fromRGB(12, 16, 25), 0.18, false, gui
local hatchCard = Instance.new("Frame")
hatchCard.Size, hatchCard.Position, hatchCard.BackgroundColor3 = UDim2.fromOffset(430, 360), UDim2.new(0.5, -215, 0.5, -180), Color3.fromRGB(44, 52, 72)
hatchCard.Parent = hatchOverlay
rounded(hatchCard, 22)
local hatchOrb = Instance.new("TextLabel")
hatchOrb.Name, hatchOrb.Size, hatchOrb.Position = "HatchEggOrb", UDim2.fromOffset(150, 150), UDim2.new(0.5, -75, 0, 28)
hatchOrb.BackgroundColor3, hatchOrb.Text = Color3.fromRGB(137, 116, 185), "✦"
hatchOrb.TextColor3, hatchOrb.TextScaled, hatchOrb.Font = Color3.new(1, 1, 1), true, Enum.Font.GothamBlack
hatchOrb.Parent = hatchCard
rounded(hatchOrb, 75)
local hatchResultLabel = Instance.new("TextLabel")
hatchResultLabel.Size, hatchResultLabel.Position, hatchResultLabel.BackgroundTransparency = UDim2.new(1, -30, 0, 92), UDim2.fromOffset(15, 194), 1
hatchResultLabel.TextColor3, hatchResultLabel.TextWrapped = Color3.new(1, 1, 1), true
hatchResultLabel.Font, hatchResultLabel.TextSize, hatchResultLabel.Parent = Enum.Font.GothamBlack, 23, hatchCard
local hatchContinue = makeButton("HatchContinue", "VIEW PET INVENTORY", UDim2.new(1, -42, 0, 54), UDim2.fromOffset(21, 292), Color3.fromRGB(75, 153, 116), hatchCard)
hatchContinue.Visible = false
local hatchAnimating = false
local activeTab = "Stats"
local function renderPage(tabName)
	activeTab = tabName
	title.Text = tabName == "Pets" and "PET INVENTORY" or "ARCHMAGE JOURNAL"
	petInventory.Visible = tabName == "Pets"
	enchantmentPage.Visible = tabName == "Enchantments"
	content.Visible = tabName ~= "Pets" and tabName ~= "Enchantments"
	if tabName == "Pets" then renderPetInventory(); return end
	if tabName == "Enchantments" then
		for id, card in pairs(enchantmentCards) do
			local config = UpgradeConfig.Enchantments[id]
			local attrName = id .. "EnchantmentLevel"
			local level = player:GetAttribute(attrName) or 0
			local cost = math.floor(config.BaseCost * config.CostMultiplier ^ level + 0.5)
			card.Detail.Text = string.format("%s  •  LEVEL %d / %d\n%s", config.DisplayName, level, config.MaxLevel, config.Description)
			card.Button.Text = level >= config.MaxLevel and "MAX" or string.format("UPGRADE  •  %d VALOR", cost)
			card.Button:SetAttribute("BaseColor", level >= config.MaxLevel and Color3.fromRGB(82, 92, 92) or Color3.fromRGB(92, 164, 118))
		end
		return
	end
	local valor = player:GetAttribute("Valor") or 0
	local magicPower = player:GetAttribute("MagicPower") or 0
	local level, xp = player:GetAttribute("Level") or 1, player:GetAttribute("XP") or 0
	local mastery = player:GetAttribute("SkillMasteryLevel") or 0
	local masteryConfig = UpgradeConfig.SkillMastery
	local nextCost = mastery < masteryConfig.MaxLevel and math.floor(masteryConfig.BaseCost * masteryConfig.CostMultiplier ^ mastery + 0.5) or nil
	local mage = MageConfig[player:GetAttribute("MageArchetype") or "Pyromancer"] or MageConfig.Pyromancer
	local pages = {
		Stats = string.format("%s\nM1: %s  •  Q: %s  •  E: %s\nLevel: %d  •  XP: %d\nValor: %d  •  Magic Power: %d\nHighest zone unlocked: %d", mage.DisplayName, mage.M1.Name, mage.Q.Name, mage.E.Name, level, xp, valor, magicPower, player:GetAttribute("HighestZoneUnlocked") or 1),
		Pets = "PETS\nSelect companions in your inventory.",
		Eggs = "EGGS\nArchmage Egg — 25 Valor\nCrystal Egg — 100 Valor\nAstral Egg — 350 Valor\nBuy eggs from their stands in the hub.",
		Enchantments = "ENCHANTMENTS\nArcane Power, Fortune, Haste, and Critical Magic are planned for a later milestone.",
		Upgrades = string.format("SKILL MASTERY\nLevel: %d / %d\nQ and E skill damage: +%d%%\n%s\nUpgrade at the Meditation Pool focus stone.", mastery, masteryConfig.MaxLevel, mastery * masteryConfig.DamagePerLevel * 100, nextCost and ("Next rank: " .. nextCost .. " Valor") or "Mastery fully upgraded."),
	}
	content.Text, content.TextTransparency = pages[tabName] or pages.Stats, 1
	TweenService:Create(content, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { TextTransparency = 0 }):Play()
end
for order, tabName in { "Stats", "Pets", "Eggs", "Enchantments", "Upgrades" } do
	local button = makeButton(tabName .. "Tab", tabName, UDim2.new(1 / 5, -6, 1, 0), UDim2.new(), Color3.fromRGB(79, 117, 112), tabBar)
	button.LayoutOrder = order
	button.Activated:Connect(function() renderPage(tabName) end)
end
local journalButton = makeButton("JournalButton", "JOURNAL  ☰", UDim2.fromOffset(150, 46), UDim2.new(1, -168, 0, 18), Color3.fromRGB(70, 91, 106))
journalButton.Activated:Connect(function() setMenuVisible(not menuOpen) end)
closeButton.Activated:Connect(function() setMenuVisible(false) end)
local function refresh()
	stats.Text = string.format("Valor  %d   •   Magic Power  %d\nLevel  %d  •  XP  %d", player:GetAttribute("Valor") or 0, player:GetAttribute("MagicPower") or 0, player:GetAttribute("Level") or 1, player:GetAttribute("XP") or 0)
	local mage = MageConfig[player:GetAttribute("MageArchetype") or "Pyromancer"] or MageConfig.Pyromancer
	boltButton.Text, waveButton.Text = string.upper(mage.Q.Name .. " [Q]"), string.upper(mage.E.Name .. " [E]")
	boltButton.BackgroundColor3, waveButton.BackgroundColor3 = mage.Color, mage.Color:Lerp(Color3.new(0, 0, 0), 0.3)
	boltButton:SetAttribute("BaseColor", mage.Color)
	waveButton:SetAttribute("BaseColor", mage.Color:Lerp(Color3.new(0, 0, 0), 0.3))
	local mastery = player:GetAttribute("SkillMasteryLevel") or 0
	local masteryConfig = UpgradeConfig.SkillMastery
	upgradeButton.Text = mastery >= masteryConfig.MaxLevel and "MASTERY MAX" or string.format("FOCUS AT POOL • %d VALOR", math.floor(masteryConfig.BaseCost * masteryConfig.CostMultiplier ^ mastery + 0.5))
	if menuOpen then renderPage(activeTab) end
end
for _, attribute in { "Valor", "MagicPower", "DamageEnchantmentLevel", "LuckEnchantmentLevel", "PetCapacityLevel", "Level", "XP", "SkillMasteryLevel", "HighestZoneUnlocked", "PetCollection", "EquippedPets", "MageArchetype" } do
	player:GetAttributeChangedSignal(attribute):Connect(refresh)
end
refresh()
renderPage("Stats")

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
	eggThreeButton:SetAttribute("BaseColor", egg.Color)
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
		local pop = TweenService:Create(hatchOrb, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = UDim2.fromOffset(210, 210), BackgroundColor3 = Color3.new(1, 1, 1) })
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
	setMenuVisible(true)
	renderPage("Pets")
end)

local function castSkill(slot) castSkillRemote:FireServer(slot) end
local sprinting = false
local function setSprinting(value)
	if sprinting == value then return end
	sprinting = value
	sprintRemote:FireServer(value)
	sprintHint.Text = value and "SPRINTING  •  RELEASE SHIFT" or "HOLD SHIFT TO SPRINT"
	local sprintColor = value and Color3.fromRGB(61, 137, 171) or Color3.fromRGB(35, 43, 52)
	TweenService:Create(sprintHint, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundColor3 = sprintColor }):Play()
end
boltButton.Activated:Connect(function() castSkill("Q") end)
waveButton.Activated:Connect(function() castSkill("E") end)
upgradeButton.Activated:Connect(function() upgradeRemote:FireServer("SkillMastery") end)
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
