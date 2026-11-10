local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CompanionConfig = require(ReplicatedStorage.Shared.Config.CompanionConfig)
local PetService = {}
local followers = {}
local dataService, remotes
local colors = {
	Sproutling = Color3.fromRGB(105, 220, 118),
	Pebbleback = Color3.fromRGB(147, 155, 164),
	Wispling = Color3.fromRGB(123, 153, 255),
}

local function addPetPart(model, name, shape, size, offset, color, material)
	local item = Instance.new("Part")
	item.Name, item.Shape, item.Size = name, shape, size
	item.CFrame = CFrame.new(offset)
	item.Anchored, item.CanCollide, item.CanTouch, item.CanQuery = true, false, false, false
	item.Material, item.Color = material or Enum.Material.SmoothPlastic, color
	item.Parent = model
	return item
end

local function makePet(parent, petId, index)
	local config = CompanionConfig[petId]
	if not config then return nil end
	local color = colors[petId] or Color3.fromRGB(231, 177, 255)
	local model = Instance.new("Model")
	model:SetAttribute("PetId", petId)
	model.Name = string.format("Follower_%d_%s", index, petId)
	local body = addPetPart(model, "Body", Enum.PartType.Ball, Vector3.new(1.8, 1.8, 1.8), Vector3.zero, color, petId == "Wispling" and Enum.Material.Neon or Enum.Material.SmoothPlastic)
	model.PrimaryPart = body
	if petId == "Sproutling" then
		addPetPart(model, "LeafLeft", Enum.PartType.Ball, Vector3.new(0.6, 1.2, 0.35), Vector3.new(-0.55, 0.9, 0), Color3.fromRGB(66, 173, 82), Enum.Material.Grass)
		addPetPart(model, "LeafRight", Enum.PartType.Ball, Vector3.new(0.6, 1.2, 0.35), Vector3.new(0.55, 0.9, 0), Color3.fromRGB(66, 173, 82), Enum.Material.Grass)
	elseif petId == "Pebbleback" then
		addPetPart(model, "Shell", Enum.PartType.Ball, Vector3.new(1.35, 0.9, 1.35), Vector3.new(0, 0.55, 0), Color3.fromRGB(95, 104, 116), Enum.Material.Slate)
	elseif petId == "Wispling" then
		for _, offset in { Vector3.new(-1, 0.55, 0), Vector3.new(1, 0.55, 0), Vector3.new(0, -0.8, 0) } do
			addPetPart(model, "Orbit", Enum.PartType.Ball, Vector3.new(0.45, 0.45, 0.45), offset, Color3.fromRGB(193, 212, 255), Enum.Material.Neon)
		end
	end
	local billboard = Instance.new("BillboardGui")
	billboard.Size, billboard.StudsOffset, billboard.AlwaysOnTop = UDim2.fromOffset(100, 24), Vector3.new(0, 1.6, 0), true
	billboard.Parent = body
	local label = Instance.new("TextLabel")
	label.Size, label.BackgroundTransparency = UDim2.fromScale(1, 1), 1
	label.Text, label.TextColor3, label.TextStrokeTransparency = config.Name, Color3.new(1, 1, 1), 0.3
	label.TextScaled, label.Font, label.Parent = true, Enum.Font.GothamBold, billboard
	model.Parent = parent
	return model
end

function PetService:Start(dependencies)
	dataService, remotes = dependencies.PlayerDataService, dependencies.Remotes
	dataService.Ready:Connect(function(player) self:RefreshPlayer(player) end)
	remotes.PetAction.OnServerEvent:Connect(function(player, action, petId)
		self:HandleAction(player, action, petId)
	end)
	Players.PlayerRemoving:Connect(function(player)
		local entry = followers[player]
		if entry and entry.Folder then entry.Folder:Destroy() end
		followers[player] = nil
	end)
	local elapsed = 0
	RunService.Heartbeat:Connect(function(dt)
		elapsed += dt
		if elapsed < 0.1 then return end
		local step = elapsed
		elapsed = 0
		for player, entry in pairs(followers) do
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if root then
				for index, model in entry.Models do
					if model.Parent then
						local xOffset = (index - (#entry.Models + 1) / 2) * 2.6
						local bob = math.sin(os.clock() * 3 + index) * 0.25
						local target = root.CFrame * CFrame.new(xOffset, 1.4 + bob, 3.2)
						model:PivotTo(model:GetPivot():Lerp(target, math.min(step * 7, 1)))
					end
				end
			end
		end
	end)
end

function PetService:HandleAction(player, action, petId)
	local data = dataService:Get(player)
	if not data or typeof(action) ~= "string" then return end
	local capacity = 3 + ((data.Upgrades.Enchantments and data.Upgrades.Enchantments.PetCapacity) or 0)
	if action == "UnequipAll" then
		data.Companions.Equipped = {}
	elseif action == "EquipBest" then
		local function score(id) local c = CompanionConfig[id]; return c and ((c.DamageBonus or 0) + (c.CupsBonus or 0)) or -1 end
		local pool = table.clone(data.Companions.Owned)
		table.sort(pool, function(a, b) return score(a) > score(b) end)
		data.Companions.Equipped = {}
		for _, id in pool do
			if #data.Companions.Equipped >= capacity then break end
			if CompanionConfig[id] then table.insert(data.Companions.Equipped, id) end
		end
	elseif (action == "Equip" or action == "Unequip") and CompanionConfig[petId] then
		local ownedCount, equippedCount = 0, 0
		for _, id in data.Companions.Owned do if id == petId then ownedCount += 1 end end
		for _, id in data.Companions.Equipped do if id == petId then equippedCount += 1 end end
		if action == "Equip" then
			if ownedCount <= equippedCount then return end
			if #data.Companions.Equipped >= capacity then
				remotes.Message:FireClient(player, "Pet capacity is " .. capacity .. " • upgrade Bond in Enchantments")
				return
			end
			table.insert(data.Companions.Equipped, petId)
		else
			for index = #data.Companions.Equipped, 1, -1 do
				if data.Companions.Equipped[index] == petId then table.remove(data.Companions.Equipped, index); break end
			end
		end
	else
		return
	end
	dataService:UpdateAttributes(player)
	self:RefreshPlayer(player)
end

function PetService:RefreshPlayer(player)
	local previous = followers[player]
	if previous and previous.Folder then previous.Folder:Destroy() end
	local data = dataService:Get(player)
	if not data then followers[player] = nil; return end
	local folder = Instance.new("Folder")
	folder.Name, folder.Parent = "PetFollowers_" .. player.UserId, workspace:FindFirstChild("RiftRunWorld") or workspace
	local models = {}
	for _, petId in data.Companions.Equipped do
		local capacity = 3 + ((data.Upgrades.Enchantments and data.Upgrades.Enchantments.PetCapacity) or 0)
		if #models >= capacity then break end
		local model = makePet(folder, petId, #models + 1)
		if model then table.insert(models, model) end
	end
	followers[player] = { Folder = folder, Models = models }
end

return PetService
