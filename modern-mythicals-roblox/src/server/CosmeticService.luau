--!strict
-- Applies equipped code-only skins to a character: aura, trail, eyes.
-- (Element recolors are read by AbilityEffects at cast time.)
-- Everything lives in a "Cosmetics" folder inside the character so it can be
-- cleared and rebuilt whenever the loadout changes.

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage").Shared
local Skins = require(Shared.Skins)

local DataService = require(script.Parent.DataService)

local CosmeticService = {}

local function clear(character: Model)
	local f = character:FindFirstChild("Cosmetics")
	if f then
		f:Destroy()
	end
end

local function weldTo(base: BasePart, part: BasePart, offset: CFrame)
	part.CFrame = base.CFrame * offset
	local w = Instance.new("WeldConstraint")
	w.Part0 = base
	w.Part1 = part
	w.Parent = part
end

local function ghost(name: string): Part
	local p = Instance.new("Part")
	p.Name = name
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Massless = true
	p.CastShadow = false
	return p
end

local function applyAura(folder: Folder, root: BasePart, color: Color3)
	local ring = ghost("Aura")
	ring.Shape = Enum.PartType.Ball
	ring.Size = Vector3.new(6.5, 6.5, 6.5)
	ring.Material = Enum.Material.Neon
	ring.Color = color
	ring.Transparency = 0.86
	weldTo(root, ring, CFrame.new(0, 0, 0))
	local light = Instance.new("PointLight")
	light.Color = color
	light.Brightness = 1.2
	light.Range = 12
	light.Shadows = false
	light.Parent = ring
	ring.Parent = folder
end

local function applyTrail(folder: Folder, root: BasePart, color: Color3, color2: Color3?)
	local a0 = Instance.new("Attachment")
	a0.Name = "TrailA"
	a0.Position = Vector3.new(0, 1, 0)
	a0.Parent = root
	local a1 = Instance.new("Attachment")
	a1.Name = "TrailB"
	a1.Position = Vector3.new(0, -1, 0)
	a1.Parent = root
	local trail = Instance.new("Trail")
	trail.Attachment0 = a0
	trail.Attachment1 = a1
	trail.Color = ColorSequence.new(color, color2 or color)
	trail.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1) })
	trail.Lifetime = 0.55
	trail.WidthScale = NumberSequence.new(1, 0.2)
	trail.LightEmission = 0.8
	trail.MinLength = 0.1
	trail.Parent = folder
	-- Keep attachments with the folder's lifetime.
	local keep = Instance.new("ObjectValue")
	keep.Name = "TrailAttachments"
	keep.Value = a0
	keep.Parent = folder
	folder.Destroying:Connect(function()
		a0:Destroy()
		a1:Destroy()
	end)
end

local function applyEyes(folder: Folder, head: BasePart, color: Color3)
	local hx, hy, hz = head.Size.X, head.Size.Y, head.Size.Z
	for i, dx in { -hx * 0.18, hx * 0.18 } do
		local eye = ghost("Eye" .. i)
		eye.Size = Vector3.new(0.2, 0.12, 0.1)
		eye.Material = Enum.Material.Neon
		eye.Color = color
		weldTo(head, eye, CFrame.new(dx, hy * 0.08, -hz / 2 - 0.03))
		eye.Parent = folder
		if i == 1 then
			local glow = Instance.new("PointLight")
			glow.Color = color
			glow.Brightness = 1.0
			glow.Range = 7
			glow.Shadows = false
			glow.Parent = eye
		end
	end
end

-- Rebuild all equipped cosmetics on the player's current character.
function CosmeticService.apply(player: Player)
	local character = player.Character
	local profile = DataService.get(player)
	if not character or not profile then
		return
	end
	clear(character)
	local root = character:FindFirstChild("HumanoidRootPart")
	local head = character:FindFirstChild("Head")
	if not root or not root:IsA("BasePart") then
		return
	end
	local folder = Instance.new("Folder")
	folder.Name = "Cosmetics"
	folder.Parent = character

	local equipped = profile.equipped or {}
	local aura = equipped.aura and Skins.get(equipped.aura)
	if aura and aura.color then
		applyAura(folder, root, aura.color)
	end
	local trail = equipped.trail and Skins.get(equipped.trail)
	if trail and trail.color then
		applyTrail(folder, root, trail.color, trail.color2)
	end
	local eyes = equipped.eyes and Skins.get(equipped.eyes)
	if eyes and eyes.color and head and head:IsA("BasePart") then
		applyEyes(folder, head, eyes.color)
	end
end

function CosmeticService.init()
	local function watch(player: Player)
		player.CharacterAdded:Connect(function()
			task.wait(0.3) -- let the rig finish assembling
			DataService.loaded(player, function()
				CosmeticService.apply(player)
			end)
		end)
	end
	Players.PlayerAdded:Connect(watch)
	for _, p in Players:GetPlayers() do
		watch(p)
	end
end

return CosmeticService
