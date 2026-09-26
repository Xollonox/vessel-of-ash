class_name Player
extends CharacterBody3D
## Kael Ardyn. Third-person melee built for feel:
## - inputs buffer and survive hitstun
## - dodge i-frames are live on frame one
## - hit detection is a deterministic shape query (never area overlap)
## - whiffed swings carry recovery; connected swings flow straight to idle

signal health_changed(cur: float, maxv: float)
signal died
signal lock_changed(target: Node3D)
signal parried(target: Node3D)

enum State { IDLE, MOVE, ATTACK, DODGE, PARRY, HURT, DEAD }

const WALK_SPEED := 5.6
const ACCEL := 34.0
const FRICTION := 26.0
const DODGE_SPEED := 12.5
const DODGE_TIME := 0.34
const DODGE_CD := 0.55
const DODGE_IFRAMES := 0.5
const PARRY_TIME := 0.5
const PARRY_WINDOW := 0.24
const BUFFER_WINDOW := 0.35
const HURT_TIME := 0.28
const INVULN_AFTER_HIT := 0.75
const LOCK_RANGE := 15.0

const LIGHT := [
    {"clip": "Sword_Regular_A", "speed": 1.15, "hit_at": 0.24, "dmg": 12.0},
    {"clip": "Sword_Regular_B", "speed": 1.10, "hit_at": 0.27, "dmg": 12.0},
    {"clip": "Sword_Regular_C", "speed": 1.30, "hit_at": 0.46, "dmg": 18.0},
]
const HEAVY := {"clip": "TreeChopping", "speed": 1.0, "hit_at": 0.52, "dmg": 30.0}

var max_health := 100.0
var health := 100.0
var state := State.IDLE
var state_t := 0.0
var invuln_until := 0.0
var dodge_ready_at := 0.0
var lock_target: Node3D = null
var combo_index := 0
var actor: AnimatedActor
var cam: CameraRig

var _buffered := ""
var _buffered_at := -10.0
var _attack: Dictionary = {}
var _attack_queried := false
var _attack_connected := false
var _slash_spawned := false
var _attack_kind := ""
var _move_dir := Vector3.ZERO
var _footstep_t := 0.0
var _spawn_yaw := 0.0

func _ready() -> void:
    add_to_group("player")
    collision_layer = 1
    collision_mask = 2 | 4
    var shape := CollisionShape3D.new()
    var cap := CapsuleShape3D.new()
    cap.radius = 0.36
    cap.height = 1.75
    shape.shape = cap
    shape.position = Vector3(0, 0.9, 0)
    add_child(shape)
    actor = AnimatedActor.new()
    actor.name = "Actor"
    add_child(actor)
    _spawn_yaw = rotation.y
    _play_idle()

func _physics_process(delta: float) -> void:
    state_t += delta
    if cam == null:
        cam = get_tree().get_first_node_in_group("camera_rig") as CameraRig
    _validate_lock()
    _gather_input()
    if not is_on_floor():
        velocity.y -= 24.0 * delta
    else:
        velocity.y = 0.0
    match state:
        State.IDLE, State.MOVE:
            _process_ground(delta)
        State.ATTACK:
            _process_attack(delta)
        State.DODGE:
            _process_dodge(delta)
        State.PARRY:
            _decay(delta, 0.8)
            if state_t >= PARRY_TIME:
                _to_idle()
        State.HURT:
            _decay(delta, 0.6)
            if state_t >= HURT_TIME:
                _to_idle()
        State.DEAD:
            _decay(delta, 0.8)
    move_and_slide()
    _handle_buffers()

func _decay(delta: float, factor: float) -> void:
    velocity.x = move_toward(velocity.x, 0.0, FRICTION * factor * delta)
    velocity.z = move_toward(velocity.z, 0.0, FRICTION * factor * delta)

func _now() -> float:
    return Time.get_ticks_msec() / 1000.0

func _play_idle() -> void:
    if actor != null:
        actor.play_loop(AnimLib.IDLE, 1.0)

func _to_idle() -> void:
    state = State.IDLE
    state_t = 0.0
    combo_index = 0
    _play_idle()

# ---------------------------------------------------------------- input ----

func _gather_input() -> void:
    if state == State.DEAD:
        return
    var ix := Input.get_axis("move_left", "move_right")
    var iz := Input.get_axis("move_forward", "move_back")
    var yaw := _camera_yaw()
    var dir := Vector3(ix, 0.0, iz).rotated(Vector3.UP, yaw)
    _move_dir = dir.normalized() if dir.length() > 0.01 else Vector3.ZERO
    if Input.is_action_just_pressed("dodge"):
        _try_or_buffer("dodge")
    if Input.is_action_just_pressed("light_attack"):
        _try_or_buffer("light")
    if Input.is_action_just_pressed("heavy_attack"):
        _try_or_buffer("heavy")
    if Input.is_action_just_pressed("parry"):
        _try_or_buffer("parry")
    if Input.is_action_just_pressed("lock_on"):
        _toggle_lock()

func _camera_yaw() -> float:
    if cam != null and is_instance_valid(cam):
        return cam.yaw
    return rotation.y

func _try_or_buffer(action: String) -> void:
    if action == "dodge":
        if state != State.DODGE and state != State.HURT and state != State.DEAD and _now() >= dodge_ready_at:
            _start_dodge()
            return
    elif (state == State.IDLE or state == State.MOVE) and action == "parry":
        _start_parry()
        return
    elif (state == State.IDLE or state == State.MOVE) and (action == "light" or action == "heavy"):
        _begin_attack(action)
        return
    _buffered = action
    _buffered_at = _now()

func _handle_buffers() -> void:
    if _buffered == "":
        return
    if _now() - _buffered_at > BUFFER_WINDOW:
        _buffered = ""
        return
    if state == State.IDLE or state == State.MOVE:
        var a := _buffered
        _buffered = ""
        if a == "dodge":
            _start_dodge()
        elif a == "parry":
            _start_parry()
        elif a == "light" or a == "heavy":
            _begin_attack(a)

# ---------------------------------------------------------------- ground ----

func _process_ground(delta: float) -> void:
    var desired := _move_dir * WALK_SPEED
    velocity.x = move_toward(velocity.x, desired.x, ACCEL * delta)
    velocity.z = move_toward(velocity.z, desired.z, ACCEL * delta)
    var speed := Vector3(velocity.x, 0.0, velocity.z).length()
    if lock_target != null and is_instance_valid(lock_target):
        _face_toward(_flat(lock_target.global_position - global_position), delta, 12.0)
    elif _move_dir != Vector3.ZERO:
        _face_toward(_move_dir, delta, 14.0)
    if speed > 0.4:
        state = State.MOVE
        if actor.current() != AnimLib.WALK:
            actor.play_loop(AnimLib.WALK, 1.0)
        actor.set_speed(clampf(speed / 4.4, 0.7, 1.6))
        _footstep_t -= delta
        if _footstep_t <= 0.0:
            _footstep_t = 0.42
            AudioManager.play_var("footstep", -18.0, 0.18)
    else:
        state = State.IDLE
        actor.set_speed(1.0)
        if actor.current() != AnimLib.IDLE:
            _play_idle()

func _flat(v: Vector3) -> Vector3:
    return Vector3(v.x, 0.0, v.z)

func _face_toward(dir: Vector3, delta: float, rate: float) -> void:
    if dir.length() < 0.01:
        return
    var target_yaw := atan2(-dir.x, -dir.z)
    rotation.y = lerp_angle(rotation.y, target_yaw, clampf(rate * delta, 0.0, 1.0))

# --------------------------------------------------------------- attacks ----

func _begin_attack(kind: String) -> void:
    state = State.ATTACK
    state_t = 0.0
    _attack_queried = false
    _attack_connected = false
    _slash_spawned = false
    _attack_kind = kind
    if kind == "light":
        combo_index = clampi(combo_index, 0, LIGHT.size() - 1)
        _attack = LIGHT[combo_index]
    else:
        combo_index = 0
        _attack = HEAVY
    actor.play_once(_attack.clip, _attack.speed)
    var lunge := 2.4 if kind == "light" else 3.2
    velocity.x += -global_transform.basis.z.x * lunge
    velocity.z += -global_transform.basis.z.z * lunge
    AudioManager.play_var("swing_light" if kind == "light" else "swing_heavy", -8.0)

func _process_attack(delta: float) -> void:
    _decay(delta, 0.9)
    if lock_target != null and is_instance_valid(lock_target):
        _face_toward(_flat(lock_target.global_position - global_position), delta, 10.0)
    elif _move_dir != Vector3.ZERO:
        _face_toward(_move_dir, delta, 8.0)
    if _buffered == "dodge" and _now() >= dodge_ready_at:
        _buffered = ""
        _start_dodge()
        return
    if not _slash_spawned and state_t >= float(_attack.hit_at) - 0.10:
        _slash_spawned = true
        Fx.slash(get_parent(), global_position + Vector3(0, 1.05, 0), rotation.y, _attack_kind == "heavy")
    if not _attack_queried and state_t >= float(_attack.hit_at):
        _attack_queried = true
        _activate_hitbox(float(_attack.dmg), false)
    var clip: String = _attack.clip
    var speed: float = _attack.speed
    var clip_len := actor.clip_len(clip) / maxf(speed, 0.05)
    if combo_index < LIGHT.size() - 1 and _buffered == "light" and state_t >= float(_attack.hit_at) + 0.10:
        _buffered = ""
        combo_index += 1
        _begin_attack("light")
        return
    if state_t >= clip_len:
        if not _attack_connected and combo_index < AnimLib.LIGHT_RECOVERY.size():
            var rec: String = AnimLib.LIGHT_RECOVERY[combo_index]
            if rec != "" and actor.has_clip(rec):
                actor.play_once(rec, 1.0)
                _attack = {"clip": rec, "speed": 1.0, "hit_at": 999.0, "dmg": 0.0}
                _attack_queried = true
                state_t = 0.0
                combo_index = 0
                return
        _to_idle()

func _activate_hitbox(dmg: float, unblockable: bool) -> void:
    var space := get_world_3d().direct_space_state
    var q := PhysicsShapeQueryParameters3D.new()
    var shape := SphereShape3D.new()
    shape.radius = 1.2
    q.shape = shape
    var fwd := -global_transform.basis.z
    q.transform = Transform3D(Basis(), global_position + Vector3(0, 0.95, 0) + fwd * 1.15)
    q.collision_mask = 2
    q.collide_with_bodies = true
    var hits := space.intersect_shape(q, 8)
    var connected := false
    var heavy := dmg >= 25.0
    for h in hits:
        var n: Object = h.get("collider")
        if n == null or n == self:
            continue
        if n.has_method("take_damage"):
            var res: Variant = n.take_damage(dmg, global_position, {"unblockable": unblockable, "source": self})
            if res is String:
                connected = true
                var n3 := n as Node3D
                if n3 != null:
                    Fx.sparks(get_parent(), n3.global_position + Vector3(0, 1.0, 0) + fwd * 0.3,
                        Color(1.0, 0.78, 0.42), 18 if heavy else 12, 6.5 if heavy else 5.0, 0.35, 0.11)
    _attack_connected = connected
    if connected:
        Juice.hitstop(0.10 if heavy else 0.055, 0.06 if heavy else 0.08)
        AudioManager.play_var("hit_heavy" if heavy else "hit_light", -4.0)
        if cam != null and is_instance_valid(cam):
            cam.add_shake(0.55 if heavy else 0.35)
            if heavy:
                cam.fov_punch(3.5)

# ---------------------------------------------------------------- dodge ----

func _start_dodge() -> void:
    state = State.DODGE
    state_t = 0.0
    dodge_ready_at = _now() + DODGE_CD
    invuln_until = maxf(invuln_until, _now() + DODGE_IFRAMES)
    var d := _move_dir
    if d == Vector3.ZERO:
        d = _flat(-global_transform.basis.z)
    velocity.x = d.x * DODGE_SPEED
    velocity.z = d.z * DODGE_SPEED
    actor.play_once(AnimLib.DODGE_CLIP, 1.35)
    AudioManager.play_var("dodge", -7.0)

func _process_dodge(delta: float) -> void:
    var t := clampf(state_t / DODGE_TIME, 0.0, 1.0)
    var sp := lerpf(DODGE_SPEED, 2.0, t)
    var d := Vector3(velocity.x, 0.0, velocity.z).normalized()
    velocity.x = d.x * sp
    velocity.z = d.z * sp
    if state_t >= DODGE_TIME:
        _to_idle()

# ---------------------------------------------------------------- parry ----

func _start_parry() -> void:
    state = State.PARRY
    state_t = 0.0
    actor.play_once(AnimLib.PARRY_CLIP, 1.25)

# ------------------------------------------------------------ damage in ----

func take_damage(amount: float, from: Vector3, opts: Dictionary = {}) -> Variant:
    if state == State.DEAD:
        return false
    var now := _now()
    if now < invuln_until:
        return false
    var unblockable: bool = bool(opts.get("unblockable", false))
    if state == State.PARRY and state_t <= PARRY_WINDOW and not unblockable:
        AudioManager.play_var("parry", 0.0)
        Juice.hitstop(0.13, 0.05)
        Fx.sparks(get_parent(), global_position + Vector3(0, 1.15, 0), Color(1.0, 0.95, 0.8), 22, 6.0, 0.32, 0.09)
        var src: Object = opts.get("source")
        if src != null and src.has_method("stagger"):
            src.stagger(1.1)
        parried.emit(src)
        invuln_until = now + 0.35
        if cam != null and is_instance_valid(cam):
            cam.add_shake(0.5)
            cam.fov_punch(4.5)
        return "parry"
    health = maxf(0.0, health - amount)
    health_changed.emit(health, max_health)
    Juice.hitstop(0.06, 0.08)
    Fx.sparks(get_parent(), global_position + Vector3(0, 1.1, 0), Color(0.85, 0.22, 0.12), 14, 4.5, 0.3, 0.1)
    invuln_until = now + INVULN_AFTER_HIT
    var kb := _flat(global_position - from).normalized() * 4.5
    velocity.x = kb.x
    velocity.z = kb.z
    state = State.HURT
    state_t = 0.0
    actor.play_once(AnimLib.HIT_CLIP, 1.15)
    AudioManager.play_var("hurt", -3.0)
    if cam != null and is_instance_valid(cam):
        cam.add_shake(0.7)
    if health <= 0.0:
        _die()
    return "hit"

func _die() -> void:
    state = State.DEAD
    state_t = 0.0
    collision_layer = 0
    actor.play_once_rev(AnimLib.DEATH_CLIP, 0.8)
    AudioManager.play_var("hurt", -2.0)
    Fx.sparks(get_parent(), global_position + Vector3(0, 1.0, 0), Color(0.8, 0.16, 0.1), 30, 6.0, 0.6, 0.14)
    Juice.hitstop(0.12, 0.08)
    died.emit()

func heal_full() -> void:
    health = max_health
    health_changed.emit(health, max_health)

func revive() -> void:
    health = max_health
    state = State.IDLE
    state_t = 0.0
    combo_index = 0
    collision_layer = 1
    invuln_until = _now() + 1.2
    _play_idle()
    health_changed.emit(health, max_health)

func is_invulnerable() -> bool:
    return _now() < invuln_until

func is_dead() -> bool:
    return state == State.DEAD

# -------------------------------------------------------------- lock-on ----

func _toggle_lock() -> void:
    if lock_target != null:
        lock_target = null
        lock_changed.emit(null)
        return
    var best: Node3D = null
    var best_score := -INF
    for e in get_tree().get_nodes_in_group("enemy"):
        if not is_instance_valid(e) or not (e is Node3D):
            continue
        if e.has_method("is_dead") and e.is_dead():
            continue
        var to: Vector3 = (e as Node3D).global_position - global_position
        var d := to.length()
        if d > LOCK_RANGE:
            continue
        var fdot := _flat(to).normalized().dot(_flat(-global_transform.basis.z))
        if fdot < -0.2:
            continue
        var score := fdot * 2.0 - d / LOCK_RANGE
        if score > best_score:
            best_score = score
            best = e
    lock_target = best
    lock_changed.emit(best)

func _validate_lock() -> void:
    if lock_target != null:
        if not is_instance_valid(lock_target) or (lock_target.has_method("is_dead") and lock_target.is_dead()):
            lock_target = null
            lock_changed.emit(null)

# ------------------------------------------------------------- test hooks ----

func force_light() -> void:
    _begin_attack("light")

func force_heavy() -> void:
    _begin_attack("heavy")

func force_dodge() -> void:
    _start_dodge()

func force_parry() -> void:
    _start_parry()
