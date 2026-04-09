extends Node

# Each secret dict:
# id, label_text, reward_type ("money" / "pi" / "heat_reduce"), reward_value, weight
#
# reward_value semantics:
#   money      -> multiplier of lifetime_money (e.g. 0.05 = 5%), floored at 500
#   pi         -> flat PI points added
#   heat_reduce -> flat heat reduction (subtracted from current heat)

const SECRETS: Array = [
	{
		"id": "encrypted_drive",
		"label_text": "🔒 Encrypted Drive Found",
		"reward_type": "money",
		"reward_value": 0.05,
		"weight": 10
	},
	{
		"id": "guest_list",
		"label_text": "📋 The Guest List",
		"reward_type": "pi",
		"reward_value": 15,
		"weight": 12
	},
	{
		"id": "unscheduled_flight",
		"label_text": "✈️ Unscheduled Flight",
		"reward_type": "money",
		"reward_value": 0.03,
		"weight": 10
	},
	{
		"id": "compromising_photos",
		"label_text": "📸 Compromising Photos",
		"reward_type": "pi",
		"reward_value": 25,
		"weight": 6
	},
	{
		"id": "pharmacy_delivery",
		"label_text": "💊 Pharmacy Delivery",
		"reward_type": "heat_reduce",
		"reward_value": 0.5,
		"weight": 8
	},
	{
		"id": "untraceable_call",
		"label_text": "📞 Untraceable Call",
		"reward_type": "pi",
		"reward_value": 10,
		"weight": 14
	},
	{
		"id": "wire_transfer",
		"label_text": "🏦 Wire Transfer",
		"reward_type": "money",
		"reward_value": 0.07,
		"weight": 7
	},
	{
		"id": "sealed_document",
		"label_text": "🗂️ Sealed Document",
		"reward_type": "pi",
		"reward_value": 20,
		"weight": 9
	},
	{
		"id": "offshore_account",
		"label_text": "🌊 Offshore Account",
		"reward_type": "money",
		"reward_value": 0.04,
		"weight": 10
	},
	{
		"id": "immunity_deal",
		"label_text": "🤝 Immunity Deal",
		"reward_type": "heat_reduce",
		"reward_value": 1.0,
		"weight": 4
	},
]

func pick_weighted() -> Dictionary:
	var total_weight: int = 0
	for s in SECRETS:
		total_weight += s.weight
	var roll: int = randi() % total_weight
	var acc: int = 0
	for s in SECRETS:
		acc += s.weight
		if roll < acc:
			return s
	return SECRETS[0]
