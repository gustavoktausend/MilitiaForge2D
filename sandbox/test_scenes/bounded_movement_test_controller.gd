## Bounded Movement Test Controller
##
## Controls test scene for BoundedMovement component.

extends Node

#region Node References
@onready var player: CharacterBody2D = $"../Player"
@onready var component_host: ComponentHost = $"../Player/ComponentHost"
var movement: BoundedMovement = null

@onready var boundary_viz: Control = $"../BoundaryVisualization"
@onready var init_timer: Timer = $"../InitTimer"

# UI Labels
@onready var mode_label: Label = $"../UI/Panel/VBoxContainer/Mode"
@onready var position_label: Label = $"../UI/Panel/VBoxContainer/Position"
@onready var distance_label: Label = $"../UI/Panel/VBoxContainer/DistanceToBoundary"
@onready var edge_label: Label = $"../UI/Panel/VBoxContainer/LastEdge"
@onready var bounds_label: Label = $"../UI/Panel/VBoxContainer/Bounds"
@onready var settings_label: Label = $"../UI/Panel/VBoxContainer/Settings"

# Bouncer/Wrapper entities
var bouncers: Array = []
var wrappers: Array = []
#endregion

#region Private Variables
var _initial_position: Vector2 = Vector2.ZERO
#endregion

#region Lifecycle
func _ready() -> void:
	# Wait for init
	init_timer.timeout.connect(_on_init_complete)

func _on_init_complete() -> void:
	movement = component_host.get_component("BoundedMovement")
	
	if not movement:
		push_error("BoundedMovement not found!")
		return
	
	_initial_position = player.position
	
	# Setup bouncer entities
	_setup_demo_entities()
	
	# Draw boundary visualization
	_draw_boundaries()
	
	print("[TestController] Bounded Movement test ready!")

func _process(_delta: float) -> void:
	_handle_input()
	_update_ui()
	_update_demo_entities(_delta)

func _draw() -> void:
	# This is called by boundary_viz
	if movement:
		var bounds = movement.get_current_bounds()
		
		# Draw boundary rectangle
		boundary_viz.queue_redraw()
#endregion

#region Input Handling
func _handle_input() -> void:
	if not movement:
		return
	
	# Change boundary mode
	if Input.is_key_pressed(KEY_1):
		movement.set_boundary_mode(BoundedMovement.BoundaryMode.CLAMP)
		await get_tree().create_timer(0.2).timeout
	
	if Input.is_key_pressed(KEY_2):
		movement.set_boundary_mode(BoundedMovement.BoundaryMode.BOUNCE)
		await get_tree().create_timer(0.2).timeout
	
	if Input.is_key_pressed(KEY_3):
		movement.set_boundary_mode(BoundedMovement.BoundaryMode.WRAP)
		await get_tree().create_timer(0.2).timeout
	
	if Input.is_key_pressed(KEY_4):
		movement.set_boundary_mode(BoundedMovement.BoundaryMode.DESTROY)
		print("[TestController] WARNING: DESTROY mode - player will be destroyed if leaving bounds!")
		await get_tree().create_timer(0.2).timeout
	
	# Adjust margin
	if Input.is_key_pressed(KEY_EQUAL) or Input.is_key_pressed(KEY_PLUS):
		movement.boundary_margin += Vector2(5, 5)
		movement.recalculate_bounds()
		_draw_boundaries()
		await get_tree().create_timer(0.1).timeout
	
	if Input.is_key_pressed(KEY_MINUS):
		movement.boundary_margin = (movement.boundary_margin - Vector2(5, 5)).clamp(Vector2.ZERO, Vector2(200, 200))
		movement.recalculate_bounds()
		_draw_boundaries()
		await get_tree().create_timer(0.1).timeout
	
	# Reset position
	if Input.is_key_pressed(KEY_R):
		player.position = _initial_position
		movement.velocity = Vector2.ZERO
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
	if not movement:
		return
	
	# Mode
	mode_label.text = "Mode: %s" % BoundedMovement.BoundaryMode.keys()[movement.boundary_mode]
	
	# Position
	position_label.text = "Position: (%.0f, %.0f)" % [player.position.x, player.position.y]
	
	# Distance to boundary
	var distance = movement.get_distance_to_boundary(player.position)
	distance_label.text = "Distance to Boundary: %.1f px" % distance
	
	# Color code by distance
	if distance < 50:
		distance_label.add_theme_color_override("font_color", Color.RED)
	elif distance < 100:
		distance_label.add_theme_color_override("font_color", Color.YELLOW)
	else:
		distance_label.add_theme_color_override("font_color", Color.GREEN)
	
	# Last edge
	var debug_info = movement.get_debug_info()
	edge_label.text = "Last Edge: %s" % debug_info["last_edge"]
	
	# Bounds
	var bounds = movement.get_current_bounds()
	bounds_label.text = "Bounds: (%.0f, %.0f, %.0f, %.0f)" % [
		bounds.position.x, bounds.position.y, bounds.size.x, bounds.size.y
	]
	
	# Settings
	settings_label.text = "Margin: %.0f pixels\nBounce Factor: %.1f" % [
		movement.boundary_margin.x,
		movement.bounce_factor
	]
#endregion

#region Demo Entities
func _setup_demo_entities() -> void:
	# Get all bouncer entities
	bouncers = get_tree().get_nodes_in_group("bouncer")
	wrappers = get_tree().get_nodes_in_group("wrapper")
	
	# Give them initial velocities
	for bouncer in bouncers:
		var bouncer_movement = bouncer.get_node("ComponentHost").get_component("BoundedMovement")
		if bouncer_movement:
			bouncer_movement.velocity = Vector2(
				randf_range(-1, 1),
				randf_range(-1, 1)
			).normalized() * bouncer_movement.max_speed
	
	for wrapper in wrappers:
		var wrapper_movement = wrapper.get_node("ComponentHost").get_component("BoundedMovement")
		if wrapper_movement:
			wrapper_movement.velocity = Vector2(
				randf_range(-1, 1),
				randf_range(-1, 1)
			).normalized() * wrapper_movement.max_speed

func _update_demo_entities(_delta: float) -> void:
	# Bouncers and wrappers move automatically
	# They handle their own boundary logic
	pass
#endregion

#region Boundary Visualization
func _draw_boundaries() -> void:
	if not movement:
		return
	
	boundary_viz.queue_redraw()
	boundary_viz.draw.connect(_on_draw_boundaries)

func _on_draw_boundaries() -> void:
	if not movement:
		return
	
	var bounds = movement.get_current_bounds()
	
	# Draw boundary rectangle
	var rect = Rect2(bounds.position, bounds.size)
	boundary_viz.draw_rect(rect, Color(1, 1, 1, 0.3), false, 2.0)
	
	# Draw corners
	var corner_size = 20
	var corners = [
		bounds.position,  # top-left
		Vector2(bounds.end.x, bounds.position.y),  # top-right
		bounds.end,  # bottom-right
		Vector2(bounds.position.x, bounds.end.y)  # bottom-left
	]
	
	for corner in corners:
		boundary_viz.draw_circle(corner, 4, Color.YELLOW)
#endregion

#region Debug
func _debug_print() -> void:
	print("=== Bounded Movement Debug ===")
	var debug_info = movement.get_debug_info()
	for key in debug_info:
		print("  %s: %s" % [key, debug_info[key]])
	print("=============================")
#endregion
