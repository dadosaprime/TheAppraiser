--!strict
-- Central registry of RemoteEvents / RemoteFunctions.
-- The server creates the folder + instances at boot (see server/init.server.luau).
-- Both sides require this module and look remotes up by name, so there are no
-- stringly-typed FindFirstChild calls scattered across the codebase.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = {}

Net.FOLDER_NAME = "Remotes"

-- Fired client → server. { [name] = "RemoteEvent" | "RemoteFunction" }
Net.Definitions = {
	-- Client requests
	ActivateAbility = "RemoteEvent", -- client presses a hotbar key: { slot: number, target? }
	ChooseClass = "RemoteFunction", -- returns ok/err
	PurchaseBox = "RemoteFunction", -- buy the next Soul-rank box with shards
	PurchasePerk = "RemoteFunction", -- buy the next rank of a tree
	RequestProfile = "RemoteFunction", -- initial state sync
	BuySkin = "RemoteFunction", -- store: buy a skin (prompts Robux, or free-grants in playtest)
	EquipSkin = "RemoteFunction", -- store: equip/unequip an owned skin

	-- Server → client
	ProfileUpdated = "RemoteEvent", -- pushes a fresh PlayerProfile
	AbilityFeedback = "RemoteEvent", -- cooldowns, cast confirmations, errors
	CombatEvent = "RemoteEvent", -- damage numbers, downs, revives (for HUD/VFX)
	Toast = "RemoteEvent", -- short player-facing messages (rank-up, etc.)
	StatusUpdated = "RemoteEvent", -- transient combat status: fury, shifted, etc.
}

-- Resolve the remotes folder (waits on the client, must exist on the server).
function Net.folder(): Folder
	local existing = ReplicatedStorage:FindFirstChild(Net.FOLDER_NAME)
	if existing then
		return existing :: Folder
	end
	-- On the client this can race with server creation; wait.
	return ReplicatedStorage:WaitForChild(Net.FOLDER_NAME) :: Folder
end

function Net.get(name: string): RemoteEvent | RemoteFunction
	local remote = Net.folder():WaitForChild(name)
	return remote :: any
end

-- Server-only: create the folder and every declared remote once at boot.
function Net.build(): Folder
	local folder = ReplicatedStorage:FindFirstChild(Net.FOLDER_NAME)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = Net.FOLDER_NAME
		folder.Parent = ReplicatedStorage
	end
	for name, className in Net.Definitions do
		if not folder:FindFirstChild(name) then
			local remote = Instance.new(className)
			remote.Name = name
			remote.Parent = folder
		end
	end
	return folder :: Folder
end

return Net
