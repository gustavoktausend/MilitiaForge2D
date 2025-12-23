class_name TurretComponent extends Component

#region Signals
signal target_acquired(target: Node2D)
signal target_lost()
signal state_changed(new_state: State)
#endregion

#region Enums
enum State {
	IDLE, ## Searching for targets
	TRACKING, ## Has target, rotating to face it
	FIRING ## Aimed and firing
}
#endregion

#region Exports
@export_group("Targeting")
## The Area2D used to detect targets (Optional, used for physics-based detection)
@export var detection_area_path: NodePath
## Range to validate targets (in pixels). Used for scanning behavior.
@export var detection_range: float = 200.0
## Strategy resource for selecting targets
@export var strategy: TargetingStrategy
## Groups to consider as valid targets
@export var target_groups: Array[String] = ["enemies"]
## Turn speed in degrees per second
@export var turn_speed: float = 180.0
## Firing arc threshold (degrees) - how close to aim before firing
@export var fire_threshold: float = 5.0

@export_group("Combat")
## The command to execute when attacking (Pattern: Command)
@export var attack_command: AttackCommand
## Path to the visual part to rotate (e.g. turret head)
@export var rotating_part_path: NodePath
#endregion

#region Private Variables
var _state: int = State.IDLE
var _current_target: Node2D = null
var _detection_area: Area2D = null
var _rotating_part: Node2D = null
var _candidates: Array[Node2D] = []
var _cooldown_timer: float = 0.0
#endregion

#region Component Lifecycle
func initialize(host: ComponentHost) -> void:
	super.initialize(host)
	_setup_strategy()

func component_ready() -> void:
	print("TURRET READY: ", host.get_parent().name)
	_setup_detection()
	# Attack command is resource-based, no node setup needed
	_setup_rotating_part()
	_setup_rotating_part()
	
	if attack_command:
		print("TURRET [Ready]: AttackCommand linked: ", attack_command)
	else:
		print("TURRET [Ready]: AttackCommand is NULL!")
		
	_change_state(State.IDLE)

func component_process(delta: float) -> void:
	# Cooldown management
	if _cooldown_timer > 0:
		_cooldown_timer -= delta
		
	match _state:
		State.IDLE: _process_idle(delta)
		State.TRACKING: _process_tracking(delta)
		State.FIRING: _process_firing(delta)

func cleanup() -> void:
	_candidates.clear()
	_current_target = null
	super.cleanup()
#endregion

#region Setup Methods
## Virtual: Setup strategy
func _setup_strategy() -> void:
	if not strategy:
		strategy = ClosestTargetStrategy.new()

## Virtual: Setup detection (Area2D or Scanner)
func _setup_detection() -> void:
	if not detection_area_path.is_empty():
		_detection_area = host.get_node_or_null(detection_area_path)
		if _detection_area:
			# We keep physics signals as a backup or optimization
			_detection_area.body_entered.connect(_on_body_entered)
			_detection_area.body_exited.connect(_on_body_exited)
			_detection_area.monitoring = true
			_detection_area.monitorable = false
			print("TURRET [Setup]: DetectionArea found and active.")

## Virtual: Setup rotation
func _setup_rotating_part() -> void:
	if not rotating_part_path.is_empty():
		_rotating_part = host.get_node_or_null(rotating_part_path)
	else:
		_rotating_part = host
#endregion

#region State Logic
func _process_idle(delta: float) -> void:
	# Active Scan
	_scan_for_targets()
	_update_target_selection()
	
	if is_instance_valid(_current_target):
		_change_state(State.TRACKING)

func _process_tracking(delta: float) -> void:
	if not _validate_current_target():
		_change_state(State.IDLE)
		return

	_rotate_towards_target(delta)
	
	if _can_fire_at_target():
		_change_state(State.FIRING)

func _process_firing(delta: float) -> void:
	_rotate_towards_target(delta)
	
	if not _validate_current_target():
		_change_state(State.IDLE)
		return
		
	if not _can_fire_at_target():
		_change_state(State.TRACKING)
		return
		
	# Try to fire
	if _cooldown_timer <= 0:
		_fire_weapon()
#endregion

#region Core Logic
func _scan_for_targets() -> void:
	for group in target_groups:
		var enemies = get_tree().get_nodes_in_group(group)
		# print("TURRET [Scan]: Found ", enemies.size(), " enemies in group ", group)
		for enemy in enemies:
			if enemy is Node2D:
				var dist = host.global_position.distance_to(enemy.global_position)
				# print("TURRET [Scan]: Enemy ", enemy.name, " distance: ", dist)
				if dist <= detection_range:
					if enemy not in _candidates:
						print("TURRET [Scan]: Added candidate %s (%d) (Dist: %f)" % [enemy.name, enemy.get_instance_id(), dist])
						_candidates.append(enemy)

func _update_target_selection() -> void:
	# Prune invalid or out-of-range candidates
	for i in range(_candidates.size() - 1, -1, -1):
		var candidate = _candidates[i]
		if not is_instance_valid(candidate):
			_candidates.remove_at(i)
			continue
			
		var dist = host.global_position.distance_to(candidate.global_position)
		if dist > detection_range * 1.5:
			print("TURRET [Update]: Dropping candidate %s (%d) (Too far: %f)" % [candidate.name, candidate.get_instance_id(), dist])
			_candidates.remove_at(i)
	
	if _candidates.is_empty():
		_current_target = null
		return
		
	var new_target = strategy.select_target(host, _candidates)
	if new_target != _current_target:
		var old_id = _current_target.get_instance_id() if is_instance_valid(_current_target) else 0
		var new_id = new_target.get_instance_id() if is_instance_valid(new_target) else 0
		print("TURRET [Update]: Target changed from %d to %d" % [old_id, new_id])
		_current_target = new_target
		if _current_target:
			target_acquired.emit(_current_target)

func _validate_current_target() -> bool:
	if not is_instance_valid(_current_target):
		return false
	
	var dist = host.global_position.distance_to(_current_target.global_position)
	# Increased buffer to 1.5x to prevent rapid switching
	if dist > detection_range * 1.5:
		print("TURRET [Validate FAIL]: %s -> %s (%d) | Dist: %f > Range(x1.5): %f" % [
			host.get_parent().name, _current_target.name, _current_target.get_instance_id(), dist, detection_range * 1.5
		])
		return false
		
	return true

func _rotate_towards_target(delta: float) -> void:
	if not _rotating_part or not is_instance_valid(_current_target): return
	
	var desired_angle = (_current_target.global_position - _rotating_part.global_position).angle()
	var new_angle = rotate_toward(_rotating_part.global_rotation, desired_angle, deg_to_rad(turn_speed) * delta)
	_rotating_part.global_rotation = new_angle

func _can_fire_at_target() -> bool:
	if not _rotating_part or not is_instance_valid(_current_target): return false
	var desired_angle = (_current_target.global_position - _rotating_part.global_position).angle()
	var diff = abs(angle_difference(_rotating_part.global_rotation, desired_angle))
	# print("TURRET [Aim]: Diff ", rad_to_deg(diff))
	return rad_to_deg(diff) <= fire_threshold

func _fire_weapon() -> void:
	# print("TURRET [Fire Request]: Cooldown %f" % _cooldown_timer)
	if attack_command:
		# print("TURRET [Debug]: CMD Script: ", attack_command.get_script().resource_path)
		print("TURRET [Debug]: Executing Command ID: %d" % attack_command.get_instance_id())
		var result = attack_command.execute(host, _current_target)
		# print("TURRET [Fire Result]: ", result)
		if result:
			# Success, reset cooldown
			_cooldown_timer = attack_command.cooldown
	else:
		print("ERROR: TurretComponent: No AttackCommand assigned! (IsNull)")
		_cooldown_timer = 1.0 # Prevent spam

func _change_state(new_state: int) -> void:
	if _state == new_state: return
	print("TURRET [State]: %s -> %s" % [State.keys()[_state], State.keys()[new_state]])
	_state = new_state
	state_changed.emit(_state)
	
	if _state == State.IDLE:
		_current_target = null
		target_lost.emit()

#endregion

#region Signal Callbacks (Physics Backup)
func _on_body_entered(body: Node2D) -> void:
	if _is_valid_target_group(body) and body not in _candidates:
		_candidates.append(body)

func _on_body_exited(body: Node2D) -> void:
	pass # Handling removal via distance check in _update_target_selection

func _is_valid_target_group(node: Node2D) -> bool:
	for group in target_groups:
		if node.is_in_group(group):
			return true
	return false
#endregion
