--!strict
-- Shared type definitions for Modern Mythicals.
-- Kept in one place so server, client, and data modules agree on shapes.

export type ClassId = "Witch" | "Werewolf" | "Vampire" | "Frankenstein" | "Immortal"

export type DamageType = "Fire" | "Electric" | "Physical" | "Supernatural"

export type CurrencyId = "SoulShards" | "Cash" | "Robux"

-- One rank of a perk tree. Rank 1 unlocks the ability; 2-5 upgrade it.
export type PerkRank = {
	rank: number, -- 1..5
	name: string, -- flavor name for this rank ("Rend", "Bite", ...)
	effect: string, -- human-readable effect (design text)
	shardCost: number, -- Soul Shards to purchase this rank
}

-- A perk tree = one ability on one hotbar slot, five ranks deep.
export type PerkTree = {
	id: string, -- stable key, e.g. "Emberhand"
	ability: string, -- the button's ability name, e.g. "Flame Dart"
	slot: number, -- hotbar slot 1..5 (0 = passive/shared, e.g. Defense)
	role: string, -- design role tag ("basic attack", "movement", ...)
	summary: string, -- one-line description
	ranks: { PerkRank },
}

export type Class = {
	id: ClassId,
	displayName: string,
	startingPower: string, -- the rank-1 ability of the basic-attack tree
	role: string, -- design role ("Ranged caster", ...)
	mythologicalAnchor: string,
	baseHealth: number,
	baseSoulPool: number,
	trees: { string }, -- ordered tree ids, slots 1..5
	attackTree: string, -- the tree left-click fires (the class's basic attack)
	resource: string, -- "SoulPool" | "Fury" | ... resource the class spends
}

-- A player's live progression state (persisted).
export type PlayerProfile = {
	class: ClassId?,
	soulRank: number, -- 1..10
	boxesInRank: number, -- 0..10 progress toward next rank
	soulShards: number,
	cash: number,
	health: number,
	soulPool: number,
	-- Owned perk ranks: treeId -> highest rank owned (0 = not owned)
	perks: { [string]: number },
	-- Crossover trees the player has bought ACCESS to (Robux). Ranks still cost Shards.
	crossoverAccess: { [string]: boolean },
	cosmetics: { [string]: boolean },
	stats: {
		nightsPlayed: number,
		enemiesFelled: number,
		arenaWins: number,
	},
}

export type EnemyArchetype = {
	id: string,
	faction: string,
	displayName: string,
	tier: number, -- Soul-equivalent difficulty tier
	supernatural: boolean, -- false for New Order mortals / Joi Boyz tech
	-- Enemies are built from the SAME perk data as players. This lists the
	-- trees (and the rank each is at) the enemy "owns". A new elite is a
	-- config entry, not new code.
	perks: { [string]: number },
	notes: string,
}

-- ModuleScripts must return exactly one non-nil value; the exported types
-- above are what callers actually consume.
return {}
