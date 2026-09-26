class_name SkeletonActor
extends Node3D
## KayKit Skeleton pack actor (CC0). Unlike AnimatedActor these models ship with
## their own 41-bone rig AND their own 95 baked clips, so no retargeting happens -
## the model's own AnimationPlayer just plays the clip it already owns.
##
## Exposes the same surface the gameplay code already uses on AnimatedActor
## (play_loop / play_once / current / set_speed / flash / has_clip / sword_tip)
## so enemies can swap between the two without touching AI code.

signal anim_finished(clip: String)

@export var model_path: String = "res://assets/models/skeletons/Skeleton_Minion.glb"
@export var scale_factor: float = 1.0
@export var model_yaw_offset: float = 0.0
@export var weapon_path: String = ""
@export var weapon_bone: String = "handslot.r"
@export var weapon_scale: float = 1.0
@export var weapon_rot: Vector3 = Vector3.ZERO
@export var weapon_offset: Vector3 = Vector3.ZERO
@export var tip_offset: Vector3 = Vector3(0, 1.2, 0)

var player: AnimationPlayer
var skeleton: Skeleton3D
var model: Node3D
var weapon: Node3D
var weapon_tip: Marker3D
var ready_ok := false

var _clips := {}
var _flash_gen := 0
var _socket: BoneAttachment3D

func _ready() -> void:
    _build()

func _build() -> void:
    var ps: PackedScene = load(model_path)
    if ps == null:
        push_warning("SkeletonActor: cannot load " + model_path)
        _fallback()
        return
    model = ps.instantiate()
    model.name = "Model"
    model.scale = Vector3.ONE * scale_factor
    model.rotation.y = model_yaw_offset
    add_child(model)
    skeleton = _find(model, "Skeleton3D") as Skeleton3D
    player = _find(model, "AnimationPlayer") as AnimationPlayer
    if skeleton == null or player == null:
        push_warning("SkeletonActor: missing rig in " + model_path)
        _fallback()
        return
    for clip in player.get_animation_list():
        _clips[clip] = true
    player.animation_finished.connect(_on_anim_finished)
    ready_ok = true
    if weapon_path != "":
        _attach_weapon()

func _fallback() -> void:
    var mi := MeshInstance3D.new()
    var cap := CapsuleMesh.new()
    cap.radius = 0.36
    cap.height = 1.75
    mi.mesh = cap
    mi.position = Vector3(0, 0.875, 0)
    add_child(mi)

func _attach_weapon() -> void:
    var ps: PackedScene = load(weapon_path)
    if ps == null:
        push_warning("SkeletonActor: cannot load weapon " + weapon_path)
        return
    if skeleton.find_bone(weapon_bone) < 0:
        push_warning("SkeletonActor: no bone " + weapon_bone)
        return
    _socket = BoneAttachment3D.new()
    _socket.name = "WeaponSocket"
    _socket.bone_name = weapon_bone
    skeleton.add_child(_socket)
    weapon = ps.instantiate()
    weapon.name = "Weapon"
    _socket.add_child(weapon)
    weapon.scale = Vector3.ONE * weapon_scale
    weapon.rotation_degrees = weapon_rot
    weapon.position = weapon_offset
    weapon_tip = Marker3D.new()
    weapon_tip.name = "Tip"
    weapon_tip.position = tip_offset
    weapon.add_child(weapon_tip)

func sword_tip() -> Vector3:
    if weapon_tip != null and is_instance_valid(weapon_tip):
        return weapon_tip.global_position
    return global_position + Vector3(0, 1.0, 0)

func _on_anim_finished(clip: String) -> void:
    anim_finished.emit(clip)

func flash(color: Color = Color(1.0, 0.92, 0.85, 0.85), time: float = 0.13) -> void:
    if model == null or not is_instance_valid(model):
        return
    _flash_gen += 1
    var g := _flash_gen
    var m := StandardMaterial3D.new()
    m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    m.albedo_color = color
    m.disable_receive_shadows = true
    var meshes := _meshes(model)
    for mi in meshes:
        mi.material_overlay = m
    var tw := create_tween()
    tw.tween_property(m, "albedo_color:a", 0.0, time)
    tw.tween_callback(func() -> void:
        if g != _flash_gen:
            return
        for mi in meshes:
            if is_instance_valid(mi):
                mi.material_overlay = null)

func _meshes(root: Node, out: Array[MeshInstance3D] = []) -> Array[MeshInstance3D]:
    if root is MeshInstance3D:
        out.append(root as MeshInstance3D)
    for c in root.get_children():
        _meshes(c, out)
    return out

func has_clip(clip: String) -> bool:
    return _clips.has(clip)

func clip_len(clip: String) -> float:
    if player == null or not _clips.has(clip):
        return 0.0
    return player.get_animation(clip).length

func set_speed(s: float) -> void:
    if player != null:
        player.speed_scale = s

func play_loop(clip: String, speed: float = 1.0) -> bool:
    if player == null or not _clips.has(clip):
        return false
    if player.current_animation == clip and player.is_playing():
        player.speed_scale = speed
        return true
    player.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
    player.play(clip, 0.12, speed)
    return true

func play_once(clip: String, speed: float = 1.0) -> bool:
    if player == null or not _clips.has(clip):
        return false
    player.get_animation(clip).loop_mode = Animation.LOOP_NONE
    player.play(clip, 0.06, speed)
    return true

func play_once_rev(clip: String, speed: float = 1.0) -> bool:
    if player == null or not _clips.has(clip):
        return false
    player.get_animation(clip).loop_mode = Animation.LOOP_NONE
    player.play(clip, 0.06, -speed)
    return true

func current() -> String:
    if player == null:
        return ""
    return player.current_animation

func _find(root: Node, cls: String) -> Node:
    if root.is_class(cls):
        return root
    for c in root.get_children():
        var r := _find(c, cls)
        if r != null:
            return r
    return null