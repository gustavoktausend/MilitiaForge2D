class_name EventBus extends Node

## Global Event Bus for the Tower Defense Framework.
## Acts as a central relay to decouple systems (Observer Pattern).
## Usage: Autoload this script as 'GlobalEventBus' or inject it where needed.

#region Combat Events
signal wave_started(wave_number: int)
signal wave_completed(wave_number: int)

signal enemy_spawned(enemy: Node2D)
signal enemy_reached_base(enemy: Node2D, damage: int)
signal enemy_killed(enemy: Node2D, reward: int)

signal tower_placed(tower: Node2D, position: Vector2)
signal tower_sold(tower: Node2D, refund: int)

signal base_damaged(current_health: int, max_health: int)
signal game_over(is_win: bool)
#endregion

#region Economy Events
signal gold_changed(current_gold: int, amount_changed: int)
#endregion

#region Input/UI Events
signal build_mode_requested(tower_data: Resource)
signal build_mode_canceled()
#endregion
