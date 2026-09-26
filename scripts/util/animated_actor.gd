class_name AnimatedActor
extends Node3D
## Character model + retargeted animation library + gear.
##
## The Quaternius character models and the Universal Animation Library share the
## same 65-bone rig, so retargeting is a deterministic path rewrite: every track
## that points at the library's skeleton is re-pointed at this model's skeleton.
##
## Gear:
## - weapon: socketed to the right hand with a BoneAttachment3D
## - hair:   worn by copying our skeleton's bone poses onto the hair's own
##           skeleton every frame (same rig, so it is a direct name match)
## - skin:   a recoloured albedo texture applied per instance, so shared
##           materials are never mutated

@export var model_path: String = "res://assets/models/characters/Superhero_Male_FullBody.gltf"
@export var anim_path: String = "res://assets/animations/UAL2_Standard.glb"
@export var scale_factor: float = 1.0
@export var model_yaw_offset: float = 0.0
@export var skin_texture: String = ""
@export var weapon_path: String = ""
@export var weapon_scale: float = 0.55
@export var weapon_rot: Vector3 = Vector3.ZERO
@export var weapon_offset: Vector3 = Vector3.ZERO
@export var hair_path: String = ""

signal anim_finished(clip: String)

var skeleton: Skeleton3D
var player: AnimationPlayer
var model: Node3D
var weapon: Node3D
var weapon_tip: Marker3D
var hair: Node3D
var ready_ok := false

var _clips := {}
var _flash_gen := 0
var _hair_skel: Skeleton3D
var _hair_map: Array = []

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
    if skin_texture != "":
        _apply_skin()
    if weapon_path != "":
        _attach_weapon()
    if hair_path != "":
        _attach_hair()

func _process(_delta: float) -> void:
    if _hair_skel == null or skeleton == null:
        return
    for i in _hair_map.size():
        var j: int = _hair_map[i]
        if j >= 0:
            _hair_skel.set_bone_pose(j, skeleton.get_bone_pose(i))

func _apply_skin() -> void:
    var tex: Texture2D = load(skin_texture)
    if tex == null:
        push_warning("AnimatedActor: cannot load skin " + skin_texture)
        return
    for mi in _meshes(model):
        if mi.mesh == null:
            continue
        for s in mi.mesh.get_surface_count():
            var base := mi.get_active_material(s)
            var m: StandardMaterial3D
            if base is StandardMaterial3D:
                m = (base as StandardMaterial3D).duplicate()
            else:
                m = StandardMaterial3D.new()
            m.albedo_texture = tex
            mi.set_surface_override_material(s, m)

func _attach_weapon() -> void:
    var ps: PackedScene = load(weapon_path)
    if ps == null:
        push_warning("AnimatedActor: cannot load weapon " + weapon_path)
        return
    var att := BoneAttachment3D.new()
    att.name = "WeaponSocket"
    att.bone_name = "hand_r"
    skeleton.add_child(att)
    weapon = ps.instantiate()
    weapon.name = "Weapon"
    att.add_child(weapon)
    weapon.scale = Vector3.ONE * weapon_scale
    weapon.rotation_degrees = weapon_rot
    weapon.position = weapon_offset
    weapon_tip = Marker3D.new()
    weapon_tip.name = "Tip"
    weapon_tip.position = Vector3(0, 1.45, 0)
    weapon.add_child(weapon_tip)

func sword_tip() -> Vector3:
    if weapon_tip != null and is_instance_valid(weapon_tip):
        return weapon_tip.global_position
    return Vector3.ZERO

func _attach_hair() -> void:
    var ps: PackedScene = load(hair_path)
    if ps == null:
        push_warning("AnimatedActor: cannot load hair " + hair_path)
        return
    hair = ps.instantiate()
    hair.name = "Hair"
    add_child(hair)
    hair.scale = Vector3.ONE * scale_factor
    hair.rotation.y = model_yaw_offset
    _hair_skel = _find(hair, "Skeleton3D") as Skeleton3D
    if _hair_skel == null or skeleton == null:
        push_warning("AnimatedActor: hair has no skeleton")
        return
    _hair_map.resize(skeleton.get_bone_count())
    for i in skeleton.get_bone_count():
        _hair_map[i] = _hair_skel.find_bone(skeleton.get_bone_name(i))

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
