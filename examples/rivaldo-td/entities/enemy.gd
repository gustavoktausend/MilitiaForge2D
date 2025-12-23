class_name TDEnemy extends CharacterBody2D

@export var gold_reward: int = 10
@export var damage_to_base: int = 1

# Dependencies (Composition)
@onready var host: ComponentHost = $ComponentHost
@onready var health: HealthComponent = $ComponentHost/HealthComponent

func _ready() -> void:
	if health:
		health.died.connect(_on_death)

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
