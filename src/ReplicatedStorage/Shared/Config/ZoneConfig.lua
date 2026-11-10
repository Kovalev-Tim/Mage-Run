local definitions = {
 { DisplayName = "Verdant Reach", EnemyNames = { "Mossling", "Bramble Bug", "Pebble Guard", "Thornback", "Grove Goliath" }, Color = Color3.fromRGB(72, 132, 83), Material = Enum.Material.Grass, CupReward = 20 },
	{ DisplayName = "Crystal Hollow", EnemyNames = { "Shardling", "Cave Wisp", "Quartz Stalker", "Crystal Golem", "Prism Brute" }, Color = Color3.fromRGB(74, 116, 151), Material = Enum.Material.Slate, CupReward = 45 },
	{ DisplayName = "Ember Depths", EnemyNames = { "Cinder Imp", "Ash Hound", "Ember Knight", "Lava Brute", "Pyre Drake" }, Color = Color3.fromRGB(145, 76, 57), Material = Enum.Material.Basalt, CupReward = 75 },
	{ DisplayName = "Gloomwood", EnemyNames = { "Shade Rat", "Dusk Crow", "Moonfang", "Hollow Guard", "Night Stalker" }, Color = Color3.fromRGB(79, 68, 105), Material = Enum.Material.Slate, CupReward = 115 },
	{ DisplayName = "Tempest Spire", EnemyNames = { "Gale Sprite", "Storm Hawk", "Thunder Ogre", "Tempest Knight", "Storm Sovereign" }, Color = Color3.fromRGB(73, 119, 157), Material = Enum.Material.Rock, CupReward = 170, SpecialAttack = { Name = "Skyfall Pulse", Damage = 30, Range = 18, Cooldown = 9 } },
	{ DisplayName = "Sunken Sanctuary", EnemyNames = { "Reefling", "Tide Serpent", "Coral Brute", "Deep Wisp", "Abyss Colossus" }, Color = Color3.fromRGB(50, 121, 132), Material = Enum.Material.Slate, CupReward = 240 },
	{ DisplayName = "Frostbound Keep", EnemyNames = { "Frostling", "Snow Lynx", "Ice Guard", "Glacier Ogre", "Winter Stalker" }, Color = Color3.fromRGB(112, 159, 184), Material = Enum.Material.Ice, CupReward = 330 },
	{ DisplayName = "Ashen Wastes", EnemyNames = { "Scorch Beetle", "Ash Phantom", "Furnace Guard", "Coal Drake", "Cinder Brute" }, Color = Color3.fromRGB(123, 78, 63), Material = Enum.Material.Basalt, CupReward = 440 },
	{ DisplayName = "Celestial Ruins", EnemyNames = { "Star Sprite", "Comet Hound", "Astral Sentinel", "Nebula Golem", "Orbit Breaker" }, Color = Color3.fromRGB(82, 91, 151), Material = Enum.Material.Slate, CupReward = 590 },
	{ DisplayName = "Rift Citadel", EnemyNames = { "Riftling", "Void Stalker", "Portal Knight", "Chaos Brute", "Rift Overlord" }, Color = Color3.fromRGB(119, 61, 131), Material = Enum.Material.Basalt, CupReward = 780, SpecialAttack = { Name = "Rift Nova", Damage = 44, Range = 20, Cooldown = 8 } },
}

for zoneId, zone in definitions do
	zone.Id = zoneId
	zone.Start = 15 - (zoneId - 1) * 60
	zone.Finish = zone.Start - 60
	zone.Difficulty = 1 + (zoneId - 1) * 0.28
	zone.EnemyIds = {}
	for enemyIndex = 1, 5 do
		table.insert(zone.EnemyIds, string.format("Z%02dE%02d", zoneId, enemyIndex))
	end
	if zone.SpecialAttack then zone.BossIndex = 5 end
end

return definitions
