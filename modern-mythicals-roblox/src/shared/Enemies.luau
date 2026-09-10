--!strict
-- Enemy archetypes. (Design doc § VIII.)
--
-- Enemies are built from the SAME perk data as players. An Awakened enemy simply
-- "owns" some player perk trees at given ranks — so a new elite is a config entry,
-- not new code, and combat stays legible (a player who owns Pyromancy recognizes a
-- fireball wind-up on an enemy caster).
--
-- ⛔ FIREWALL: faction flavor referenced here consumes canon (Master Faction List).
-- Nothing invented for the game flows back to canon.

local Types = require(script.Parent.Types)

local Enemies: { [string]: Types.EnemyArchetype } = {}

-- ── 1. NEW ORDER — trained mortal hunter teams (the baseline urban enemy) ────
-- Mortals with training, gear, ideology. Escalate: later teams include Awakened
-- members with full perk trees, and the player feels the difference immediately.
Enemies.NewOrderGrunt = {
	id = "NewOrderGrunt",
	faction = "New Order",
	displayName = "New Order Hunter",
	tier = 1,
	supernatural = false,
	perks = {}, -- trained mortal; gear-driven, no Soul perks
	notes = "Baseline. Ranged suppression + coordinated five-man team behavior.",
}
Enemies.NewOrderAwakened = {
	id = "NewOrderAwakened",
	faction = "New Order",
	displayName = "New Order Zealot (Awakened)",
	tier = 3,
	supernatural = true,
	-- An Awakened hunter who bought into a player tree. Legible on sight.
	perks = { Emberhand = 3, SoulHardened = 2 },
	notes = "The escalation. A New Order member with a real perk tree.",
}

-- ── 2. DARKLING-POSSESSED STREET GANGS — the horror encounter ────────────────
-- Ordinary mortal gang led by a possessed individual. Fight changes shape when
-- the leader dies and something comes out of him (Ravager emergence).
Enemies.GangMook = {
	id = "GangMook",
	faction = "Darkling Gang",
	displayName = "Gang Member",
	tier = 1,
	supernatural = false,
	perks = {},
	notes = "Ordinary until the leader is killed.",
}
Enemies.RiddenLeader = {
	id = "RiddenLeader",
	faction = "Darkling Gang",
	displayName = "The Ridden",
	tier = 4,
	supernatural = true,
	perks = { RedRend = 4, SoulHardened = 3 },
	notes = "Mid-encounter shape change: Ravager emerges (quadrupedal). Stylized horror per content standard — light/silhouette, not viscera.",
}

-- ── 3. JOI BOYZ — ex-Yakuza, technologically augmented (NOT Mythical) ────────
-- A TECH threat in a supernatural setting. No perks, no Darkling mechanics.
-- Anti-Darkling tools do nothing. Natural weakness: augmentation is hardware —
-- Frankenstein electrical attacks get a class advantage.
Enemies.JoiBoy = {
	id = "JoiBoy",
	faction = "Joi Boyz",
	displayName = "Joi Boy",
	tier = 3,
	supernatural = false,
	perks = {}, -- tech, not Soul
	notes = "Eerily precise, long blades. Weak to electric (Frankenstein advantage). Five-man teams; music/comm-pod signal.",
}

-- ── 4. NARAKA — Utal-engineered bio-weapons (Everglades zone) ────────────────
-- Separate lineage, not Darkling-derived. Immune to cold and regenerate from it,
-- giving the swamp zone its own puzzle. Sense strong Souls and prefer them.
Enemies.NarakaPup = {
	id = "NarakaPup",
	faction = "Naraka",
	displayName = "Naraka Pup",
	tier = 2,
	supernatural = true,
	perks = { BloodScent = 2 },
	notes = "Pack hunter. Hexapedal. Escaped stock now evolving past its programming.",
}
Enemies.NarakaElder = {
	id = "NarakaElder",
	faction = "Naraka",
	displayName = "Naraka Elder",
	tier = 5,
	supernatural = true,
	perks = { BloodScent = 4, SoulHardened = 4, RedRend = 5 },
	notes = "Everglades boss. Circular maw defeats regeneration; immune to cold, regenerates from it. Change loadout for the zone.",
}

-- Factions grouped for spawn tables.
Enemies.FACTIONS = {
	"New Order",
	"Darkling Gang",
	"Joi Boyz",
	"Naraka",
}

function Enemies.get(id: string): Types.EnemyArchetype?
	return Enemies[id]
end

return Enemies
