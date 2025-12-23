class_name TDEnemy extends CharacterBody2D

@export var gold_reward: int = 10
@export var damage_to_base: int = 1

@export var movement_strategy: MovementStrategy
@export var speed: float = 100.0

var _path_follow: PathFollow2D

# Dependencies (Composition)
@onready var host: ComponentHost = $ComponentHost
@onready var health: HealthComponent = $ComponentHost/HealthComponent

func _ready() -> void:
	# Try to find path follow parent
	var parent = get_parent()
	if parent is PathFollow2D:
		_path_follow = parent
		# Ensure the strategy knows about it (or strategy finds it)
		
	if health:
		health.died.connect(_on_death)

	# Connect to event bus (Optional, but good practice)
	# EventBus.enemy_spawned.emit(self)

func _physics_process(delta: float) -> void:
	if movement_strategy:
		# Context data for the strategy
		var context = {
			"speed": speed,
			"path_follow": _path_follow
		}
		var old_pos = global_position
		movement_strategy.move(self, delta, context)
		var dist = old_pos.distance_to(global_position)
		if dist > 50.0: # Only print huge jumps
			print("ENEMY [Move]: Jumped %f pixels! Delta: %f" % [dist, delta])
	else:
		push_warning("Enemy: No MovementStrategy assigned.")


func _on_death() -> void:
	# Reward gold via global manager if available
	# In a real scene, we'd inject GameManager reference.
	# For simplicity, we search for it in the main scene group "game_manager"
	var managers = get_tree().get_nodes_in_group("game_manager")
	if not managers.is_empty():
		managers[0].add_gold(gold_reward)
		
	queue_free()

## Called by the map when enemy reaches the end
func reach_base() -> void:
	var managers = get_tree().get_nodes_in_group("game_manager")
	if not managers.is_empty():
		managers[0].lose_life(damage_to_base)
	queue_free()
