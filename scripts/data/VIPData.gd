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
	}
]
