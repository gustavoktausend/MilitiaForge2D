## Health Component
##
## Manages health, damage, healing, and death for game entities.
## Provides a complete health system with invincibility frames, regeneration,
## and comprehensive event signaling.
##
## Features:
## - Configurable max health and starting health
## - Damage and healing systems
## - Invincibility frames (i-frames) after taking damage
## - Optional health regeneration
## - Death detection and signaling
## - Shield/armor system (optional)
## - Integration with damage dealers and hitboxes
##
## @tutorial(Health System): res://docs/components/health.md

class_name HealthComponent extends Component

#region Signals
## Emitted when health changes for any reason
signal health_changed(new_health: int, old_health: int)

## Emitted when entity takes damage
signal damage_taken(amount: int, attacker: Node)

## Emitted when entity is healed
signal healed(amount: int)

## Emitted when entity dies (health reaches 0)
signal died()

## Emitted when invincibility starts
signal invincibility_started()

## Emitted when invincibility ends
signal invincibility_ended()

## Emitted when health reaches critical threshold
signal health_critical(current_health: int)
#endregion

#region Exports
@export_group("Health")
## Maximum health
@export var max_health: int = 100

## Starting health (if 0, starts at max_health)
@export var starting_health: int = 0

## Percentage of max health considered "critical" (0.0 to 1.0)
@export_range(0.0, 1.0) var critical_health_threshold: float = 0.25

@export_group("Invincibility")
## Whether invincibility frames are enabled after taking damage
@export var invincibility_enabled: bool = true

## Duration of invincibility after taking damage (in seconds)
@export var invincibility_duration: float = 0.5

@export_group("Regeneration")
## Whether health regenerates over time
@export var regeneration_enabled: bool = false

## Health regenerated per second
@export var regeneration_rate: float = 5.0

## Delay before regeneration starts after taking damage (in seconds)
@export var regeneration_delay: float = 3.0

@export_group("Advanced")
## Whether the entity can die (if false, health never goes below 1)
@export var can_die: bool = true

## Whether to print debug messages
@export var debug_health: bool = false
#endregion

#region Private Variables
## Current health
var current_health: int = 0

## Whether currently invincible
var _is_invincible: bool = false

## Whether entity is dead
var _is_dead: bool = false

## Whether health is in critical range
var _is_critical: bool = false

## Timer for invincibility duration
var _invincibility_timer: float = 0.0

## Timer for regeneration delay
var _regeneration_timer: float = 0.0

## Whether regeneration is active
var _regeneration_active: bool = false
#endregion

#region Component Lifecycle
func initialize(host_node: ComponentHost) -> void:
	super.initialize(host_node)
	
	# Set starting health
	if starting_health > 0:
		current_health = mini(starting_health, max_health)
	else:
		current_health = max_health

func component_ready() -> void:
	if debug_health:
		print("[HealthComponent] Initialized with %d/%d health" % [current_health, max_health])

func component_process(delta: float) -> void:
	# Update invincibility timer
	if _is_invincible:
		_invincibility_timer -= delta
		if _invincibility_timer <= 0:
			_end_invincibility()
	
	# Update regeneration
	if regeneration_enabled and not _is_dead:
		_update_regeneration(delta)

func cleanup() -> void:
	current_health = 0
	_is_invincible = false
	_is_dead = false
	super.cleanup()
#endregion

#region Public Methods - Damage & Healing
## Deal damage to this entity.
##
## Respects invincibility frames and death state.
## Emits damage_taken signal and may trigger death.
##
## @param amount: Amount of damage to deal (positive integer)
## @param attacker: Optional reference to the entity dealing damage
## @returns: Actual damage dealt (may be 0 if invincible or dead)
func take_damage(amount: int, attacker: Node = null) -> int:
	if amount <= 0:
		push_warning("Damage amount must be positive")
		return 0
	
	# Check if can take damage
	if _is_dead:
		return 0
	
	if _is_invincible:
		if debug_health:
			print("[HealthComponent] Damage blocked by invincibility")
		return 0
	
	# Calculate actual damage
	var actual_damage = amount
	var old_health = current_health
	
	# Apply damage
	current_health -= actual_damage
	
	# Prevent death if can_die is false
	if not can_die and current_health < 1:
		current_health = 1
		actual_damage = old_health - 1
	
	# Clamp to 0
	current_health = maxi(0, current_health)
	
	# Calculate actual damage dealt
	actual_damage = old_health - current_health
	
	if debug_health:
		print("[HealthComponent] Took %d damage: %d -> %d" % [actual_damage, old_health, current_health])

	# Emit signals
	if debug_health:
		print("[HealthComponent] Emitting health_changed signal: %d -> %d" % [old_health, current_health])
	health_changed.emit(current_health, old_health)
	damage_taken.emit(actual_damage, attacker)
	
	# Check for critical health
	_check_critical_health()
	
	# Start invincibility
	if invincibility_enabled and current_health > 0:
		_start_invincibility()
	
	# Reset regeneration timer
	if regeneration_enabled:
		_regeneration_active = false
		_regeneration_timer = regeneration_delay
	
	# Check for death
	if current_health <= 0 and not _is_dead:
		_die()
	
	return actual_damage

## Heal this entity.
##
## Cannot heal beyond max_health or if dead.
##
## @param amount: Amount to heal (positive integer)
## @returns: Actual amount healed
func heal(amount: int) -> int:
	if amount <= 0:
		push_warning("Heal amount must be positive")
		return 0
	
	if _is_dead:
		return 0
	
	var old_health = current_health
	current_health = mini(current_health + amount, max_health)
	var actual_healed = current_health - old_health
	
	if actual_healed > 0:
		if debug_health:
			print("[HealthComponent] Healed %d: %d -> %d" % [actual_healed, old_health, current_health])
		
		health_changed.emit(current_health, old_health)
		healed.emit(actual_healed)
		
		# Check if no longer critical
		_check_critical_health()
	
	return actual_healed

## Set health to a specific value.
##
## Bypasses invincibility and damage/heal logic.
## Useful for debugging or specific game mechanics.
##
## @param new_health: The health value to set
func set_health(new_health: int) -> void:
	var old_health = current_health
	current_health = clampi(new_health, 0, max_health)
	
	if current_health != old_health:
		health_changed.emit(current_health, old_health)
		_check_critical_health()
		
		if current_health <= 0 and not _is_dead:
			_die()

## Restore health to maximum.
func restore_full_health() -> void:
	heal(max_health - current_health)

## Kill the entity immediately.
##
## Bypasses can_die setting.
func kill() -> void:
	if _is_dead:
		return
	
	var old_health = current_health
	current_health = 0
	health_changed.emit(current_health, old_health)
	_die()

## Revive the entity with specified health.
##
## @param revive_health: Health to revive with (default: max_health)
func revive(revive_health: int = 0) -> void:
	if not _is_dead:
		return
	
	_is_dead = false
	
	if revive_health > 0:
		current_health = mini(revive_health, max_health)
	else:
		current_health = max_health
	
	if debug_health:
		print("[HealthComponent] Revived with %d health" % current_health)
	
	health_changed.emit(current_health, 0)
#endregion

#region Public Methods - Status Queries
## Get current health.
func get_current_health() -> int:
	return current_health

## Get maximum health.
func get_max_health() -> int:
	return max_health

## Get health as a percentage (0.0 to 1.0).
func get_health_percentage() -> float:
	return float(current_health) / float(max_health)

## Check if entity is dead.
func is_dead() -> bool:
	return _is_dead

## Check if entity is alive.
func is_alive() -> bool:
	return not _is_dead

## Check if currently invincible.
func is_invincible() -> bool:
	return _is_invincible

## Check if health is in critical range.
func is_critical() -> bool:
	return _is_critical

## Check if at full health.
func is_full_health() -> bool:
	return current_health >= max_health
#endregion

#region Private Methods
## Start invincibility frames.
func _start_invincibility() -> void:
	if not invincibility_enabled:
		return
	
	_is_invincible = true
	_invincibility_timer = invincibility_duration
	invincibility_started.emit()
	
	if debug_health:
		print("[HealthComponent] Invincibility started for %.2fs" % invincibility_duration)

## End invincibility frames.
func _end_invincibility() -> void:
	_is_invincible = false
	_invincibility_timer = 0.0
	invincibility_ended.emit()
	
	if debug_health:
		print("[HealthComponent] Invincibility ended")

## Handle death.
func _die() -> void:
	_is_dead = true
	died.emit()
	
	if debug_health:
		print("[HealthComponent] Entity died")

## Check and update critical health state.
func _check_critical_health() -> void:
	var critical_threshold = int(max_health * critical_health_threshold)
	var was_critical = _is_critical
	_is_critical = current_health > 0 and current_health <= critical_threshold
	
	# Emit signal when entering critical state
	if _is_critical and not was_critical:
		health_critical.emit(current_health)
		
		if debug_health:
			print("[HealthComponent] Health critical: %d/%d" % [current_health, max_health])

## Update regeneration system.
func _update_regeneration(delta: float) -> void:
	if current_health >= max_health:
		return
	
	# Update delay timer
	if not _regeneration_active:
		_regeneration_timer -= delta
		if _regeneration_timer <= 0:
			_regeneration_active = true
			if debug_health:
				print("[HealthComponent] Regeneration started")
	
	# Apply regeneration
	if _regeneration_active:
		var regen_amount = regeneration_rate * delta
		var old_health = current_health
		current_health = mini(current_health + int(regen_amount), max_health)
		
		if current_health != old_health:
			health_changed.emit(current_health, old_health)
#endregion

#region Debug Methods
## Get debug information about health state.
func get_debug_info() -> Dictionary:
	return {
		"current_health": current_health,
		"max_health": max_health,
		"health_percentage": "%.1f%%" % (get_health_percentage() * 100),
		"is_dead": _is_dead,
		"is_invincible": _is_invincible,
		"is_critical": _is_critical,
		"invincibility_time_left": "%.2fs" % _invincibility_timer if _is_invincible else "N/A",
		"regeneration_active": _regeneration_active if regeneration_enabled else "disabled",
	}
#endregion
