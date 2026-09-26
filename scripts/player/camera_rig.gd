class_name CameraRig
extends Node3D
## Third-person camera: mouse/right-stick orbit, lock-on framing, wall pull-in,
## and hit shake.

@export var target: Node3D
var yaw := 0.0
var pitch := -0.14
var distance := 4.9
var pivot_height := 1.5
var sensitivity := 0.0024
var shake := 0.0
var base_fov := 62.0

var _cam: Camera3D
var _lock_target: Node3D

func _ready() -> void:
    add_to_group("camera_rig")
    _cam = Camera3D.new()
    _cam.fov = base_fov
    _cam.near = 0.05
    add_child(_cam)
    if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
        Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
        yaw -= event.relative.x * sensitivity
        pitch = clampf(pitch - event.relative.y * sensitivity, -1.0, 0.45)
    elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
        if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
            Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
        else:
            Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta: float) -> void:
    if target == null or not is_instance_valid(target):
        return
    var p := target.global_position
    var goal := p + Vector3(0, pivot_height, 0)
    global_position = global_position.lerp(goal, clampf(10.0 * delta, 0.0, 1.0))
    _lock_target = null
    if target is Player:
        _lock_target = (target as Player).lock_target
    if _lock_target != null and is_instance_valid(_lock_target):
        var to := (_lock_target.global_position + Vector3(0, 1.0, 0)) - (p + Vector3(0, 1.35, 0))
        yaw = lerp_angle(yaw, atan2(-to.x, -to.z), clampf(5.0 * delta, 0.0, 1.0))
        pitch = lerpf(pitch, -0.06, clampf(2.4 * delta, 0.0, 1.0))
    var fwd := Vector3(-sin(yaw) * cos(pitch), sin(pitch), -cos(yaw) * cos(pitch)).normalized()
    var eye := global_position
    var desired := eye - fwd * distance
    var space := get_world_3d().direct_space_state
    var q := PhysicsRayQueryParameters3D.create(eye, desired)
    q.collision_mask = 4
    var hit := space.intersect_ray(q)
    if not hit.is_empty():
        desired = hit.get("position") + fwd * 0.28
    if shake > 0.0:
        shake = maxf(0.0, shake - delta * 2.2)
        desired += Vector3(randf_range(-1.0, 1.0), randf_range(-0.7, 1.0), randf_range(-1.0, 1.0)) * shake * 0.09
    _cam.global_position = desired
    _cam.look_at(eye + fwd * 10.0, Vector3.UP)

func add_shake(amount: float) -> void:
    shake = minf(1.4, shake + amount)

func fov_punch(amount: float) -> void:
    if _cam == null:
        return
    var t := create_tween()
    t.tween_property(_cam, "fov", base_fov + amount, 0.07)
    t.tween_property(_cam, "fov", base_fov, 0.30)
