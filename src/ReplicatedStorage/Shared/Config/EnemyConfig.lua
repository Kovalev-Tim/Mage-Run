local ZoneConfig = require(script.Parent.ZoneConfig)
local EnemyConfig = {}

for zoneId, zone in ZoneConfig do
	for enemyIndex, enemyId in zone.EnemyIds do
		local isBoss = zone.BossIndex == enemyIndex
		local health = math.floor((42 + enemyIndex * 16) * zone.Difficulty * (isBoss and 6 or 1) + 0.5)
		local damage = 3 + zoneId * 1.15 + (enemyIndex - 1) * 0.55
		if isBoss then damage *= 1.75 end
		local tint = isBoss and Color3.fromRGB(255, 92, 70) or Color3.fromRGB(232, 242, 255)
		EnemyConfig[enemyId] = {
			Name = zone.EnemyNames[enemyIndex],
			Health = health,
			Damage = math.floor(damage + 0.5),
			AttackRange = isBoss and 8 or 6,
			AttackCooldown = math.max(1.8, 2.8 - zoneId * 0.035),
			Cups = math.floor((4 + zoneId * 1.6 + enemyIndex * 1.2) * (isBoss and 5 or 1) + 0.5),
			XP = math.floor((7 + zoneId * 2 + enemyIndex * 1.5) * (isBoss and 4 or 1) + 0.5),
			Color = isBoss and zone.Color:Lerp(tint, 0.38) or zone.Color:Lerp(tint, (enemyIndex - 1) * 0.07),
			IsBoss = isBoss,
			SpecialAttack = isBoss and zone.SpecialAttack or nil,
		}
	end
end

return EnemyConfig
