--!strict
-- Concrete ability effects, keyed by perk-tree id. AbilityService dispatches
-- here after validating class, rank, and cooldown. Each effect receives a
-- context and may return a cooldown override (seconds).
--
-- Numbers are PLACEHOLDERS for playtest. Every effect is built from parts,
-- lights, and tweens — no assets required — so all five classes are testable
-- on the default avatar today. Trees without an entry fall back to a log line.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local Shared = game:GetService("ReplicatedStorage").Shared
local GameConfig = require(Shared.GameConfig)

local Effects = require(script.Parent.Effects)
local CombatService = require(script.Parent.CombatService)

export type Ctx = {
	player: Player,
	character: Model,
	humanoid: Humanoid,
	root: BasePart,
	rank: number,
	aim: Vector3, -- unit vector, usually the camera's look direction
}
type Effect = (ctx: Ctx) -> number?

local AbilityEffects: { [string]: Effect } = {}

local FIRE = Color3.fromRGB(255, 120, 40)
local ELECTRIC = Color3.fromRGB(120, 200, 255)
local BLOOD = Color3.fromRGB(200, 20, 40)
local STEEL = Color3.fromRGB(220, 225, 240)
local BEAST = Color3.fromRGB(255, 60, 60)
local VOID = Color3.fromRGB(90, 60, 140)

-- ── Targeting helpers ───────────────────────────────────────────────────────

-- Anything with a Humanoid we care about: player characters + training dummies.
local function candidates(): { Model }
	local list = {}
	for _, p in Players:GetPlayers() do
		if p.Character then
			table.insert(list, p.Character)
		end
	end
	local dummies = Workspace:FindFirstChild("Dummies")
	if dummies then
		for _, m in dummies:GetChildren() do
			if m:IsA("Model") then
				table.insert(list, m)
			end
		end
	end
	return list
end

local function modelPos(m: Model): Vector3?
	local part = m.PrimaryPart or m:FindFirstChild("HumanoidRootPart") or m:FindFirstChildWhichIsA("BasePart")
	return if part then (part :: BasePart).Position else nil
end

local function flatForward(ctx: Ctx): Vector3
	local f = Vector3.new(ctx.aim.X, 0, ctx.aim.Z)
	return if f.Magnitude > 0.01 then f.Unit else ctx.root.CFrame.LookVector
end

local function targetsInCone(ctx: Ctx, range: number, cosHalfAngle: number): { Model }
	local out = {}
	local origin = ctx.root.Position
	local f = flatForward(ctx)
	for _, m in candidates() do
		if m ~= ctx.character then
			local p = modelPos(m)
			if p then
				local d = p - origin
				local flat = Vector3.new(d.X, 0, d.Z)
				if d.Magnitude <= range and flat.Magnitude > 0.01 and f:Dot(flat.Unit) >= cosHalfAngle then
					table.insert(out, m)
				end
			end
		end
	end
	return out
end

local function targetsInRadius(center: Vector3, radius: number, exclude: Model?): { Model }
	local out = {}
	for _, m in candidates() do
		if m ~= exclude then
			local p = modelPos(m)
			if p and (p - center).Magnitude <= radius then
				table.insert(out, m)
			end
		end
	end
	return out
end

-- ── Parry state (Immortal Riposte) ──────────────────────────────────────────
-- "The most important number in the game": GameConfig.Combat.ParryWindowMs.
local parryUntil: { [Model]: number } = {}
local parryRank: { [Model]: number } = {}

-- ── Damage application ──────────────────────────────────────────────────────
local function hit(target: Model, amount: number, dmgType: string, attacker: Model, color: Color3): number
	if target == attacker then
		return 0
	end
	local hum = target:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then
		return 0
	end

	-- Parry: a physical hit inside the window is negated (and countered at rank 3+).
	local pu = parryUntil[target]
	if pu and os.clock() < pu and dmgType == "Physical" then
		parryUntil[target] = nil
		local tp = modelPos(target)
		if tp then
			Effects.burst(tp, STEEL, 4, 0.25)
		end
		if (parryRank[target] or 0) >= 3 then
			local ahum = attacker:FindFirstChildOfClass("Humanoid")
			if ahum then
				ahum:TakeDamage(amount * 0.75)
				local ap = modelPos(attacker)
				if ap then
					Effects.damageNumber(ap, amount * 0.75, STEEL)
				end
			end
		end
		return 0
	end

	local applied = amount
	if CombatService.state(target) then
		applied = CombatService.applyDamage(target, amount, dmgType :: any, attacker)
	end
	hum:TakeDamage(applied)
	local p = modelPos(target)
	if p then
		Effects.damageNumber(p, applied, color)
	end
	return applied
end

local function heal(ctx: Ctx, amount: number)
	if amount <= 0 then
		return
	end
	ctx.humanoid.Health = math.min(ctx.humanoid.Health + amount, ctx.humanoid.MaxHealth)
	Effects.damageNumber(ctx.root.Position, amount, Color3.fromRGB(80, 230, 120))
end

local function bolt(ctx: Ctx, color: Color3, speed: number, range: number, damage: number, dmgType: string, radius: number, onHit: ((pos: Vector3, model: Model?) -> ())?)
	local origin = ctx.root.Position + ctx.aim * 2 + Vector3.new(0, 1, 0)
	Effects.flash(ctx.root, color, 1.5, 10, 0.25)
	Effects.projectile(origin, ctx.aim, {
		color = color,
		speed = speed,
		range = range,
		radius = radius,
		ignore = { ctx.character },
		onHit = function(_part, pos, model)
			Effects.burst(pos, color, 3, 0.25)
			if model then
				hit(model, damage, dmgType, ctx.character, color)
			end
			if onHit then
				onHit(pos, model)
			end
		end,
	})
end

-- ── Timed-state helpers (shift, vanish, mist) ───────────────────────────────
type Timed = { token: number, revert: () -> () }
local timed: { [Model]: { [string]: Timed } } = {}

local function setTimed(ctx: Ctx, key: string, duration: number, revert: () -> ())
	timed[ctx.character] = timed[ctx.character] or {}
	local token = os.clock()
	timed[ctx.character][key] = { token = token, revert = revert }
	task.delay(duration, function()
		local t = timed[ctx.character] and timed[ctx.character][key]
		if t and t.token == token then
			timed[ctx.character][key] = nil
			if ctx.character.Parent then
				revert()
			end
		end
	end)
end

local function clearTimed(character: Model, key: string)
	local t = timed[character] and timed[character][key]
	if t then
		timed[character][key] = nil
		if character.Parent then
			t.revert()
		end
	end
end

local function isTimed(character: Model, key: string): boolean
	return (timed[character] and timed[character][key]) ~= nil
end

local function setPartTransparency(character: Model, value: number): () -> ()
	local originals: { [BasePart]: number } = {}
	for _, d in character:GetDescendants() do
		if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" then
			originals[d] = d.Transparency
			d.Transparency = value
		end
	end
	return function()
		for part, t in originals do
			if part.Parent then
				part.Transparency = t
			end
		end
	end
end

-- ═══════════════════════════ WITCH ═══════════════════════════
AbilityEffects.Emberhand = function(ctx)
	local dmg = 22 + 6 * ctx.rank
	bolt(ctx, FIRE, 90, 120, dmg, "Fire", 0.7)
	if ctx.rank >= 4 then
		task.delay(0.12, function()
			if ctx.character.Parent then
				bolt(ctx, FIRE, 90, 120, dmg, "Fire", 0.7)
			end
		end)
	end
	return 0.6
end

AbilityEffects.Conflagration = function(ctx)
	local dmg = 60 + 10 * ctx.rank
	bolt(ctx, FIRE, 55, 110, dmg, "Fire", 1.6, function(pos, model)
		if ctx.rank >= 2 then
			Effects.burst(pos, FIRE, 10, 0.5)
			for _, m in targetsInRadius(pos, 10, ctx.character) do
				if m ~= model then
					hit(m, dmg * 0.5, "Fire", ctx.character, FIRE)
				end
			end
		end
	end)
	return 8 - 0.5 * ctx.rank
end

AbilityEffects.Widdershins = function(ctx)
	Effects.flash(ctx.root, VOID, 2, 12, 0.4)
	ctx.root.AssemblyLinearVelocity = Vector3.new(0, 45 + 5 * ctx.rank, 0) + flatForward(ctx) * 10
	return 4
end

-- ═══════════════════════════ WEREWOLF ═══════════════════════════
local SCALE_NAMES = { "BodyHeightScale", "BodyWidthScale", "BodyDepthScale", "HeadScale" }

AbilityEffects.TheTurning = function(ctx)
	if isTimed(ctx.character, "shift") then
		clearTimed(ctx.character, "shift") -- toggle back to human
		return 1
	end
	local hum = ctx.humanoid
	local rank = ctx.rank

	-- Bigger: the drawback is physical. Larger hitbox, easier to hit.
	local scaleOriginals: { [NumberValue]: number } = {}
	for _, name in SCALE_NAMES do
		local v = hum:FindFirstChild(name)
		if v and v:IsA("NumberValue") then
			scaleOriginals[v] = v.Value
			v.Value = v.Value * (if name == "HeadScale" then 1.15 else 1.3)
		end
	end
	-- Darker: the beast.
	local colorOriginals: { [BasePart]: Color3 } = {}
	for _, d in ctx.character:GetDescendants() do
		if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" then
			colorOriginals[d] = d.Color
			d.Color = Color3.fromRGB(58, 44, 40)
		end
	end
	-- Faster, tougher.
	local speed0, maxHp0 = hum.WalkSpeed, hum.MaxHealth
	local bonusHp = 60 + 15 * rank
	hum.WalkSpeed = 24
	hum.MaxHealth = maxHp0 + bonusHp
	hum.Health += bonusHp
	if rank >= 3 then
		heal(ctx, maxHp0 * 0.3)
	end
	-- Weak to fire and electric — the Witch and the Frankenstein counter you.
	local st = CombatService.state(ctx.character)
	if st then
		local w = if rank >= 5 then 1.3 else 1.6
		st.weaknesses.Fire = w
		st.weaknesses.Electric = w
	end
	Effects.flash(ctx.root, BEAST, 4, 18, 0.8)
	Effects.burst(ctx.root.Position, BEAST, 6, 0.4)

	setTimed(ctx, "shift", 12 + 4 * rank, function()
		for v, val in scaleOriginals do
			if v.Parent then
				v.Value = val
			end
		end
		for part, c in colorOriginals do
			if part.Parent then
				part.Color = c
			end
		end
		if hum.Parent then
			hum.WalkSpeed = speed0
			hum.MaxHealth = maxHp0
			hum.Health = math.min(hum.Health, maxHp0)
		end
		local s = CombatService.state(ctx.character)
		if s then
			s.weaknesses.Fire = nil
			s.weaknesses.Electric = nil
		end
	end)
	return 1
end

AbilityEffects.RedRend = function(ctx)
	local shifted = isTimed(ctx.character, "shift")
	local dmg = (14 + 4 * ctx.rank) * (if shifted then 1 else 0.5)
	local hits = if shifted then 2 else 1 -- two simultaneous claws while shifted
	Effects.flash(ctx.root, BEAST, 1.5, 10, 0.2)
	for _, m in targetsInCone(ctx, 8, 0.4) do
		for _ = 1, hits do
			hit(m, dmg, "Physical", ctx.character, BEAST)
		end
		if ctx.rank >= 3 then
			task.spawn(function() -- Rend: short bleed
				for _ = 1, 3 do
					task.wait(0.7)
					if m.Parent then
						hit(m, 5, "Physical", ctx.character, BLOOD)
					end
				end
			end)
		end
	end
	return 0.6
end

AbilityEffects.HuntersHowl = function(ctx)
	local radius = 20 + 3 * ctx.rank
	Effects.burst(ctx.root.Position, BEAST, radius, 0.6)
	Effects.flash(ctx.root, BEAST, 3, radius, 0.6)
	for _, m in targetsInRadius(ctx.root.Position, radius, ctx.character) do
		local h = m:FindFirstChildOfClass("Humanoid")
		if h and ctx.rank >= 3 then
			local s0 = h.WalkSpeed
			h.WalkSpeed = s0 * 0.6
			task.delay(4, function()
				if h.Parent then
					h.WalkSpeed = s0
				end
			end)
		end
	end
	return 12
end

AbilityEffects.CragClimb = function(ctx)
	Effects.flash(ctx.root, BEAST, 1.5, 10, 0.3)
	if ctx.rank >= 3 then -- Pounce
		ctx.root.AssemblyLinearVelocity = flatForward(ctx) * (70 + 10 * ctx.rank) + Vector3.new(0, 40, 0)
	else
		ctx.root.AssemblyLinearVelocity = Vector3.new(0, 40, 0) + flatForward(ctx) * 15
	end
	return 4
end

-- ═══════════════════════════ VAMPIRE ═══════════════════════════
AbilityEffects.RedThirst = function(ctx)
	local dmg = 16 + 5 * ctx.rank
	local leech = if ctx.rank >= 2 then 0.6 else 0.4
	Effects.flash(ctx.root, BLOOD, 2, 10, 0.25)
	local any = false
	for _, m in targetsInCone(ctx, 9, 0.5) do
		local applied = hit(m, dmg, "Physical", ctx.character, BLOOD)
		if applied > 0 then
			any = true
			heal(ctx, applied * leech)
		end
	end
	return if any then 0.8 else 0.5
end

AbilityEffects.Nightspeed = function(ctx)
	Effects.flash(ctx.root, BLOOD, 2, 12, 0.3)
	ctx.root.AssemblyLinearVelocity = flatForward(ctx) * (100 + 10 * ctx.rank) + Vector3.new(0, 8, 0)
	return 5 - 0.5 * ctx.rank
end

AbilityEffects.Mist = function(ctx)
	if isTimed(ctx.character, "mist") then
		return 1
	end
	local hum = ctx.humanoid
	local speed0 = hum.WalkSpeed
	local restore = setPartTransparency(ctx.character, 0.75)
	hum.WalkSpeed = 8
	Effects.burst(ctx.root.Position, Color3.fromRGB(150, 150, 170), 5, 0.5)
	setTimed(ctx, "mist", 3 + ctx.rank, function()
		restore()
		if hum.Parent then
			hum.WalkSpeed = speed0
		end
	end)
	return 14
end

-- ═══════════════════════════ FRANKENSTEIN ═══════════════════════════
AbilityEffects.TheSpark = function(ctx)
	local dmg = 18 + 5 * ctx.rank
	bolt(ctx, ELECTRIC, 140, 110, dmg, "Electric", 0.6, function(pos, model)
		if ctx.rank >= 3 then -- Arc: chain to one nearby
			for _, m in targetsInRadius(pos, 15, ctx.character) do
				if m ~= model then
					hit(m, dmg * 0.5, "Electric", ctx.character, ELECTRIC)
					break
				end
			end
		end
	end)
	return 0.6
end

AbilityEffects.Overload = function(ctx)
	local radius = 12 + 2 * ctx.rank
	local dmg = 30 + 8 * ctx.rank
	Effects.burst(ctx.root.Position, ELECTRIC, radius, 0.45)
	Effects.flash(ctx.root, ELECTRIC, 4, radius, 0.45)
	for _, m in targetsInRadius(ctx.root.Position, radius, ctx.character) do
		hit(m, dmg, "Electric", ctx.character, ELECTRIC)
	end
	return 8
end

-- ═══════════════════════════ IMMORTAL ═══════════════════════════
local combo: { [Player]: { count: number, at: number } } = {}

AbilityEffects.Swordwork = function(ctx)
	clearTimed(ctx.character, "vanish") -- attacking breaks stealth
	local c = combo[ctx.player]
	local now = os.clock()
	if not c or now - c.at > 1.5 then
		c = { count = 0, at = now }
	end
	c.count += 1
	c.at = now
	combo[ctx.player] = c
	local chainLen = if ctx.rank >= 4 then 4 else 3
	local finisher = c.count >= chainLen
	local dmg = (18 + 4 * ctx.rank) * (if finisher then 1.6 else 1)
	Effects.flash(ctx.root, STEEL, 1.5, 9, 0.2)
	for _, m in targetsInCone(ctx, 10, 0.4) do
		hit(m, dmg, "Physical", ctx.character, STEEL)
		if finisher and ctx.rank >= 3 then -- stagger
			local p = m.PrimaryPart or m:FindFirstChild("HumanoidRootPart")
			if p and p:IsA("BasePart") and not p.Anchored then
				p.AssemblyLinearVelocity = flatForward(ctx) * 30 + Vector3.new(0, 10, 0)
			end
		end
	end
	if finisher then
		c.count = 0
	end
	return 0.5
end

AbilityEffects.Riposte = function(ctx)
	local ms = GameConfig.Combat.ParryWindowMs + 60 * math.max(ctx.rank - 1, 0)
	parryUntil[ctx.character] = os.clock() + ms / 1000
	parryRank[ctx.character] = ctx.rank
	Effects.flash(ctx.root, STEEL, 2.5, 8, ms / 1000)
	return 1.2
end

AbilityEffects.Stillness = function(ctx)
	if isTimed(ctx.character, "vanish") then
		clearTimed(ctx.character, "vanish")
		return 1
	end
	local hum = ctx.humanoid
	local speed0 = hum.WalkSpeed
	local restore = setPartTransparency(ctx.character, 0.85)
	hum.WalkSpeed = if ctx.rank >= 5 then 16 elseif ctx.rank >= 2 then 13 else 10
	setTimed(ctx, "vanish", 6 + 2 * ctx.rank, function()
		restore()
		if hum.Parent then
			hum.WalkSpeed = speed0
		end
	end)
	return 8
end

AbilityEffects.FirstCut = function(ctx)
	local fromStealth = isTimed(ctx.character, "vanish")
	clearTimed(ctx.character, "vanish")
	local dmg = (18 + 4 * ctx.rank) * (if fromStealth then 2.5 + 0.3 * ctx.rank else 0.8)
	Effects.flash(ctx.root, STEEL, 2, 9, 0.25)
	for _, m in targetsInCone(ctx, 10, 0.4) do
		hit(m, dmg, "Physical", ctx.character, STEEL)
	end
	return if fromStealth then 0.5 else 1.5
end

-- Clean up per-character state when a character goes away.
Players.PlayerRemoving:Connect(function(player)
	combo[player] = nil
	if player.Character then
		timed[player.Character] = nil
		parryUntil[player.Character] = nil
		parryRank[player.Character] = nil
	end
end)

return AbilityEffects
