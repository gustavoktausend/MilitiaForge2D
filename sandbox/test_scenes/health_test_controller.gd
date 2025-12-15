## Health Test Controller
##
## Controls the test scene for the Health component system.

extends Node

#region Node References
@onready var player: CharacterBody2D = $"../Player"
@onready var component_host: ComponentHost = $"../Player/ComponentHost"
var health: HealthComponent = null

# UI Labels
@onready var health_label: Label = $"../UI/Panel/VBoxContainer/Health"
@onready var health_bar: ProgressBar = $"../UI/Panel/VBoxContainer/HealthBar"
@onready var state_label: Label = $"../UI/Panel/VBoxContainer/State"
@onready var invincible_label: Label = $"../UI/Panel/VBoxContainer/Invincible"
@onready var critical_label: Label = $"../UI/Panel/VBoxContainer/Critical"
@onready var damage_taken_label: Label = $"../UI/Panel/VBoxContainer/DamageTaken"
@onready var times_hit_label: Label = $"../UI/Panel/VBoxContainer/TimesHit"
@onready var settings_label: Label = $"../UI/Panel/VBoxContainer/Settings"
#endregion

#region Private Variables
var _total_damage_taken: int = 0
var _times_hit: int = 0
#endregion

#region Lifecycle
func _ready() -> void:
	await get_tree().process_frame
	
	health = component_host.get_component("HealthComponent")
	
	if not health:
		push_error("HealthComponent not found!")
		return
	
	# Connect to health signals for stats
	health.damage_taken.connect(_on_damage_taken)
	
	# Initialize UI
	_update_ui()
	
	print("[TestController] Health test ready!")

func _process(_delta: float) -> void:
	_handle_input()
	_update_ui()
#endregion

#region Input Handling
func _handle_input() -> void:
	if not health:
		return
	
	# Heal
	if Input.is_key_pressed(KEY_H):
		health.heal(20)
		await get_tree().create_timer(0.2).timeout
	
	# Take damage
	if Input.is_key_pressed(KEY_J):
		health.take_damage(10)
		await get_tree().create_timer(0.2).timeout
	
	# Kill
	if Input.is_key_pressed(KEY_K):
		health.kill()
		await get_tree().create_timer(0.2).timeout
	
	# Revive
	if Input.is_key_pressed(KEY_R):
		health.revive()
		_reset_stats()
		await get_tree().create_timer(0.2).timeout
	
	# Toggle regeneration
	if Input.is_key_pressed(KEY_T):
		health.regeneration_enabled = not health.regeneration_enabled
		print("[TestController] Regeneration: %s" % ("ON" if health.regeneration_enabled else "OFF"))
		await get_tree().create_timer(0.2).timeout
	
	# Debug print
	if Input.is_key_pressed(KEY_D):
		_debug_print()
		await get_tree().create_timer(0.5).timeout
	
	# Quit
	if Input.is_key_pressed(KEY_Q):
		get_tree().quit()
#endregion

#region UI Updates
func _update_ui() -> void:
	if not health:
		return
	
	# Health display
	var current = health.get_current_health()
	var maximum = health.get_max_health()
	var percentage = health.get_health_percentage() * 100
	
	health_label.text = "Health: %d/%d (%.0f%%)" % [current, maximum, percentage]
	health_bar.value = percentage
	
	# Color code health bar
	if percentage > 50:
		health_bar.modulate = Color.GREEN
	elif percentage > 25:
		health_bar.modulate = Color.YELLOW
	else:
		health_bar.modulate = Color.RED
	
	# State
	if health.is_dead():
		state_label.text = "State: DEAD"
		state_label.add_theme_color_override("font_color", Color.RED)
	elif health.is_critical():
		state_label.text = "State: CRITICAL"
		state_label.add_theme_color_override("font_color", Color.YELLOW)
	else:
		state_label.text = "State: Alive"
		state_label.add_theme_color_override("font_color", Color.GREEN)
	
	# Invincible
	if health.is_invincible():
		invincible_label.text = "Invincible: YES"
		invincible_label.add_theme_color_override("font_color", Color.CYAN)
	else:
		invincible_label.text = "Invincible: No"
		invincible_label.add_theme_color_override("font_color", Color.WHITE)
	
	# Critical
	if health.is_critical():
		critical_label.text = "Critical: YES"
		critical_label.add_theme_color_override("font_color", Color.RED)
	else:
		critical_label.text = "Critical: No"
		critical_label.add_theme_color_override("font_color", Color.WHITE)
	
	# Stats
	damage_taken_label.text = "Total Damage Taken: %d" % _total_damage_taken
	times_hit_label.text = "Times Hit: %d" % _times_hit
	
	# Settings
	settings_label.text = "Regeneration: %s\nInvincibility: %.1fs" % [
		"ON" if health.regeneration_enabled else "OFF",
		health.invincibility_duration
	]
#endregion

#region Signal Callbacks
func _on_damage_taken(amount: int, _attacker: Node) -> void:
	_total_damage_taken += amount
	_times_hit += 1
#endregion

#region Debug
func _debug_print() -> void:
	print("=== Health System Debug ===")
	var debug_info = health.get_debug_info()
	for key in debug_info:
		print("  %s: %s" % [key, debug_info[key]])
	print("  total_damage_taken: %d" % _total_damage_taken)
	print("  times_hit: %d" % _times_hit)
	print("===========================")

func _reset_stats() -> void:
	_total_damage_taken = 0
	_times_hit = 0
#endregion
