## Player Data Autoload
##
## Stores persistent player data across scenes (ship selection, settings, etc.)

extends Node

#region Ship Selection
## Currently selected ship configuration
var selected_ship_config: ShipConfig

## Available ship configurations
var available_ships: Array[ShipConfig] = []
#endregion

func _ready() -> void:
	_load_available_ships()

	# Set default ship if none selected
	if not selected_ship_config and available_ships.size() > 0:
		selected_ship_config = available_ships[0]

## Load all available ship configurations
func _load_available_ships() -> void:
	available_ships = [
		load("res://examples/space_shooter/resources/ships/ship_balanced.tres"),
		load("res://examples/space_shooter/resources/ships/ship_speed.tres"),
		load("res://examples/space_shooter/resources/ships/ship_tank.tres")
	]

## Select a ship by index
func select_ship(index: int) -> void:
	if index >= 0 and index < available_ships.size():
		selected_ship_config = available_ships[index]

## Get currently selected ship
func get_selected_ship() -> ShipConfig:
	return selected_ship_config
