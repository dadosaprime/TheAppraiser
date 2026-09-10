--!strict
-- All perk trees, transcribed from the Class & Perk Tree design doc.
--
-- ONE TREE, ONE BUTTON: every class has exactly 5 trees; each tree grants ONE
-- ability on ONE hotbar slot and has 5 ranks. Rank 1 unlocks the ability;
-- ranks 2-5 upgrade that same ability — they never add a new button. The only
-- path to a 6th ability is buying a CROSSOVER tree (Robux access + Shard ranks)
-- from the Church of Sol.
--
-- ⛔ FIREWALL: every name and effect below is invented for Roblox. None of it is
-- Common Sense Games canon. Do not import any of it into the CSG rules docs.
--
-- Shard costs per rank are PLACEHOLDERS pending playtest. Ranks 1-2 come fast;
-- 3-5 are the long tail.

local Types = require(script.Parent.Types)

local RANK_SHARD_COST = { 1000, 1500, 3000, 5000, 8000 }

-- Build a rank row with its cost pulled from the shared curve.
local function r(rank: number, name: string, effect: string): Types.PerkRank
	return { rank = rank, name = name, effect = effect, shardCost = RANK_SHARD_COST[rank] }
end

local PerkTrees: { [string]: Types.PerkTree } = {}

-- ═══════════════════════════ WITCH ═══════════════════════════
PerkTrees.Emberhand = {
	id = "Emberhand",
	ability = "Flame Dart",
	slot = 1,
	role = "basic attack",
	summary = "Fast, low-cost ranged bolt. The Witch's bread and butter.",
	ranks = {
		r(1, "Flame Dart", "Single flame dart. Low damage, low cost."),
		r(2, "Quick Ember", "Faster cast, slightly more damage."),
		r(3, "Searing", "Applies a short burn — small damage over time."),
		r(4, "Twin Darts", "Two darts per cast."),
		r(5, "Wildfire", "Burn spreads to one nearby enemy on kill."),
	},
}
PerkTrees.Conflagration = {
	id = "Conflagration",
	ability = "Fireball → Wave of Fire",
	slot = 2,
	role = "heavy offense",
	summary = "The big one. Long cooldown, high impact. Rank 3 changes its shape.",
	ranks = {
		r(1, "Fireball", "Single target, heavy damage, slow travel."),
		r(2, "Burst", "Small explosion radius on impact."),
		r(3, "Wave of Fire", "Becomes a cone in front of you instead of a projectile."),
		r(4, "Scorched Earth", "Leaves burning ground for a few seconds."),
		r(5, "Firestorm", "Wider cone, shorter cooldown."),
	},
}
PerkTrees.WitchfireAegis = {
	id = "WitchfireAegis",
	ability = "Flame Shield",
	slot = 3,
	role = "defense + melee",
	summary = "Active stance. Adds parry and burns melee attackers. The Witch's answer to being closed on.",
	ranks = {
		r(1, "Flame Shield", "Grants parry. Melee attackers take fire damage."),
		r(2, "Kindled Ward", "Longer duration, more retaliation damage."),
		r(3, "Flame Sword", "While the shield is up, your melee attacks are fire."),
		r(4, "Staggering Guard", "A successful parry staggers the attacker."),
		r(5, "Mirror Flame", "Reflects a portion of ranged damage back at the shooter."),
	},
}
PerkTrees.SigilCraft = {
	id = "SigilCraft",
	ability = "Break Seal",
	slot = 4,
	role = "utility / unlock",
	summary = "Opens wards and sigils. The Witch half of the shared unlock mechanic (wards need a Witch).",
	ranks = {
		r(1, "Break Seal", "Open warded and sigil-locked doors and containers."),
		r(2, "Ward Sight", "Faster. Reveals nearby wards through walls."),
		r(3, "Trap Sigil", "Place a sigil on the ground — burns the first enemy to cross it."),
		r(4, "Double Sigil", "Two sigils placed at once."),
		r(5, "Binding Rune", "Trap sigils briefly root instead of only burning."),
	},
}
PerkTrees.Widdershins = {
	id = "Widdershins",
	ability = "Levitate",
	slot = 5,
	role = "movement",
	summary = "Rise and drift. Slow, deliberate, vulnerable — buys position, not escape.",
	ranks = {
		r(1, "Hover", "Rise briefly. Enough to cross a gap or reach a low roof."),
		r(2, "Drift", "Longer duration, better drift control."),
		r(3, "Featherfall", "Fall-damage immunity while any levitate charge remains."),
		r(4, "Airborne Casting", "Can cast Flame Dart while levitating."),
		r(5, "Witch's Flight", "Short controlled flight. Still slow, still an easy target."),
	},
}

-- ═══════════════════════════ WEREWOLF ═══════════════════════════
PerkTrees.TheTurning = {
	id = "TheTurning",
	ability = "Shape Shift",
	slot = 2,
	role = "the shift",
	summary = "The class identity, on one button. Shifted = bigger, stronger, and easier to hit (fire/electric weakness).",
	ranks = {
		r(1, "Shift", "Bonus health, faster regen, claws, speed, larger hitbox, fire/electric weakness."),
		r(2, "Deeper Beast", "More bonus health. Faster health regen while shifted."),
		r(3, "Blood Rush", "Shifting heals you for a chunk on activation."),
		r(4, "Sustained Form", "The form locks less of your Soul (30% instead of 40%)."),
		r(5, "Thick Hide", "Weakness reduced — fire/electric hurt less, but still more than human form."),
	},
}
PerkTrees.RedRend = {
	id = "RedRend",
	ability = "Claw Combo → Rend → Bite",
	slot = 1,
	role = "offense",
	summary = "Two simultaneous claw attacks while shifted, building into bleed and a healing finisher.",
	ranks = {
		r(1, "Claws", "Claw strike. Two simultaneous attacks while shifted."),
		r(2, "Savage", "More damage. Shorter swing recovery."),
		r(3, "Rend", "Third hit in a chain applies a bleed."),
		r(4, "Deep Wounds", "Bleed stacks."),
		r(5, "Bite", "Auto-finisher against low-health targets. Heavy damage, heals you."),
	},
}
PerkTrees.HuntersHowl = {
	id = "HuntersHowl",
	ability = "Howl",
	slot = 3,
	role = "control / team",
	summary = "Area debuff — the pack showing up as a button. The Werewolf's only genuinely supportive ability.",
	ranks = {
		r(1, "Howl", "Nearby enemies deal reduced damage briefly."),
		r(2, "Terror", "Larger radius, longer duration."),
		r(3, "Hamstring", "Also slows affected enemies."),
		r(4, "Pack Fervor", "Allies in radius gain a small damage bonus."),
		r(5, "Blood Call", "Restores Soul on cast, scaling with enemies hit."),
	},
}
PerkTrees.BloodScent = {
	id = "BloodScent",
	ability = "Scent",
	slot = 4,
	role = "utility / tracking",
	summary = "Reveals enemies through walls; rewards staying in when you shouldn't. Rank 5 is a counter to Immortal stealth.",
	ranks = {
		r(1, "Scent", "Outline nearby enemies through geometry for a few seconds."),
		r(2, "Keen Nose", "Longer range, longer duration."),
		r(3, "Blood in the Water", "Wounded enemies are highlighted distinctly."),
		r(4, "Cornered Beast", "Your damage and regen increase while your own health is low. Passive."),
		r(5, "Hunt the Hidden", "Reveals stealthed enemies within a short radius — the Immortal counter."),
	},
}
PerkTrees.CragClimb = {
	id = "CragClimb",
	ability = "Climb → Pounce",
	slot = 5,
	role = "movement",
	summary = "Claws sink into wood, brick, and concrete. Pounce is the gap-closer melee needs on approach.",
	ranks = {
		r(1, "Climb", "Climb most vertical surfaces. Slow."),
		r(2, "Sure Grip", "Faster climb. Longer before you tire."),
		r(3, "Pounce", "Leap from a climb or standstill, knocking down where you land."),
		r(4, "Long Leap", "Pounce range increased. Fall-damage immunity."),
		r(5, "Apex", "Climb at near-run speed. Pounce refreshes on kill."),
	},
}

-- ═══════════════════════════ VAMPIRE ═══════════════════════════
PerkTrees.RedThirst = {
	id = "RedThirst",
	ability = "Blood Drain",
	slot = 1,
	role = "basic attack + sustain",
	summary = "Bite, leech, heal — all one thing. Gets stronger the longer a fight runs.",
	ranks = {
		r(1, "Blood Drain", "Melee bite. Damage, and heal for a portion of it."),
		r(2, "Deep Draught", "More damage, more healing."),
		r(3, "Prey Sense", "Healing increased against wounded targets."),
		r(4, "Gorged", "Overheal becomes temporary bonus health."),
		r(5, "Insatiable", "Killing with Blood Drain refunds its cooldown."),
	},
}
PerkTrees.DreadCharm = {
	id = "DreadCharm",
	ability = "Charm",
	slot = 2,
	role = "control",
	summary = "One ability, one effect table, one NPC/player multiplier. NPCs take full value; players take a fraction.",
	ranks = {
		r(1, "Charm", "NPCs: stand still, do nothing. Players: interrupts whatever they were casting."),
		r(2, "Hold Gaze", "NPCs: longer hold, wider cone. Players: interrupt + brief blurred vision."),
		r(3, "Waver", "NPCs: wander away from the fight. Players: slowed and vision-impaired."),
		r(4, "Thrall", "NPCs: fight for you briefly. Players: short stun."),
		r(5, "Command", "NPCs: two at once, fighting longer. Players: longer stun, shorter cooldown."),
	},
}
PerkTrees.Nightspeed = {
	id = "Nightspeed",
	ability = "Blur",
	slot = 3,
	role = "mobility offense",
	summary = "Burst of supernatural speed.",
	ranks = {
		r(1, "Blur", "Short burst of extreme speed."),
		r(2, "Streak", "Longer, shorter cooldown."),
		r(3, "Phase Dash", "Brief damage immunity during the dash."),
		r(4, "Ambush Speed", "Your next attack after a dash does bonus damage."),
		r(5, "Doubleblur", "Two charges."),
	},
}
PerkTrees.Mist = {
	id = "Mist",
	ability = "Mist Form",
	slot = 4,
	role = "escape",
	summary = "Become vapor — the Vampire's panic button. Nothing in the Werewolf or Immortal kit does this.",
	ranks = {
		r(1, "Mist Form", "Briefly untargetable. Cannot attack. Move slowly."),
		r(2, "Roiling Fog", "Longer duration, faster drift."),
		r(3, "Restorative Vapor", "Regain health while misted."),
		r(4, "Seep", "Pass through grates, gaps, and barred windows."),
		r(5, "Blinding Exit", "Leaving mist form drops a blinding cloud where you exit."),
	},
}
PerkTrees.TheCrawl = {
	id = "TheCrawl",
	ability = "Wall-Crawl",
	slot = 5,
	role = "movement",
	summary = "Up walls and across ceilings, head-first.",
	ranks = {
		r(1, "Wall-Crawl", "Crawl vertical surfaces."),
		r(2, "Ceiling Walk", "Faster. Ceilings unlocked."),
		r(3, "Perch Strike", "Attack from a wall without dropping off."),
		r(4, "Drop Fang", "Drop attack from above deals bonus damage."),
		r(5, "Silent Crawl", "Silent — no footstep audio for other players."),
	},
}

-- ═══════════════════════════ FRANKENSTEIN ═══════════════════════════
PerkTrees.TheSpark = {
	id = "TheSpark",
	ability = "Electric Bolt",
	slot = 1,
	role = "basic attack",
	summary = "Ranged electric bolt that learns to chain.",
	ranks = {
		r(1, "Electric Bolt", "Ranged electric bolt."),
		r(2, "Charged", "More damage, faster cast."),
		r(3, "Arc", "Chains to one nearby enemy."),
		r(4, "Fork", "Chains to two. Brief slow on hit."),
		r(5, "Feedback", "Chains bounce back to you, healing a small amount."),
	},
}
PerkTrees.Overload = {
	id = "Overload",
	ability = "Discharge",
	slot = 2,
	role = "heavy offense / control",
	summary = "Point-blank radial burst. Scales with standing on a live source.",
	ranks = {
		r(1, "Discharge", "Radial electric burst around you."),
		r(2, "Surge", "Larger radius, more damage."),
		r(3, "Concussion", "Briefly stuns everything hit."),
		r(4, "Grounded Power", "Damage scales up if cast while standing on a live source."),
		r(5, "Live Field", "Leaves a lingering electrified field."),
	},
}
PerkTrees.VitalSpark = {
	id = "VitalSpark",
	ability = "Revive",
	slot = 3,
	role = "revive / support",
	summary = "The team answer to going down. Fast and repeatable — this is why teams bring a Frankenstein.",
	ranks = {
		r(1, "Revive", "Revive a downed ally. Slow channel."),
		r(2, "Quick Jolt", "Faster channel."),
		r(3, "Full Charge", "Revived ally comes up with more health."),
		r(4, "Remote Spark", "Can revive from a short distance — no need to stand in the fire."),
		r(5, "Vital Field", "Also heals living allies for a small amount when used."),
	},
}
PerkTrees.BreakersTouch = {
	id = "BreakersTouch",
	ability = "Bypass",
	slot = 4,
	role = "utility / unlock",
	summary = "Electronic locks and machinery. The Frankenstein half of the shared unlock mechanic (electronics need a Frankenstein).",
	ranks = {
		r(1, "Bypass", "Open electronic locks, panels, and gates."),
		r(2, "Live Wire", "Faster. Highlights nearby powered locks."),
		r(3, "Kill Switch", "Disable a device temporarily — camera, alarm, turret."),
		r(4, "Rig", "Rig a powered object to burst when an enemy comes near."),
		r(5, "Double Rig", "Two rigs at once."),
	},
}
PerkTrees.ArcStep = {
	id = "ArcStep",
	ability = "Lightning Ride",
	slot = 5,
	role = "movement",
	summary = "Enter one electrical source, exit at another. Map-dependent: teleports in a wired city, walks in the swamp.",
	ranks = {
		r(1, "Lightning Ride", "Travel between two nearby fixed sources."),
		r(2, "Long Arc", "Longer range. Shorter cooldown."),
		r(3, "Grounded Arrival", "Arrive healed."),
		r(4, "Wildcurrent", "Spontaneous sources count as valid exits — you can ride into open ground."),
		r(5, "Thunderclap", "Arrival discharges, damaging enemies near the exit point."),
	},
}

-- ═══════════════════════════ IMMORTAL ═══════════════════════════
PerkTrees.Swordwork = {
	id = "Swordwork",
	ability = "Blade Combo",
	slot = 1,
	role = "basic attack",
	summary = "Sword chain. Landing a full chain pays back in cooldown reduction.",
	ranks = {
		r(1, "Blade Combo", "Three-hit sword chain."),
		r(2, "Practiced Edge", "Faster, more damage."),
		r(3, "Stagger Cut", "The third hit staggers."),
		r(4, "Fourth Form", "Chain extends to four hits."),
		r(5, "Flowing Steel", "Landing a full chain shortens all your cooldowns."),
	},
}
PerkTrees.Riposte = {
	id = "Riposte",
	ability = "Parry",
	slot = 2,
	role = "defense / signature",
	summary = "Timing-based. The single most skill-expressive thing in the game — polish the parry window above all.",
	ranks = {
		r(1, "Parry", "Parry window. Negates a melee hit."),
		r(2, "Read the Blade", "Wider window."),
		r(3, "Counter", "A successful parry counters for damage automatically."),
		r(4, "Deflect", "Can parry projectiles, deflecting them."),
		r(5, "Perfect Parry", "A perfect parry briefly slows the attacker."),
	},
}
PerkTrees.Stillness = {
	id = "Stillness",
	ability = "Vanish",
	slot = 3,
	role = "stealth + movement",
	summary = "The Immortal's only traversal tool and whole identity. PASSIVE at all ranks: sense other Immortals nearby, always.",
	ranks = {
		r(1, "Vanish", "Go unseen while moving slowly. Broken by attacking or taking damage. (Passive: sense other Immortals.)"),
		r(2, "Quiet Step", "Move faster while hidden. (Passive: sense other Immortals.)"),
		r(3, "Silent", "No footstep audio. Longer duration. (Passive: sense other Immortals.)"),
		r(4, "Slip Away", "Re-enter stealth quickly after breaking it. (Passive: sense other Immortals.)"),
		r(5, "Ghostwalk", "Move at near-full speed while hidden. (Passive: sense other Immortals.)"),
	},
}
PerkTrees.FirstCut = {
	id = "FirstCut",
	ability = "First Cut",
	slot = 4,
	role = "burst",
	summary = "The opening strike from stealth — every opener hits far harder than anything else in the game.",
	ranks = {
		r(1, "First Cut", "Attacks from stealth deal heavy bonus damage."),
		r(2, "Deeper Cut", "More bonus damage."),
		r(3, "Silencing Strike", "Opener also briefly silences — target can't use abilities."),
		r(4, "Shadow Kill", "Killing from stealth immediately re-enters stealth."),
		r(5, "Assassinate", "Opener from behind is a critical."),
	},
}
PerkTrees.Undying = {
	id = "Undying",
	ability = "Refusal",
	slot = 5,
	role = "sustain / self-res",
	summary = "Once per night. The thing that makes them Immortal — distinct from Frankenstein revive: once, for you, dramatic.",
	ranks = {
		r(1, "Refusal", "Self-revive once per run, at low health. Long cooldown."),
		r(2, "Second Wind", "Revive with more health."),
		r(3, "Old Blood", "Slow out-of-combat regeneration. Passive."),
		r(4, "Deathless Moment", "Brief invulnerability window on self-revive."),
		r(5, "Return in Full", "Self-revive also restores your cooldowns."),
	},
}

-- ═══════════════════════════ SHARED — SOUL-HARDENED ═══════════════════════════
-- Available to all five classes. NOT one of the five class trees — it sits
-- alongside them, bought from the general trainer with Shards. Slot 0 = passive.
-- The principle "no armor; protection comes from the Soul" is canon; the tree is not.
PerkTrees.SoulHardened = {
	id = "SoulHardened",
	ability = "Soul-Hardened (passive defense)",
	slot = 0,
	role = "shared defense",
	summary = "The floor everyone stands on. Entirely passive except rank 5. Rank 4 is how any player buys down their worst matchup.",
	ranks = {
		r(1, "Thick Soul", "Flat damage reduction. Small, always on."),
		r(2, "Set Jaw", "Reduces stun and knockback duration."),
		r(3, "Turned Aside", "Chance to take reduced damage from any hit. Passive."),
		r(4, "Warded Flesh", "Choose one damage type on purchase (fire/electric/physical/supernatural). Take less from it permanently."),
		r(5, "Refuse to Fall", "Once per night, dropping to zero leaves you at 1 health with a brief reduced-damage window instead of downing you. Long cooldown."),
	},
}

-- ── Accessors ──────────────────────────────────────────────────────────────
function PerkTrees.get(treeId: string): Types.PerkTree?
	return PerkTrees[treeId]
end

function PerkTrees.getRank(treeId: string, rank: number): Types.PerkRank?
	local tree = PerkTrees[treeId]
	if not tree then
		return nil
	end
	return tree.ranks[rank]
end

PerkTrees.MAX_RANK = 5
PerkTrees.SHARED_DEFENSE = "SoulHardened"

return PerkTrees
