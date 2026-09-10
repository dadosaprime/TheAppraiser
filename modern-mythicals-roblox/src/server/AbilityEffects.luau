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
local AssetService = game:GetService("AssetService")
local InsertService = game:GetService("InsertService")

local Shared = game:GetService("ReplicatedStorage").Shared
local GameConfig = require(Shared.GameConfig)
local AssetIds = require(Shared.AssetIds)

local Effects = require(script.Parent.Effects)
local CombatService = require(script.Parent.CombatService)
local ProgressionService = require(script.Parent.ProgressionService)
local SpawnService = require(script.Parent.SpawnService)
local Fury = require(script.Parent.Fury)
local SoulService = require(script.Parent.SoulService)

export type Ctx = {
	player: Player,
	character: Model,
	humanoid: Humanoid,
	root: BasePart,
	rank: number,
	aim: Vector3, -- unit vector, usually the camera's look direction
}
type Effect = (ctx: Ctx) -> (number?, string?)

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
	for _, folderName in { "Dummies", "Enemies" } do
		local f = Workspace:FindFirstChild(folderName)
		if f then
			for _, m in f:GetChildren() do
				if m:IsA("Model") then
					table.insert(list, m)
				end
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
	-- Fury builds on both ends of a hit (only matters for Werewolves).
	local attackerPlayer = Players:GetPlayerFromCharacter(attacker)
	if attackerPlayer then
		Fury.add(attackerPlayer, applied * Fury.GAIN_DEALT)
	end
	local victimPlayer = Players:GetPlayerFromCharacter(target)
	if victimPlayer then
		Fury.add(victimPlayer, applied * Fury.GAIN_TAKEN)
	end
	-- A kill pays Soul Shards to the player who landed it (once).
	if hum.Health <= 0 then
		local reward = target:GetAttribute("ShardReward")
		if typeof(reward) == "number" and reward > 0 then
			target:SetAttribute("ShardReward", nil)
			local killer = Players:GetPlayerFromCharacter(attacker)
			if killer then
				ProgressionService.awardShards(killer, reward)
				SoulService.restore(killer, SoulService.KILL_RESTORE) -- a fight feeds you
				if p then
					Effects.damageNumber(p + Vector3.new(0, 2, 0), reward, Color3.fromRGB(255, 215, 90))
				end
			end
			local zone = target:GetAttribute("Zone")
			if typeof(zone) == "string" then
				SpawnService.reportKill(zone)
			end
		end
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
	-- Start just outside the body at chest height, along the aim.
	local origin = ctx.root.Position + Vector3.new(0, 0.5, 0) + ctx.aim * 3
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
	Effects.animate(ctx.character, "cast", 1.6)
	local dmg = 22 + 6 * ctx.rank
	bolt(ctx, FIRE, 80, 140, dmg, "Fire", 1.0)
	if ctx.rank >= 4 then
		task.delay(0.12, function()
			if ctx.character.Parent then
				bolt(ctx, FIRE, 80, 140, dmg, "Fire", 1.0)
			end
		end)
	end
	return 0.6
end

AbilityEffects.Conflagration = function(ctx)
	Effects.animate(ctx.character, "cast", 1.1)
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
local FUR = Color3.fromRGB(48, 36, 32)
local EYE = Color3.fromRGB(255, 40, 40)

-- Weld a cosmetic part to the head (ears, eyes). Massless so physics ignores it.
local function attachToHead(character: Model, head: BasePart, name: string, size: Vector3, offset: CFrame, color: Color3, material: Enum.Material): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Color = color
	p.Material = material
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Massless = true
	p.CastShadow = false
	p.CFrame = head.CFrame * offset
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = head
	weld.Part1 = p
	weld.Parent = p
	p.Parent = character
	return p
end

-- ── Werewolf avatar swap ────────────────────────────────────────────────────
-- AssetIds.ClassModels.WerewolfShifted decides how the shift looks:
--   ""                 → procedural beast (fur recolor + scale + ears/eyes)
--   "bundle:<id>"      → apply an Avatar Shop bundle to the player's description
--   "rbxassetid://<id>" or "<id>" → morph into a Creator Store rig model
local function shiftAsset(): (string?, number?)
	local raw = AssetIds.ClassModels.WerewolfShifted
	if raw == "" then
		return nil, nil
	end
	local b = raw:match("^bundle:(%d+)$")
	if b then
		return "bundle", tonumber(b)
	end
	local m = raw:match("(%d+)$")
	if m then
		return "asset", tonumber(m) -- rig model or avatar accessory; detected on load
	end
	return nil, nil
end

-- Bundle → HumanoidDescription (fetched once per server, cloned per use).
local bundleDescCache: { [number]: HumanoidDescription } = {}
local function bundleDescription(bundleId: number): HumanoidDescription?
	local cached = bundleDescCache[bundleId]
	if cached then
		return cached:Clone()
	end
	local ok, desc = pcall(function()
		local details = AssetService:GetBundleDetailsAsync(bundleId)
		for _, item in details.Items do
			if item.Type == "UserOutfit" then
				return Players:GetHumanoidDescriptionFromOutfitId(item.Id)
			end
		end
		return nil
	end)
	if ok and desc then
		bundleDescCache[bundleId] = desc
		return desc:Clone()
	end
	warn("[Shift] bundle lookup failed for", bundleId, desc)
	return nil
end

-- Load the configured asset once and work out what it is:
--   a Humanoid rig   → morph the player into a clone of it
--   Accessory(s)     → wear them on the player's own avatar (costume)
local loadedKind: string? = nil
local loadedRig: Model? = nil
local loadedAccessories: { Accessory } = {}
local loadAttempted = false

local function loadShiftAsset(assetId: number): (string?, any)
	if loadAttempted then
		return loadedKind, if loadedKind == "rig" then loadedRig else loadedAccessories
	end
	loadAttempted = true
	local ok, container = pcall(function()
		return InsertService:LoadAsset(assetId)
	end)
	if not ok or not container then
		warn("[Shift] could not load asset", assetId, container)
		return nil, nil
	end
	local rig = container:FindFirstChildWhichIsA("Model", true)
	if rig and rig:FindFirstChildOfClass("Humanoid") and rig:FindFirstChild("HumanoidRootPart") then
		rig.Parent = nil
		container:Destroy()
		loadedKind, loadedRig = "rig", rig
		print("[Shift] asset", assetId, "is a Humanoid rig — morphing on shift")
		return loadedKind, loadedRig
	end
	for _, d in container:GetDescendants() do
		if d:IsA("Accessory") then
			table.insert(loadedAccessories, d)
		end
	end
	if #loadedAccessories > 0 then
		loadedKind = "accessories"
		print("[Shift] asset", assetId, "is", #loadedAccessories, "accessory(ies) — wearing on shift")
		return loadedKind, loadedAccessories
	end
	warn("[Shift] asset", assetId, "is neither a Humanoid rig nor an Accessory; using procedural beast")
	container:Destroy()
	return nil, nil
end

-- Layered-clothing accessory types deform to the body; everything else is rigid.
local LAYERED: { [Enum.AccessoryType]: boolean } = {
	[Enum.AccessoryType.Jacket] = true,
	[Enum.AccessoryType.Sweater] = true,
	[Enum.AccessoryType.Shirt] = true,
	[Enum.AccessoryType.TShirt] = true,
	[Enum.AccessoryType.Pants] = true,
	[Enum.AccessoryType.Shorts] = true,
	[Enum.AccessoryType.DressSkirt] = true,
	[Enum.AccessoryType.LeftShoe] = true,
	[Enum.AccessoryType.RightShoe] = true,
	[Enum.AccessoryType.Eyebrow] = true,
	[Enum.AccessoryType.Eyelash] = true,
}

-- Model morph: the player's character is REPLACED by a clone of a rigged model
-- for the duration, then the original character is restored in place.

type Morph = { wolf: Model, human: Model }
local morphs: { [Player]: Morph } = {}

local function revertMorph(player: Player)
	local m = morphs[player]
	if not m then
		return
	end
	morphs[player] = nil
	local pivot = m.wolf:GetPivot()
	m.human.Parent = Workspace
	m.human:PivotTo(pivot)
	player.Character = m.human
	m.wolf:Destroy()
end

local function morphShift(ctx: Ctx, template: Model): number?
	if morphs[ctx.player] then
		revertMorph(ctx.player)
		return 1
	end
	local human = ctx.character
	local wolf = template:Clone()
	wolf.Name = ctx.player.Name
	-- Carry the default character scripts so the rig animates and can die.
	for _, name in { "Animate", "Health" } do
		local scr = human:FindFirstChild(name)
		if scr then
			scr:Clone().Parent = wolf
		end
	end
	wolf:PivotTo(human:GetPivot())
	wolf.Parent = Workspace
	ctx.player.Character = wolf -- fires CharacterAdded; combat state re-registers
	human.Parent = nil
	morphs[ctx.player] = { wolf = wolf, human = human }

	local whum = wolf:FindFirstChildOfClass("Humanoid")
	if whum then
		whum.WalkSpeed = 24
		whum.MaxHealth = math.max(whum.MaxHealth, ctx.humanoid.MaxHealth + 60 + 15 * ctx.rank)
		whum.Health = whum.MaxHealth
		whum.Died:Connect(function()
			-- The beast fell: restore the human and let normal death/respawn run.
			if morphs[ctx.player] and morphs[ctx.player].wolf == wolf then
				revertMorph(ctx.player)
				local hh = human:FindFirstChildOfClass("Humanoid")
				if hh then
					hh.Health = 0
				end
			end
		end)
	end
	local st = CombatService.state(wolf)
	if st then
		local w = if ctx.rank >= 5 then 1.3 else 1.6
		st.weaknesses.Fire = w
		st.weaknesses.Electric = w
	end
	local root = wolf:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		Effects.flash(root, BEAST, 4, 18, 0.8)
		Effects.burst(root.Position, BEAST, 6, 0.4)
	end
	-- The form lasts as long as Fury does (see Fury.luau).
	Fury.setShiftRank(ctx.player, ctx.rank)
	return 1
end

Players.PlayerRemoving:Connect(function(player)
	local m = morphs[player]
	if m then
		morphs[player] = nil
		m.human:Destroy()
	end
end)

AbilityEffects.TheTurning = function(ctx)
	if isTimed(ctx.character, "shift") then
		clearTimed(ctx.character, "shift") -- toggle back to human
		return 1
	end
	if morphs[ctx.player] then
		revertMorph(ctx.player)
		return 1
	end
	if not Fury.canShift(ctx.player) then
		return nil, ("Need %d Fury — fight in human form to build it"):format(Fury.SHIFT_COST)
	end
	Effects.animate(ctx.character, "roar", 1.0)
	local hum = ctx.humanoid
	local rank = ctx.rank

	-- A real werewolf avatar, if one is configured in AssetIds.
	local kind, assetId = shiftAsset()
	local wearAccessories: { Accessory }? = nil
	if kind == "asset" and assetId then
		local akind, payload = loadShiftAsset(assetId)
		if akind == "rig" then
			local cd = morphShift(ctx, payload :: Model)
			if cd then
				return cd
			end
			kind = nil
		elseif akind == "accessories" then
			wearAccessories = payload :: { Accessory }
			kind = "accessories"
		else
			kind = nil -- fall back to the procedural beast
		end
	end

	-- The beast, done the robust way: rewrite the avatar description. This
	-- strips clothing textures (which hide plain part recolors), sets fur color
	-- on every limb, and scales the whole rig — bigger hitbox, the drawback.
	local original: HumanoidDescription? = nil
	local applied = pcall(function()
		local desc = hum:GetAppliedDescription()
		original = desc:Clone()
		local target = desc
		if kind == "bundle" and assetId then
			-- A real werewolf body from the Avatar Shop replaces the procedural fur.
			local bd = bundleDescription(assetId)
			if bd then
				target = bd
			else
				kind = nil
			end
		end
		if kind == "accessories" and wearAccessories and assetId then
			local list = target:GetAccessories(true)
			for _, acc in wearAccessories do
				table.insert(list, {
					AssetId = assetId,
					AccessoryType = acc.AccessoryType,
					IsLayered = LAYERED[acc.AccessoryType] == true,
				})
			end
			target:SetAccessories(list, true)
		end
		if kind ~= "bundle" then
			target.HeadColor = FUR
			target.TorsoColor = FUR
			target.LeftArmColor = FUR
			target.RightArmColor = FUR
			target.LeftLegColor = FUR
			target.RightLegColor = FUR
			target.Shirt = 0
			target.Pants = 0
			target.GraphicTShirt = 0
			target.Face = 0
		end
		-- Bigger either way: the hitbox drawback is the design.
		target.HeightScale = target.HeightScale * 1.3
		target.WidthScale = target.WidthScale * 1.35
		target.DepthScale = target.DepthScale * 1.3
		target.HeadScale = target.HeadScale * 1.15
		hum:ApplyDescription(target)
	end)

	-- Fallback for rigs without a description: scale values + recolor.
	local scaleOriginals: { [NumberValue]: number } = {}
	local colorOriginals: { [BasePart]: Color3 } = {}
	if not applied then
		for _, name in SCALE_NAMES do
			local v = hum:FindFirstChild(name)
			if v and v:IsA("NumberValue") then
				scaleOriginals[v] = v.Value
				v.Value = v.Value * (if name == "HeadScale" then 1.15 else 1.3)
			end
		end
		for _, d in ctx.character:GetDescendants() do
			if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" then
				colorOriginals[d] = d.Color
				d.Color = FUR
			end
		end
	end

	-- Ears and glowing eyes so the silhouette reads as a wolf at night.
	local extras: { Instance } = {}
	local head = ctx.character:FindFirstChild("Head")
	if kind ~= "bundle" and head and head:IsA("BasePart") then
		local hx, hy, hz = head.Size.X, head.Size.Y, head.Size.Z
		table.insert(extras, attachToHead(ctx.character, head, "WolfEarL", Vector3.new(0.35, 0.9, 0.25),
			CFrame.new(-hx * 0.38, hy * 0.5 + 0.4, 0) * CFrame.Angles(0, 0, math.rad(18)), FUR, Enum.Material.Fabric))
		table.insert(extras, attachToHead(ctx.character, head, "WolfEarR", Vector3.new(0.35, 0.9, 0.25),
			CFrame.new(hx * 0.38, hy * 0.5 + 0.4, 0) * CFrame.Angles(0, 0, math.rad(-18)), FUR, Enum.Material.Fabric))
		local eyeL = attachToHead(ctx.character, head, "WolfEyeL", Vector3.new(0.2, 0.12, 0.1),
			CFrame.new(-hx * 0.18, hy * 0.08, -hz / 2 - 0.03), EYE, Enum.Material.Neon)
		local eyeR = attachToHead(ctx.character, head, "WolfEyeR", Vector3.new(0.2, 0.12, 0.1),
			CFrame.new(hx * 0.18, hy * 0.08, -hz / 2 - 0.03), EYE, Enum.Material.Neon)
		table.insert(extras, eyeL)
		table.insert(extras, eyeR)
		local glow = Instance.new("PointLight")
		glow.Color = EYE
		glow.Brightness = 1.5
		glow.Range = 9
		glow.Shadows = false
		glow.Parent = eyeL
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

	-- The form lasts as long as Fury does (see Fury.luau); no fixed timer.
	Fury.setShiftRank(ctx.player, rank)
	setTimed(ctx, "shift", math.huge, function()
		for _, e in extras do
			e:Destroy()
		end
		if original and hum.Parent then
			pcall(function()
				hum:ApplyDescription(original :: HumanoidDescription)
			end)
		end
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
		local s2 = CombatService.state(ctx.character)
		if s2 then
			s2.weaknesses.Fire = nil
			s2.weaknesses.Electric = nil
		end
	end)
	return 1
end

AbilityEffects.RedRend = function(ctx)
	Effects.animate(ctx.character, "melee", 1.6)
	local shifted = isTimed(ctx.character, "shift") or morphs[ctx.player] ~= nil
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
	Effects.animate(ctx.character, "roar", 1.2)
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
	Effects.animate(ctx.character, "melee", 1.5)
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
	Effects.animate(ctx.character, "cast", 1.6)
	local dmg = 18 + 5 * ctx.rank
	bolt(ctx, ELECTRIC, 120, 130, dmg, "Electric", 0.9, function(pos, model)
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
	Effects.animate(ctx.character, "roar", 1.4)
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
	Effects.animate(ctx.character, "melee", 1.5)
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
	Effects.animate(ctx.character, "lunge", 1.4)
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

-- Fury owns the drain; it asks us whether a player is shifted and tells us to end it.
Fury.isShifted = function(player: Player): boolean
	local c = player.Character
	return (c ~= nil and isTimed(c, "shift")) or morphs[player] ~= nil
end
Fury.endShift = function(player: Player)
	local c = player.Character
	if c then
		clearTimed(c, "shift")
	end
	revertMorph(player)
end

return AbilityEffects
