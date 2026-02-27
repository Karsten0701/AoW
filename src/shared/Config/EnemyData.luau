--[[
	Configuratie voor alle enemy/unit types per Age.
	Deze data wordt gedeeld tussen server en client.
]]

export type EnemyInfo = {
	Name: string,
	DisplayName: string,
	Age: string,
	Health: number,
	Damage: number,
	AttackSpeed: number, -- seconden tussen aanvallen
	WalkSpeed: number,
	Cost: number, -- goud om te spawnen
	KillReward: number, -- goud die je krijgt als je hem doodt
	XpReward: number, -- XP voor age progressie
	SpawnCooldown: number, -- seconden cooldown na spawnen
	Description: string,
}

local EnemyData: { [string]: EnemyInfo } = {
	-- ═══════════════════════════════
	-- PREHISTORIC AGE
	-- ═══════════════════════════════
	Enemy1 = {
		Name = "Enemy1",
		DisplayName = "Caveman",
		Age = "Prehistoric",
		Health = 80,
		Damage = 10,
		AttackSpeed = 1.2,
		WalkSpeed = 8,
		Cost = 25,
		KillReward = 15,
		XpReward = 5,
		SpawnCooldown = 3,
		Description = "Basic melee fighter with a club.",
	},
	Enemy2 = {
		Name = "Enemy2",
		DisplayName = "Slinger",
		Age = "Prehistoric",
		Health = 50,
		Damage = 15,
		AttackSpeed = 2.0,
		WalkSpeed = 7,
		Cost = 40,
		KillReward = 25,
		XpReward = 8,
		SpawnCooldown = 5,
		Description = "Ranged unit that throws rocks.",
	},

	-- ═══════════════════════════════
	-- MEDIEVAL AGE
	-- ═══════════════════════════════
	Enemy3 = {
		Name = "Enemy3",
		DisplayName = "Swordsman",
		Age = "Medieval",
		Health = 150,
		Damage = 20,
		AttackSpeed = 1.0,
		WalkSpeed = 9,
		Cost = 60,
		KillReward = 35,
		XpReward = 12,
		SpawnCooldown = 4,
		Description = "Armored melee warrior with a sword.",
	},
	Enemy4 = {
		Name = "Enemy4",
		DisplayName = "Archer",
		Age = "Medieval",
		Health = 90,
		Damage = 25,
		AttackSpeed = 1.8,
		WalkSpeed = 8,
		Cost = 75,
		KillReward = 45,
		XpReward = 15,
		SpawnCooldown = 5,
		Description = "Skilled ranged unit with a longbow.",
	},

	-- ═══════════════════════════════
	-- RENAISSANCE AGE
	-- ═══════════════════════════════
	Enemy5 = {
		Name = "Enemy5",
		DisplayName = "Musketeer",
		Age = "Renaissance",
		Health = 120,
		Damage = 35,
		AttackSpeed = 2.5,
		WalkSpeed = 8,
		Cost = 100,
		KillReward = 60,
		XpReward = 20,
		SpawnCooldown = 5,
		Description = "Slow-firing but deadly ranged soldier.",
	},
	Enemy6 = {
		Name = "Enemy6",
		DisplayName = "Knight",
		Age = "Renaissance",
		Health = 250,
		Damage = 30,
		AttackSpeed = 1.2,
		WalkSpeed = 10,
		Cost = 130,
		KillReward = 80,
		XpReward = 25,
		SpawnCooldown = 6,
		Description = "Heavy armored cavalry unit.",
	},

	-- ═══════════════════════════════
	-- INDUSTRIAL AGE
	-- ═══════════════════════════════
	Enemy7 = {
		Name = "Enemy7",
		DisplayName = "Rifleman",
		Age = "Industrial",
		Health = 180,
		Damage = 45,
		AttackSpeed = 1.5,
		WalkSpeed = 10,
		Cost = 180,
		KillReward = 100,
		XpReward = 35,
		SpawnCooldown = 5,
		Description = "Standard infantry with a rifle.",
	},
	Enemy8 = {
		Name = "Enemy8",
		DisplayName = "Cannoneer",
		Age = "Industrial",
		Health = 300,
		Damage = 80,
		AttackSpeed = 3.5,
		WalkSpeed = 6,
		Cost = 250,
		KillReward = 150,
		XpReward = 50,
		SpawnCooldown = 8,
		Description = "Slow but devastating area damage.",
	},

	-- ═══════════════════════════════
	-- MODERN AGE
	-- ═══════════════════════════════
	Enemy9 = {
		Name = "Enemy9",
		DisplayName = "Marine",
		Age = "Modern",
		Health = 280,
		Damage = 60,
		AttackSpeed = 1.0,
		WalkSpeed = 12,
		Cost = 350,
		KillReward = 200,
		XpReward = 60,
		SpawnCooldown = 5,
		Description = "Fast modern soldier with automatic weapon.",
	},
	Enemy10 = {
		Name = "Enemy10",
		DisplayName = "Tank",
		Age = "Modern",
		Health = 800,
		Damage = 120,
		AttackSpeed = 3.0,
		WalkSpeed = 6,
		Cost = 600,
		KillReward = 350,
		XpReward = 100,
		SpawnCooldown = 12,
		Description = "Massive armored vehicle. Very tanky.",
	},

	-- ═══════════════════════════════
	-- FUTURE AGE
	-- ═══════════════════════════════
	Enemy11 = {
		Name = "Enemy11",
		DisplayName = "Laser Trooper",
		Age = "Future",
		Health = 400,
		Damage = 90,
		AttackSpeed = 0.8,
		WalkSpeed = 14,
		Cost = 800,
		KillReward = 500,
		XpReward = 120,
		SpawnCooldown = 6,
		Description = "High-tech soldier with a laser rifle.",
	},
	Enemy12 = {
		Name = "Enemy12",
		DisplayName = "Mech",
		Age = "Future",
		Health = 1500,
		Damage = 200,
		AttackSpeed = 2.0,
		WalkSpeed = 8,
		Cost = 1500,
		KillReward = 900,
		XpReward = 200,
		SpawnCooldown = 15,
		Description = "Giant robotic war machine.",
	},
}

return EnemyData
