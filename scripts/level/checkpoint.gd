class_name Checkpoint
extends Node3D
## A cinder brazier. Walking close lights it, heals Kael, and sets the respawn.

signal taken(cp: Checkpoint)

var activated := false
var _flame: MeshInstance3D
var _mat: StandardMaterial3D
var _light: OmniLight3D
var _t := 0.0

func _ready() -> void:
    add_to_group("checkpoint")
    var stone := LevelKit.mat(Color(0.38, 0.34, 0.32), 0.9)
    var pedestal := LevelKit.cyl(self, "Pedestal", 0.42, 0.95, Vector3(0, 0.475, 0), stone)
    pedestal.name = "Pedestal"
    LevelKit.cyl(self, "Bowl", 0.55, 0.22, Vector3(0, 1.0, 0), LevelKit.mat(Color(0.3, 0.27, 0.26), 0.85))
    _mat = LevelKit.mat(Color(0.9, 0.5, 0.2), 0.6, Color(1.0, 0.55, 0.2), 0.85)
    _flame = LevelKit.sphere(self, "Flame", 0.24, Vector3(0, 1.22, 0), _mat)
    _light = LevelKit.add_light(self, Vector3(0, 1.5, 0), Color(1.0, 0.62, 0.28), 1.0, 6.0)

func activate() -> void:
    if activated:
        return
    activated = true
    _mat.emission_energy_multiplier = 1.8
    if _light != null and is_instance_valid(_light):
        _light.light_energy = 1.9
    taken.emit(self)

func _process(delta: float) -> void:
    _t += delta
    if _flame != null and is_instance_valid(_flame):
        var s := 1.0 + 0.08 * sin(_t * 5.0)
        _flame.scale = Vector3(s, 1.0 + 0.12 * sin(_t * 7.3), s)
