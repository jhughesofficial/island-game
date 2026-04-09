extends Node

# Each VIP dict:
# id, name, appears_at (lifetime $), cost, earnings_multiplier, pi_award, flavor, secondary_effect
const VIPS: Array = [
	{
		"id": "guest",
		"name": "The Guest",
		"appears_at": 1000.0,
		"cost": 500.0,
		"multiplier": 1.5,
		"pi_award": 5,
		"flavor": "A friend of a friend.",
		"effect": "none"
	},
	{
		"id": "litigator",
		"name": "The Litigator",
		"appears_at": 10000.0,
		"cost": 5000.0,
		"multiplier": 2.0,
		"pi_award": 15,
		"flavor": "He prefers cash.",
		"effect": "heat_reduce_1"
	},
	{
		"id": "president",
		"name": "The Former President",
		"appears_at": 100000.0,
		"cost": 50000.0,
		"multiplier": 3.0,
		"pi_award": 40,
		"flavor": "Attended for policy reasons.",
		"effect": "heat_suppress"
	},
	{
		"id": "merchant",
		"name": "The Merchant Prince",
		"appears_at": 500000.0,
		"cost": 250000.0,
		"multiplier": 4.0,
		"pi_award": 80,
		"flavor": "His lawyers are on retainer.",
		"effect": "none"
	},
	{
		"id": "academic",
		"name": "The Academic",
		"appears_at": 5000000.0,
		"cost": 2500000.0,  # was 3M (60% of threshold); now 50% — consistent with early VIP cost pattern
		"multiplier": 1.4,
		"pi_award": 20,
		"flavor": "Lends credibility. Asks no questions.",
		"effect": ""
	},
	{
		"id": "socialite",
		"name": "The Socialite",
		"appears_at": 15000000.0,
		"cost": 8000000.0,
		"multiplier": 1.6,
		"pi_award": 25,
		"flavor": "Everyone wants to meet her. She arranges it.",
		"effect": ""
	},
	{
		"id": "general",
		"name": "The General",
		"appears_at": 30000000.0,
		"cost": 15000000.0,  # was 20M (67% of threshold); now 50% — player needs cash reserves for venues too
		"multiplier": 1.8,
		"pi_award": 35,
		"flavor": "National security is a flexible concept.",
		"effect": "heat_reduce_2"
	},
	{
		"id": "sovereign",
		"name": "The Sovereign",
		"appears_at": 40000000.0,  # was 80M — arrest reveal triggers at $50M, so Sovereign must appear BEFORE that crunch
		"cost": 20000000.0,        # was 50M (63% of old threshold); now 50% of new threshold — still a major purchase
		"multiplier": 2.5,
		"pi_award": 50,
		"flavor": "Diplomatic immunity. For everyone.",
		"effect": "heat_reduce_3"
	}
]
