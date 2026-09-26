class_name BladeTrail
extends MeshInstance3D
## Ribbon trail sampled from the weapon tip while a swing is live.

const MAX_POINTS := 18
const WIDTH := 0.085

var active := false

var _points: Array[Vector3] = []
var _mesh := ImmediateMesh.new()

func _ready() -> void:
    mesh = _mesh
    top_level = true
    var m := StandardMaterial3D.new()
    m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
    m.cull_mode = BaseMaterial3D.CULL_DISABLED
    m.vertex_color_use_as_albedo = true
    material_override = m
    add_to_group("fx")

func begin() -> void:
    active = true
    _points.clear()

func end() -> void:
    active = false

func push_point(p: Vector3) -> void:
    if p == Vector3.ZERO:
        return
    if _points.is_empty() or _points[_points.size() - 1].distance_to(p) > 0.03:
        _points.append(p)
    while _points.size() > MAX_POINTS:
        _points.remove_at(0)

func _physics_process(_delta: float) -> void:
    if not active and not _points.is_empty():
        _points.remove_at(0)
    _rebuild()

func _rebuild() -> void:
    _mesh.clear_surfaces()
    var n := _points.size()
    if n < 2:
        return
    _mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
    for i in n:
        var t := float(i) / float(n - 1)
        var p := _points[i]
        var w := WIDTH * (0.35 + 0.65 * t)
        var c := Color(1.0, 0.86, 0.58, 0.75 * t)
        _mesh.surface_set_color(c)
        _mesh.surface_add_vertex(p + Vector3(0, -w * 0.5, 0))
        _mesh.surface_set_color(c)
        _mesh.surface_add_vertex(p + Vector3(0, w * 0.5, 0))
    _mesh.surface_end()
