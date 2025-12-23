class_name PathFollowMovementStrategy extends MovementStrategy

## Movement Strategy that assumes the subject is a child of PathFollow2D (or has one).

@export var loop: bool = false
@export var rotate: bool = true

func move(subject: Node2D, delta: float, data: Dictionary = {}) -> void:
    # Expectation: The subject's parent is the PathFollow2D, 
    # OR we pass the PathFollow2D node in 'data'.
    var path_follow: PathFollow2D = data.get("path_follow", null)
    
    if not path_follow:
        # Fallback: Check parent
        var parent = subject.get_parent()
        if parent is PathFollow2D:
            path_follow = parent
    
    if path_follow:
        var speed = data.get("speed", 100.0)
        path_follow.progress += speed * delta
        path_follow.loop = loop
        path_follow.rotates = rotate
    else:
        push_warning("PathFollowMovementStrategy: No PathFollow2D found for %s" % subject.name)
