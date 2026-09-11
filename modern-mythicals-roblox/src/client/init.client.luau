--!strict
-- Client bootstrap. Builds the HUD, starts hotbar input, shows the class-select
-- screen until a class exists, and keeps everything in sync with server-pushed
-- profile updates. Rojo turns this into a LocalScript under StarterPlayerScripts.Client.

local Shared = game:GetService("ReplicatedStorage").Shared
local Net = require(Shared.Net)
local Classes = require(Shared.Classes)

local HUD = require(script.HUD)
local HotbarController = require(script.HotbarController)
local ClassSelect = require(script.ClassSelect)
local StoreUI = require(script.StoreUI)

HUD.build()
HotbarController.start()
StoreUI.start(HUD.toast)

HotbarController.onFeedback = function(slot, feedback)
	HUD.flashSlot(slot, feedback)
	if not feedback.ok and feedback.err then
		HUD.toast(feedback.err)
	end
end
HotbarController.onMessage = HUD.toast

local function applyProfile(profile: any)
	if not profile then
		return
	end
	HUD.update(profile)
	StoreUI.setProfile(profile)
	HotbarController.currentClass = profile.class
	local cls = profile.class and Classes.get(profile.class)
	HotbarController.attackSlot = if cls then table.find(cls.trees, cls.attackTree) else nil
	if profile.class == nil then
		ClassSelect.show(function(id)
			HUD.toast(("You are a %s."):format(id))
		end)
	else
		ClassSelect.hide()
	end
end

Net.get("ProfileUpdated").OnClientEvent:Connect(applyProfile)
Net.get("StatusUpdated").OnClientEvent:Connect(HUD.setStatus)
Net.get("Toast").OnClientEvent:Connect(function(msg)
	if type(msg) == "string" then
		HUD.toast(msg)
	end
end)

-- Initial sync (in case the push happened before we connected).
task.spawn(function()
	applyProfile(Net.get("RequestProfile"):InvokeServer())
end)

print("[ModernMythicals] Client started.")
