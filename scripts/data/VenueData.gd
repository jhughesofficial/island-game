extends Node

# Each venue dict:
# id, name, base_cost, base_income_per_sec, heat_per_sec, flavor, sprite_path
const VENUES: Array = [
	{
		"id": "bonfire",
		"name": "Beach Bonfire",
		"base_cost": 10.0,
		"base_income": 0.1,
		"heat_rate": 0.001,
		"flavor": "A modest gathering. BYOB.",
		"sprite": ""
	},
	{
		"id": "yacht",
		"name": "Luxury Yacht",
		"base_cost": 150.0,
		"base_income": 0.5,
		"heat_rate": 0.005,
		"flavor": "The ocean hides many things.",
		"sprite": ""
	},
	{
		"id": "villa",
		"name": "Private Villa",
		"base_cost": 1000.0,
		"base_income": 3.0,
		"heat_rate": 0.01,
		"flavor": "Rooms with no cameras.",
		"sprite": ""
	},
	{
		"id": "jet",
		"name": "Private Jet",
		"base_cost": 10000.0,
		"base_income": 15.0,
		"heat_rate": 0.02,
		"flavor": "Travel discreetly.",
		"sprite": ""
	},
	{
		"id": "offshore",
		"name": "Offshore Account",
		"base_cost": 75000.0,
		"base_income": 80.0,
		"heat_rate": 0.03,
		"flavor": "Money that doesn't exist.",
		"sprite": ""
	},
	{
		"id": "shell",
		"name": "Shell Corporation",
		"base_cost": 300000.0,  # was 400k; gap from Offshore ($75k) was 5.3x, now 4x — more digestible
		"base_income": 300.0,
		"heat_rate": 0.05,
		"flavor": "Technically legal.",
		"sprite": ""
	},
	{
		"id": "political",
		"name": "Political Connections",
		"base_cost": 2000000.0,
		"base_income": 1200.0,
		"heat_rate": 0.08,
		"flavor": "Friends in high places.",
		"sprite": ""
	},
	{
		"id": "blackout",
		"name": "Media Blackout",
		"base_cost": 10000000.0,  # was 15M; gap from Political Connections ($2M) was 7.5x, now 5x — still feels earned
		"base_income": 5000.0,
		"heat_rate": -0.05,
		"flavor": "Nothing happened here.",
		"sprite": ""
	}
]

# Cost of the Nth copy of a venue: base_cost * COST_SCALE ^ owned
const COST_SCALE: float = 1.15

func get_cost(venue: Dictionary, owned: int) -> float:
	return venue.base_cost * pow(COST_SCALE, owned)

# Quantity tier multipliers: owning 10/25/50/100 doubles output
func get_quantity_multiplier(owned: int) -> float:
	var mult: float = 1.0
	if owned >= 10: mult *= 2.0
	if owned >= 25: mult *= 2.0
	if owned >= 50: mult *= 2.0
	if owned >= 100: mult *= 2.0
	return mult
