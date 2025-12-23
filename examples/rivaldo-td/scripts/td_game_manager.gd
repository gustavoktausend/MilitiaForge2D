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
	
	# FALLBACK: Inject AttackCommand manually since resource loader is failing
	print("DEBUG: Injecting AttackCommand manually (Deferred)...")
	call_deferred("_inject_attack_command")
	
func _inject_attack_command() -> void:
	var cmd = ProjectileAttackCommand.new()
	# Just load the scene directly now that we fixed it
	var path = "res://examples/rivaldo-td/entities/projectile.tscn"
	if FileAccess.file_exists(path):
		var proj_scene = load(path)
		if proj_scene:
			print("DEBUG: Projectile scene loaded successfully.")
			cmd.projectile_scene = proj_scene
		else:
			print("ERROR: Failed to load projectile.tscn! load() returned null.")
	else:
		print("ERROR: File NOT found at path: ", path)
		
	cmd.projectile_speed = 400.0
	cmd.cooldown = 0.8
	cmd.damage = 25
	cmd.range_radius = 200.0
	
	var towers = get_tree().get_nodes_in_group("towers")
	print("DEBUG: Found %d towers to inject." % towers.size())
	print("DEBUG: Created Command ID: %d | Scene: %s" % [cmd.get_instance_id(), cmd.projectile_scene])
	
	for tower in towers:
		var host = tower.get_node_or_null("ComponentHost")
		if host:
			var turret = host.get_component("TurretComponent")
			if turret:
				turret.attack_command = cmd
				print("DEBUG: Injected command into %s" % tower.name)

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
