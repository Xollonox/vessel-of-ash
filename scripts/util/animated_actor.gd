class_name AnimatedActor
extends Node3D
## Character model + retargeted animation library.
##
## The Quaternius character models and the Universal Animation Library share the
## same 65-bone rig, so retargeting is a deterministic path rewrite: every track
## that points at the library's skeleton is re-pointed at this model's skeleton.

@export var model_path: String = "res://assets/models/characters/Superhero_Male_FullBody.gltf"
@export var anim_path: String = "res://assets/animations/UAL2_Standard.glb"
@export var scale_factor: float = 1.0
@export var model_yaw_offset: float = 0.0

signal anim_finished(clip: String)

var skeleton: Skeleton3D
var player: AnimationPlayer
var model: Node3D
var ready_ok := false

var _clips := {}
var _flash_gen := 0

func _ready() -> void:
    _build()

func _build() -> void:
    var model_scene: PackedScene = load(model_path)
    if model_scene == null:
        push_warning("AnimatedActor: cannot load " + model_path)
        _fallback()
        return
    var model: Node3D = model_scene.instantiate()
    model.name = "Model"
    model.scale = Vector3.ONE * scale_factor
    model.rotation.y = model_yaw_offset
    add_child(model)
    self.model = model
    skeleton = _find(model, "Skeleton3D") as Skeleton3D
    if skeleton == null:
        push_warning("AnimatedActor: no Skeleton3D in " + model_path)
        _fallback()
        return
    var lib_scene: PackedScene = load(anim_path)
    if lib_scene == null:
        push_warning("AnimatedActor: cannot load " + anim_path)
        return
    var lib_inst: Node = lib_scene.instantiate()
    var src: AnimationPlayer = _find(lib_inst, "AnimationPlayer") as AnimationPlayer
    if src == null:
        push_warning("AnimatedActor: no AnimationPlayer in " + anim_path)
        lib_inst.free()
        return
    player = AnimationPlayer.new()
    player.name = "Anim"
    add_child(player)
    player.root_node = player.get_path_to(self)
    var skel_rel := String(get_path_to(skeleton))
    var lib := AnimationLibrary.new()
    var dropped := 0
    for clip in src.get_animation_list():
        var src_anim: Animation = src.get_animation(clip)
        if src_anim == null:
            continue
        var anim: Animation = src_anim.duplicate(true)
        var kept := 0
        for i in anim.get_track_count():
            var np: NodePath = anim.track_get_path(i)
            var bone := String(np.get_concatenated_subnames())
            if skeleton.find_bone(bone) < 0:
                dropped += 1
                continue
            anim.track_set_path(i, NodePath(skel_rel + ":" + bone))
            kept += 1
        if kept > 0:
            lib.add_animation(clip, anim)
            _clips[clip] = true
    player.add_animation_library("", lib)
    lib_inst.free()
    ready_ok = true
    player.animation_finished.connect(_on_anim_finished)
    print("[AnimatedActor] ", model_path.get_file(), ": ", _clips.size(), " clips retargeted, ", dropped, " tracks dropped")

func _on_anim_finished(clip: String) -> void:
    anim_finished.emit(clip)

func _fallback() -> void:
    var mi := MeshInstance3D.new()
    var cap := CapsuleMesh.new()
    cap.radius = 0.36
    cap.height = 1.75
    mi.mesh = cap
    mi.position = Vector3(0, 0.875, 0)
    add_child(mi)

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
    player.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
    player.play(clip, 0.14, speed)
    return true

func play_once(clip: String, speed: float = 1.0) -> bool:
    if player == null or not _clips.has(clip):
        return false
    player.get_animation(clip).loop_mode = Animation.LOOP_NONE
    player.play(clip, 0.08, speed)
    return true

func play_once_rev(clip: String, speed: float = 1.0) -> bool:
    if player == null or not _clips.has(clip):
        return false
    player.get_animation(clip).loop_mode = Animation.LOOP_NONE
    player.play(clip, 0.08, -speed)
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
