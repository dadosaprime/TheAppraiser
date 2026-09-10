--!strict
-- A weak street gang on the beach — the first live enemies. (Enemies.GangMook.)
--
-- Built from zero assets: Players:CreateHumanoidModelFromDescription gives a
-- full R15 rig; Roblox's public default animations make it idle and walk. The
-- AI is a small loop: wander near home, notice players within sight range,
-- close and swing for light damage. Dying pays Soul Shards to the killer
-- (see AbilityEffects.hit) and the mook respawns at home a few seconds later.
-- Swap AssetIds.EnemyModels.GangMook in later for a real model.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local Shared = game:GetService("ReplicatedStorage").Shared
local Enemies = require(Shared.Enemies)

local Effects = require(script.Parent.Effects)
local CombatService = require(script.Parent.CombatService)
local Fury = require(script.Parent.Fury)

local StreetGang = {}

-- Home points on the sand between the spawn and the beach-walk lamps.
local HOMES = {
	Vector3.new(872, 4, -150),
	Vector3.new(896, 4, -162),
	Vector3.new(922, 4, -150),
	Vector3.new(900, 4, -136),
}

local MAX_HEALTH = 120
local SIGHT = 45
local LEASH = 28
local MELEE_RANGE = 5.5
local ATTACK_DAMAGE = 8
local ATTACK_INTERVAL = 1.2
local WALK_SPEED = 13
local RESPAWN_SECONDS = 8
local SHARD_REWARD = 150

-- Roblox's public default R15 animations.
local ANIM_IDLE = "rbxassetid://507766666"
local ANIM_WALK = "rbxassetid://507777826"

local GANG_RED = Color3.fromRGB(120, 24, 32)

local function folder(): Folder
	local f = Workspace:FindFirstChild("Enemies")
	if not f then
		f = Instance.new("Folder")
		f.Name = "Enemies"
		f.Parent = Workspace
	end
	return f :: Folder
end

local function gangDescription(): HumanoidDescription
	local d = Instance.new("HumanoidDescription")
	d.HeadColor = Color3.fromRGB(190, 150, 120)
	d.TorsoColor = GANG_RED
	d.LeftArmColor = Color3.fromRGB(40, 40, 46)
	d.RightArmColor = Color3.fromRGB(40, 40, 46)
	d.LeftLegColor = Color3.fromRGB(28, 28, 34)
	d.RightLegColor = Color3.fromRGB(28, 28, 34)
	return d
end

local function nearestPlayer(from: Vector3, maxDist: number): (Model?, number)
	local best: Model? = nil
	local bestDist = maxDist
	for _, p in Players:GetPlayers() do
		local c = p.Character
		local root = c and c:FindFirstChild("HumanoidRootPart")
		local hum = c and c:FindFirstChildOfClass("Humanoid")
		if c and root and root:IsA("BasePart") and hum and hum.Health > 0 then
			local d = (root.Position - from).Magnitude
			if d < bestDist then
				best = c
				bestDist = d
			end
		end
	end
	return best, bestDist
end

local function swingAt(npc: Model, npcRoot: BasePart, target: Model)
	local hum = target:FindFirstChildOfClass("Humanoid")
	local tRoot = target:FindFirstChild("HumanoidRootPart")
	if not hum or hum.Health <= 0 or not tRoot or not tRoot:IsA("BasePart") then
		return
	end
	-- Face the target, flash, hit.
	local look = Vector3.new(tRoot.Position.X, npcRoot.Position.Y, tRoot.Position.Z)
	npcRoot.CFrame = CFrame.lookAt(npcRoot.Position, look)
	Effects.animate(npc, "melee", 1.2)
	Effects.flash(npcRoot, GANG_RED, 1.5, 8, 0.2)
	local applied = ATTACK_DAMAGE
	if CombatService.state(target) then
		applied = CombatService.applyDamage(target, ATTACK_DAMAGE, "Physical", npc)
	end
	hum:TakeDamage(applied)
	Effects.damageNumber(tRoot.Position, applied, GANG_RED)
	local victim = Players:GetPlayerFromCharacter(target)
	if victim then
		Fury.add(victim, applied * Fury.GAIN_TAKEN)
	end
end

local function runBrain(npc: Model, hum: Humanoid, root: BasePart, home: Vector3)
	local animator = hum:FindFirstChildOfClass("Animator") or Instance.new("Animator", hum)
	local idleAnim = Instance.new("Animation")
	idleAnim.AnimationId = ANIM_IDLE
	local walkAnim = Instance.new("Animation")
	walkAnim.AnimationId = ANIM_WALK
	local idle = animator:LoadAnimation(idleAnim)
	local walk = animator:LoadAnimation(walkAnim)
	idle.Priority = Enum.AnimationPriority.Idle
	walk.Priority = Enum.AnimationPriority.Movement
	idle:Play()

	local moving = false
	local wanderTarget: Vector3? = nil
	local lastAttack = 0

	task.spawn(function()
		while npc.Parent and hum.Health > 0 do
			local target, dist = nearestPlayer(root.Position, SIGHT)
			if target then
				local tRoot = target:FindFirstChild("HumanoidRootPart") :: BasePart
				if dist > MELEE_RANGE then
					hum:MoveTo(tRoot.Position)
				else
					hum:MoveTo(root.Position) -- hold
					if os.clock() - lastAttack >= ATTACK_INTERVAL then
						lastAttack = os.clock()
						swingAt(npc, root, target)
					end
				end
				wanderTarget = nil
			else
				-- Wander around home.
				if not wanderTarget or (root.Position - wanderTarget).Magnitude < 3 or math.random() < 0.05 then
					local ang = math.random() * math.pi * 2
					local r = math.random(4, LEASH)
					wanderTarget = home + Vector3.new(math.cos(ang) * r, 0, math.sin(ang) * r)
					hum:MoveTo(wanderTarget)
				end
			end

			local nowMoving = hum.MoveDirection.Magnitude > 0.05
			if nowMoving ~= moving then
				moving = nowMoving
				if moving then
					walk:Play(0.15)
				else
					walk:Stop(0.15)
				end
			end
			task.wait(0.25)
		end
	end)
end

local function spawnMook(index: number, home: Vector3)
	local ok, model = pcall(function()
		return Players:CreateHumanoidModelFromDescription(gangDescription(), Enum.HumanoidRigType.R15)
	end)
	if not ok or not model then
		warn("[StreetGang] could not create rig:", model)
		return
	end
	local archetype = Enemies.get("GangMook")
	model.Name = ("Gang Member %d"):format(index)
	model:SetAttribute("ShardReward", SHARD_REWARD)
	model:SetAttribute("Zone", "ClubBeach")
	model:SetAttribute("Archetype", archetype and archetype.id or "GangMook")

	local hum = model:FindFirstChildOfClass("Humanoid") :: Humanoid
	local root = model:FindFirstChild("HumanoidRootPart") :: BasePart
	hum.DisplayName = "Gang Member"
	hum.MaxHealth = MAX_HEALTH
	hum.Health = MAX_HEALTH
	hum.WalkSpeed = WALK_SPEED
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer
	hum.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOn
	hum.BreakJointsOnDeath = false

	model:PivotTo(CFrame.new(home))
	model.Parent = folder()
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			d:SetNetworkOwner(nil) -- server drives NPC physics
		end
	end

	runBrain(model, hum, root, home)

	hum.Died:Connect(function()
		Effects.burst(root.Position, GANG_RED, 4, 0.5)
		task.delay(RESPAWN_SECONDS, function()
			if model.Parent then
				model:Destroy()
			end
			spawnMook(index, home)
		end)
	end)
end

function StreetGang.init()
	for i, home in HOMES do
		task.spawn(spawnMook, i, home)
	end
end

return StreetGang
