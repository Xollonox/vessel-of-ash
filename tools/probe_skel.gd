extends SceneTree
## Dumps rig info for the KayKit skeleton pack.
## Run: godot --headless --path . --script res://tools/probe_skel.gd

func _initialize() -> void:
    for f in ["Skeleton_Minion", "Skeleton_Rogue", "Skeleton_Warrior", "Skeleton_Mage"]:
        var ps: PackedScene = load("res://assets/models/skeletons/%s.glb" % f)
        if ps == null:
            print("!! %s failed" % f)
            continue
        var inst: Node = ps.instantiate()
        print("== %s ==" % f)
        _walk(inst, 0)
        var ap := _find(inst, "AnimationPlayer")
        if ap != null:
            var names: PackedStringArray = ap.get_animation_list()
            print("   anims(%d): %s" % [names.size(), ", ".join(names.slice(0, 8))])
        var sk := _find(inst, "Skeleton3D")
        if sk != null:
            var bn: PackedStringArray = []
            for bi in sk.get_bone_count():
                bn.append(sk.get_bone_name(bi))
            print("   bones=%d: %s" % [sk.get_bone_count(), ", ".join(bn)])
        var mi := _find(inst, "MeshInstance3D")
        if mi != null:
            print("   aabb=%s" % mi.get_aabb())
        inst.free()
    quit(0)

func _walk(n: Node, d: int) -> void:
    if d <= 2:
        print("   %s%s (%s)" % ["  ".repeat(d), n.name, n.get_class()])
    for c in n.get_children():
        _walk(c, d + 1)

func _find(root: Node, cls: String) -> Node:
    if root.get_class() == cls:
        return root
    for c in root.get_children():
        var r := _find(c, cls)
        if r != null:
            return r
    return null