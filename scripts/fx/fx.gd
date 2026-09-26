class_name Fx
extends Object
## One-shot combat VFX: impact sparks, slash crescents, death bursts.
## Every spawned node joins the "fx" group so tests and cleanup can find it.

static func sparks(parent: Node, pos: Vector3, color: Color, count: int = 14,
        speed: float = 5.5, life: float = 0.35, size: float = 0.1) -> void:
    if parent == null or not parent.is_inside_tree():
        return
    var p := CPUParticles3D.new()
    p.amount = count
    p.lifetime = life
    p.one_shot = true
    p.explosiveness = 1.0
    p.direction = Vector3.UP
    p.spread = 85.0
    p.initial_velocity_min = speed * 0.35
    p.initial_velocity_max = speed
    p.gravity = Vector3(0, -11.0, 0)
    p.damping_min = 1.5
    p.damping_max = 4.0
    p.scale_amount_min = size * 0.5
    p.scale_amount_max = size
    p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
    p.emission_sphere_radius = 0.09
    p.color = color
    var q := QuadMesh.new()
    q.size = Vector2(0.09, 0.09)
    var m := StandardMaterial3D.new()
    m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
    m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
    m.vertex_color_use_as_albedo = true
    m.cull_mode = BaseMaterial3D.CULL_DISABLED
    q.material = m
    p.mesh = q
    p.add_to_group("fx")
    parent.add_child(p)
    p.global_position = pos
    p.emitting = true
    var t := p.get_tree().create_timer(life + 0.5)
    t.timeout.connect(p.queue_free)

static func slash(parent: Node, at: Vector3, yaw: float, big: bool = false,
        color: Color = Color(1.0, 0.88, 0.62, 0.95)) -> void:
    _slash_impl(parent, at, yaw, big, color)

## Ground telegraph / impact ring: a flat disc that snaps out to `radius` and fades.
## `grow_time` of 0 means "instant shockwave", anything longer reads as a warning.
static func ring(parent: Node, at: Vector3, radius: float = 5.0,
        color: Color = Color(1.0, 0.5, 0.2), grow_time: float = 0.3) -> void:
    if parent == null or not parent.is_inside_tree():
        return
    var mi := MeshInstance3D.new()
    var disc := TorusMesh.new()
    disc.inner_radius = radius * 0.86
    disc.outer_radius = radius
    disc.rings = 32
    disc.ring_segments = 6
    mi.mesh = disc
    var m := StandardMaterial3D.new()
    m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
    m.albedo_color = color
    m.disable_receive_shadows = true
    mi.material_override = m
    mi.add_to_group("fx")
    parent.add_child(mi)
    mi.global_position = at + Vector3(0, 0.08, 0)
    var t := mi.get_tree().create_tween()
    var start := 0.15 if grow_time <= 0.0 else 0.55
    mi.scale = Vector3.ONE * start
    t.tween_property(mi, "scale", Vector3.ONE, maxf(grow_time, 0.08))
    t.parallel().tween_property(m, "albedo_color:a", 0.0, maxf(grow_time, 0.08) + 0.22)
    t.tween_callback(mi.queue_free)

static func _slash_impl(parent: Node, at: Vector3, yaw: float, big: bool,
        color: Color = Color(1.0, 0.88, 0.62, 0.95)) -> void:
    if parent == null or not parent.is_inside_tree():
        return
    var mi := MeshInstance3D.new()
    var radius := 1.55 if big else 1.15
    var sweep := 175.0 if big else 150.0
    var width := 0.30 if big else 0.19
    mi.mesh = _arc_mesh(radius, sweep, width, 18)
    var m := StandardMaterial3D.new()
    m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
    m.cull_mode = BaseMaterial3D.CULL_DISABLED
    m.disable_receive_shadows = true
    m.albedo_color = color
    mi.material_override = m
    mi.add_to_group("fx")
    parent.add_child(mi)
    mi.global_position = at
    mi.rotation = Vector3(0.0, yaw, 0.7 if not big else 0.95)
    mi.scale = Vector3.ONE * 0.72
    var tw := mi.create_tween()
    tw.set_parallel(true)
    tw.tween_property(mi, "scale", Vector3.ONE * (1.25 if big else 1.12), 0.22) \
        .set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
    tw.tween_property(m, "albedo_color:a", 0.0, 0.22).set_delay(0.03)
    tw.chain().tween_callback(mi.queue_free)

static func _arc_mesh(radius: float, sweep_deg: float, width: float, segs: int) -> ArrayMesh:
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
    var sweep := deg_to_rad(sweep_deg)
    for i in range(segs + 1):
        var t := float(i) / float(segs)
        var a := -sweep * 0.5 + sweep * t
        var taper: float = pow(sin(t * PI), 0.6)
        var w := width * (0.25 + 0.75 * taper)
        var dir := Vector3(sin(a), 0.0, -cos(a))
        st.set_uv(Vector2(t, 0.0))
        st.add_vertex(dir * (radius - w * 0.5) + Vector3(0, -w * 0.5, 0))
        st.set_uv(Vector2(t, 1.0))
        st.add_vertex(dir * (radius + w * 0.5) + Vector3(0, w * 0.5, 0))
    return st.commit()
