class_name TDGameManager extends Node

#region Signals
signal gold_changed(current_gold: int)
signal lives_changed(current_lives: int)
signal game_over(victory: bool)
signal wave_started(wave: int)
signal wave_completed(wave: int)
#endregion

#region Exports
@export var starting_gold: int = 100
@export var starting_lives: int = 20
@export var spawner_path: NodePath
#endregion

#region Variables
var current_gold: int = 0
var current_lives: int = 0
var current_wave: int = 0
var _spawner: SpawnerComponent = null
#endregion

func _ready() -> void:
	current_gold = starting_gold
	current_lives = starting_lives
	
	# Connect to Spawner to track waves
	if not spawner_path.is_empty():
		_spawner = get_node_or_null(spawner_path)
		if _spawner:
			_spawner.wave_started.connect(_on_wave_started)
			_spawner.wave_completed.connect(_on_wave_completed)
			_spawner.all_waves_completed.connect(_on_all_waves_completed)
			
	# Update UI initial state
	call_deferred("_nitial_ui_update")

func _nitial_ui_update() -> void:
	gold_changed.emit(current_gold)
	lives_changed.emit(current_lives)

#region Public Methods
func add_gold(amount: int) -> void:
	current_gold += amount
	gold_changed.emit(current_gold)

func spend_gold(amount: int) -> bool:
	if current_gold >= amount:
		current_gold -= amount
		gold_changed.emit(current_gold)
		return true
	return false

func lose_life(amount: int = 1) -> void:
	current_lives -= amount
	lives_changed.emit(current_lives)
	
	if current_lives <= 0:
		_trigger_game_over(false)

func start_next_wave() -> void:
	if _spawner:
		_spawner.start_next_wave()
#endregion

#region Signal Callbacks
func _on_wave_started(wave: int) -> void:
	current_wave = wave
	wave_started.emit(wave)
	print("Wave %d started!" % wave)

func _on_wave_completed(wave: int) -> void:
	wave_completed.emit(wave)
	print("Wave %d completed!" % wave)

func _on_all_waves_completed() -> void:
	# Victory if still alive!
	if current_lives > 0:
		_trigger_game_over(true)

func _trigger_game_over(victory: bool) -> void:
	print("Game Over! Victory: %s" % victory)
	game_over.emit(victory)
	get_tree().paused = true
#endregion
