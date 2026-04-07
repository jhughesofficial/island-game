extends Node

# Each staff dict: id, name, flavor, base_cost, cost_growth, clicks_per_second
const STAFF: Array = [
	{
		"id": "intern",
		"name": "The Intern",
		"flavor": "Eager. Disposable.",
		"base_cost": 50.0,
		"cost_growth": 1.12,
		"clicks_per_second": 0.5
	},
	{
		"id": "fixer",
		"name": "The Fixer",
		"flavor": "Problems disappear. So do witnesses.",
		"base_cost": 750.0,
		"cost_growth": 1.13,
		"clicks_per_second": 2.0
	},
	{
		"id": "coordinator",
		"name": "The Coordinator",
		"flavor": "Runs the parties you never attend.",
		"base_cost": 8000.0,
		"cost_growth": 1.14,
		"clicks_per_second": 8.0
	},
	{
		"id": "handler",
		"name": "The Handler",
		"flavor": "Everyone on the island answers to them.",
		"base_cost": 80000.0,
		"cost_growth": 1.15,
		"clicks_per_second": 30.0
	},
]

func get_cost(staff: Dictionary, count: int) -> float:
	return staff.base_cost * pow(staff.cost_growth, count)
