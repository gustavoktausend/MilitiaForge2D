class_name MovementStrategy extends Resource

## Base Strategy for Entity Movement.
## Encapsulates HOW an entity moves, decoupled from the entity itself.

## Moves the subject entity based on the strategy logic.
## @param subject: The Node2D (usually Enemy) to move.
## @param delta: Time step.
## @param data: Optional context data (speed, stats, etc).
func move(subject: Node2D, delta: float, data: Dictionary = {}) -> void:
    push_warning("MovementStrategy: move() not implemented")
