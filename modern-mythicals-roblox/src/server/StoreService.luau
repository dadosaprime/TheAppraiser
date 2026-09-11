--!strict
-- The skin store. Real path: Roblox Developer Products — the client asks to
-- buy, the server prompts Robux, Roblox calls ProcessReceipt, we grant. Test
-- path (GameConfig.Playtest.FreeSkins, or a skin with no product id yet):
-- grant immediately so the flow can be exercised before the game is published.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage").Shared
local Net = require(Shared.Net)
local Skins = require(Shared.Skins)
local GameConfig = require(Shared.GameConfig)

local DataService = require(script.Parent.DataService)
local ProgressionService = require(script.Parent.ProgressionService)
local CosmeticService = require(script.Parent.CosmeticService)

local StoreService = {}

local function grant(player: Player, skinId: string): boolean
	local profile = DataService.get(player)
	local skin = Skins.get(skinId)
	if not profile or not skin then
		return false
	end
	if profile.cosmetics[skinId] then
		return true
	end
	profile.cosmetics[skinId] = true
	DataService.markDirty(player)
	ProgressionService._push(player, profile)
	Net.get("Toast"):FireClient(player, ("Unlocked: %s"):format(skin.name))
	return true
end

-- Roblox calls this for every Developer Product purchase. Must be idempotent.
local function processReceipt(receipt: any): Enum.ProductPurchaseDecision
	local player = Players:GetPlayerByUserId(receipt.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet -- retried on next join
	end
	local skin = Skins.byProduct(receipt.ProductId)
	if not skin then
		warn("[Store] receipt for unknown product", receipt.ProductId)
		return Enum.ProductPurchaseDecision.PurchaseGranted -- don't charge forever for a dead product
	end
	if not DataService.get(player) then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	return if grant(player, skin.id) then Enum.ProductPurchaseDecision.PurchaseGranted
		else Enum.ProductPurchaseDecision.NotProcessedYet
end

function StoreService.init()
	MarketplaceService.ProcessReceipt = processReceipt

	-- method: "cash" spends in-game Cash; anything else is the Robux path.
	Net.get("BuySkin").OnServerInvoke = function(player, skinId, method)
		if type(skinId) ~= "string" then
			return { ok = false, err = "bad skin" }
		end
		local profile = DataService.get(player)
		local skin = Skins.get(skinId)
		if not profile or not skin then
			return { ok = false, err = "unknown skin" }
		end
		if not Skins.fitsClass(skin, profile.class) then
			return { ok = false, err = ("%s is for the %s"):format(skin.name, skin.class or "?") }
		end
		if profile.cosmetics[skinId] then
			return { ok = true, owned = true }
		end
		if method == "cash" then
			if profile.cash < skin.cashPrice then
				return { ok = false, err = ("Need $%d — you have $%d"):format(skin.cashPrice, profile.cash) }
			end
			profile.cash -= skin.cashPrice
			DataService.markDirty(player)
			grant(player, skinId)
			return { ok = true, granted = true, spent = skin.cashPrice }
		end
		if skin.devProductId > 0 and not GameConfig.Playtest.FreeSkins then
			MarketplaceService:PromptProductPurchase(player, skin.devProductId)
			return { ok = true, prompted = true }
		end
		-- Playtest / no product yet: free grant.
		grant(player, skinId)
		return { ok = true, granted = true }
	end

	Net.get("EquipSkin").OnServerInvoke = function(player, skinId)
		local profile = DataService.get(player)
		if not profile then
			return { ok = false, err = "profile not loaded" }
		end
		profile.equipped = profile.equipped or {}
		if skinId == nil or skinId == "" then
			return { ok = false, err = "no skin" }
		end
		if type(skinId) ~= "string" then
			return { ok = false, err = "bad skin" }
		end
		local skin = Skins.get(skinId)
		if not skin then
			return { ok = false, err = "unknown skin" }
		end
		if not profile.cosmetics[skinId] then
			return { ok = false, err = "not owned" }
		end
		if not Skins.fitsClass(skin, profile.class) then
			return { ok = false, err = "wrong class" }
		end
		-- Toggle: equipping the equipped skin unequips it.
		if profile.equipped[skin.category] == skinId then
			profile.equipped[skin.category] = nil
		else
			profile.equipped[skin.category] = skinId
		end
		DataService.markDirty(player)
		ProgressionService._push(player, profile)
		CosmeticService.apply(player)
		return { ok = true, equipped = profile.equipped[skin.category] == skinId }
	end
end

return StoreService
