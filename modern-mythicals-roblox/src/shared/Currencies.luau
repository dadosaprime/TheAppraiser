--!strict
-- Three currencies, three distinct jobs. (Design doc § III.)
local Types = require(script.Parent.Types)

export type CurrencyDef = {
	id: Types.CurrencyId,
	displayName: string,
	source: string,
	buys: string,
	sellableForRobux: boolean,
}

local Currencies: { [Types.CurrencyId]: CurrencyDef } = {
	SoulShards = {
		id = "SoulShards",
		displayName = "Soul Shards",
		source = "Earned only — never sold for Robux",
		buys = "Soul-rank boxes and perk ranks (from the same pool)",
		sellableForRobux = false,
	},

	Cash = {
		id = "Cash",
		displayName = "Cash",
		source = "Enemy drops, quest rewards",
		buys = "Consumables, one-use items, gear from the antique shop",
		sellableForRobux = false,
	},

	Robux = {
		id = "Robux",
		displayName = "Robux",
		source = "Purchased",
		-- Robux buys ACCESS to crossover trees (variety), plus cosmetics,
		-- limited stock, and convenience — never raw stats. Stats normalize
		-- inside PvP so a spender brings options, not power.
		buys = "Cosmetics, limited items, crossover-tree access, character slots",
		sellableForRobux = false,
	},
}

return Currencies
