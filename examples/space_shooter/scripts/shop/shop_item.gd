## Shop Item Data Class
##
## Represents a purchasable item in the shop.
## Contains all metadata needed for display and purchase logic.

class_name ShopItem

#region Enums
enum Category {
	TIER1,      # Basic upgrades (Health, Damage, Fire Rate, Speed)
	TIER2,      # Advanced upgrades (Piercing, Homing, Regen)
	TIER3,      # Special upgrades (Extra Life, etc.)
	CONSUMABLE  # Single-use buffs (Shield, Score 2x, etc.)
}
#endregion

#region Properties
var id: String                    # Unique identifier (e.g., "health_boost")
var display_name: String          # Display name (e.g., "Health Boost")
var description: String           # What it does
var cost: int                     # Credit cost
var icon: String                  # Icon identifier or emoji
var category: Category            # Which tab in shop
var max_purchases: int            # How many times can buy (-1 = unlimited)
var current_purchases: int = 0    # How many already purchased this run
var effect_id: String             # Identifier for UpgradeManager to apply effect
var effect_value: float           # Value to pass to effect (e.g., +10 health, +5% damage)
#endregion

#region Constructor
func _init(
	p_id: String,
	p_name: String,
	p_description: String,
	p_cost: int,
	p_icon: String,
	p_category: Category,
	p_max_purchases: int,
	p_effect_id: String,
	p_effect_value: float
) -> void:
	id = p_id
	display_name = p_name
	description = p_description
	cost = p_cost
	icon = p_icon
	category = p_category
	max_purchases = p_max_purchases
	effect_id = p_effect_id
	effect_value = p_effect_value
	current_purchases = 0
#endregion

#region Public Methods
func can_purchase() -> bool:
	"""Check if item can still be purchased (not at max stack)"""
	if max_purchases == -1:
		return true  # Unlimited
	return current_purchases < max_purchases

func get_stack_text() -> String:
	"""Get stack display text (e.g., '3/10' or 'MAX')"""
	if max_purchases == -1:
		return "∞"
	if current_purchases >= max_purchases:
		return "MAX"
	return "%d/%d" % [current_purchases, max_purchases]

func increment_purchases() -> void:
	"""Increment purchase count"""
	current_purchases += 1

func reset_purchases() -> void:
	"""Reset purchase count (called on new game)"""
	current_purchases = 0

func is_maxed() -> bool:
	"""Check if item is maxed out"""
	if max_purchases == -1:
		return false
	return current_purchases >= max_purchases
#endregion
