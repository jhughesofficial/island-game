extends Node

# Each identity dict:
# id, name, cover, flavor, bonus_label, accent_color
# bonus_type: "pi" | "money" | "click_mult" | "vip_discount"
# bonus_value: numeric value applied on new game
const IDENTITIES: Array = [
	{
		"id": "philanthropist",
		"name": "The Philanthropist",
		"cover": "Youth Development Foundation",
		"flavor": "Giving back has always been your passion.\nEspecially to causes that appreciate discretion.",
		"bonus_label": "+15 Political Influence",
		"bonus_type": "pi",
		"bonus_value": 15,
		"accent_color": Color(0.788, 0.659, 0.298, 1)  # gold
	},
	{
		"id": "financier",
		"name": "The Financier",
		"cover": "Hedge Fund Manager",
		"flavor": "Money is just math.\nYou're very good at math. Especially the undisclosed kind.",
		"bonus_label": "Start with $500",
		"bonus_type": "money",
		"bonus_value": 500.0,
		"accent_color": Color(0.75, 0.15, 0.15, 1)  # deep red
	},
	{
		"id": "tech_mogul",
		"name": "The Tech Mogul",
		"cover": "Disruptive Hospitality Technology",
		"flavor": "You're not buying an island.\nYou're building a platform. Party as a service.",
		"bonus_label": "Click value ×2",
		"bonus_type": "click_mult",
		"bonus_value": 2.0,
		"accent_color": Color(0.2, 0.5, 0.95, 1)  # electric blue
	},
	{
		"id": "diplomat",
		"name": "The Diplomat",
		"cover": "Retired Senior Official",
		"flavor": "Thirty years in government.\nYou know everyone. Everyone owes you something.",
		"bonus_label": "VIP costs −25%",
		"bonus_type": "vip_discount",
		"bonus_value": 0.75,
		"accent_color": Color(0.75, 0.85, 0.92, 1)  # silver-ice
	}
]
