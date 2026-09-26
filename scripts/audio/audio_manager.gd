extends Node
## Central audio. Real CC0 SFX (Kenney "Impact Sounds" + "RPG Audio") with the
## procedural set kept as fallback. Variants are picked at random per play.

const SFX := {
    "swing_light": ["res://assets/audio_kenney/knife_slice.ogg",
                    "res://assets/audio_kenney/knife_slice_2.ogg"],
    "swing_heavy": "res://assets/audio_kenney/knife_slice_2.ogg",
    "hit_light": ["res://assets/audio_kenney/impact_metal_light_000.ogg",
                  "res://assets/audio_kenney/impact_metal_light_001.ogg"],
    "hit_heavy": ["res://assets/audio_kenney/impact_metal_heavy_000.ogg",
                  "res://assets/audio_kenney/impact_metal_heavy_001.ogg",
                  "res://assets/audio_kenney/impact_metal_heavy_003.ogg"],
    "parry": "res://assets/audio_kenney/impact_bell_heavy_001.ogg",
    "dodge": "res://assets/audio_kenney/cloth_2.ogg",
    "footstep": ["res://assets/audio_kenney/footstep_concrete_000.ogg",
                 "res://assets/audio_kenney/footstep_concrete_001.ogg",
                 "res://assets/audio_kenney/footstep_concrete_002.ogg",
                 "res://assets/audio_kenney/footstep_concrete_003.ogg"],
    "telegraph": "res://assets/audio_kenney/draw_knife_1.ogg",
    "enemy_death": "res://assets/audio_kenney/impact_bell_heavy_002.ogg",
    "checkpoint": "res://assets/audio_kenney/impact_bell_heavy_000.ogg",
    "creak": ["res://assets/audio_kenney/creak_1.ogg",
              "res://assets/audio_kenney/creak_2.ogg",
              "res://assets/audio_kenney/creak_3.ogg"],
    "ui": "res://assets/audio_kenney/metal_click.ogg",
    "hurt": "res://assets/audio/hurt.wav",
    "boss_roar": "res://assets/audio/boss_roar.wav",
    "ambient": "res://assets/audio/ambient.wav",
    "victory": "res://assets/audio/victory.wav",
}

var _streams := {}
var _rng := RandomNumberGenerator.new()
var _ambient_player: AudioStreamPlayer

func _ready() -> void:
    _rng.randomize()
    for key in SFX:
        var v: Variant = SFX[key]
        var paths: Array = v if v is Array else [v]
        var loaded: Array = []
        for p in paths:
            if ResourceLoader.exists(String(p)):
                loaded.append(load(String(p)))
        if not loaded.is_empty():
            _streams[key] = loaded

func has_sfx(key: String) -> bool:
    return _streams.has(key)

func _pick(key: String) -> AudioStream:
    var arr: Array = _streams[key]
    if arr.size() == 1:
        return arr[0]
    return arr[_rng.randi_range(0, arr.size() - 1)]

func play(key: String, volume_db: float = 0.0, pitch: float = 1.0) -> void:
    if not _streams.has(key):
        return
    var p := AudioStreamPlayer.new()
    p.stream = _pick(key)
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
    p.stream = _pick(key)
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
    _ambient_player.stream = _streams["ambient"][0]
    _ambient_player.volume_db = volume_db
    add_child(_ambient_player)
    _ambient_player.play()

func stop_ambient() -> void:
    if _ambient_player != null and is_instance_valid(_ambient_player):
        _ambient_player.queue_free()
        _ambient_player = null
