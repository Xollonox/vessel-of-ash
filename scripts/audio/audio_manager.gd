extends Node
## Central audio. Preloads the procedural SFX set and plays it with pitch variation.

const SFX := {
    "swing_light": "res://assets/audio/swing_light.wav",
    "swing_heavy": "res://assets/audio/swing_heavy.wav",
    "hit_light": "res://assets/audio/hit_light.wav",
    "hit_heavy": "res://assets/audio/hit_heavy.wav",
    "parry": "res://assets/audio/parry.wav",
    "dodge": "res://assets/audio/dodge.wav",
    "telegraph": "res://assets/audio/telegraph.wav",
    "checkpoint": "res://assets/audio/checkpoint.wav",
    "hurt": "res://assets/audio/hurt.wav",
    "enemy_death": "res://assets/audio/enemy_death.wav",
    "boss_roar": "res://assets/audio/boss_roar.wav",
    "footstep": "res://assets/audio/footstep.wav",
    "ambient": "res://assets/audio/ambient.wav",
    "victory": "res://assets/audio/victory.wav",
}

var _streams := {}
var _rng := RandomNumberGenerator.new()
var _ambient_player: AudioStreamPlayer

func _ready() -> void:
    _rng.randomize()
    for key in SFX:
        var path: String = SFX[key]
        if ResourceLoader.exists(path):
            _streams[key] = load(path)

func has_sfx(key: String) -> bool:
    return _streams.has(key)

func play(key: String, volume_db: float = 0.0, pitch: float = 1.0) -> void:
    if not _streams.has(key):
        return
    var p := AudioStreamPlayer.new()
    p.stream = _streams[key]
    p.volume_db = volume_db
    p.pitch_scale = pitch
    add_child(p)
    p.finished.connect(p.queue_free)
    p.play()

func play_var(key: String, volume_db: float = 0.0, pitch_spread: float = 0.12) -> void:
    play(key, volume_db, 1.0 + _rng.randf_range(-pitch_spread, pitch_spread))

func play_3d(key: String, pos: Vector3, volume_db: float = 0.0, pitch: float = 1.0, max_dist: float = 34.0) -> void:
    if not _streams.has(key):
        return
    var host: Node = get_tree().current_scene
    if host == null:
        host = get_tree().root
    var p := AudioStreamPlayer3D.new()
    p.stream = _streams[key]
    p.volume_db = volume_db
    p.pitch_scale = pitch
    p.max_distance = max_dist
    p.unit_size = 9.0
    host.add_child(p)
    p.global_position = pos
    p.finished.connect(p.queue_free)
    p.play()

func start_ambient(volume_db: float = -16.0) -> void:
    if _ambient_player != null and is_instance_valid(_ambient_player):
        return
    if not _streams.has("ambient"):
        return
    _ambient_player = AudioStreamPlayer.new()
    _ambient_player.stream = _streams["ambient"]
    _ambient_player.volume_db = volume_db
    add_child(_ambient_player)
    _ambient_player.play()

func stop_ambient() -> void:
    if _ambient_player != null and is_instance_valid(_ambient_player):
        _ambient_player.queue_free()
        _ambient_player = null
