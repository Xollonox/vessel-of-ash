extends SceneTree
## Measures the KayKit dungeon modular pieces so the level generator can tile them
## on the right grid. Run:
##   godot --headless --path . --script res://tools/probe_grid.gd

const PROPS := [
    "floor_tile_large", "floor_tile_small", "floor_tile_small_decorated",
    "floor_tile_big_grate", "floor_wood_large", "floor_dirt_large",
    "wall", "wall_arched", "wall_doorway", "wall_corner", "wall_half",
    "wall_pillar", "wall_window_open", "wall_endcap",
    "stairs_wide", "stairs_walled", "column", "pillar_decorated",
    "barrier", "barrier_half", "torch_lit", "candle_triple",
]

func _initialize() -> void:
    for name in PROPS:
        var path := "res://assets/props/dungeon/%s.gltf.glb" % name
        if not ResourceLoader.exists(path):
            path = "res://assets/props/dungeon/%s.glb" % name
        if not ResourceLoader.exists(path):
            print("%-26s MISSING" % name)
            continue
        var ps: PackedScene = load(path)
        var inst: Node3D = ps.instantiate()
        var box := _bounds(inst)
        print("%-26s size=(%.2f, %.2f, %.2f)  min_y=%.2f  center=(%.2f, %.2f)" % [
            name, box.size.x, box.size.y, box.size.z, box.position.y,
            box.position.x, box.position.z])
        inst.free()
    quit(0)

func _bounds(root: Node) -> AABB:
    var out := AABB()
    var first := true
    for mi in _meshes(root):
        if mi.mesh == null:
            continue
        var b: AABB = mi.transform * mi.get_aabb()
        if first:
            out = b
            first = false
        else:
            out = out.merge(b)
    return out

func _meshes(root: Node, out: Array[MeshInstance3D] = []) -> Array[MeshInstance3D]:
    if root is MeshInstance3D:
        out.append(root as MeshInstance3D)
    for c in root.get_children():
        _meshes(c, out)
    return out