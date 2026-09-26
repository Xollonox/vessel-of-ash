class_name VolleyBolt
extends Node3D
## A single arcing projectile from the Ossuary Choir. Deterministic travel:
## no physics areas, just integration + a radius check against the player.

var velocity := Vector3.ZERO
var life := 4.0
var damage := 10.0
var floor_y := -22.0

func _ready() -> void:
    var mi := MeshInstance3D.new()
    var sm := SphereMesh.new()
    sm.radius = 0.22
    sm.height = 0.44
    mi.mesh = sm
    var m := StandardMaterial3D.new()
    m.albedo_color = Color(0.95, 0.5, 0.2)
    m.emission_enabled = true
    m.emission = Color(1.0, 0.5, 0.18)
    m.emission_energy_multiplier = 2.4
    mi.material_override = m
    add_child(mi)

func _physics_process(delta: float) -> void:
    life -= delta
    if life <= 0.0:
        queue_free()
        return
    velocity.y -= 6.0 * delta
    global_position += velocity * delta
    var player := get_tree().get_first_node_in_group("player")
    if player != null and is_instance_valid(player):
        if global_position.distance_to(player.global_position + Vector3(0, 0.9, 0)) < 0.8:
            player.take_damage(damage, global_position, {"unblockable": false, "source": null})
            queue_free()
            return
    if global_position.y < floor_y:
        queue_free()
