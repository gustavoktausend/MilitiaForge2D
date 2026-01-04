## Upgrade Manager (Autoload Singleton)
##
## Manages purchased upgrades and applies them to the player.
## Tracks permanent upgrades (persist within a run) and temporary buffs (expire after X waves).

extends Node

#region Signals
signal upgrade_purchased(effect_id: String, value: float)
signal buff_applied(buff_id: String, duration_waves: int)
signal buff_expired(buff_id: String)
#endregion

#region State
# Permanent upgrades (reset on game over)
# Structure: { "effect_id": total_value }
var purchased_upgrades: Dictionary = {}

# Temporary buffs (expire after N waves)
# Structure: { "buff_id": { "value": float, "expires_wave": int } }
var active_buffs: Dictionary = {}

# Extra lives (special case)
var extra_lives: int = 0
#endregion

func _ready() -> void:
	print("[UpgradeManager] Initialized")

#region Public Methods - Purchases
func purchase_upgrade(effect_id: String, value: float) -> void:
	"""Purchase and apply an upgrade"""

	# Check if it's a consumable buff (temporary)
	if _is_consumable(effect_id):
		_apply_consumable(effect_id, value)
		return

	# Check if it's extra life (special case)
	if effect_id == "extra_life":
		extra_lives += int(value)
		print("[UpgradeManager] Extra lives: %d" % extra_lives)
		upgrade_purchased.emit(effect_id, value)
		return

	# Permanent upgrade - add to total
	if effect_id not in purchased_upgrades:
		purchased_upgrades[effect_id] = 0.0

	purchased_upgrades[effect_id] += value

	# Apply to player immediately
	_apply_to_player(effect_id, value)

	upgrade_purchased.emit(effect_id, value)
	print("[UpgradeManager] Purchased: %s = %.2f (total: %.2f)" % [effect_id, value, purchased_upgrades[effect_id]])

func get_upgrade_total(effect_id: String) -> float:
	"""Get total purchased value for an upgrade"""
	return purchased_upgrades.get(effect_id, 0.0)

func has_upgrade(effect_id: String) -> bool:
	"""Check if player has purchased this upgrade"""
	return effect_id in purchased_upgrades
#endregion

#region Public Methods - Buffs
func check_expired_buffs(current_wave: int) -> void:
	"""Check and remove expired buffs (call at start of each wave)"""
	var expired_buffs: Array = []

	for buff_id in active_buffs.keys():
		if active_buffs[buff_id]["expires_wave"] <= current_wave:
			expired_buffs.append(buff_id)

	for buff_id in expired_buffs:
		_remove_buff(buff_id)

func get_active_buffs() -> Dictionary:
	"""Get all active buffs"""
	return active_buffs.duplicate()
#endregion

#region Public Methods - Extra Lives
func consume_extra_life() -> bool:
	"""Consume one extra life (returns true if had one)"""
	if extra_lives > 0:
		extra_lives -= 1
		print("[UpgradeManager] Extra life consumed (%d remaining)" % extra_lives)
		return true
	return false

func get_extra_lives() -> int:
	"""Get number of extra lives"""
	return extra_lives
#endregion

#region Public Methods - Reset
func reset_all_upgrades() -> void:
	"""Reset all upgrades (called on game over)"""
	purchased_upgrades.clear()
	active_buffs.clear()
	extra_lives = 0

	# Also reset shop database purchases
	ShopDatabase.reset_all_purchases()

	print("[UpgradeManager] All upgrades reset")
#endregion

#region Private Methods - Apply to Player
func _apply_to_player(effect_id: String, value: float) -> void:
	"""Apply upgrade effect to player"""
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		push_warning("[UpgradeManager] Player not found - upgrade queued for next spawn")
		return

	match effect_id:
		"health":
			if player.has_method("modify_max_health"):
				player.modify_max_health(int(value))

		"damage":
			if player.has_method("modify_damage_multiplier"):
				player.modify_damage_multiplier(1.0 + value)

		"fire_rate":
			if player.has_method("modify_fire_rate_multiplier"):
				player.modify_fire_rate_multiplier(1.0 + value)

		"speed":
			if player.has_method("modify_speed_multiplier"):
				player.modify_speed_multiplier(1.0 + value)

		"pickup_range":
			if player.has_method("modify_pickup_range"):
				player.modify_pickup_range(1.0 + value)

		"piercing":
			if player.has_method("modify_piercing"):
				player.modify_piercing(int(value))

		"homing":
			if player.has_method("enable_homing"):
				player.enable_homing(true)

		"regen":
			if player.has_method("modify_regeneration"):
				player.modify_regeneration(value)

		"drop_rate":
			if player.has_method("modify_drop_rate"):
				player.modify_drop_rate(1.0 + value)

		"projectile_size":
			if player.has_method("modify_projectile_size"):
				player.modify_projectile_size(1.0 + value)

		"iframe":
			if player.has_method("modify_iframe_duration"):
				player.modify_iframe_duration(value)

		_:
			push_warning("[UpgradeManager] Unknown effect_id: %s" % effect_id)

func _is_consumable(effect_id: String) -> bool:
	"""Check if effect is a consumable buff"""
	return effect_id in ["shield_buff", "score_mult", "rapid_fire"]

func _apply_consumable(effect_id: String, value: float) -> void:
	"""Apply temporary consumable buff"""
	var game_controller = get_tree().get_first_node_in_group("game_controller")
	if not game_controller:
		push_error("[UpgradeManager] GameController not found")
		return

	var current_wave = game_controller.current_wave if "current_wave" in game_controller else 1
	var duration_waves = 0

	match effect_id:
		"shield_buff":
			duration_waves = 1  # 1 wave
			_apply_shield_buff(value, current_wave + duration_waves)

		"score_mult":
			duration_waves = 2  # 2 waves
			_apply_score_mult(value, current_wave + duration_waves)

		"rapid_fire":
			duration_waves = 1  # 1 wave
			_apply_rapid_fire(value, current_wave + duration_waves)

	buff_applied.emit(effect_id, duration_waves)
	print("[UpgradeManager] Buff applied: %s (expires wave %d)" % [effect_id, current_wave + duration_waves])

func _apply_shield_buff(value: float, expires_wave: int) -> void:
	"""Apply shield buff"""
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("add_temporary_shield"):
		player.add_temporary_shield(int(value * 30))  # 30 HP shield

	active_buffs["shield_buff"] = {
		"value": value,
		"expires_wave": expires_wave
	}

func _apply_score_mult(multiplier: float, expires_wave: int) -> void:
	"""Apply score multiplier"""
	var game_controller = get_tree().get_first_node_in_group("game_controller")
	if game_controller and game_controller.has_method("set_score_multiplier"):
		game_controller.set_score_multiplier(multiplier)

	active_buffs["score_mult"] = {
		"value": multiplier,
		"expires_wave": expires_wave
	}

func _apply_rapid_fire(multiplier: float, expires_wave: int) -> void:
	"""Apply rapid fire buff"""
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("modify_fire_rate_multiplier"):
		player.modify_fire_rate_multiplier(multiplier)

	active_buffs["rapid_fire"] = {
		"value": multiplier,
		"expires_wave": expires_wave
	}

func _remove_buff(buff_id: String) -> void:
	"""Remove expired buff"""
	if buff_id not in active_buffs:
		return

	var buff_data = active_buffs[buff_id]
	var player = get_tree().get_first_node_in_group("player")
	var game_controller = get_tree().get_first_node_in_group("game_controller")

	match buff_id:
		"shield_buff":
			# Shield naturally depletes, no need to remove
			pass

		"score_mult":
			if game_controller and game_controller.has_method("set_score_multiplier"):
				game_controller.set_score_multiplier(1.0)  # Reset to 1x

		"rapid_fire":
			if player and player.has_method("modify_fire_rate_multiplier"):
				# Divide by multiplier to undo effect
				player.modify_fire_rate_multiplier(1.0 / buff_data["value"])

	active_buffs.erase(buff_id)
	buff_expired.emit(buff_id)
	print("[UpgradeManager] Buff expired: %s" % buff_id)
#endregion

#region Public Methods - Apply All (for respawn)
func apply_all_upgrades_to_player() -> void:
	"""Apply all purchased upgrades to player (called on respawn)"""
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		push_warning("[UpgradeManager] Player not found")
		return

	print("[UpgradeManager] Applying all upgrades to player...")

	for effect_id in purchased_upgrades.keys():
		var total_value = purchased_upgrades[effect_id]
		_apply_to_player(effect_id, total_value)

	print("[UpgradeManager] All upgrades applied")
#endregion
