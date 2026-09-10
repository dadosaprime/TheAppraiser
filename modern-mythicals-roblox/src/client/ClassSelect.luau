--!strict
-- Class selection screen. Shown whenever the player's profile has no class.
-- Picking a card calls the ChooseClass RemoteFunction; the server validates,
-- grants rank 1 of the class's basic-attack tree, and pushes a fresh profile.

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage").Shared
local Classes = require(Shared.Classes)
local Net = require(Shared.Net)

local player = Players.LocalPlayer

local ClassSelect = {}

local gui: ScreenGui? = nil

local function destroy()
	if gui then
		gui:Destroy()
		gui = nil
	end
end

local function label(parent: Instance, text: string, pos: UDim2, size: UDim2, bold: boolean): TextLabel
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Position = pos
	l.Size = size
	l.Text = text
	l.TextColor3 = Color3.fromRGB(235, 230, 245)
	l.Font = if bold then Enum.Font.GothamBold else Enum.Font.Gotham
	l.TextScaled = true
	l.TextWrapped = true
	l.Parent = parent
	return l
end

function ClassSelect.show(onChosen: (string) -> ())
	if gui then
		return
	end
	local sg = Instance.new("ScreenGui")
	sg.Name = "ClassSelect"
	sg.ResetOnSpawn = false
	sg.IgnoreGuiInset = true
	sg.DisplayOrder = 10
	sg.Parent = player:WaitForChild("PlayerGui")
	gui = sg

	local dim = Instance.new("Frame")
	dim.Size = UDim2.fromScale(1, 1)
	dim.BackgroundColor3 = Color3.fromRGB(6, 5, 12)
	dim.BackgroundTransparency = 0.12
	dim.Parent = sg

	label(dim, "You step into another night.", UDim2.fromScale(0, 0.07), UDim2.fromScale(1, 0.09), true)
	label(dim, "Choose what you are.", UDim2.fromScale(0, 0.17), UDim2.fromScale(1, 0.05), false)

	local row = Instance.new("Frame")
	row.AnchorPoint = Vector2.new(0.5, 0.5)
	row.Position = UDim2.fromScale(0.5, 0.58)
	row.Size = UDim2.fromScale(0.94, 0.5)
	row.BackgroundTransparency = 1
	row.Parent = dim

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Padding = UDim.new(0.012, 0)
	layout.Parent = row

	for _, id in Classes.ORDER do
		local class = Classes.get(id)
		if class then
			local card = Instance.new("TextButton")
			card.Size = UDim2.fromScale(0.185, 1)
			card.BackgroundColor3 = Color3.fromRGB(28, 22, 40)
			card.AutoButtonColor = true
			card.Text = ""
			card.Parent = row

			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(0, 10)
			corner.Parent = card

			label(card, class.displayName, UDim2.fromScale(0.05, 0.05), UDim2.fromScale(0.9, 0.16), true)
			label(card, "Starts with: " .. class.startingPower, UDim2.fromScale(0.05, 0.23), UDim2.fromScale(0.9, 0.08), false)
			label(card, class.role, UDim2.fromScale(0.05, 0.34), UDim2.fromScale(0.9, 0.3), false)
			label(card, class.mythologicalAnchor, UDim2.fromScale(0.05, 0.66), UDim2.fromScale(0.9, 0.3), false).TextColor3 =
				Color3.fromRGB(170, 160, 200)

			card.MouseButton1Click:Connect(function()
				card.BackgroundColor3 = Color3.fromRGB(60, 45, 90)
				local result = Net.get("ChooseClass"):InvokeServer(id)
				if type(result) == "table" and result.ok then
					destroy()
					onChosen(id)
				else
					card.BackgroundColor3 = Color3.fromRGB(110, 40, 40)
					task.delay(0.6, function()
						card.BackgroundColor3 = Color3.fromRGB(28, 22, 40)
					end)
				end
			end)
		end
	end
end

function ClassSelect.hide()
	destroy()
end

return ClassSelect
