--!strict
-- Training dummies on the Collins sidewalk so every ability has a target.
-- Built from parts; each has a Humanoid so damage, health bars, and death all
-- work with no assets. Dummies respawn a few seconds after dying.

local Workspace = game:GetService("Workspace")

local TrainingDummies = {}

local SPOTS = {
	Vector3.new(880, 3, -22),
	Vector3.new(900, 3, -18),
	Vector3.new(920, 3, -22),
}
local MAX_HEALTH = 300
local RESPAWN_SECONDS = 5

local function folder(): Folder
	local f = Workspace:FindFirstChild("Dummies")
	if not f then
		f = Instance.new("Folder")
		f.Name = "Dummies"
		f.Parent = Workspace
	end
	return f :: Folder
end

local function spawnDummy(index: number, at: Vector3)
	local model = Instance.new("Model")
	model.Name = ("Training Dummy %d"):format(index)

	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(2, 2, 1)
	root.Transparency = 1
	root.Anchored = true
	root.CanCollide = false
	root.Position = at
	root.Parent = model

	local torso = Instance.new("Part")
	torso.Name = "Torso"
	torso.Size = Vector3.new(2.2, 3, 1.2)
	torso.Material = Enum.Material.Fabric
	torso.Color = Color3.fromRGB(120, 90, 70)
	torso.Anchored = true
	torso.Position = at
	torso.Parent = model

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Shape = Enum.PartType.Ball
	head.Size = Vector3.new(1.4, 1.4, 1.4)
	head.Material = Enum.Material.Fabric
	head.Color = Color3.fromRGB(150, 120, 100)
	head.Anchored = true
	head.Position = at + Vector3.new(0, 2.2, 0)
	head.Parent = model

	local post = Instance.new("Part")
	post.Name = "Post"
	post.Size = Vector3.new(0.5, 3, 0.5)
	post.Material = Enum.Material.Wood
	post.Color = Color3.fromRGB(80, 60, 40)
	post.Anchored = true
	post.Position = at - Vector3.new(0, 3, 0)
	post.Parent = model

	local hum = Instance.new("Humanoid")
	hum.MaxHealth = MAX_HEALTH
	hum.Health = MAX_HEALTH
	hum.WalkSpeed = 0
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer
	hum.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOn
	hum.BreakJointsOnDeath = false
	hum.Parent = model

	model.PrimaryPart = root
	model.Parent = folder()

	hum.Died:Connect(function()
		task.delay(RESPAWN_SECONDS, function()
			if model.Parent then
				model:Destroy()
			end
			spawnDummy(index, at)
		end)
	end)
end

function TrainingDummies.init()
	for i, at in SPOTS do
		spawnDummy(i, at)
	end
end

return TrainingDummies
