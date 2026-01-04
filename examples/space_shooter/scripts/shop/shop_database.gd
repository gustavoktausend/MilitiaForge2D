## Shop Database
##
## Contains all available shop items with their prices and effects.
## Items are hardcoded here and loaded by ShopUI.

class_name ShopDatabase

#region Private Variables
static var _all_items: Array[ShopItem] = []
static var _initialized: bool = false
#endregion

#region Initialization
static func initialize() -> void:
	"""Initialize shop items database (call once at startup)"""
	if _initialized:
		return

	_all_items.clear()

	# ========================================
	# TIER 1: Basic Upgrades (Stackable)
	# ========================================

	_all_items.append(ShopItem.new(
		"health_boost",
		"Health Boost",
		"Increase max health by 10 HP",
		50,    # cost
		"💚",  # icon
		ShopItem.Category.TIER1,
		10,    # max stacks
		"health",
		10.0   # +10 HP
	))

	_all_items.append(ShopItem.new(
		"damage_boost",
		"Damage Boost",
		"Increase damage by 5%",
		75,    # cost
		"💥",  # icon
		ShopItem.Category.TIER1,
		10,    # max stacks
		"damage",
		0.05   # +5% damage
	))

	_all_items.append(ShopItem.new(
		"fire_rate",
		"Fire Rate",
		"Increase fire rate by 10%",
		100,   # cost
		"⚡",  # icon
		ShopItem.Category.TIER1,
		5,     # max stacks
		"fire_rate",
		0.10   # +10% fire rate
	))

	_all_items.append(ShopItem.new(
		"speed_boost",
		"Speed Boost",
		"Increase movement speed by 5%",
		60,    # cost
		"💨",  # icon
		ShopItem.Category.TIER1,
		5,     # max stacks
		"speed",
		0.05   # +5% speed
	))

	_all_items.append(ShopItem.new(
		"pickup_range",
		"Magnet",
		"Increase pickup range by 20%",
		80,    # cost
		"🧲",  # icon
		ShopItem.Category.TIER1,
		3,     # max stacks
		"pickup_range",
		0.20   # +20% range
	))

	# ========================================
	# TIER 2: Advanced Upgrades (Limited)
	# ========================================

	_all_items.append(ShopItem.new(
		"piercing",
		"Piercing Shots",
		"Bullets pierce 1 additional enemy",
		200,   # cost
		"🔷",  # icon
		ShopItem.Category.TIER2,
		3,     # max stacks
		"piercing",
		1.0    # +1 pierce
	))

	_all_items.append(ShopItem.new(
		"homing",
		"Homing",
		"Projectiles home towards enemies",
		250,   # cost
		"🎯",  # icon
		ShopItem.Category.TIER2,
		1,     # max stacks (one-time unlock)
		"homing",
		1.0    # enable homing
	))

	_all_items.append(ShopItem.new(
		"regeneration",
		"Regeneration",
		"Restore 1 HP per second",
		300,   # cost
		"💗",  # icon
		ShopItem.Category.TIER2,
		1,     # max stacks
		"regen",
		1.0    # +1 HP/s
	))

	_all_items.append(ShopItem.new(
		"lucky_charm",
		"Lucky Charm",
		"Increase drop rate by 10%",
		150,   # cost
		"🍀",  # icon
		ShopItem.Category.TIER2,
		3,     # max stacks
		"drop_rate",
		0.10   # +10% drop rate
	))

	_all_items.append(ShopItem.new(
		"projectile_size",
		"Bigger Bullets",
		"Increase projectile size by 15%",
		120,   # cost
		"⚪",  # icon
		ShopItem.Category.TIER2,
		3,     # max stacks
		"projectile_size",
		0.15   # +15% size
	))

	# ========================================
	# TIER 3: Special Upgrades (Very Limited)
	# ========================================

	_all_items.append(ShopItem.new(
		"extra_life",
		"Extra Life",
		"Revive once upon death",
		500,   # cost
		"👼",  # icon
		ShopItem.Category.TIER3,
		2,     # max stacks
		"extra_life",
		1.0    # +1 life
	))

	_all_items.append(ShopItem.new(
		"iframe_duration",
		"I-Frame Boost",
		"Increase invincibility time by 0.2s",
		180,   # cost
		"🛡️",  # icon
		ShopItem.Category.TIER3,
		3,     # max stacks
		"iframe",
		0.2    # +0.2s
	))

	# ========================================
	# CONSUMABLES: Single-use buffs
	# ========================================

	_all_items.append(ShopItem.new(
		"shield_consumable",
		"Shield",
		"Temporary shield for 1 wave",
		100,   # cost
		"🔰",  # icon
		ShopItem.Category.CONSUMABLE,
		-1,    # unlimited purchases
		"shield_buff",
		1.0    # 1 wave duration
	))

	_all_items.append(ShopItem.new(
		"score_multiplier",
		"Score Boost",
		"2× score for next 2 waves",
		150,   # cost
		"⭐",  # icon
		ShopItem.Category.CONSUMABLE,
		-1,    # unlimited purchases
		"score_mult",
		2.0    # 2× multiplier
	))

	_all_items.append(ShopItem.new(
		"rapid_fire_buff",
		"Rapid Fire",
		"3× fire rate for 1 wave",
		200,   # cost
		"🔥",  # icon
		ShopItem.Category.CONSUMABLE,
		-1,    # unlimited purchases
		"rapid_fire",
		3.0    # 3× fire rate
	))

	_initialized = true
	print("[ShopDatabase] Initialized with %d items" % _all_items.size())
#endregion

#region Public Methods
static func get_all_items() -> Array[ShopItem]:
	"""Get all shop items"""
	if not _initialized:
		initialize()
	return _all_items

static func get_items_by_category(category: ShopItem.Category) -> Array[ShopItem]:
	"""Get all items in a specific category"""
	if not _initialized:
		initialize()

	var filtered: Array[ShopItem] = []
	for item in _all_items:
		if item.category == category:
			filtered.append(item)
	return filtered

static func get_item_by_id(item_id: String) -> ShopItem:
	"""Get specific item by ID"""
	if not _initialized:
		initialize()

	for item in _all_items:
		if item.id == item_id:
			return item

	push_warning("[ShopDatabase] Item not found: %s" % item_id)
	return null

static func reset_all_purchases() -> void:
	"""Reset all purchase counts (called on new game)"""
	if not _initialized:
		initialize()

	for item in _all_items:
		item.reset_purchases()

	print("[ShopDatabase] All purchases reset")
#endregion
