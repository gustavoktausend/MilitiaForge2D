## Object Pool
##
## Generic object pooling system to reduce instantiation overhead.
## Follows SOLID principles for reusability across different object types.
##
## Benefits:
## - Reduces GC pressure by reusing objects instead of destroying them
## - Improves performance by avoiding costly instantiate() calls
## - Prevents frame drops from mass spawning/destruction
##
## Usage:
##   var pool = ObjectPool.new(projectile_scene, 50)
##   var projectile = pool.acquire()  # Get from pool
##   # ... use projectile ...
##   pool.release(projectile)  # Return to pool
##
## @tutorial(Object Pooling): https://en.wikipedia.org/wiki/Object_pool_pattern

class_name ObjectPool extends RefCounted

#region Configuration
## The scene to pool
var pooled_scene: PackedScene

## Maximum pool size (to prevent unbounded growth)
var max_pool_size: int = 100

## Initial pool size (pre-warmed objects)
var initial_pool_size: int = 20
#endregion

#region Private Variables
## Available objects ready for reuse
var _available_objects: Array[Node] = []

## Objects currently in use
var _active_objects: Array[Node] = []

## Parent node to store pooled objects (keeps scene tree clean)
var _pool_container: Node = null
#endregion

#region Lifecycle
## Constructor
## @param scene: The PackedScene to pool
## @param initial_size: How many objects to pre-create (default: 20)
## @param max_size: Maximum pool size (default: 100)
func _init(scene: PackedScene, initial_size: int = 20, max_size: int = 100) -> void:
	pooled_scene = scene
	initial_pool_size = initial_size
	max_pool_size = max_size

## Initialize pool with pre-warmed objects
## Call this once at game start for best performance
func initialize(container: Node) -> void:
	if not pooled_scene:
		push_error("[ObjectPool] No scene to pool!")
		return

	_pool_container = container

	# Pre-warm pool with initial objects
	for i in range(initial_pool_size):
		var obj = _create_new_object()
		if obj:
			_available_objects.append(obj)

	print("[ObjectPool] Initialized with %d pre-warmed objects" % _available_objects.size())

## Cleanup all pooled objects
func cleanup() -> void:
	# Clean up available objects
	for obj in _available_objects:
		if is_instance_valid(obj):
			obj.queue_free()
	_available_objects.clear()

	# Clean up active objects
	for obj in _active_objects:
		if is_instance_valid(obj):
			obj.queue_free()
	_active_objects.clear()

	print("[ObjectPool] Cleaned up pool")
#endregion

#region Public API
## Acquire an object from the pool
## Returns: An object ready to use, or null if creation failed
func acquire() -> Node:
	var obj: Node = null

	# Try to reuse an available object
	if _available_objects.size() > 0:
		obj = _available_objects.pop_back()
		_reset_object(obj)
	else:
		# Create new object if pool is empty
		obj = _create_new_object()
		if not obj:
			push_error("[ObjectPool] Failed to create new object!")
			return null

	# Track as active
	_active_objects.append(obj)

	# CRITICAL FIX: Ensure object is in the tree
	# If object is not in tree (can happen during initialization), re-add it
	if not obj.is_inside_tree() and _pool_container:
		# Remove and re-add to ensure proper tree entry
		if obj.get_parent():
			obj.get_parent().remove_child(obj)
		_pool_container.add_child(obj)

		# Wait for next frame to ensure object enters tree
		var tree = _pool_container.get_tree()
		if tree:
			await tree.process_frame

	# Make visible and enable processing
	obj.visible = true
	obj.process_mode = Node.PROCESS_MODE_INHERIT

	return obj

## Release an object back to the pool
## @param obj: The object to return (must have been acquired from this pool)
func release(obj: Node) -> void:
	if not is_instance_valid(obj):
		return

	# Remove from active tracking
	var idx = _active_objects.find(obj)
	if idx >= 0:
		_active_objects.remove_at(idx)

	# Return to pool if under max size, otherwise destroy
	if _available_objects.size() < max_pool_size:
		_deactivate_object(obj)
		_available_objects.append(obj)
	else:
		# Pool is full, destroy the object
		obj.queue_free()

## Get pool statistics for debugging
func get_stats() -> Dictionary:
	return {
		"available": _available_objects.size(),
		"active": _active_objects.size(),
		"total": _available_objects.size() + _active_objects.size(),
		"max_size": max_pool_size
	}

## Print pool statistics
func debug_print_stats() -> void:
	var stats = get_stats()
	print("[ObjectPool] Available: %d | Active: %d | Total: %d/%d" % [
		stats["available"],
		stats["active"],
		stats["total"],
		stats["max_size"]
	])
#endregion

#region Private Methods
## Create a new object instance
func _create_new_object() -> Node:
	var obj = pooled_scene.instantiate()

	if not obj:
		push_error("[ObjectPool] Failed to instantiate scene!")
		return null

	# Add to pool container to keep scene tree clean
	if _pool_container:
		_pool_container.add_child(obj)

	# Start disabled
	_deactivate_object(obj)

	return obj

## Deactivate object (hide and disable processing)
func _deactivate_object(obj: Node) -> void:
	obj.visible = false
	obj.process_mode = Node.PROCESS_MODE_DISABLED

	# Reset position to avoid issues
	if obj is Node2D:
		obj.global_position = Vector2.ZERO

## Reset object to default state
func _reset_object(obj: Node) -> void:
	# Reset common properties
	if obj is Node2D:
		obj.rotation = 0.0
		obj.scale = Vector2.ONE

	# Call custom reset method if available
	if obj.has_method("reset_for_pool"):
		obj.reset_for_pool()
#endregion
