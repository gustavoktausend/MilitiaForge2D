## Score Component
##
## Manages score, combos, multipliers, and high scores.
## Generic component useful for any game with scoring system.
##
## Features:
## - Score accumulation
## - Combo system with decay
## - Score multipliers
## - High score tracking
## - Persistent high scores (optional)
## - Rank/grade system
## - Score events and milestones
##
## @tutorial(Progression): res://docs/components/progression.md

class_name ScoreComponent extends Component

#region Signals
## Emitted when score changes
signal score_changed(new_score: int, delta_score: int)

## Emitted when combo changes
signal combo_changed(new_combo: int)

## Emitted when combo breaks
signal combo_broken(final_combo: int, bonus_score: int)

## Emitted when multiplier changes
signal multiplier_changed(new_multiplier: float)

## Emitted when high score is beaten
signal new_high_score(score: int)

## Emitted when a milestone is reached
signal milestone_reached(milestone: int, reward: Variant)

## Emitted when rank changes
signal rank_changed(new_rank: String, new_grade: int)

## Emitted when an enemy is killed
signal enemy_killed(enemy: Node2D, points: int)
#endregion

#region Enums
## Score ranks/grades
enum Rank {
	F = 0,
	E = 1,
	D = 2,
	C = 3,
	B = 4,
	A = 5,
	S = 6,
	SS = 7,
	SSS = 8
}
#endregion

#region Exports
@export_group("Score")
## Current score
@export var current_score: int = 0

## Whether score can be negative
@export var allow_negative: bool = false

## Score cap (0 = unlimited)
@export var max_score: int = 0

@export_group("Combo")
## Enable combo system
@export var enable_combos: bool = true

## Current combo count
@export var current_combo: int = 0

## Combo decay time (seconds)
@export var combo_decay_time: float = 3.0

## Combo bonus per hit (multiplier)
@export var combo_multiplier: float = 0.1

## Maximum combo multiplier
@export var max_combo_multiplier: float = 5.0

@export_group("Multiplier")
## Base score multiplier
@export var base_multiplier: float = 1.0

## Current additional multipliers (temporary)
var _temp_multipliers: Array[float] = []

@export_group("High Score")
## Enable high score tracking
@export var track_high_score: bool = true

## Current high score
@export var high_score: int = 0

## Whether to persist high score (save to file)
@export var persist_high_score: bool = false

## Save file path
@export var save_file_path: String = "user://high_score.save"

@export_group("Ranks")
## Enable rank system
@export var enable_ranks: bool = false

## Score thresholds for each rank
@export var rank_thresholds: Array[int] = [0, 1000, 5000, 10000, 25000, 50000, 100000, 250000, 500000]

## Current rank
var current_rank: Rank = Rank.F

@export_group("Milestones")
## Score milestones (achievements)
@export var milestones: Array[int] = [1000, 5000, 10000, 50000, 100000]

## Reached milestones
var _reached_milestones: Array[int] = []

@export_group("Advanced")
## Whether to print debug messages
@export var debug_score: bool = false
#endregion

#region Private Variables
## Combo decay timer
var _combo_timer: float = 0.0

## Whether combo is active
var _combo_active: bool = false
#endregion

#region Component Lifecycle
func component_ready() -> void:
	# Load high score if persistent
	if persist_high_score and track_high_score:
		_load_high_score()
	
	# Initialize rank
	if enable_ranks:
		_update_rank()
	
	if debug_score:
		print("[ScoreComponent] Ready - Score: %d, High Score: %d" % [current_score, high_score])

func component_process(delta: float) -> void:
	# Update combo decay
	if enable_combos and _combo_active:
		_combo_timer -= delta
		
		if _combo_timer <= 0:
			_break_combo()

func cleanup() -> void:
	# Save high score
	if persist_high_score and track_high_score:
		_save_high_score()
	
	super.cleanup()
#endregion

#region Public Methods - Score
## Add score
##
## @param amount: Amount to add (can be negative if allowed)
## @param apply_multiplier: Whether to apply current multipliers
func add_score(amount: int, apply_multiplier: bool = true) -> void:
	var original = current_score
	var final_amount = amount
	
	# Apply multipliers
	if apply_multiplier:
		final_amount = int(amount * get_total_multiplier())
	
	# Add score
	current_score += final_amount
	
	# Clamp if needed
	if not allow_negative:
		current_score = maxi(0, current_score)
	
	if max_score > 0:
		current_score = mini(max_score, current_score)
	
	# Check high score
	if track_high_score and current_score > high_score:
		_set_new_high_score()
	
	# Check milestones
	_check_milestones()
	
	# Update rank
	if enable_ranks:
		_update_rank()
	
	# Emit signal
	var delta_score = current_score - original
	score_changed.emit(current_score, delta_score)
	
	if debug_score:
		print("[ScoreComponent] Score: %d (+%d)" % [current_score, delta_score])

## Set score directly
func set_score(new_score: int) -> void:
	var delta = new_score - current_score
	current_score = new_score
	
	# Check high score
	if track_high_score and current_score > high_score:
		_set_new_high_score()
	
	score_changed.emit(current_score, delta)

## Reset score
func reset_score() -> void:
	current_score = 0
	current_combo = 0
	_combo_active = false
	_reached_milestones.clear()
	
	if enable_ranks:
		current_rank = Rank.F
		rank_changed.emit(Rank.keys()[current_rank], current_rank)

## Register an enemy kill
##
## Adds score, increments combo, and emits enemy_killed signal.
## This is the main method to call when an enemy is defeated.
##
## @param enemy: The enemy entity that was killed
## @param points: Score points to award
func register_enemy_kill(enemy: Node2D, points: int) -> void:
	# Add score
	add_score(points)
	
	# Increment combo
	if enable_combos:
		increment_combo()
	
	# Emit signal for other systems to react
	enemy_killed.emit(enemy, points)
	
	if debug_score:
		print("[ScoreComponent] Enemy killed! Points: %d, Combo: %d" % [points, current_combo])
#endregion

#region Public Methods - Combo
## Increment combo
func increment_combo() -> void:
	if not enable_combos:
		return
	
	current_combo += 1
	_combo_active = true
	_combo_timer = combo_decay_time
	
	combo_changed.emit(current_combo)
	
	if debug_score:
		print("[ScoreComponent] Combo: %d (x%.2f)" % [current_combo, get_combo_multiplier()])

## Reset combo
func reset_combo() -> void:
	if current_combo > 0:
		_break_combo()

## Get combo multiplier
func get_combo_multiplier() -> float:
	if not enable_combos or current_combo == 0:
		return 1.0
	
	var multiplier = 1.0 + (current_combo * combo_multiplier)
	return minf(multiplier, max_combo_multiplier)
#endregion

#region Public Methods - Multiplier
## Add temporary multiplier
##
## @param multiplier: Multiplier value
## @param duration: Duration in seconds (0 = permanent until removed)
func add_multiplier(multiplier: float, duration: float = 0.0) -> void:
	_temp_multipliers.append(multiplier)
	multiplier_changed.emit(get_total_multiplier())
	
	# Remove after duration if specified
	if duration > 0:
		await get_tree().create_timer(duration).timeout
		remove_multiplier(multiplier)

## Remove a multiplier
func remove_multiplier(multiplier: float) -> void:
	_temp_multipliers.erase(multiplier)
	multiplier_changed.emit(get_total_multiplier())

## Clear all temporary multipliers
func clear_multipliers() -> void:
	_temp_multipliers.clear()
	multiplier_changed.emit(get_total_multiplier())

## Get total multiplier
func get_total_multiplier() -> float:
	var total = base_multiplier
	
	# Add combo multiplier
	if enable_combos:
		total *= get_combo_multiplier()
	
	# Add temp multipliers
	for mult in _temp_multipliers:
		total *= mult
	
	return total
#endregion

#region Public Methods - High Score
## Get high score
func get_high_score() -> int:
	return high_score

## Manually set high score (admin/cheat)
func set_high_score(score: int) -> void:
	high_score = score
	
	if persist_high_score:
		_save_high_score()
#endregion

#region Public Methods - Rank
## Get current rank
func get_rank() -> Rank:
	return current_rank

## Get rank name
func get_rank_name() -> String:
	return Rank.keys()[current_rank]
#endregion

#region Private Methods - Combo
## Break the combo
func _break_combo() -> void:
	var final_combo = current_combo
	
	# Calculate combo bonus
	var bonus = 0
	if final_combo > 0:
		bonus = int(final_combo * final_combo * 10)  # Example formula
		add_score(bonus, false)
	
	combo_broken.emit(final_combo, bonus)
	
	current_combo = 0
	_combo_active = false
	combo_changed.emit(0)
	
	if debug_score and final_combo > 0:
		print("[ScoreComponent] Combo broken! Final: %d, Bonus: %d" % [final_combo, bonus])
#endregion

#region Private Methods - High Score
## Set new high score
func _set_new_high_score() -> void:
	high_score = current_score
	new_high_score.emit(high_score)
	
	if persist_high_score:
		_save_high_score()
	
	if debug_score:
		print("[ScoreComponent] NEW HIGH SCORE: %d!" % high_score)

## Save high score to file
func _save_high_score() -> void:
	var file = FileAccess.open(save_file_path, FileAccess.WRITE)
	if file:
		file.store_32(high_score)
		file.close()

## Load high score from file
func _load_high_score() -> void:
	if FileAccess.file_exists(save_file_path):
		var file = FileAccess.open(save_file_path, FileAccess.READ)
		if file:
			high_score = file.get_32()
			file.close()
			
			if debug_score:
				print("[ScoreComponent] Loaded high score: %d" % high_score)
#endregion

#region Private Methods - Milestones
## Check if any milestones were reached
func _check_milestones() -> void:
	for milestone in milestones:
		if current_score >= milestone and milestone not in _reached_milestones:
			_reached_milestones.append(milestone)
			milestone_reached.emit(milestone, null)  # Can pass reward data
			
			if debug_score:
				print("[ScoreComponent] Milestone reached: %d" % milestone)
#endregion

#region Private Methods - Ranks
## Update current rank based on score
func _update_rank() -> void:
	var new_rank = Rank.F
	
	# Find highest rank threshold met
	for i in range(rank_thresholds.size() - 1, -1, -1):
		if current_score >= rank_thresholds[i]:
			new_rank = i as Rank
			break
	
	# Emit if changed
	if new_rank != current_rank:
		current_rank = new_rank
		rank_changed.emit(Rank.keys()[current_rank], current_rank)
		
		if debug_score:
			print("[ScoreComponent] Rank up! New rank: %s" % Rank.keys()[current_rank])
#endregion

#region Debug
## Get debug information
func get_debug_info() -> Dictionary:
	return {
		"score": current_score,
		"high_score": high_score,
		"combo": current_combo if enable_combos else "disabled",
		"combo_timer": "%.2fs" % _combo_timer if _combo_active else "inactive",
		"multiplier": "x%.2f" % get_total_multiplier(),
		"rank": Rank.keys()[current_rank] if enable_ranks else "disabled",
		"next_milestone": _get_next_milestone()
	}

## Get next milestone
func _get_next_milestone() -> String:
	for milestone in milestones:
		if milestone > current_score:
			return str(milestone)
	return "none"
#endregion
