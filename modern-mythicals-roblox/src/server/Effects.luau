--!strict
-- Server-side visual helpers shared by ability effects: floating damage
-- numbers, light flashes, AoE bursts, and a raycasting projectile. Everything
-- here is built from primitive Parts — no assets required.

local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Workspace = game:GetService("Workspace")

local Effects = {}

local function folder(): Folder
	local f = Workspace:FindFirstChild("FX")
	if not f then
		f = Instance.new("Folder")
		f.Name = "FX"
		f.Parent = Workspace
	end
	return f :: Folder
end

local function ghostPart(): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	return p
end

-- Floating damage number at a world position.
function Effects.damageNumber(position: Vector3, amount: number, color: Color3)
	local anchor = ghostPart()
	anchor.Transparency = 1
	anchor.Size = Vector3.new(0.2, 0.2, 0.2)
	anchor.Position = position + Vector3.new(math.random(-10, 10) / 10, 2, math.random(-10, 10) / 10)
	anchor.Parent = folder()

	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(120, 40)
	bb.AlwaysOnTop = true
	bb.Parent = anchor

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = tostring(math.floor(amount + 0.5))
	label.TextColor3 = color
	label.TextStrokeTransparency = 0.3
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.Parent = bb

	local info = TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(anchor, info, { Position = anchor.Position + Vector3.new(0, 4, 0) }):Play()
	TweenService:Create(label, TweenInfo.new(0.9), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	Debris:AddItem(anchor, 1)
end

-- Brief colored light on a part.
function Effects.flash(part: BasePart, color: Color3, brightness: number, range: number, duration: number)
	local light = Instance.new("PointLight")
	light.Color = color
	light.Brightness = brightness
	light.Range = range
	light.Shadows = false
	light.Parent = part
	TweenService:Create(light, TweenInfo.new(duration), { Brightness = 0 }):Play()
	Debris:AddItem(light, duration)
end

-- Expanding neon sphere for AoE abilities.
function Effects.burst(position: Vector3, color: Color3, radius: number, duration: number)
	local p = ghostPart()
	p.Shape = Enum.PartType.Ball
	p.Material = Enum.Material.Neon
	p.Color = color
	p.Transparency = 0.3
	p.Size = Vector3.new(1, 1, 1)
	p.Position = position
	p.Parent = folder()
	local info = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(p, info, { Size = Vector3.new(radius * 2, radius * 2, radius * 2), Transparency = 1 }):Play()
	Debris:AddItem(p, duration)
end

export type ProjectileOpts = {
	color: Color3,
	speed: number,
	range: number,
	radius: number?,
	ignore: { Instance },
	onHit: (hitPart: BasePart, position: Vector3, model: Model?) -> (),
}

-- Server projectile: a neon ball that raycasts along its path every frame.
function Effects.projectile(origin: Vector3, direction: Vector3, opts: ProjectileOpts)
	local dir = if direction.Magnitude > 0 then direction.Unit else Vector3.new(0, 0, -1)
	local size = (opts.radius or 0.8) * 2

	local ball = ghostPart()
	ball.Shape = Enum.PartType.Ball
	ball.Material = Enum.Material.Neon
	ball.Color = opts.color
	ball.Size = Vector3.new(size, size, size)
	ball.Position = origin
	ball.Parent = folder()

	local light = Instance.new("PointLight")
	light.Color = opts.color
	light.Brightness = 2
	light.Range = 14
	light.Shadows = false
	light.Parent = ball

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local filter = table.clone(opts.ignore)
	table.insert(filter, folder())
	params.FilterDescendantsInstances = filter

	task.spawn(function()
		local traveled = 0
		local pos = origin
		while traveled < opts.range and ball.Parent do
			local dt = task.wait()
			local step = dir * (opts.speed * dt)
			local result = Workspace:Raycast(pos, step, params)
			if result then
				local model = result.Instance:FindFirstAncestorOfClass("Model")
				opts.onHit(result.Instance, result.Position, model)
				break
			end
			pos += step
			traveled += step.Magnitude
			ball.Position = pos
		end
		ball:Destroy()
	end)
end

return Effects
