--!strict
-- ┌─────────────────────────────────────────────────────────────────────────┐
-- │  PASTE CREATOR STORE ASSET IDS HERE.                                      │
-- │                                                                           │
-- │  How to get an ID in Roblox Studio:                                       │
-- │    1. View → Toolbox → Creator Store tab.                                 │
-- │    2. Search (e.g. "wolf", "zombie", "streetlight", "dumpster").          │
-- │    3. Right-click the asset → Copy Asset ID.                              │
-- │    4. Paste the number below (as rbxassetid://<number>).                  │
-- │                                                                           │
-- │  Leave a slot as "" and the game falls back to a default primitive / the  │
-- │  standard R15 avatar, so nothing here blocks playtesting.                 │
-- │                                                                           │
-- │  ⚠ Keep to plain MeshParts. Avoid assets needing SurfaceAppearance,       │
-- │    EditableMesh, or CSG unions — they break the headless publish path.    │
-- └─────────────────────────────────────────────────────────────────────────┘

local AssetIds = {}

-- Player class visuals. "" = use the player's default avatar. The shifted forms
-- (e.g. Werewolf) are swapped in at runtime when the ability fires.
AssetIds.ClassModels = {
	Witch = "",
	Werewolf = "", -- human form
	-- The beast. Accepts:  "bundle:<id>" (Avatar Shop bundle, cleanest)
	--                       "rbxassetid://<id>" (Creator Store rig → morph)
	--                       "" (procedural fur + ears + eyes)
	WerewolfShifted = "107113755734876", -- free werewolf from the Roblox catalog/store (auto-detected on load)
	Vampire = "",
	Frankenstein = "",
	Immortal = "",
}

-- Enemy models, keyed by the archetype ids in Enemies.luau.
AssetIds.EnemyModels = {
	NewOrderGrunt = "",
	NewOrderAwakened = "",
	GangMook = "",
	RiddenLeader = "",
	JoiBoy = "",
	NarakaPup = "",
	NarakaElder = "",
}

-- Environment props for the city generator's scatter pass and landmarks.
AssetIds.Props = {
	Palm = "",
	Streetlight = "",
	ParkedCar = "",
	Dumpster = "",
	FireEscape = "",
	JunctionBox = "", -- Frankenstein "live source"
	Transformer = "",
}

-- Audio (bass loops per club, surf, ambience). Monthly upload caps apply to
-- audio for unverified accounts — mind quotas.
AssetIds.Audio = {
	ClubBass = "",
	Surf = "",
	AbbottAmbience = "", -- crickets, A/C, distant siren
	WarehouseSilence = "", -- deliberately empty
}

-- Resolve an id to a usable rbxassetid string, or nil if unset.
function AssetIds.resolve(id: string): string?
	if id == "" then
		return nil
	end
	if string.match(id, "^rbxassetid://") then
		return id
	end
	if string.match(id, "^%d+$") then
		return "rbxassetid://" .. id
	end
	return id
end

return AssetIds
