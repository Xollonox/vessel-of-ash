class_name EnemyBase
extends CharacterBody3D
## Thralls, stalkers and wardens. Strikes are deterministic shape queries gated by
## a facing cone and a line-of-sight raycast, so there is no phantom damage through
## walls or from behind.

signal died(kind: String)
signal health_changed(cur: float, maxv: float)
signal aggroed

enum State { SLEEP, RISE, CHASE, WINDUP, STRIKE, RECOVER, STAGGER, DEAD }

const CONFIG := {
    "thrall": {
        "hp": 60.0, "speed": 2.9, "dmg": 12.0, "range": 2.3, "aggro": 12.0,
        "windup": 0.5, "strike": 0.18, "recover": 0.5, "cd": 1.0, "lunge": 0.0,
        "scale": 1.0, "unblockable": false, "col_r": 0.4, "col_h": 1.7,
        "model": "res://assets/models/skeletons/Skeleton_Minion.glb",
        "walk": "Walking_C", "walk_speed": 1.35, "attack": "1H_Melee_Attack_Slice_Diagonal",
        "atk_speed": 1.1, "name": "Bone Thrall",
        "hit": "Hit_A", "death": "Death_A", "awaken": "Skeletons_Awaken_Floor",
        "weapon": "res://assets/weapons/skeleton/Skeleton_Blade.gltf", "weapon_scale": 1.0,
        "weapon_rot": Vector3.ZERO,
    },
    "stalker": {
        "hp": 45.0, "speed": 4.5, "dmg": 14.0, "range": 2.6, "aggro": 14.0,
        "windup": 0.4, "strike": 0.15, "recover": 0.42, "cd": 0.85, "lunge": 6.5,
        "scale": 0.98, "unblockable": false, "col_r": 0.38, "col_h": 1.65,
        "model": "res://assets/models/skeletons/Skeleton_Rogue.glb",
        "walk": "Running_A", "walk_speed": 1.0, "attack": "1H_Melee_Attack_Slice_Horizontal",
        "atk_speed": 1.25, "name": "Bone Stalker",
        "alt_every": 3,
        "alt": {"windup": 0.62, "strike": 0.16, "dmg": 22.0, "lunge": 9.0,
                "unblockable": true, "clip": "1H_Melee_Attack_Stab", "atk_speed": 0.95},
        "hit": "Hit_B", "death": "Death_B", "awaken": "Skeletons_Awaken_Standing",
        "weapon": "res://assets/weapons/skeleton/Skeleton_Blade.gltf", "weapon_scale": 0.9,
        "weapon_rot": Vector3.ZERO,
    },
    "warden": {
        "hp": 140.0, "speed": 2.0, "dmg": 34.0, "range": 2.9, "aggro": 10.0,
        "windup": 0.95, "strike": 0.22, "recover": 0.9, "cd": 1.6, "lunge": 2.0,
        "scale": 1.22, "unblockable": true, "col_r": 0.48, "col_h": 2.05,
        "model": "res://assets/models/skeletons/Skeleton_Warrior.glb",
        "walk": "Walking_D_Skeletons", "walk_speed": 1.0, "attack": "2H_Melee_Attack_Chop",
        "atk_speed": 0.85, "name": "Bone Warden",
        "hit": "Hit_A", "death": "Death_C_Skeletons", "awaken": "Skeletons_Awaken_Floor_Long",
        "feint": true, "feint_chance": 0.34, "feint_at": 0.42,
        "feint_clip": "2H_Melee_Attack_Stab",
        "weapon": "res://assets/weapons/skeleton/Skeleton_Axe.gltf", "weapon_scale": 1.0,
        "weapon_rot": Vector3.ZERO,
    },
    "mage": {
        "hp": 70.0, "speed": 2.3, "dmg": 13.0, "range": 3.0, "aggro": 17.0,
        "windup": 0.75, "strike": 0.2, "recover": 0.7, "cd": 1.9, "lunge": 0.0,
        "scale": 1.05, "unblockable": false, "col_r": 0.42, "col_h": 1.8,
        "model": "res://assets/models/skeletons/Skeleton_Mage.glb",
        "walk": "Walking_A", "walk_speed": 1.1, "attack": "Spellcast_Shoot",
        "atk_speed": 0.95, "name": "Ossuary Mage", "ranged": true,
        "keep_min": 6.5, "keep_max": 13.0,
        "hit": "Hit_B", "death": "Death_A", "awaken": "Skeletons_Awaken_Floor",
        "weapon": "res://assets/weapons/skeleton/Skeleton_Staff.gltf", "weapon_scale": 1.0,
        "weapon_rot": Vector3.ZERO,
    },
    "boss": {
        "hp": 600.0, "speed": 2.4, "dmg": 18.0, "range": 3.4, "aggro": 20.0,
        "windup": 0.8, "strike": 0.2, "recover": 0.7, "cd": 0.6, "lunge": 0.0,
        "scale": 1.75, "unblockable": false, "col_r": 0.6, "col_h": 2.7,
        "model": "res://assets/models/skeletons/Skeleton_Mage.glb",
        "walk": "Walking_D_Skeletons", "walk_speed": 0.8, "attack": "1H_Melee_Attack_Chop",
        "atk_speed": 0.8, "name": "The Ossuary Choir",
        "hit": "Hit_A", "death": "Death_C_Skeletons_Resurrect", "awaken": "Skeletons_Awaken_Standing",
        "weapon": "res://assets/weapons/skeleton/Skeleton_Staff.gltf", "weapon_scale": 1.4,
        "weapon_rot": Vector3.ZERO,
    },
}

var kind := "thrall"
var cfg: Dictionary = {}
var max_health := 60.0
var health := 60.0
var state := State.SLEEP
var state_t := 0.0
var attack_cd_until := 0.0
var stagger_until := 0.0
var actor: SkeletonActor

var _player: Node3D
var _hit_done := false
var _cur_attack: Dictionary = {}
var _attack_count := 0
var _alt := false
var _rise_until := 0.0
var _feint := false
var _blink_ready_at := 0.0

static func spawn(kind_name: String) -> EnemyBase:
    var e := EnemyBase.new()
    e.kind = kind_name
    return e

func _ready() -> void:
    add_to_group("enemy")
    cfg = CONFIG.get(kind, CONFIG["thrall"])
    max_health = float(cfg.hp)
    health = max_health
    collision_layer = 2
    collision_mask = 1 | 4
    var shape := CollisionShape3D.new()
    var cap := CapsuleShape3D.new()
    cap.radius = float(cfg.col_r)
    cap.height = float(cfg.col_h)
    shape.shape = cap
    shape.position = Vector3(0, float(cfg.col_h) * 0.5, 0)
    add_child(shape)
    actor = SkeletonActor.new()
    actor.name = "Actor"
    actor.model_path = String(cfg.model)
    actor.scale_factor = float(cfg.scale)
    actor.weapon_path = String(cfg.get("weapon", ""))
    actor.weapon_scale = float(cfg.get("weapon_scale", 1.0))
    actor.weapon_rot = cfg.get("weapon_rot", Vector3.ZERO)
    add_child(actor)
    _player = get_tree().get_first_node_in_group("player")
    rng.randomize()
    actor.play_loop(String(cfg.get("idle", "Idle_Combat")), 1.0)

var rng := RandomNumberGenerator.new()

func _now() -> float:
    return Time.get_ticks_msec() / 1000.0

func is_dead() -> bool:
    return state == State.DEAD

func _decay(delta: float, factor: float) -> void:
    velocity.x = move_toward(velocity.x, 0.0, 18.0 * factor * delta)
    velocity.z = move_toward(velocity.z, 0.0, 18.0 * factor * delta)

func _flat(v: Vector3) -> Vector3:
    return Vector3(v.x, 0.0, v.z)

func _dist_to_player() -> float:
    if _player == null or not is_instance_valid(_player):
        return 999.0
    return global_position.distance_to(_player.global_position)

func _face_player(delta: float, rate: float) -> void:
    if _player == null or not is_instance_valid(_player):
        return
    var dir := _flat(_player.global_position - global_position)
    if dir.length() < 0.01:
        return
    var target_yaw := atan2(-dir.x, -dir.z)
    rotation.y = lerp_angle(rotation.y, target_yaw, clampf(rate * delta, 0.0, 1.0))

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
                _wake()
        State.CHASE:
            _process_chase(delta)
        State.RISE:
            _process_rise(delta)
        State.WINDUP:
            _decay(delta, 1.4)
            _face_player(delta, 5.0)
            if _feint and state_t >= float(cfg.get("feint_at", 0.34)):
                _feint = false
                _cur_attack = {"clip": String(cfg.get("feint_clip", "2H_Melee_Attack_Stab")),
                    "windup": 0.16, "strike": 0.14, "dmg": float(cfg.dmg) * 0.6,
                    "atk_speed": 1.35, "recover": 0.5}
                state_t = 0.0
                actor.play_once(String(_cur_attack.clip), 1.35)
                AudioManager.play_3d("telegraph", global_position, -6.0, 1.25)
                Fx.sparks(get_parent(), global_position + Vector3(0, 1.3, 0),
                    Color(1.0, 0.85, 0.4), 12, 3.0, 0.3, 0.1)
                return
            if state_t >= _windup_time():
                _enter_strike()
        State.STRIKE:
            _decay(delta, 0.6)
            if not _hit_done:
                _hit_done = true
                _do_strike()
            if state_t >= float(cfg.strike):
                _set_state(State.RECOVER)
        State.RECOVER:
            _decay(delta, 1.2)
            if state_t >= float(cfg.recover):
                attack_cd_until = _now() + float(cfg.cd)
                _alt = false
                _cur_attack = {}
                _set_state(State.CHASE)
        State.STAGGER:
            _decay(delta, 1.2)
            if state_t >= stagger_until:
                _set_state(State.CHASE)
        State.DEAD:
            _decay(delta, 0.8)
    move_and_slide()

func _set_state(s: int) -> void:
    state = s
    state_t = 0.0

func _wake() -> void:
    _set_state(State.CHASE)
    aggroed.emit()
    # Skeletons claw their way up out of the floor the first time they notice you.
    var awaken := String(cfg.get("awaken", ""))
    if awaken != "" and actor.has_clip(awaken):
        actor.play_once(awaken, 1.0)
        AudioManager.play_3d("creak", global_position, -6.0)
        Fx.sparks(get_parent(), global_position + Vector3(0, 0.4, 0), Color(0.55, 0.6, 0.7), 14, 3.0, 0.4, 0.1)
        _rise_until = _now() + actor.clip_len(awaken) * 0.85
        _set_state(State.RISE)
        return
    actor.play_loop(String(cfg.walk), float(cfg.walk_speed))

func _process_rise(delta: float) -> void:
    _decay(delta, 1.2)
    if _now() >= _rise_until:
        _set_state(State.CHASE)
        actor.play_loop(String(cfg.walk), float(cfg.walk_speed))

func _process_chase(delta: float) -> void:
    _face_player(delta, 6.0)
    var d := _dist_to_player()
    if bool(cfg.get("ranged", false)):
        _process_ranged(delta, d)
        return
    if d > float(cfg.range) * 0.82:
        var dir := _flat(_player.global_position - global_position).normalized()
        velocity.x = move_toward(velocity.x, dir.x * float(cfg.speed), 16.0 * delta)
        velocity.z = move_toward(velocity.z, dir.z * float(cfg.speed), 16.0 * delta)
        if actor.current() != String(cfg.walk):
            actor.play_loop(String(cfg.walk), float(cfg.walk_speed))
    else:
        _decay(delta, 1.4)
        if _now() >= attack_cd_until:
            _attack_count += 1
            _begin_windup()

func _blink_away() -> void:
    _blink_ready_at = _now() + float(cfg.get("blink_cd", 4.0))
    var away := _flat(global_position - _player.global_position).normalized()
    if away.length() < 0.01:
        away = Vector3.FORWARD
    Fx.sparks(get_parent(), global_position + Vector3(0, 1.0, 0), Color(0.55, 0.7, 1.0), 26, 5.0, 0.45, 0.12)
    Fx.ring(get_parent(), global_position, 2.2, Color(0.5, 0.7, 1.0), 0.22)
    global_position += away * 6.0 + Vector3(0, 0.2, 0)
    Fx.sparks(get_parent(), global_position + Vector3(0, 1.0, 0), Color(0.6, 0.8, 1.0), 26, 5.0, 0.45, 0.12)
    Fx.ring(get_parent(), global_position, 2.2, Color(0.5, 0.7, 1.0), 0.22)
    actor.play_once("Spellcast_Raise", 1.3)
    AudioManager.play_3d("dodge", global_position, -6.0)

func _process_ranged(delta: float, d: float) -> void:
    var keep_min := float(cfg.get("keep_min", 6.5))
    var keep_max := float(cfg.get("keep_max", 13.0))
    var dir := _flat(_player.global_position - global_position).normalized()
    if d < keep_min * 0.72 and _now() >= _blink_ready_at:
        _blink_away()
        return
    if d < keep_min:
        # too close: back off while still facing the player
        velocity.x = move_toward(velocity.x, -dir.x * float(cfg.speed), 14.0 * delta)
        velocity.z = move_toward(velocity.z, -dir.z * float(cfg.speed), 14.0 * delta)
        if actor.current() != String(cfg.walk):
            actor.play_loop(String(cfg.walk), float(cfg.walk_speed))
    elif d > keep_max:
        velocity.x = move_toward(velocity.x, dir.x * float(cfg.speed), 14.0 * delta)
        velocity.z = move_toward(velocity.z, dir.z * float(cfg.speed), 14.0 * delta)
        if actor.current() != String(cfg.walk):
            actor.play_loop(String(cfg.walk), float(cfg.walk_speed))
    else:
        _decay(delta, 1.4)
        if actor.current() != "Spellcasting":
            actor.play_loop("Spellcasting", 1.0)
        if _now() >= attack_cd_until:
            _attack_count += 1
            _begin_windup()

func _begin_windup() -> void:
    _alt = cfg.has("alt") and _attack_count % int(cfg.get("alt_every", 3)) == 0
    _cur_attack = (cfg.get("alt", {}) as Dictionary).duplicate() if _alt else {}
    _feint = _feint_trigger()
    _set_state(State.WINDUP)
    if _alt:
        actor.play_once(String(_cur_attack.get("clip", cfg.attack)), float(_cur_attack.get("atk_speed", 0.9)))
        AudioManager.play_3d("telegraph", global_position, -3.0, 0.78)
        Fx.sparks(get_parent(), global_position + Vector3(0, 1.35, 0), Color(1.0, 0.38, 0.16), 16, 3.4, 0.5, 0.13)
    else:
        actor.play_once(String(cfg.attack), float(cfg.atk_speed))
        AudioManager.play_3d("telegraph", global_position, -8.0)

func _windup_time() -> float:
    return float(_cur_attack.get("windup", cfg.windup))

## Wardens fake you out: the heavy overhead sometimes snaps into a fast poke,
## so holding the parry on the long tell is a real gamble.
func _feint_trigger() -> bool:
    if _feint or _alt or not bool(cfg.get("feint", false)):
        return false
    if rng.randf() > float(cfg.get("feint_chance", 0.35)):
        return false
    return true

func force_alt_windup() -> void:
    _attack_count = int(cfg.get("alt_every", 3))
    _begin_windup()

func is_alt() -> bool:
    return _alt

func _enter_strike() -> void:
    _set_state(State.STRIKE)
    _hit_done = false
    var lunge := float(_cur_attack.get("lunge", cfg.lunge))
    if lunge > 0.0:
        var fwd := -global_transform.basis.z
        velocity.x = fwd.x * lunge
        velocity.z = fwd.z * lunge

func _do_strike() -> void:
    var dmg := float(_cur_attack.get("dmg", cfg.dmg))
    var unblockable := bool(_cur_attack.get("unblockable", cfg.unblockable))
    if bool(cfg.get("ranged", false)) and _player != null and is_instance_valid(_player):
        _cast_bolt(dmg)
        return
    AudioManager.play_3d("swing_heavy" if (kind == "warden" or unblockable) else "swing_light", global_position, -6.0)
    var space := get_world_3d().direct_space_state
    var q := PhysicsShapeQueryParameters3D.new()
    var shape := SphereShape3D.new()
    shape.radius = float(cfg.range) * 0.8
    q.shape = shape
    var fwd := -global_transform.basis.z
    q.transform = Transform3D(Basis(), global_position + Vector3(0, 0.95, 0) + fwd * float(cfg.range) * 0.55)
    q.collision_mask = 1
    q.collide_with_bodies = true
    var hits := space.intersect_shape(q, 4)
    for h in hits:
        var n: Object = h.get("collider")
        if n == null or not n.has_method("take_damage"):
            continue
        var to := _flat((n as Node3D).global_position - global_position)
        if to.length() > 0.01 and to.normalized().dot(_flat(fwd)) < 0.30:
            continue
        if not _has_los(n):
            continue
        n.take_damage(dmg, global_position, {"unblockable": unblockable, "source": self})

func _cast_bolt(dmg: float) -> void:
    var origin := global_position + Vector3(0, 1.5, 0)
    var aim: Vector3 = _player.global_position + Vector3(0, 0.9, 0)
    var bolt := VolleyBolt.new()
    get_parent().add_child(bolt)
    bolt.global_position = origin
    bolt.damage = dmg
    bolt.floor_y = origin.y - 6.0
    var flight := maxf(0.45, origin.distance_to(aim) / 15.0)
    var vel := (aim - origin) / flight
    vel.y += 0.5 * 6.0 * flight
    bolt.velocity = vel
    bolt.life = flight + 1.2
    AudioManager.play_3d("swing_heavy", global_position, -9.0)
    Fx.sparks(get_parent(), origin + (-global_transform.basis.z) * 0.5,
        Color(0.6, 0.75, 1.0), 12, 3.0, 0.4, 0.1)

func _has_los(n: Object) -> bool:
    var space := get_world_3d().direct_space_state
    var from := global_position + Vector3(0, 1.0, 0)
    var to: Vector3 = (n as Node3D).global_position + Vector3(0, 1.0, 0)
    var q := PhysicsRayQueryParameters3D.create(from, to)
    q.collision_mask = 4 | 1
    q.exclude = [get_rid()]
    var hit := space.intersect_ray(q)
    if hit.is_empty():
        return true
    return hit.get("collider") == n

func take_damage(amount: float, _from: Vector3, _opts: Dictionary = {}) -> Variant:
    if state == State.DEAD:
        return false
    if state == State.SLEEP:
        _wake()
    health -= amount
    health_changed.emit(health, max_health)
    if actor != null:
        actor.flash(Color(1.0, 0.92, 0.85, 0.85), 0.13)
        var tw := create_tween()
        tw.tween_property(actor, "scale", Vector3.ONE * 1.07, 0.05)
        tw.tween_property(actor, "scale", Vector3.ONE, 0.13)
    AudioManager.play_3d("hit_heavy" if amount >= 20.0 else "hit_light", global_position, -5.0)
    if health <= 0.0:
        _die()
        return "dead"
    if amount >= 18.0:
        stagger(0.5)
    return "hit"

func stagger(t: float) -> void:
    if state == State.DEAD:
        return
    _set_state(State.STAGGER)
    stagger_until = t
    velocity.x = 0.0
    velocity.z = 0.0
    actor.play_once(String(cfg.get("hit", "Hit_A")), 1.1)

func _die() -> void:
    _set_state(State.DEAD)
    collision_layer = 0
    collision_mask = 4
    actor.play_once(String(cfg.get("death", "Death_A")), 0.9)
    AudioManager.play_3d("enemy_death", global_position, -4.0)
    Fx.sparks(get_parent(), global_position + Vector3(0, 1.0, 0), Color(0.95, 0.45, 0.25), 26, 6.5, 0.55, 0.13)
    Juice.hitstop(0.09, 0.08)
    died.emit(kind)
    var tw := create_tween()
    tw.tween_interval(2.3)
    tw.tween_property(actor, "scale", Vector3(0.01, 0.01, 0.01), 0.8)
    tw.tween_callback(queue_free)
