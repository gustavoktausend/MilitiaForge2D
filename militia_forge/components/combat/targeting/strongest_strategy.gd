## Selects the target with the highest current health.
## Requires targets to have a HealthComponent.
class_name StrongestTargetStrategy extends TargetingStrategy

func select_target(_turret: Node2D, candidates: Array[Node2D]) -> Node2D:
	var best_target: Node2D = null
	var max_health = -1
	
	for candidate in candidates:
		if not is_instance_valid(candidate): continue
		
		# Try to find health component via ComponentHost
		var health: int = 0
		
		# Direct child check
		if candidate.has_node("ComponentHost"):
			var host = candidate.get_node("ComponentHost")
			var health_comp = host.get_component("HealthComponent")
			if health_comp:
				health = health_comp.current_health
		
		if health > max_health:
			max_health = health
			best_target = candidate
			
	return best_target
