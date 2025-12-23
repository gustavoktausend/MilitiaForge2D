## Selects the target that is furthest along the path (highest progress).
## Assumes targets are parented to a PathFollow2D node.
class_name FirstTargetStrategy extends TargetingStrategy

func select_target(_turret: Node2D, candidates: Array[Node2D]) -> Node2D:
	var best_target: Node2D = null
	var max_progress = -1.0
	
	for candidate in candidates:
		if not is_instance_valid(candidate): continue
		
		# Check if candidate has a PathFollow2D parent (standard for our TD)
		var parent = candidate.get_parent()
		if parent is PathFollow2D:
			# Use progress or progress_ratio
			if parent.progress > max_progress:
				max_progress = parent.progress
				best_target = candidate
				
	# Fallback to index 0 if simply first in list and no path data (simplified)
	if not best_target and not candidates.is_empty():
		return candidates[0]
		
	return best_target
