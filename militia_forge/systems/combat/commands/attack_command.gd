class_name AttackCommand extends Resource

## Base Command for Attacks.
## Encapsulates the logic of an attack action (Fire logic, Effects, Cooldown checks).

@export var cooldown: float = 1.0
@export var damage: int = 10
@export var range_radius: float = 200.0

## Executed when the attack is requested.
## @param source: The entity launching the attack (Tower).
## @param target: The target entity (Enemy).
## @return: True if attack was successfully initiated.
func execute(source: Node2D, target: Node2D) -> bool:
    return false
