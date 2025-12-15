## Player Controller for Movement Test
##
## Simple controller that reads input and passes it to the TopDownMovement component.
## This demonstrates how to integrate input with the movement system.

extends CharacterBody2D

#region Node References
@onready var component_host: ComponentHost = $ComponentHost
var movement: TopDownMovement = null
#endregion

#region Lifecycle
func _ready() -> void:
	# Get movement component
	await get_tree().process_frame
	movement = component_host.get_component("TopDownMovement")
	
	if not movement:
		push_error("TopDownMovement component not found!")
		return
	
	# Connect to movement signals for feedback
	movement.movement_started.connect(_on_movement_started)
	movement.movement_stopped.connect(_on_movement_stopped)
	movement.sprint_started.connect(_on_sprint_started)
	movement.sprint_ended.connect(_on_sprint_ended)
	
	print("[PlayerController] Ready! Use WASD to move, Shift to sprint")

func _physics_process(_delta: float) -> void:
	if not movement:
		return
	
	_handle_input()

func _process(_delta: float) -> void:
	# Update velocity from movement component
	# (movement component handles this internally, but we can access it)
	pass
#endregion

#region Input Handling
func _handle_input() -> void:
	# Get input direction
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	# Also support WASD
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		input_dir.x -= 1
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		input_dir.x += 1
	if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
		input_dir.y -= 1
	if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
		input_dir.y += 1
	
	# Set direction on movement component
	movement.set_input_direction(input_dir)
	
	# Handle sprint
	if Input.is_key_pressed(KEY_SHIFT):
		if not movement.is_sprinting():
			movement.start_sprint()
	else:
		if movement.is_sprinting():
			movement.stop_sprint()
#endregion

#region Signal Callbacks
func _on_movement_started(direction: Vector2) -> void:
	print("[PlayerController] Started moving: %s" % direction)

func _on_movement_stopped() -> void:
	print("[PlayerController] Stopped moving")

func _on_sprint_started() -> void:
	print("[PlayerController] Sprint started!")

func _on_sprint_ended() -> void:
	print("[PlayerController] Sprint ended")
#endregion
