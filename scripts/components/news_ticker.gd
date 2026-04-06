extends PanelContainer

# Act 1 headlines — innocent party host framing
const ACT1_HEADLINES: Array[String] = [
	"LOCAL PHILANTHROPIST HOSTS RECORD-BREAKING FUNDRAISER ON PRIVATE ISLAND",
	"EXCLUSIVE RESORT ATTRACTS HIGH-PROFILE GUESTS FROM ACROSS THE GLOBE",
	"ISLAND GETAWAY BECOMES HOT TICKET FOR ELITE NETWORKING EVENTS",
	"PRIVATE VENUE SEES SURGE IN BOOKINGS AS WORD SPREADS AMONG THE WELL-CONNECTED",
	"SOCIALITE CIRCLES BUZZ OVER MYSTERY HOST'S LEGENDARY HOSPITALITY",
	"FINANCIER'S ISLAND PARTIES DESCRIBED AS 'ONCE IN A LIFETIME' BY ATTENDEES",
	"OFFSHORE ACCOUNTS SHOW STRONG RETURNS AS RESORT EXPANSION CONTINUES",
	"GUEST LIST GROWS AS MORE PROMINENT FIGURES SEEK INVITATIONS",
	"ISLAND INFRASTRUCTURE INVESTMENT DRAWS PRAISE FROM REGIONAL ECONOMISTS",
	"PROMINENT POLITICAL FIGURE SPOTTED VACATIONING AT EXCLUSIVE ISLAND ESTATE",
	"LUXURY YACHT FLEET EXPANDED TO ACCOMMODATE GROWING VIP CLIENTELE",
	"PRIVATE JET ARRIVALS UP 300% — ISLAND HOST BECOMES SOUGHT-AFTER DESTINATION",
]

@onready var ticker_label: Label = $MarginContainer/TickerLabel

var _current_index: int = 0
var _scroll_x: float = 0.0
var _speed: float = 80.0  # pixels per second

func _ready() -> void:
	_current_index = randi() % ACT1_HEADLINES.size()
	ticker_label.text = "  ★  " + ACT1_HEADLINES[_current_index] + "  ★  " + ACT1_HEADLINES[(_current_index + 1) % ACT1_HEADLINES.size()]
	_scroll_x = 0.0

func _process(delta: float) -> void:
	_scroll_x -= _speed * delta
	ticker_label.position.x = _scroll_x
	# When the first headline has fully scrolled off, advance and reset
	if _scroll_x < -ticker_label.size.x * 0.5:
		_current_index = (_current_index + 1) % ACT1_HEADLINES.size()
		ticker_label.text = "  ★  " + ACT1_HEADLINES[_current_index] + "  ★  " + ACT1_HEADLINES[(_current_index + 1) % ACT1_HEADLINES.size()]
		_scroll_x = 0.0
