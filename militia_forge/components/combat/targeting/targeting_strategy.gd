## Base class for Turret Targeting Strategies.
## Implements the Strategy Pattern for selecting targets.
class_name TargetingStrategy extends Resource

## abstract method to select the best target from a list of candidates.
## @param turret: The turret component asking for a target (useful for position)
## @param candidates: List of Node2D (potential targets)
## @return: The selected target Node2D, or null if none suitable
func select_target(turret: Node2D, candidates: Array[Node2D]) -> Node2D:
	return null
