## Selects the target that is physically closest to the turret.
class_name ClosestTargetStrategy extends TargetingStrategy

func select_target(turret: Node2D, candidates: Array[Node2D]) -> Node2D:
	var best_target: Node2D = null
	var min_dist_sq = INF
	var turret_pos = turret.global_position
	
	for candidate in candidates:
		if not is_instance_valid(candidate): continue
		
		var dist_sq = turret_pos.distance_squared_to(candidate.global_position)
		if dist_sq < min_dist_sq:
			min_dist_sq = dist_sq
			best_target = candidate
			
	return best_target
