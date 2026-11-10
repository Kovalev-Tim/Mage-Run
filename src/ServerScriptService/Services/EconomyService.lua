local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CompanionConfig = require(ReplicatedStorage.Shared.Config.CompanionConfig)
local EconomyService = {}
local dataService, remotes
local function xpToNext(level) return math.floor(60 * (level ^ 1.35) + 0.5) end
function EconomyService:Start(dependencies)
	dataService, remotes = dependencies.PlayerDataService, dependencies.Remotes
end
function EconomyService:AwardEnemy(player, config)
	local data = dataService:Get(player)
	if not data then return end
	local valorBonus = 0
	for _, companionId in data.Companions.Equipped do
		local companion = CompanionConfig[companionId]
		if companion then valorBonus += companion.CupsBonus or 0 end
	end
	local valor = math.floor(config.Cups * (1 + valorBonus) + 0.5)
	data.Valor += valor
	data.XP += config.XP
	while data.XP >= xpToNext(data.Level) do
		data.XP -= xpToNext(data.Level)
		data.Level += 1
	end
	dataService:UpdateAttributes(player)
	remotes.Reward:FireClient(player, { Valor = valor, XP = config.XP, Level = data.Level, TotalValor = data.Valor, TotalXP = data.XP, XPToNext = xpToNext(data.Level) })
end
function EconomyService:XPToNext(level) return xpToNext(level) end
return EconomyService
