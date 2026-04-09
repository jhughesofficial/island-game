extends Control

@onready var close_btn: Button = $Panel/VBoxContainer/HeaderRow/CloseBtn
@onready var scroll: ScrollContainer = $Panel/VBoxContainer/ScrollContainer

const HELP_TEXT := """HOW TO PLAY

Welcome to The Island — an exclusive private resort where discretion is everything and money flows freely.

─────────────────────────

EARNING MONEY

Click THROW PARTY to host events and collect earnings directly. As your operation grows, your click value scales with your passive income — every venue you build makes each party worth more.

─────────────────────────

VENUES

Purchase venues from the Venues tab to generate passive income automatically. Unlock higher-tier venues by expanding your portfolio. Owning multiples of the same venue increases output.

Use the ×1 / ×10 / ×100 / MAX buttons to buy in bulk.

─────────────────────────

STAFF

Hire staff from the Staff tab to throw parties on your behalf. Each hire generates automatic clicks — no button required. The more you employ, the faster money flows.

─────────────────────────

UPGRADES

The Upgrades tab unlocks improvements as your lifetime earnings grow. Upgrades multiply your income and click value permanently. New ones reveal themselves as your operation expands.

─────────────────────────

VIPs

Certain high-profile individuals can be invited to the island. Each brings unique benefits — income multipliers, political connections, and the occasional problem quietly resolved. Recruit them from the VIPs tab when they become available.

─────────────────────────

THE HEAT METER

Five stars. Every venue generates attention. If heat reaches maximum and stays there for 60 seconds, the authorities close in and your story ends badly.

Some upgrades and VIPs reduce heat. Don't ignore it.

─────────────────────────

POLITICAL INFLUENCE (PI)

PI represents your insurance. It never decreases, never gets spent — it simply accumulates. VIPs award PI when recruited. The higher your PI, the more options you have when things get complicated.

─────────────────────────

ENDINGS

There are three ways your story ends. How it concludes depends entirely on how you've played.

─────────────────────────

SECRETS

Keep an eye on the island. Sometimes things appear that weren't there before. Click them quickly — they don't stay long.

─────────────────────────

TIPS

  • Build passive income before spending on upgrades
  • Recruit VIPs early — their multipliers compound
  • Don't let heat sit at maximum
  • The news ticker tells you more than you think
  • PI is your safety net. Build it.
"""

@onready var help_label: Label = $Panel/VBoxContainer/ScrollContainer/HelpLabel

func _ready() -> void:
	help_label.text = HELP_TEXT
	close_btn.pressed.connect(func(): hide())

func show_panel() -> void:
	show()
	scroll.scroll_vertical = 0
