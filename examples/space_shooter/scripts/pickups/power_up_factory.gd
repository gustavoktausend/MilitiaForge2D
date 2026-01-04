## Power-Up Factory
##
## Factory pattern for creating power-ups with weighted random selection.
## Used by enemy_base.gd to spawn drops.
## Pure static utility class - does not extend Node.

class_name PowerUpFactory

#region Preloaded Scripts
const HealthPickup = preload("res://examples/space_shooter/scripts/pickups/health_pickup.gd")
const CreditGem = preload("res://examples/space_shooter/scripts/pickups/credit_gem.gd")
const AmmoRefill = preload("res://examples/space_shooter/scripts/pickups/ammo_refill.gd")
#endregion

#region Drop Rates (must sum to 100)
const DROP_RATES = {
	"health": 40.0,           # 40% - Health restore
	"shield": 0.0,            # TODO: Not implemented yet
	"ammo": 20.0,             # 20% - Ammo refill
	"credit_small": 16.0,     # 16% - Small gem
	"rapid_fire": 0.0,        # TODO: Not implemented yet
	"score_mult": 0.0,        # TODO: Not implemented yet
	"credit_medium": 4.0,     # 4% - Medium gem
	"smart_bomb": 0.0,        # TODO: Not implemented yet
	"credit_large": 0.8,      # 0.8% - Large gem

	# Placeholder to reach 100%
	"_placeholder": 19.2      # Will default to health for now
}
#endregion

## Create a random power-up based on weighted drop rates
static func create() -> PowerUpBase:
	var roll = randf() * 100.0
	var cumulative = 0.0
	var selected_type = "health"  # Default fallback

	# Weighted random selection
	for type in DROP_RATES.keys():
		cumulative += DROP_RATES[type]
		if roll < cumulative:
			selected_type = type
			break

	return create_specific(selected_type)

## Create a specific type of power-up
static func create_specific(type: String) -> PowerUpBase:
	var powerup: PowerUpBase = null

	match type:
		"health":
			powerup = _create_health()

		"ammo":
			powerup = _create_ammo()

		"credit_small":
			powerup = _create_credit_gem(CreditGem.GemSize.SMALL)

		"credit_medium":
			powerup = _create_credit_gem(CreditGem.GemSize.MEDIUM)

		"credit_large":
			powerup = _create_credit_gem(CreditGem.GemSize.LARGE)

		"_placeholder":
			# Default to health for unimplemented types
			powerup = _create_health()

		_:
			push_warning("[PowerUpFactory] Unknown type: %s, defaulting to health" % type)
			powerup = _create_health()

	if powerup:
		print("[PowerUpFactory] Created %s power-up" % type)
	else:
		push_error("[PowerUpFactory] Failed to create power-up of type: %s" % type)

	return powerup

#region Factory Methods
static func _create_health() -> PowerUpBase:
	var pickup = Area2D.new()
	pickup.set_script(HealthPickup)
	return pickup

static func _create_ammo() -> PowerUpBase:
	var pickup = Area2D.new()
	pickup.set_script(AmmoRefill)
	return pickup

static func _create_credit_gem(size: int) -> PowerUpBase:
	var gem = Area2D.new()
	gem.set_script(CreditGem)
	gem.set("gem_size", size)
	return gem
#endregion

#region Debug & Stats
## Get statistics about drop rates
static func get_drop_stats() -> String:
	var stats = "Power-Up Drop Rates:\n"
	var rates = DROP_RATES.duplicate()

	# Sort by value descending
	var sorted_keys = rates.keys()
	sorted_keys.sort_custom(func(a, b): return rates[a] > rates[b])

	for key in sorted_keys:
		if key != "_placeholder":
			stats += "  %s: %.1f%%\n" % [key, rates[key]]

	return stats

## Test drop distribution
static func test_drops(count: int = 1000) -> void:
	var results = {}

	for i in range(count):
		var powerup = create()
		var type = powerup.get_class()

		if type not in results:
			results[type] = 0
		results[type] += 1

		powerup.queue_free()

	print("\n[PowerUpFactory] Test Results (%d drops):" % count)
	for type in results.keys():
		var percentage = (results[type] / float(count)) * 100.0
		print("  %s: %d (%.1f%%)" % [type, results[type], percentage])
#endregion
