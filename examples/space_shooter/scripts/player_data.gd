## Player Data Autoload
##
## Stores persistent player data across scenes (ship selection, settings, etc.)
##
## Design Pattern: Singleton (autoload) for global state management

extends Node

#region Ship Selection
## Currently selected ship configuration
var selected_ship_config: ShipConfig

## Available ship configurations
var available_ships: Array[ShipConfig] = []

## Ship color customization
var selected_ship_color: Color = Color.WHITE
var selected_color_intensity: float = 1.0
#endregion

#region Pilot Selection
## Currently selected pilot
var selected_pilot_data: PilotData

## Available pilots (loaded from database)
var available_pilots: Array[PilotData] = []
#endregion

#region Weapon Selection (Temporary for Testing)
## Selected weapons - will be removed when ship loadout system is implemented
var selected_primary_weapon: String = "basic_laser"
var selected_secondary_weapon: String = "homing_missile"
var selected_special_weapon: String = "plasma_bomb"
#endregion

func _ready() -> void:
	_load_available_ships()
	_load_available_pilots()

	# Set default ship if none selected
	if not selected_ship_config and available_ships.size() > 0:
		selected_ship_config = available_ships[0]

	# Set default pilot if none selected
	if not selected_pilot_data and available_pilots.size() > 0:
		selected_pilot_data = available_pilots[0]

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

#region Pilot Selection Methods
## Load all available pilots from database
func _load_available_pilots() -> void:
	available_pilots = PilotDatabase.get_all_pilots()
	print("[PlayerData] Loaded %d pilots from database" % available_pilots.size())

## Select a pilot by index
func select_pilot(index: int) -> void:
	if index >= 0 and index < available_pilots.size():
		selected_pilot_data = available_pilots[index]
		print("[PlayerData] Selected pilot: %s" % selected_pilot_data.pilot_name)

## Select a pilot by name (case-insensitive)
func select_pilot_by_name(pilot_name: String) -> void:
	var pilot = PilotDatabase.get_pilot(pilot_name)
	if pilot:
		selected_pilot_data = pilot
		print("[PlayerData] Selected pilot: %s" % selected_pilot_data.pilot_name)
	else:
		push_error("[PlayerData] Pilot not found: %s" % pilot_name)

## Get currently selected pilot
func get_selected_pilot() -> PilotData:
	return selected_pilot_data

## Get pilot index (for UI)
func get_selected_pilot_index() -> int:
	if not selected_pilot_data:
		return -1

	for i in range(available_pilots.size()):
		if available_pilots[i].pilot_name == selected_pilot_data.pilot_name:
			return i

	return -1
#endregion
