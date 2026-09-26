extends Node
func _ready() -> void:
    for p in ["res://assets/props/dungeon/torch_lit.gltf.glb",
              "res://assets/props/dungeon/pillar.gltf.glb",
              "res://assets/props/dungeon/sword_shield.gltf.glb",
              "res://assets/weapons/sword_1handed.gltf",
              "res://assets/hair/Hair_SimpleParted.gltf"]:
        var ps: PackedScene = load(p)
        if ps == null:
            print("LOADFAIL ", p)
            continue
        var inst := ps.instantiate()
        add_child(inst)
        var aabb := _aabb(inst)
        print("OK ", p.get_file(), " size=", aabb.size, " center=", aabb.get_center())
        inst.free()
    get_tree().quit(0)

func _aabb(n: Node) -> AABB:
    var total := AABB()
    var first := true
    for c in _meshes(n):
        var a: AABB = c.get_aabb()
        if first:
            total = a
            first = false
        else:
            total = total.merge(a)
    return total

func _meshes(n: Node) -> Array:
    var out := []
    if n is MeshInstance3D:
        out.append(n)
    for c in n.get_children():
        out.append_array(_meshes(c))
    return out
