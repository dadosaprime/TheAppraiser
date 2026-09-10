--!strict
-- Client bootstrap. Builds the HUD, starts hotbar input, and keeps the HUD in
-- sync with server-pushed profile updates. Rojo turns this into a LocalScript
-- under StarterPlayerScripts.Client.

local Shared = game:GetService("ReplicatedStorage").Shared
local Net = require(Shared.Net)

local HUD = require(script.HUD)
local HotbarController = require(script.HotbarController)

HUD.build()
HotbarController.start()

-- Route ability feedback to the HUD.
HotbarController.onFeedback = function(slot, feedback)
	HUD.flashSlot(slot, feedback)
end

-- Live profile updates.
Net.get("ProfileUpdated").OnClientEvent:Connect(function(profile)
	HUD.update(profile)
end)

-- Initial sync (in case the push happened before we connected).
task.spawn(function()
	local profile = Net.get("RequestProfile"):InvokeServer()
	if profile then
		HUD.update(profile)
	end
end)

print("[ModernMythicals] Client started.")
