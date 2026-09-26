extends SceneTree
## Dumps rig + clip information for the character and the animation library.
## Run: godot --headless --path . --script res://tools/inspect.gd

func _initialize() -> void:
    print("== character: Superhero_Male_FullBody ==")
    var ch: PackedScene = load("res://assets/models/characters/Superhero_Male_FullBody.gltf")
    if ch == null:
        print("!! character failed to load")
    else:
        var inst := ch.instantiate()
        _dump(inst)
        inst.free()
    print("== library: UAL2_Standard ==")
    var lib: PackedScene = load("res://assets/animations/UAL2_Standard.glb")
    if lib == null:
        print("!! library failed to load")
    else:
        var inst2 := lib.instantiate()
        _dump(inst2)
        inst2.free()
    quit()

func _dump(n: Node, depth: int = 0) -> void:
    var pad := "  ".repeat(depth)
    if n is Skeleton3D:
        var sk := n as Skeleton3D
        print(pad, "Skeleton3D '", sk.name, "' bones=", sk.get_bone_count())
        for i in sk.get_bone_count():
            print(pad, "    ", i, ": ", sk.get_bone_name(i))
    if n is AnimationPlayer:
        var ap := n as AnimationPlayer
        var names := ap.get_animation_list()
        print(pad, "AnimationPlayer '", ap.name, "' animations=", names.size())
        for a in names:
            var anim := ap.get_animation(a)
            var t0 := ""
            if anim.get_track_count() > 0:
                t0 = str(anim.track_get_path(0))
            print(pad, "    clip: ", a, "  len=", snappedf(anim.length, 0.001), "  tracks=", anim.get_track_count(), "  first=", t0)
    if n is MeshInstance3D:
        print(pad, "MeshInstance3D '", n.name, "'")
    for c in n.get_children():
        _dump(c, depth + 1)
