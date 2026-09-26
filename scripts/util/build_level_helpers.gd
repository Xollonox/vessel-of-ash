class_name LevelKit
extends Object
## Static build helpers for the level generator.
##
## Godot's Compatibility renderer silently drops every light past 32 with no
## error at all, so every light goes through add_light() with a hard budget.

const LIGHT_BUDGET := 28
static var light_count := 0

static func reset_lights() -> void:
    light_count = 0

static func claim_light() -> bool:
    if light_count >= LIGHT_BUDGET:
        push_warning("LevelKit: light budget exhausted (%d) - dropping a light" % LIGHT_BUDGET)
        return false
    light_count += 1
    return true

static func mat(color: Color, rough: float = 0.9, emission: Color = Color.BLACK, emission_energy: float = 1.0) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = color
    m.roughness = rough
    m.metallic = 0.0
    if emission != Color.BLACK:
        m.emission_enabled = true
        m.emission = emission
        m.emission_energy_multiplier = emission_energy
    return m

static func box(parent: Node, name: String, size: Vector3, pos: Vector3, material: StandardMaterial3D, solid: bool = true) -> MeshInstance3D:
    var mi := MeshInstance3D.new()
    var bm := BoxMesh.new()
    bm.size = size
    mi.mesh = bm
    mi.name = name
    mi.material_override = material
    if solid:
        var body := StaticBody3D.new()
        body.name = name + "Body"
        body.collision_layer = 4
        body.collision_mask = 0
        body.position = pos
        var cs := CollisionShape3D.new()
        var bs := BoxShape3D.new()
        bs.size = size
        cs.shape = bs
        body.add_child(cs)
        body.add_child(mi)
        parent.add_child(body)
    else:
        mi.position = pos
        parent.add_child(mi)
    return mi

static func cyl(parent: Node, name: String, radius: float, height: float, pos: Vector3, material: StandardMaterial3D, solid: bool = true) -> MeshInstance3D:
    var mi := MeshInstance3D.new()
    var cm := CylinderMesh.new()
    cm.top_radius = radius
    cm.bottom_radius = radius
    cm.height = height
    mi.mesh = cm
    mi.name = name
    mi.material_override = material
    if solid:
        var body := StaticBody3D.new()
        body.name = name + "Body"
        body.collision_layer = 4
        body.collision_mask = 0
        body.position = pos
        var cs := CollisionShape3D.new()
        var csh := CylinderShape3D.new()
        csh.radius = radius
        csh.height = height
        cs.shape = csh
        body.add_child(cs)
        body.add_child(mi)
        parent.add_child(body)
    else:
        mi.position = pos
        parent.add_child(mi)
    return mi

static func sphere(parent: Node, name: String, radius: float, pos: Vector3, material: StandardMaterial3D) -> MeshInstance3D:
    var mi := MeshInstance3D.new()
    var sm := SphereMesh.new()
    sm.radius = radius
    sm.height = radius * 2.0
    mi.mesh = sm
    mi.name = name
    mi.position = pos
    mi.material_override = material
    parent.add_child(mi)
    return mi

static func add_light(parent: Node, pos: Vector3, color: Color, energy: float, range_m: float) -> OmniLight3D:
    if not claim_light():
        return null
    var l := OmniLight3D.new()
    l.position = pos
    l.light_color = color
    l.light_energy = energy
    l.omni_range = range_m
    l.shadow_enabled = false
    parent.add_child(l)
    return l

static func set_owner_recursive(node: Node, owner_node: Node) -> void:
    for c in node.get_children():
        c.owner = owner_node
        set_owner_recursive(c, owner_node)
