## TopDown Movement Test Controller
##
## Controls the test scene for the TopDownMovement component.
## Displays real-time movement information and allows testing different settings.

extends Node

#region Node References
@onready var player: CharacterBody2D = $"../Player"
@onready var component_host: ComponentHost = $"../Player/ComponentHost"
@onready var direction_indicator: Line2D = $"../Player/DirectionIndicator"

var movement: TopDownMovement = null

# UI Labels
@onready var velocity_label: Label = $"../UI/Panel/VBoxContainer/Velocity"
@onready var speed_label: Label = $"../UI/Panel/VBoxContainer/Speed"
@onready var direction_label: Label = $"../UI/Panel/VBoxContainer/Direction"
@onready var state_label: Label = $"../UI/Panel/VBoxContainer/State"
@onready var sprint_label: Label = $"../UI/Panel/VBoxContainer/Sprint"
@onready var position_label: Label = $"../UI/Panel/VBoxContainer/Position"
@onready var settings_label: Label = $"../UI/Panel/VBoxContainer/Settings"
#endregion

#region Private Variables
var _initial_position: Vector2 = Vector2.ZERO
#endregion

#region Lifecycle
func _ready() -> void:
	await get_tree().process_frame
	
	movement = component_host.get_component("TopDownMovement")
	
	if not movement:
		push_error("TopDownMovement component not found!")
		return
	
	_initial_position = player.position
	
	print("[TestController] TopDown Movement test ready!")
	print("Use WASD or Arrow Keys to move, Shift to sprint")

func _process(_delta: float) -> void:
	_handle_input()
	_update_ui()
	_update_direction_indicator()
#endregion

#region Input Handling
func _handle_input() -> void:
	if not movement:
		return
	
	# Toggle normalize diagonal
	if Input.is_key_pressed(KEY_1):
		movement.normalize_diagonal = not movement.normalize_diagonal
		print("[TestController] Normalize diagonal: %s" % movement.normalize_diagonal)
		await get_tree().create_timer(0.2).timeout
	
	# Increase max speed
	if Input.is_key_pressed(KEY_2):
		movement.max_speed += 50
		print("[TestController] Max speed: %.1f" % movement.max_speed)
		await get_tree().create_timer(0.2).timeout
	
	# Decrease max speed
	if Input.is_key_pressed(KEY_3):
		movement.max_speed = max(50.0, movement.max_speed - 50)
		print("[TestController] Max speed: %.1f" % movement.max_speed)
		await get_tree().create_timer(0.2).timeout
	
	# Debug print
	if Input.is_key_pressed(KEY_D):
		_debug_print()
		await get_tree().create_timer(0.5).timeout
	
	# Reset position
	if Input.is_key_pressed(KEY_R):
		player.position = _initial_position
		movement.stop()
		print("[TestController] Position reset")
		await get_tree().create_timer(0.2).timeout
	
	# Quit
	if Input.is_key_pressed(KEY_Q):
		get_tree().quit()
#endregion

#region UI Updates
func _update_ui() -> void:
	if not movement:
		return
	
	var vel = movement.get_velocity()
	var spd = movement.get_speed()
	var dir = movement.direction
	
	# Update labels
	velocity_label.text = "Velocity: (%.1f, %.1f)" % [vel.x, vel.y]
	speed_label.text = "Speed: %.1f px/s" % spd
	direction_label.text = "Direction: (%.2f, %.2f)" % [dir.x, dir.y]
	
	# State
	if movement.is_moving():
		if movement.is_sprinting():
			state_label.text = "State: Sprinting"
			state_label.add_theme_color_override("font_color", Color.YELLOW)
		else:
			state_label.text = "State: Moving"
			state_label.add_theme_color_override("font_color", Color.GREEN)
	else:
		state_label.text = "State: Idle"
		state_label.add_theme_color_override("font_color", Color.WHITE)
	
	# Sprint
	if movement.is_sprinting():
		sprint_label.text = "Sprint: ON"
		sprint_label.add_theme_color_override("font_color", Color.YELLOW)
	else:
		sprint_label.text = "Sprint: OFF"
		sprint_label.add_theme_color_override("font_color", Color.WHITE)
	
	# Position
	position_label.text = "Position: (%.0f, %.0f)" % [player.position.x, player.position.y]
	
	# Settings
	settings_label.text = "Normalize Diagonal: %s\nMax Speed: %.1f" % [
		"ON" if movement.normalize_diagonal else "OFF",
		movement.max_speed
	]

func _update_direction_indicator() -> void:
	if not movement:
		return
	
	var dir = movement.direction
	
	if dir.length() > 0:
		direction_indicator.points[1] = dir * 40
		direction_indicator.visible = true
		
		# Change color based on sprint
		if movement.is_sprinting():
			direction_indicator.default_color = Color.YELLOW
		else:
			direction_indicator.default_color = Color(0.941, 0.439, 0.439)
	else:
		direction_indicator.visible = false
#endregion

#region Debug
func _debug_print() -> void:
	print("=== TopDown Movement Debug ===")
	var debug_info = movement.get_debug_info()
	for key in debug_info:
		print("  %s: %s" % [key, debug_info[key]])
	print("  position: %.1f, %.1f" % [player.position.x, player.position.y])
	print("============================")
#endregion
