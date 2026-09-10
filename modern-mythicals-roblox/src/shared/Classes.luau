--!strict
-- The five playable Mythical classes. (ClassPerkTrees doc.)
-- Each class has exactly 5 perk trees (slots 1-5); tree data lives in PerkTrees.luau.
local Types = require(script.Parent.Types)

local SoulRanks = require(script.Parent.SoulRanks)

local Classes: { [Types.ClassId]: Types.Class } = {
	Witch = {
		id = "Witch",
		displayName = "Witch",
		startingPower = "Flame Dart",
		role = "Ranged caster — pyromancy and sigil-work. Highest damage at range, most fragile up close.",
		mythologicalAnchor = "Cunning folk and hedge-witchcraft — fire, sigils, wards, seals, widdershins.",
		baseHealth = SoulRanks.BASE_HEALTH,
		baseSoulPool = SoulRanks.BASE_SOUL_POOL,
		resource = "SoulPool",
		-- slots 1..5
		trees = { "Emberhand", "Conflagration", "WitchfireAegis", "SigilCraft", "Widdershins" },
		attackTree = "Emberhand",
	},

	Werewolf = {
		id = "Werewolf",
		displayName = "Werewolf",
		startingPower = "Shape Shift",
		role = "Form-swapping bruiser — sustain and pressure. Trades survivability for raw output when shifted.",
		mythologicalAnchor = "Lycanthropy proper — the turning, the pack howl, scent, claws that hold stone.",
		baseHealth = SoulRanks.BASE_HEALTH,
		baseSoulPool = SoulRanks.BASE_SOUL_POOL,
		-- Werewolves spend FURY (builds by dealing/taking damage, drains while shifted),
		-- not Soul Pool. This is the only class whose resource rewards staying in the fight.
		resource = "Fury",
		trees = { "TheTurning", "RedRend", "HuntersHowl", "BloodScent", "CragClimb" },
		-- Slot 1 is the shift, not an attack: left-click swings the claws instead.
		attackTree = "RedRend",
	},

	Vampire = {
		id = "Vampire",
		displayName = "Vampire",
		startingPower = "Blood Drain",
		role = "Speed skirmisher — leech and control. Fastest class; wins by choosing when fights happen.",
		mythologicalAnchor = "The old folklore, not the modern one — mist, the head-first wall-crawl, the gaze that takes your will.",
		baseHealth = SoulRanks.BASE_HEALTH,
		baseSoulPool = SoulRanks.BASE_SOUL_POOL,
		resource = "SoulPool",
		trees = { "RedThirst", "DreadCharm", "Nightspeed", "Mist", "TheCrawl" },
		attackTree = "RedThirst",
	},

	Frankenstein = {
		id = "Frankenstein",
		displayName = "Frankenstein",
		startingPower = "Electric Bolt",
		role = "Support and control — galvanism. The team's answer to a wipe; gets stronger from the map itself.",
		mythologicalAnchor = "Galvanism. Aldini and the vital spark. Not robotics.",
		baseHealth = SoulRanks.BASE_HEALTH,
		baseSoulPool = SoulRanks.BASE_SOUL_POOL,
		resource = "SoulPool",
		trees = { "TheSpark", "Overload", "VitalSpark", "BreakersTouch", "ArcStep" },
		attackTree = "TheSpark",
	},

	Immortal = {
		id = "Immortal",
		displayName = "Immortal",
		startingPower = "Blade Combo",
		role = "Technical duelist — blades, timing, stillness. Highest skill ceiling; walks (stealth is its only traversal).",
		mythologicalAnchor = "The duelist who has had two thousand years to practice and cannot fly, climb, or vanish in a puff — only stand very still.",
		baseHealth = SoulRanks.BASE_HEALTH,
		baseSoulPool = SoulRanks.BASE_SOUL_POOL,
		resource = "SoulPool",
		trees = { "Swordwork", "Riposte", "Stillness", "FirstCut", "Undying" },
		attackTree = "Swordwork",
	},
}

-- Ordered list for UI / iteration.
Classes.ORDER = { "Witch", "Werewolf", "Vampire", "Frankenstein", "Immortal" } :: { Types.ClassId }

function Classes.get(id: Types.ClassId): Types.Class?
	return Classes[id]
end

return Classes
