## Player Controller for Bounded Movement Test
##
## Demonstrates BoundedMovement with different boundary modes.

extends CharacterBody2D

#region Node References
@onready var component_host: ComponentHost = $ComponentHost
var input_comp: InputComponent = null
var movement: BoundedMovement = null
#endregion

#region Lifecycle
func _ready() -> void:
	await get_tree().process_frame
	
	input_comp = component_host.get_component("InputComponent")
	movement = component_host.get_component("BoundedMovement")
	
	if not movement:
		push_error("BoundedMovement not found!")
		return
	
	# Setup input
	_setup_input()
	
	# Connect to boundary signals
	movement.boundary_touched.connect(_on_boundary_touched)
	movement.destroyed_by_boundary.connect(_on_destroyed_by_boundary)
	
	print("[Player] Ready with BoundedMovement!")
	print("Mode: %s" % BoundedMovement.BoundaryMode.keys()[movement.boundary_mode])

func _physics_process(_delta: float) -> void:
	if not input_comp or not movement:
		return
	
	_handle_input()

func _process(_delta: float) -> void:
	# Visual feedback at boundaries
	_update_visuals()
#endregion

#region Input Setup
func _setup_input() -> void:
	input_comp.add_action("move_left", [KEY_A, KEY_LEFT])
	input_comp.add_action("move_right", [KEY_D, KEY_RIGHT])
	input_comp.add_action("move_up", [KEY_W, KEY_UP])
	input_comp.add_action("move_down", [KEY_S, KEY_DOWN])
	input_comp.add_action("sprint", [KEY_SHIFT])
#endregion

#region Input Handling
func _handle_input() -> void:
	var input_dir = input_comp.get_vector(
		"move_left", "move_right",
		"move_up", "move_down"
	)
	
	movement.set_input_direction(input_dir)
	
	# Sprint
	if input_comp.is_action_pressed("sprint"):
		movement.start_sprint()
	else:
		movement.stop_sprint()
#endregion

#region Visuals
func _update_visuals() -> void:
	if not movement:
		return
	
	# Change color based on distance to boundary
	var distance = movement.get_distance_to_boundary(global_position)
	
	if distance < 50:
		# Near boundary - warning color
		$Sprite.modulate = Color(1.0, 0.5, 0.5)
	else:
		# Normal color
		$Sprite.modulate = Color.WHITE
#endregion

#region Signal Callbacks
func _on_boundary_touched(edge: BoundedMovement.BoundaryEdge, position: Vector2) -> void:
	print("[Player] Touched %s boundary at %s" % [
		BoundedMovement.BoundaryEdge.keys()[edge],
		position
	])
	
	# Visual feedback
	$Sprite.scale = Vector2(1.2, 0.8)
	await get_tree().create_timer(0.1).timeout
	$Sprite.scale = Vector2.ONE

func _on_destroyed_by_boundary(edge: BoundedMovement.BoundaryEdge) -> void:
	print("[Player] Destroyed by %s boundary!" % BoundedMovement.BoundaryEdge.keys()[edge])
#endregion
