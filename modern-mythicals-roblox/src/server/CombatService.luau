--!strict
-- Damage resolution, downing, and revives — authoritative.
--
-- The design doc calls for a "CSG-derived rules engine" for resolution math. The
-- exact tabletop numbers live in the CSG rules docs (CSG-core-systems, CSG-combat)
-- and must be TRANSLATED for real-time play, not copied — game design wins where it
-- conflicts with TTRPG fidelity. This module implements the real-time skeleton with
-- clearly-marked hooks where those translated numbers plug in.

local Shared = game:GetService("ReplicatedStorage").Shared
local GameConfig = require(Shared.GameConfig)
local Types = require(Shared.Types)

local CombatService = {}

-- Per-character combat state (health, downed flag, warded damage type, etc.).
type CombatState = {
	health: number,
	maxHealth: number,
	downed: boolean,
	bleedoutAt: number?, -- os.clock() deadline while downed
	wardedType: Types.DamageType?, -- from Soul-Hardened rank 4
	weaknesses: { [Types.DamageType]: number }, -- multipliers > 1 (e.g. shifted Werewolf)
	resistances: { [Types.DamageType]: number }, -- multipliers < 1
	flatReduction: number, -- Soul-Hardened rank 1
}

local states: { [Instance]: CombatState } = {}

function CombatService.register(character: Instance, maxHealth: number): CombatState
	local state: CombatState = {
		health = maxHealth,
		maxHealth = maxHealth,
		downed = false,
		bleedoutAt = nil,
		wardedType = nil,
		weaknesses = {},
		resistances = {},
		flatReduction = 0,
	}
	states[character] = state
	return state
end

function CombatService.state(character: Instance): CombatState?
	return states[character]
end

-- Translate a raw hit into applied damage after reductions, resistances, and
-- weaknesses. This is the seam where CSG-translated math lands.
local function computeDamage(state: CombatState, raw: number, dmgType: Types.DamageType): number
	local dmg = raw

	-- Flat reduction (Soul-Hardened rank 1) applies first, floored at a chip amount.
	dmg = math.max(dmg - state.flatReduction, raw * 0.1)

	-- Warded Flesh (rank 4): chosen type takes less permanently.
	if state.wardedType == dmgType then
		dmg *= 0.6 -- PLACEHOLDER
	end

	-- Class resistances / weaknesses (e.g. shifted Werewolf +fire/+electric).
	local weak = state.weaknesses[dmgType]
	if weak then
		dmg *= weak
	end
	local resist = state.resistances[dmgType]
	if resist then
		dmg *= resist
	end

	return math.max(dmg, 0)
end

-- Apply damage from source to target. Returns applied amount + whether it downed.
function CombatService.applyDamage(
	targetChar: Instance,
	raw: number,
	dmgType: Types.DamageType,
	_sourceChar: Instance?
): (number, boolean)
	local state = states[targetChar]
	if not state or state.downed then
		return 0, false
	end

	local applied = computeDamage(state, raw, dmgType)
	state.health = math.max(state.health - applied, 0)

	local justDowned = false
	if state.health <= 0 then
		-- TODO: honor Soul-Hardened rank 5 "Refuse to Fall" and Immortal "Refusal"
		-- once-per-night self-res before actually downing.
		state.downed = true
		state.bleedoutAt = os.clock() + GameConfig.Combat.DownedBleedoutSeconds
		justDowned = true
	end

	CombatService.onCombatEvent(targetChar, applied, dmgType, state.health, justDowned)
	return applied, justDowned
end

function CombatService.heal(targetChar: Instance, amount: number)
	local state = states[targetChar]
	if not state or amount <= 0 then
		return
	end
	if state.downed then
		return -- revives go through revive(), not heal()
	end
	state.health = math.min(state.health + amount, state.maxHealth)
end

-- Revive a downed character (Frankenstein Vital Spark / Immortal Refusal / shop res).
function CombatService.revive(targetChar: Instance, healthFraction: number)
	local state = states[targetChar]
	if not state or not state.downed then
		return
	end
	state.downed = false
	state.bleedoutAt = nil
	state.health = math.max(1, math.floor(state.maxHealth * math.clamp(healthFraction, 0, 1)))
end

function CombatService.unregister(character: Instance)
	states[character] = nil
end

-- Wired by init.server.luau to broadcast combat events to clients (HUD/VFX).
CombatService.onCombatEvent = function(
	_char: Instance,
	_applied: number,
	_dmgType: Types.DamageType,
	_healthLeft: number,
	_downed: boolean
) end

-- Called on a fixed step to expire bleedouts (full death after the window).
function CombatService.step()
	local now = os.clock()
	for char, state in states do
		if state.downed and state.bleedoutAt and now >= state.bleedoutAt then
			state.health = 0
			state.bleedoutAt = nil
			-- TODO: trigger respawn flow / drop rewards to killer.
		end
	end
end

return CombatService
