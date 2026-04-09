extends Node

# Each upgrade dict:
# id, name, cost, type ("click" or venue id or "heat_suppress"), multiplier, unlock_at (lifetime $), flavor
const UPGRADES: Array = [
	{
		"id": "champagne",
		"name": "Champagne Toast",
		"cost": 60.0,  # was 100; unlocks at $50 lifetime so player only has ~$50 cash — $60 is reachable in ~1 extra min
		"type": "click",
		"multiplier": 2.0,
		"unlock_at": 50.0,
		"flavor": "The good stuff."
	},
	{
		"id": "open_bar",
		"name": "Open Bar",
		"cost": 5000.0,
		"type": "click",
		"multiplier": 3.0,
		"unlock_at": 2000.0,
		"flavor": "Keep them drinking."
	},
	{
		"id": "live_dj",
		"name": "Live DJ",
		"cost": 50000.0,
		"type": "click",
		"multiplier": 5.0,
		"unlock_at": 20000.0,
		"flavor": "Discretion not included."
	},
	{
		"id": "fireworks",
		"name": "Fireworks",
		"cost": 500000.0,
		"type": "click",
		"multiplier": 10.0,
		"unlock_at": 200000.0,
		"flavor": "Nobody asks questions during fireworks."
	},
	{
		"id": "bonfire_upgrade",
		"name": "Better Kindling",
		"cost": 200.0,
		"type": "bonfire",
		"multiplier": 2.0,
		"unlock_at": 100.0,
		"flavor": "Burns longer, talks less."
	},
	{
		"id": "yacht_upgrade",
		"name": "International Waters",
		"cost": 3000.0,
		"type": "yacht",
		"multiplier": 2.0,
		"unlock_at": 1500.0,
		"flavor": "Different rules out here."
	},
	{
		"id": "villa_upgrade",
		"name": "Security System",
		"cost": 20000.0,
		"type": "villa",
		"multiplier": 2.0,
		"unlock_at": 10000.0,
		"flavor": "The cameras face outward."
	},
	{
		"id": "jet_upgrade",
		"name": "Unregistered Flight Plan",
		"cost": 200000.0,
		"type": "jet",
		"multiplier": 2.0,
		"unlock_at": 100000.0,
		"flavor": "Logged nowhere."
	},
	{
		"id": "legal_retainer",
		"name": "Legal Retainer",
		"cost": 50000.0,
		"type": "heat_suppress",
		"multiplier": 1.0,
		"unlock_at": 25000.0,
		"flavor": "He's very good at making things go away."
	},
	{
		"id": "hush_money",
		"name": "Hush Money",
		"cost": 500000.0,
		"type": "heat_suppress",
		"multiplier": 1.0,
		"unlock_at": 250000.0,
		"flavor": "A generous gift. No receipt."
	}
]
