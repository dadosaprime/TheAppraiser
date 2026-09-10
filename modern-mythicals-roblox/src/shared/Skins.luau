--!strict
-- The cosmetic catalog: code-only skins, sold in-experience for Robux.
--
-- Every entry is built from parts, lights, trails and color overrides — no
-- art assets. Three kinds:
--   element  → recolors a class's ability effects (one per class at a time)
--   aura     → a glowing ring around the body, any class
--   trail    → a colored trail behind you as you move, any class
--   eyes     → glowing eyes, any class
--
-- devProductId is the Roblox Developer Product created in the Creator
-- Dashboard once the game is published. 0 = not created yet; in that case
-- GameConfig.Playtest.FreeSkins lets the store grant for free so the flow can
-- be tested. Prices are Robux PLACEHOLDERS.
--
-- ⛔ FIREWALL: cosmetics are game assets; names here are not canon.

export type Skin = {
	id: string,
	name: string,
	description: string,
	category: string, -- "element" | "aura" | "trail" | "eyes"
	class: string?, -- element skins belong to one class; nil = any class
	price: number, -- Robux
	devProductId: number,
	colors: { [string]: Color3 }?, -- element: overrides for FIRE/ELECTRIC/BLOOD/STEEL/BEAST/VOID
	color: Color3?, -- aura / trail / eyes
	color2: Color3?, -- trail gradient end
}

local Skins = {}

local list: { Skin } = {
	-- ── Element recolors (per class) ─────────────────────────────────────
	{ id = "witch_bluefire", name = "Blue Witchfire", description = "Your fire burns cold blue.", category = "element", class = "Witch", price = 149, devProductId = 0,
		colors = { FIRE = Color3.fromRGB(80, 160, 255), VOID = Color3.fromRGB(60, 110, 200) } },
	{ id = "witch_greenfire", name = "Grave Fire", description = "Sickly green flame, straight from the old stories.", category = "element", class = "Witch", price = 149, devProductId = 0,
		colors = { FIRE = Color3.fromRGB(90, 255, 120), VOID = Color3.fromRGB(40, 140, 80) } },
	{ id = "frank_greenarc", name = "Green Galvanism", description = "The vital spark in acid green.", category = "element", class = "Frankenstein", price = 149, devProductId = 0,
		colors = { ELECTRIC = Color3.fromRGB(120, 255, 100) } },
	{ id = "frank_violetarc", name = "Violet Arc", description = "Purple lightning.", category = "element", class = "Frankenstein", price = 149, devProductId = 0,
		colors = { ELECTRIC = Color3.fromRGB(190, 120, 255) } },
	{ id = "vamp_blackblood", name = "Black Blood", description = "What runs in the old ones.", category = "element", class = "Vampire", price = 149, devProductId = 0,
		colors = { BLOOD = Color3.fromRGB(110, 30, 160) } },
	{ id = "wolf_ember", name = "Ember Fury", description = "Claws that leave sparks.", category = "element", class = "Werewolf", price = 149, devProductId = 0,
		colors = { BEAST = Color3.fromRGB(255, 150, 40) } },
	{ id = "imm_goldsteel", name = "Gilded Edge", description = "A blade that catches every light.", category = "element", class = "Immortal", price = 149, devProductId = 0,
		colors = { STEEL = Color3.fromRGB(255, 215, 110) } },

	-- ── Auras (any class) ────────────────────────────────────────────────
	{ id = "aura_sol", name = "Sol Halo", description = "Warm gold light about you.", category = "aura", price = 99, devProductId = 0, color = Color3.fromRGB(255, 205, 110) },
	{ id = "aura_cold", name = "Cold Halo", description = "Blue-white, like a streetlight at 3 a.m.", category = "aura", price = 99, devProductId = 0, color = Color3.fromRGB(180, 220, 255) },
	{ id = "aura_dark", name = "Dark Halo", description = "Violet, and not quite there.", category = "aura", price = 99, devProductId = 0, color = Color3.fromRGB(150, 80, 220) },

	-- ── Trails (any class) ───────────────────────────────────────────────
	{ id = "trail_ember", name = "Ember Trail", description = "Sparks in your wake.", category = "trail", price = 79, devProductId = 0, color = Color3.fromRGB(255, 140, 40), color2 = Color3.fromRGB(120, 30, 10) },
	{ id = "trail_neon", name = "Collins Neon", description = "Pink-to-blue, like the strip.", category = "trail", price = 79, devProductId = 0, color = Color3.fromRGB(255, 80, 200), color2 = Color3.fromRGB(40, 140, 255) },
	{ id = "trail_ghost", name = "Ghost Trail", description = "A pale afterimage.", category = "trail", price = 79, devProductId = 0, color = Color3.fromRGB(220, 225, 245), color2 = Color3.fromRGB(120, 130, 170) },

	-- ── Eyes (any class) ─────────────────────────────────────────────────
	{ id = "eyes_red", name = "Red Eyes", description = "Something looks back.", category = "eyes", price = 49, devProductId = 0, color = Color3.fromRGB(255, 40, 40) },
	{ id = "eyes_cyan", name = "Cyan Eyes", description = "Cold and awake.", category = "eyes", price = 49, devProductId = 0, color = Color3.fromRGB(60, 240, 240) },
	{ id = "eyes_gold", name = "Gold Eyes", description = "Sun-touched.", category = "eyes", price = 49, devProductId = 0, color = Color3.fromRGB(255, 215, 80) },
}

local byId: { [string]: Skin } = {}
for _, s in list do
	byId[s.id] = s
end

Skins.CATEGORIES = { "element", "aura", "trail", "eyes" }
Skins.CATEGORY_LABEL = { element = "Elements", aura = "Auras", trail = "Trails", eyes = "Eyes" }

function Skins.all(): { Skin }
	return list
end

function Skins.get(id: string): Skin?
	return byId[id]
end

function Skins.byProduct(productId: number): Skin?
	if productId <= 0 then
		return nil
	end
	for _, s in list do
		if s.devProductId == productId then
			return s
		end
	end
	return nil
end

-- Element skins are class-bound; everything else fits anyone.
function Skins.fitsClass(skin: Skin, classId: string?): boolean
	return skin.class == nil or skin.class == classId
end

return Skins
