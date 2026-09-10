--!strict
-- Hotbar input. One tree, one button — keys 1..5 map straight to ability slots.
-- The client only REQUESTS activation; the server is authoritative (see AbilityService).

local UserInputService = game:GetService("UserInputService")

local Shared = game:GetService("ReplicatedStorage").Shared
local Net = require(Shared.Net)

local HotbarController = {}

local KEY_TO_SLOT: { [Enum.KeyCode]: number } = {
	[Enum.KeyCode.One] = 1,
	[Enum.KeyCode.Two] = 2,
	[Enum.KeyCode.Three] = 3,
	[Enum.KeyCode.Four] = 4,
	[Enum.KeyCode.Five] = 5,
}

-- Optional: called with (slot, feedback) so the HUD can flash cooldowns/errors.
HotbarController.onFeedback = function(_slot: number, _feedback: any) end

function HotbarController.start()
	local activate = Net.get("ActivateAbility")

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end
		local slot = KEY_TO_SLOT[input.KeyCode]
		if slot then
			-- Target resolution (mouse hit / lock-on) can be added here later.
			activate:FireServer({ slot = slot, target = nil })
		end
	end)

	Net.get("AbilityFeedback").OnClientEvent:Connect(function(feedback)
		if type(feedback) == "table" and feedback.slot then
			HotbarController.onFeedback(feedback.slot, feedback)
		end
	end)
end

return HotbarController
