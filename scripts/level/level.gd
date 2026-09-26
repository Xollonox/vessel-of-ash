class_name GameLevel
extends Node3D
## Run controller: beat titles, checkpoints, respawn, boss wiring, victory.

const BEATS := [
    {"name": "Gate of Ash", "box": AABB(Vector3(-8, -3, -7), Vector3(16, 9, 17))},
    {"name": "The Long Descent", "box": AABB(Vector3(-6, -22, -41), Vector3(12, 23, 35))},
    {"name": "Hall of Cinders", "box": AABB(Vector3(-12, -22, -65), Vector3(24, 10, 24))},
    {"name": "The Broken Gallery", "box": AABB(Vector3(-9, -22, -95), Vector3(18, 10, 30))},
    {"name": "The Ossuary Niche", "box": AABB(Vector3(-9, -22, -113), Vector3(18, 9, 18))},
    {"name": "The Vessel Chamber", "box": AABB(Vector3(-8, -22, -131), Vector3(16, 10, 18))},
    {"name": "The Choir's Maw", "box": AABB(Vector3(-13, -22, -159), Vector3(26, 12, 28))},
]

var player: Player
var hud: GameHud
var boss: BossChoir
var respawn_pos := Vector3.ZERO
var deaths := 0
var start_ms := 0

var _seen := {}
var _gate_closed := false
var _ended := false
var _busy := false

func _ready() -> void:
    add_to_group("level")
    player = get_tree().get_first_node_in_group("player") as Player
    hud = get_tree().get_first_node_in_group("hud") as GameHud
    start_ms = Time.get_ticks_msec()
    _seen[0] = true
    AudioManager.play_ambient("ambient_ash", -21.0)
    AudioManager.play_music("music_crypt", -12.0)
    if player != null:
        respawn_pos = player.global_position + Vector3(0, 0.2, 0)
        player.health_changed.connect(func(c: float, m: float) -> void:
            if hud != null:
                hud.set_health(c, m)
            if c < player.max_health:
                if hud != null:
                    hud.damage_flash())
        player.died.connect(_on_player_died)
        player.parried.connect(func(_t: Object) -> void:
            if hud != null:
                hud.parry_popup())
        player.lock_changed.connect(_on_lock_changed)
        if hud != null:
            hud.set_health(player.health, player.max_health)
    for c in get_tree().get_nodes_in_group("checkpoint"):
        if c.has_signal("taken"):
            c.taken.connect(_on_checkpoint)
    boss = get_tree().get_first_node_in_group("boss") as BossChoir
    if boss != null:
        boss.aggroed.connect(_on_boss_aggro)
        boss.health_changed.connect(func(c: float, m: float) -> void:
            if hud != null:
                hud.set_boss(c, m))
        boss.phase_changed.connect(func(p: int) -> void:
            if hud != null:
                hud.toast("The Choir shifts — phase %d" % p))
        boss.died.connect(_on_boss_died)
    AudioManager.start_ambient()
    if hud != null:
        hud.beat_title(String(BEATS[0].name))

func _process(_delta: float) -> void:
    if player == null or not is_instance_valid(player):
        return
    _check_beats()
    _check_checkpoints()

func _check_checkpoints() -> void:
    for c in get_tree().get_nodes_in_group("checkpoint"):
        if c.activated:
            continue
        if player.global_position.distance_to((c as Node3D).global_position) < 2.4:
            c.activate()

func _check_beats() -> void:
    var p := player.global_position
    for i in BEATS.size():
        if _seen.has(i):
            continue
        var b: AABB = BEATS[i].box
        if b.has_point(p):
            _seen[i] = true
            if hud != null:
                hud.beat_title(String(BEATS[i].name))
            if i == 6:
                _close_gate()

func _close_gate() -> void:
    if _gate_closed:
        return
    _gate_closed = true
    if hud != null:
        hud.toast("The gate seals behind you")
    AudioManager.play("swing_heavy", -6.0, 0.6)
    var gate := get_tree().get_first_node_in_group("gate") as Node3D
    if gate != null:
        var tw := gate.create_tween()
        tw.tween_property(gate, "position:y", -18.4, 1.4).set_trans(Tween.TRANS_SINE)

func _on_checkpoint(cp: Node) -> void:
    respawn_pos = (cp as Node3D).global_position + Vector3(0, 0.2, 1.6)
    if player != null:
        player.heal_full()
    if hud != null:
        hud.toast("Checkpoint — the Cinderhold remembers")
    AudioManager.play("checkpoint", -4.0)

func _on_lock_changed(target: Node3D) -> void:
    if hud == null:
        return
    if target == null or not is_instance_valid(target):
        hud.clear_lock()
        return
    hud.set_lock(_enemy_name(target), _enemy_hp(target), _enemy_max(target))
    if target.has_signal("health_changed") and not target.health_changed.is_connected(_on_locked_hp):
        target.health_changed.connect(_on_locked_hp.bind(target))

func _on_locked_hp(cur: float, maxv: float, t: Node3D) -> void:
    if hud == null or player == null:
        return
    if player.lock_target == t:
        hud.set_lock(_enemy_name(t), cur, maxv)

func _enemy_name(t: Node3D) -> String:
    if t is EnemyBase:
        return String((t as EnemyBase).cfg.get("name", "Enemy"))
    return "Enemy"

func _enemy_hp(t: Node3D) -> float:
    if t is EnemyBase:
        return (t as EnemyBase).health
    return 1.0

func _enemy_max(t: Node3D) -> float:
    if t is EnemyBase:
        return (t as EnemyBase).max_health
    return 1.0

func _on_player_died() -> void:
    if _busy:
        return
    _busy = true
    deaths += 1
    if hud != null:
        hud.defeat()
    await get_tree().create_timer(2.6).timeout
    if player != null and is_instance_valid(player):
        player.global_position = respawn_pos
        player.velocity = Vector3.ZERO
        player.revive()
    if hud != null:
        hud.hide_defeat()
    _busy = false

func _on_boss_aggro() -> void:
    if hud != null and boss != null:
        hud.show_boss("THE OSSUARY CHOIR")
        hud.set_boss(boss.health, boss.max_health)
    AudioManager.play_music("music_boss", -6.0)

func _on_boss_died(_k: String) -> void:
    if _ended:
        return
    _ended = true
    AudioManager.stop_ambient()
    AudioManager.stop_music()
    AudioManager.play("victory", -3.0)
    var secs := int((Time.get_ticks_msec() - start_ms) / 1000.0)
    var stats := "cleared in %d:%02d · deaths %d" % [secs / 60, secs % 60, deaths]
    if hud != null:
        hud.victory(stats)
