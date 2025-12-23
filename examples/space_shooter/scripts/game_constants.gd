## Game Constants for Space Shooter
##
## Centralized constants to eliminate magic numbers and ensure consistency.
## Registered as autoload singleton for global access.
##
## Usage:
##   var spawn_x = GameConstants.PLAY_AREA_CENTER + offset
##   if position.x < GameConstants.PLAY_AREA_LEFT:
##       # ...

class_name SpaceShooterConstants extends Node

#region Screen Layout (1920x1080)
## Total screen width
const SCREEN_WIDTH: int = 1920

## Total screen height
const SCREEN_HEIGHT: int = 1080

## Width of left HUD panel
const LEFT_PANEL_WIDTH: int = 480

## Width of right HUD panel
const RIGHT_PANEL_WIDTH: int = 480

## Width of playable area (between HUD panels)
const PLAY_AREA_WIDTH: int = 960

## X position where play area starts (after left panel)
const PLAY_AREA_LEFT: int = 480

## X position where play area ends (before right panel)
const PLAY_AREA_RIGHT: int = 1440

## Center X position of play area
const PLAY_AREA_CENTER: int = 960  # 480 + (960 / 2)

## Half width of play area (for calculations)
const PLAY_AREA_HALF_WIDTH: int = 480
#endregion

#region Gameplay Boundaries
## Margin from play area edges for spawning/movement
const BOUNDARY_MARGIN: int = 30

## Left boundary for enemy movement (with margin)
const ENEMY_LEFT_BOUND: int = PLAY_AREA_LEFT + BOUNDARY_MARGIN  # 510

## Right boundary for enemy movement (with margin)
const ENEMY_RIGHT_BOUND: int = PLAY_AREA_RIGHT - BOUNDARY_MARGIN  # 1410

## Top boundary (off-screen spawn)
const SPAWN_TOP: int = -50

## Bottom boundary (despawn line)
const DESPAWN_BOTTOM: int = SCREEN_HEIGHT + 50
#endregion

#region Player Settings
## Player starting health
const PLAYER_MAX_HEALTH: int = 100

## Player movement speed
const PLAYER_SPEED: float = 400.0

## Player invincibility duration after taking damage
const PLAYER_INVINCIBILITY_DURATION: float = 0.5
#endregion

#region Enemy Settings
## Basic enemy default health
const ENEMY_BASIC_HEALTH: int = 20

## Fast enemy default health
const ENEMY_FAST_HEALTH: int = 10

## Tank enemy default health
const ENEMY_TANK_HEALTH: int = 50

## Basic enemy default speed
const ENEMY_BASIC_SPEED: float = 100.0

## Fast enemy default speed
const ENEMY_FAST_SPEED: float = 200.0

## Tank enemy default speed
const ENEMY_TANK_SPEED: float = 60.0
#endregion

#region Projectile Settings
## Player projectile speed
const PLAYER_PROJECTILE_SPEED: float = 600.0

## Player projectile damage
const PLAYER_PROJECTILE_DAMAGE: int = 10

## Enemy projectile speed
const ENEMY_PROJECTILE_SPEED: float = 300.0

## Enemy projectile damage
const ENEMY_PROJECTILE_DAMAGE: int = 20
#endregion

#region Wave Settings
## Delay before first wave starts
const WAVE_START_DELAY: float = 2.0

## Delay between waves
const WAVE_DELAY: float = 3.0
#endregion

#region Collision Layers
## Collision layer for player
const LAYER_PLAYER: int = 1

## Collision layer for enemies
const LAYER_ENEMIES: int = 2

## Collision layer for player projectiles
const LAYER_PLAYER_PROJECTILES: int = 4

## Collision layer for enemy projectiles
const LAYER_ENEMY_PROJECTILES: int = 8
#endregion

#region Helper Functions
## Check if a position is inside the play area
static func is_in_play_area(pos: Vector2) -> bool:
	return pos.x >= PLAY_AREA_LEFT and pos.x <= PLAY_AREA_RIGHT

## Clamp a position to play area boundaries (with margin)
static func clamp_to_play_area(pos: Vector2, margin: float = 0) -> Vector2:
	return Vector2(
		clampf(pos.x, PLAY_AREA_LEFT + margin, PLAY_AREA_RIGHT - margin),
		pos.y
	)

## Get random X position within play area
static func random_play_area_x(margin: float = BOUNDARY_MARGIN) -> float:
	return randf_range(PLAY_AREA_LEFT + margin, PLAY_AREA_RIGHT - margin)

## Get random spawn position at top of play area
static func random_spawn_position(margin: float = BOUNDARY_MARGIN) -> Vector2:
	return Vector2(random_play_area_x(margin), SPAWN_TOP)
#endregion
