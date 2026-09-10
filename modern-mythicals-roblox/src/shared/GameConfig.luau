--!strict
-- Global game constants. Single source of truth for tunable numbers.
-- Values marked PLACEHOLDER are flagged in the design docs as needing playtest.

local GameConfig = {}

-- ── World ────────────────────────────────────────────────────────────────
GameConfig.PerpetualNight = true
GameConfig.ClockTime = 0 -- Lighting.ClockTime, midnight
GameConfig.LoginMessage = "You step into another night."

-- ── Map / streaming (from the Miami spec) ─────────────────────────────────
GameConfig.StreamingEnabled = true
GameConfig.PartBudgetPerPlace = 30000 -- budget against phones, not desktop
GameConfig.StudsPerFoot = 1 -- ~1 stud ≈ 1 foot
GameConfig.DefaultWalkSpeed = 16 -- studs/second

-- ── PvP arenas ────────────────────────────────────────────────────────────
GameConfig.PvP = {
	MatchLengthSeconds = 240, -- 4 minutes — the single biggest retention lever
	TeamFormat = 3, -- balance at 3v3, not 1v1
	NormalizeStats = true, -- everyone enters at the same rank/health/pool
	NormalizedSoulRank = 5,
	SeasonalLeaderboards = true,
}

-- ── Combat tunables ────────────────────────────────────────────────────────
GameConfig.Combat = {
	-- "The most important number in the game." Base Immortal parry window.
	-- PLACEHOLDER — must be set by playtest.
	ParryWindowMs = 200,
	-- Downed players can be revived within this window before they fully die.
	DownedBleedoutSeconds = 20,
	-- Global cooldown floor between ability activations (anti-spam).
	GlobalCooldownSeconds = 0.4,
}

-- ── Playtest conveniences (strip before launch) ────────────────────────────
GameConfig.Playtest = {
	-- Granted once when a class is first chosen, so box/perk purchasing can be
	-- exercised before real shard income (kills, quests) exists. PLACEHOLDER.
	StartingShards = 25000,
	-- Werewolves spawn already shifted and the shift never expires (toggle
	-- still works). Off = human form is the wind-up, per the design doc.
	WerewolfStartsShifted = false,
	-- Until Developer Products exist (game must be published), the store grants
	-- skins for free so the buy/equip flow can be tested. Turn OFF for launch.
	FreeSkins = true,
}

-- ── Spawning (rotating hot zones) ──────────────────────────────────────────
GameConfig.Spawns = {
	HotZonesPerNight = 3,
	-- Spawn density climbs the longer players linger in a hot zone.
	DensityRampPerMinute = 0.15,
	DensityCap = 2.5,
	-- After enough pressure, something bigger comes to investigate.
	EscalationThreshold = 40, -- enemies felled in a zone before an elite arrives
}

-- ── Frankenstein "The Current" map mechanic ────────────────────────────────
-- Electrical source density gradient by zone (0-1). Collins is wired; the
-- swamp is not — which gives the Frankenstein real zone identity.
GameConfig.ElectricalDensity = {
	Collins = 1.0,
	Abbott = 0.35,
	WarehouseBelt = 0.5,
	Everglades = 0.05,
}

-- ── Content standard (stricter than the novels) ────────────────────────────
GameConfig.ContentStandard = {
	NoGore = true,
	NoProfanity = true,
	NoSexualContent = true,
	-- Darkling emergence rendered through light/energy/silhouette, not viscera.
	StylizedHorror = true,
}

return GameConfig
