## Game HUD
##
## Displays player health, weapon energy, and game stats.
## Mega Man X style HUD.

extends CanvasLayer

#region Node References
@onready var health_bar: ProgressBar = $MarginContainer/VBoxContainer/HealthBar
@onready var health_label: Label = $MarginContainer/VBoxContainer/HealthLabel
@onready var weapon_energy_bar: ProgressBar = $MarginContainer/VBoxContainer/WeaponEnergyBar
@onready var lives_label: Label = $MarginContainer/VBoxContainer/LivesLabel
@onready var score_label: Label = $MarginContainer/VBoxContainer/ScoreLabel
#endregion

#region State
var player: Node2D = null
var current_health: int = 100
var max_health: int = 100
var lives: int = 3
var score: int = 0
#endregion

#region Lifecycle
func _ready() -> void:
	_find_player()
	_connect_player_signals()
	_update_hud()

func _process(delta: float) -> void:
	_update_health_from_player()
#endregion

#region Setup
func _find_player() -> void:
	# Find player in scene
	player = get_tree().get_first_node_in_group("player")
	
	if player:
		# Get player health component
		var host = player as ComponentHost
		if host:
			var health_comp = host.get_component("HealthComponent")
			if health_comp:
				max_health = health_comp.max_health
				current_health = health_comp.current_health

func _connect_player_signals() -> void:
	if not player:
		return
	
	# Connect to player signals
	if player.has_signal("player_died"):
		player.player_died.connect(_on_player_died)
	
	if player.has_signal("player_respawned"):
		player.player_respawned.connect(_on_player_respawned)
	
	# Connect to health component
	var host = player as ComponentHost
	if host:
		var health_comp = host.get_component("HealthComponent")
		if health_comp and health_comp.has_signal("health_changed"):
			health_comp.health_changed.connect(_on_health_changed)
#endregion

#region Health Updates
func _update_health_from_player() -> void:
	if not player:
		return
	
	var host = player as ComponentHost
	if not host:
		return
	
	var health_comp = host.get_component("HealthComponent")
	if health_comp:
		current_health = health_comp.current_health
		max_health = health_comp.max_health
		_update_health_display()

func _update_health_display() -> void:
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = current_health
	
	if health_label:
		health_label.text = "HP: %d/%d" % [current_health, max_health]
#endregion

#region HUD Updates
func _update_hud() -> void:
	_update_health_display()
	_update_lives_display()
	_update_score_display()

func _update_lives_display() -> void:
	if lives_label:
		lives_label.text = "Lives: %d" % lives

func _update_score_display() -> void:
	if score_label:
		score_label.text = "Score: %d" % score

func add_score(points: int) -> void:
	score += points
	_update_score_display()
#endregion

#region Signal Handlers
func _on_player_died() -> void:
	lives -= 1
	_update_lives_display()
	
	if lives <= 0:
		_game_over()

func _on_player_respawned() -> void:
	_update_health_display()

func _on_health_changed(new_health: int, old_health: int) -> void:
	current_health = new_health
	_update_health_display()

func _game_over() -> void:
	# TODO: Show game over screen
	print("GAME OVER")
	
	# Wait and restart
	await get_tree().create_timer(2.0).timeout
	get_tree().reload_current_scene()
#endregion
