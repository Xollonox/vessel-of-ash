class_name BossChoir
extends EnemyBase
## The Ossuary Choir. Three phases: conducting volleys, summoning the ossuary,
## then an enraged finale with unblockable grabs. Bosses do not flinch from hits;
## only phase shifts interrupt their rhythm.

signal phase_changed(phase: int)

var phase := 1
var _queue: Array = []
var _move: Dictionary = {}
var _summoned := false
var _internal_stagger := false

func _ready() -> void:
    kind = "boss"
    super._ready()
    add_to_group("boss")
    phase = 1

func take_damage(amount: float, from: Vector3, opts: Dictionary = {}) -> Variant:
    var res: Variant = super.take_damage(amount, from, opts)
    if state == State.DEAD:
        return res
    var new_phase := 3 if health <= max_health * 0.30 else (2 if health <= max_health * 0.66 else 1)
    if new_phase != phase:
        phase = new_phase
        _queue.clear()
        phase_changed.emit(phase)
        AudioManager.play_3d("boss_roar", global_position, 0.0)
        _internal_stagger = true
        stagger(1.2)
        _internal_stagger = false
        actor.play_once("Chest_Open", 1.0)
    return res

func stagger(t: float) -> void:
    if _internal_stagger:
        super.stagger(t)

func _physics_process(delta: float) -> void:
    state_t += delta
    if _player == null or not is_instance_valid(_player):
        _player = get_tree().get_first_node_in_group("player")
    if not is_on_floor():
        velocity.y -= 24.0 * delta
    else:
        velocity.y = 0.0
    match state:
        State.SLEEP:
            _decay(delta, 1.0)
            if _dist_to_player() <= float(cfg.aggro):
                _set_state(State.CHASE)
                aggroed.emit()
                AudioManager.play_3d("boss_roar", global_position, -2.0)
                actor.play_once("Chest_Open", 1.0)
        State.CHASE:
            _process_chase(delta)
        State.WINDUP:
            _decay(delta, 1.4)
            _face_player(delta, 4.0)
            if state_t >= float(_move.get("windup", 0.8)):
                _enter_strike()
        State.STRIKE:
            _decay(delta, 0.8)
            if not _hit_done:
                _hit_done = true
                _execute_move()
            if state_t >= float(_move.get("strike", 0.2)):
                _set_state(State.RECOVER)
        State.RECOVER:
            _decay(delta, 1.2)
            if state_t >= float(_move.get("recover", 0.7)):
                attack_cd_until = _now() + float(cfg.cd)
                _set_state(State.CHASE)
        State.STAGGER:
            _decay(delta, 1.2)
            if state_t >= stagger_until:
                _set_state(State.CHASE)
        State.DEAD:
            _decay(delta, 0.8)
    move_and_slide()

func _process_chase(delta: float) -> void:
    _face_player(delta, 4.0)
    var d := _dist_to_player()
    if d > float(cfg.range) * 0.9:
        var dir := _flat(_player.global_position - global_position).normalized()
        velocity.x = move_toward(velocity.x, dir.x * float(cfg.speed), 12.0 * delta)
        velocity.z = move_toward(velocity.z, dir.z * float(cfg.speed), 12.0 * delta)
        if actor.current() != String(cfg.walk):
            actor.play_loop(String(cfg.walk), float(cfg.walk_speed))
    else:
        _decay(delta, 1.4)
        if _now() >= attack_cd_until:
            _begin_move()

func _begin_move() -> void:
    if _queue.is_empty():
        _queue = _build_queue()
    _move = _queue.pop_front()
    _set_state(State.WINDUP)
    actor.play_once(String(_move.anim), float(_move.speed))
    if bool(_move.get("unblockable", false)):
        AudioManager.play_3d("telegraph", global_position, 0.0, 0.7)
        Fx.sparks(get_parent(), global_position + Vector3(0, 2.0, 0), Color(1.0, 0.3, 0.12), 24, 4.0, 0.55, 0.16)
    else:
        AudioManager.play_3d("telegraph", global_position, -4.0)

func _build_queue() -> Array:
    if phase == 1:
        return [
            {"type": "melee", "anim": "Zombie_Scratch", "speed": 0.9, "windup": 0.8, "strike": 0.2, "recover": 0.7, "dmg": 18.0},
            {"type": "volley", "anim": "OverhandThrow", "speed": 0.9, "windup": 0.9, "strike": 0.3, "recover": 0.8, "bolts": 5},
            {"type": "melee", "anim": "Zombie_Scratch", "speed": 0.9, "windup": 0.8, "strike": 0.2, "recover": 0.7, "dmg": 18.0},
            {"type": "volley", "anim": "OverhandThrow", "speed": 0.9, "windup": 0.9, "strike": 0.3, "recover": 0.8, "bolts": 6},
        ]
    if phase == 2:
        var q := [
            {"type": "volley", "anim": "OverhandThrow", "speed": 1.0, "windup": 0.8, "strike": 0.3, "recover": 0.7, "bolts": 6},
            {"type": "melee", "anim": "Zombie_Scratch", "speed": 1.0, "windup": 0.7, "strike": 0.2, "recover": 0.6, "dmg": 18.0},
        ]
        if not _summoned:
            _summoned = true
            q.push_front({"type": "summon", "anim": "Chest_Open", "speed": 1.0, "windup": 1.0, "strike": 0.2, "recover": 0.9})
        q.append({"type": "melee", "anim": "Zombie_Scratch", "speed": 1.0, "windup": 0.7, "strike": 0.2, "recover": 0.6, "dmg": 18.0})
        return q
    return [
        {"type": "grab", "anim": "Melee_Hook", "speed": 0.7, "windup": 0.85, "strike": 0.2, "recover": 0.9, "dmg": 34.0, "unblockable": true},
        {"type": "volley", "anim": "OverhandThrow", "speed": 1.15, "windup": 0.7, "strike": 0.3, "recover": 0.6, "bolts": 8},
        {"type": "melee", "anim": "Zombie_Scratch", "speed": 1.1, "windup": 0.6, "strike": 0.2, "recover": 0.5, "dmg": 18.0},
        {"type": "grab", "anim": "Melee_Hook", "speed": 0.7, "windup": 0.85, "strike": 0.2, "recover": 0.9, "dmg": 34.0, "unblockable": true},
        {"type": "volley", "anim": "OverhandThrow", "speed": 1.15, "windup": 0.7, "strike": 0.3, "recover": 0.6, "bolts": 8},
    ]

func _execute_move() -> void:
    var t := String(_move.get("type", "melee"))
    if t == "melee":
        _strike_with(dmg_of(18.0), false)
    elif t == "grab":
        _strike_with(dmg_of(34.0), true)
    elif t == "volley":
        _spawn_volley(int(_move.get("bolts", 5)))
    elif t == "summon":
        _summon()

func dmg_of(fallback: float) -> float:
    return float(_move.get("dmg", fallback))

func _strike_with(dmg: float, unblockable: bool) -> void:
    AudioManager.play_3d("swing_heavy", global_position, -3.0)
    var space := get_world_3d().direct_space_state
    var q := PhysicsShapeQueryParameters3D.new()
    var shape := SphereShape3D.new()
    shape.radius = 2.6
    q.shape = shape
    var fwd := -global_transform.basis.z
    q.transform = Transform3D(Basis(), global_position + Vector3(0, 1.2, 0) + fwd * 1.8)
    q.collision_mask = 1
    q.collide_with_bodies = true
    var hits := space.intersect_shape(q, 4)
    for h in hits:
        var n: Object = h.get("collider")
        if n == null or not n.has_method("take_damage"):
            continue
        var to := _flat((n as Node3D).global_position - global_position)
        if to.length() > 0.01 and to.normalized().dot(_flat(fwd)) < 0.2:
            continue
        if not _has_los(n):
            continue
        n.take_damage(dmg, global_position, {"unblockable": unblockable, "source": self})

func _spawn_volley(count: int) -> void:
    AudioManager.play_3d("swing_light", global_position, -3.0)
    var host := get_tree().current_scene
    if host == null:
        return
    var player_pos := _player.global_position + Vector3(0, 0.9, 0) if _player != null and is_instance_valid(_player) else global_position + Vector3(0, 0, -6)
    for i in count:
        var bolt := VolleyBolt.new()
        host.add_child(bolt)
        bolt.global_position = global_position + Vector3(0, 1.8, 0) + (-global_transform.basis.z) * 0.8
        bolt.floor_y = global_position.y - 0.4
        var spread := 0.5
        var aim := player_pos + Vector3(randf_range(-spread, spread), randf_range(-0.2, 0.4), randf_range(-spread, spread))
        var to := aim - bolt.global_position
        var flight := 1.05 + randf_range(-0.1, 0.15)
        var v := Vector3(to.x / flight, (to.y + 0.5 * 6.0 * flight * flight) / flight, to.z / flight)
        bolt.velocity = v
        bolt.damage = 10.0

func _summon() -> void:
    AudioManager.play_3d("boss_roar", global_position, -3.0)
    var host := get_tree().current_scene
    if host == null:
        return
    for i in 2:
        var thrall := EnemyBase.spawn("thrall")
        host.add_child(thrall)
        var ang := TAU * float(i) / 2.0 + 0.6
        thrall.global_position = global_position + Vector3(cos(ang) * 3.4, 0.4, sin(ang) * 3.4)

func _die() -> void:
    _set_state(State.DEAD)
    collision_layer = 0
    collision_mask = 4
    actor.play_once_rev("LayToIdle", 0.55)
    AudioManager.play_3d("boss_roar", global_position, 0.0)
    Fx.sparks(get_parent(), global_position + Vector3(0, 1.6, 0), Color(1.0, 0.55, 0.25), 40, 8.0, 0.8, 0.16)
    Juice.hitstop(0.22, 0.05)
    died.emit(kind)
