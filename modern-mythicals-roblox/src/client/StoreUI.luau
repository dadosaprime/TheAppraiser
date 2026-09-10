--!strict
-- The skin store panel. Toggle with K. Lists the catalog by category with
-- Buy / Equip / Equipped states driven by the player's profile.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local Shared = game:GetService("ReplicatedStorage").Shared
local Net = require(Shared.Net)
local Skins = require(Shared.Skins)

local player = Players.LocalPlayer

local StoreUI = {}

local gui: ScreenGui? = nil
local profile: any = nil
local rows: { [string]: { button: TextButton, price: TextLabel } } = {}
local onMessage: (string) -> () = function() end

local function refreshRows()
	if not profile then
		return
	end
	for id, r in rows do
		local skin = Skins.get(id)
		if skin then
			local owned = profile.cosmetics and profile.cosmetics[id] == true
			local equipped = profile.equipped and profile.equipped[skin.category] == id
			local fits = Skins.fitsClass(skin, profile.class)
			if not fits then
				r.button.Text = ("%s only"):format(skin.class or "?")
				r.button.BackgroundColor3 = Color3.fromRGB(40, 36, 48)
				r.button.AutoButtonColor = false
			elseif equipped then
				r.button.Text = "Equipped ✓"
				r.button.BackgroundColor3 = Color3.fromRGB(60, 120, 70)
				r.button.AutoButtonColor = true
			elseif owned then
				r.button.Text = "Equip"
				r.button.BackgroundColor3 = Color3.fromRGB(70, 60, 120)
				r.button.AutoButtonColor = true
			else
				r.button.Text = ("Buy  R$%d"):format(skin.price)
				r.button.BackgroundColor3 = Color3.fromRGB(120, 80, 40)
				r.button.AutoButtonColor = true
			end
		end
	end
end

local function build()
	local sg = Instance.new("ScreenGui")
	sg.Name = "SkinStore"
	sg.ResetOnSpawn = false
	sg.DisplayOrder = 8
	sg.Enabled = false
	sg.Parent = player:WaitForChild("PlayerGui")

	local panel = Instance.new("Frame")
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.Size = UDim2.fromScale(0.62, 0.78)
	panel.BackgroundColor3 = Color3.fromRGB(14, 11, 22)
	panel.BackgroundTransparency = 0.05
	panel.Parent = sg
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = panel

	local title = Instance.new("TextLabel")
	title.Size = UDim2.fromScale(1, 0.09)
	title.BackgroundTransparency = 1
	title.Text = "THE ANTIQUE SHOP  ·  skins"
	title.TextColor3 = Color3.fromRGB(235, 230, 245)
	title.Font = Enum.Font.GothamBold
	title.TextScaled = true
	title.Parent = panel

	local hint = Instance.new("TextLabel")
	hint.Position = UDim2.fromScale(0, 0.09)
	hint.Size = UDim2.fromScale(1, 0.04)
	hint.BackgroundTransparency = 1
	hint.Text = "K to close   ·   element skins recolor your abilities; auras, trails and eyes fit any class"
	hint.TextColor3 = Color3.fromRGB(150, 145, 170)
	hint.Font = Enum.Font.Gotham
	hint.TextScaled = true
	hint.Parent = panel

	local scroll = Instance.new("ScrollingFrame")
	scroll.Position = UDim2.fromScale(0.03, 0.15)
	scroll.Size = UDim2.fromScale(0.94, 0.82)
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 6
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.Parent = panel
	local list = Instance.new("UIListLayout")
	list.Padding = UDim.new(0, 6)
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Parent = scroll

	local order = 0
	for _, cat in Skins.CATEGORIES do
		order += 1
		local header = Instance.new("TextLabel")
		header.Size = UDim2.new(1, 0, 0, 30)
		header.BackgroundTransparency = 1
		header.Text = Skins.CATEGORY_LABEL[cat] or cat
		header.TextColor3 = Color3.fromRGB(200, 190, 230)
		header.Font = Enum.Font.GothamBold
		header.TextScaled = true
		header.TextXAlignment = Enum.TextXAlignment.Left
		header.LayoutOrder = order
		header.Parent = scroll

		for _, skin in Skins.all() do
			if skin.category == cat then
				order += 1
				local row = Instance.new("Frame")
				row.Size = UDim2.new(1, 0, 0, 52)
				row.BackgroundColor3 = Color3.fromRGB(28, 22, 40)
				row.BorderSizePixel = 0
				row.LayoutOrder = order
				row.Parent = scroll
				local rc = Instance.new("UICorner")
				rc.CornerRadius = UDim.new(0, 8)
				rc.Parent = row

				local swatch = Instance.new("Frame")
				swatch.Position = UDim2.new(0, 10, 0.5, -14)
				swatch.Size = UDim2.fromOffset(28, 28)
				local c = skin.color
				if not c and skin.colors then
					for _, v in skin.colors do
						c = v
						break
					end
				end
				swatch.BackgroundColor3 = c or Color3.fromRGB(120, 120, 130)
				swatch.BorderSizePixel = 0
				swatch.Parent = row
				local sc = Instance.new("UICorner")
				sc.CornerRadius = UDim.new(1, 0)
				sc.Parent = swatch

				local name = Instance.new("TextLabel")
				name.Position = UDim2.new(0, 48, 0, 4)
				name.Size = UDim2.new(0.55, 0, 0, 22)
				name.BackgroundTransparency = 1
				name.Text = skin.name .. (if skin.class then ("   ·   " .. skin.class) else "")
				name.TextColor3 = Color3.fromRGB(235, 230, 245)
				name.Font = Enum.Font.GothamBold
				name.TextScaled = true
				name.TextXAlignment = Enum.TextXAlignment.Left
				name.Parent = row

				local desc = Instance.new("TextLabel")
				desc.Position = UDim2.new(0, 48, 0, 27)
				desc.Size = UDim2.new(0.55, 0, 0, 18)
				desc.BackgroundTransparency = 1
				desc.Text = skin.description
				desc.TextColor3 = Color3.fromRGB(160, 155, 180)
				desc.Font = Enum.Font.Gotham
				desc.TextScaled = true
				desc.TextXAlignment = Enum.TextXAlignment.Left
				desc.Parent = row

				local btn = Instance.new("TextButton")
				btn.AnchorPoint = Vector2.new(1, 0.5)
				btn.Position = UDim2.new(1, -10, 0.5, 0)
				btn.Size = UDim2.new(0.22, 0, 0, 36)
				btn.BackgroundColor3 = Color3.fromRGB(120, 80, 40)
				btn.TextColor3 = Color3.fromRGB(245, 240, 250)
				btn.Font = Enum.Font.GothamBold
				btn.TextScaled = true
				btn.Text = ""
				btn.Parent = row
				local bc = Instance.new("UICorner")
				bc.CornerRadius = UDim.new(0, 8)
				bc.Parent = btn

				btn.MouseButton1Click:Connect(function()
					if not profile then
						return
					end
					local owned = profile.cosmetics and profile.cosmetics[skin.id] == true
					local remote = if owned then Net.get("EquipSkin") else Net.get("BuySkin")
					local result = remote:InvokeServer(skin.id)
					if type(result) == "table" then
						if result.ok then
							if result.prompted then
								onMessage("Complete the purchase in the Roblox prompt.")
							elseif result.granted then
								onMessage(("Unlocked %s — press Equip"):format(skin.name))
							end
						else
							onMessage(result.err or "store error")
						end
					end
				end)
				rows[skin.id] = { button = btn, price = name }
			end
		end
	end
	gui = sg
	refreshRows()
end

function StoreUI.setProfile(p: any)
	profile = p
	refreshRows()
end

function StoreUI.toggle()
	if not gui then
		build()
	end
	local g = gui :: ScreenGui
	g.Enabled = not g.Enabled
	if g.Enabled then
		refreshRows()
	end
end

function StoreUI.start(messageSink: (string) -> ())
	onMessage = messageSink
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end
		if input.KeyCode == Enum.KeyCode.K then
			StoreUI.toggle()
		end
	end)
end

return StoreUI
