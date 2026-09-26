extends Node
## Automated gameplay assertions for the Cinderhold slice.
## Run: godot --headless --path . res://tools/playtest.tscn

var passed := 0
var failed := 0
var _level: Node
var _player: Player
var _rig: CameraRig
var _music_at_start := ""

func _ready() -> void:
    print("=== VESSEL OF ASH — PLAYTEST ===")
    _level = (load("res://scenes/level_01.tscn") as PackedScene).instantiate()
    add_child(_level)
    await _wait(40)
    _player = get_tree().get_first_node_in_group("player") as Player
    _rig = get_tree().get_first_node_in_group("camera_rig") as CameraRig
    _music_at_start = AudioManager._music_key
    if _player == null:
        print("FATAL: no player in level")
        get_tree().quit(1)
        return
    for e in get_tree().get_nodes_in_group("enemy"):
        e.set_physics_process(false)
    await _t_spawn()
    await _t_move()
    await _t_camera_relative()
    await _t_dodge()
    await _t_light()
    await _t_combo()
    await _t_heavy()
    await _t_front_only()
    await _t_enemy_hits()
    await _t_enemy_cone()
    await _t_los()
    await _t_parry()
    await _t_unblockable()
    await _t_hitstop()
    await _t_slash_fx()
    await _t_stalker_alt()
    await _t_weapon_gear()
    await _t_touch_ui()
    await _t_trail()
    await _t_enemy_death()
    await _t_checkpoint()
    await _t_boss()
    await _t_skeleton_rigs()
    await _t_mage_bolt()
    await _t_sprint()
    await _t_lock_cycle()
    await _t_awaken()
    await _t_heavy_chain()
    await _t_run_attack()
    await _t_combo_hud()
    await _t_boss_moves()
    await _t_music()
    print("=== RESULT: %d/%d passed ===" % [passed, passed + failed])
    get_tree().quit(0 if failed == 0 else 1)

func _wait(n: int) -> void:
    for i in range(n):
        await get_tree().physics_frame

func _ok(label: String, cond: bool) -> void:
    if cond:
        passed += 1
        print("PASS  ", label)
    else:
        failed += 1
        print("FAIL  ", label)

func _spawn_enemy(kind: String, pos: Vector3) -> EnemyBase:
    var e := EnemyBase.spawn(kind)
    _level.add_child(e)
    e.global_position = pos
    e.set_physics_process(false)
    return e

func _await_idle(maxf: int = 140) -> void:
    for i in range(maxf):
        if _player.state == Player.State.IDLE or _player.state == Player.State.MOVE:
            return
        await get_tree().physics_frame

func _t_spawn() -> void:
    await _wait(20)
    _ok("player spawns and settles on the floor", _player.is_on_floor())

func _t_move() -> void:
    var p0 := _player.global_position
    Input.action_press("move_forward")
    await _wait(25)
    Input.action_release("move_forward")
    var moved := _player.global_position.distance_to(p0)
    _ok("forward input moves the player (%.2f m)" % moved, moved > 1.0)
    await _wait(30)

func _t_camera_relative() -> void:
    _rig.yaw = PI * 0.5
    await _wait(6)
    var p0 := _player.global_position
    Input.action_press("move_forward")
    await _wait(22)
    Input.action_release("move_forward")
    var d := _player.global_position - p0
    _rig.yaw = 0.0
    _ok("movement is camera-relative (dx=%.2f)" % d.x, d.x < -0.6)
    await _wait(30)

func _t_dodge() -> void:
    await _await_idle()
    _player.heal_full()
    _player.invuln_until = 0.0
    _player.force_dodge()
    var blocked: Variant = _player.take_damage(10.0, _player.global_position + Vector3(0, 0, -1), {})
    _ok("dodge i-frames are live on frame one", blocked == false and _player.health >= _player.max_health)
    var p0 := _player.global_position
    await _wait(25)
    var moved := _player.global_position.distance_to(p0)
    _ok("dodge covers ground (%.2f m)" % moved, moved > 1.5)
    await _wait(40)

func _t_light() -> void:
    await _await_idle()
    _player.rotation.y = 0.0
    _player.heal_full()
    var e := _spawn_enemy("thrall", _player.global_position + Vector3(0, 0, -1.4))
    await _wait(2)
    _player.force_light()
    await _wait(45)
    _ok("light attack deals 12 (hp %.0f)" % e.health, is_equal_approx(e.health, 48.0))
    e.queue_free()
    await _wait(5)

func _t_combo() -> void:
    await _await_idle()
    _player.rotation.y = 0.0
    var e := _spawn_enemy("thrall", _player.global_position + Vector3(0, 0, -1.4))
    await _wait(2)
    for i in range(5):
        _player._try_or_buffer("light")
        await _wait(12)
    await _wait(150)
    var dealt := 60.0 - e.health
    _ok("light combo chains A-B-C (dealt %.0f)" % dealt, dealt >= 40.0)
    e.queue_free()
    await _wait(5)

func _t_heavy() -> void:
    await _await_idle()
    _player.rotation.y = 0.0
    var e := _spawn_enemy("thrall", _player.global_position + Vector3(0, 0, -1.4))
    await _wait(2)
    _player.force_heavy()
    await _wait(80)
    _ok("heavy attack deals 30 (hp %.0f)" % e.health, is_equal_approx(e.health, 30.0))
    e.queue_free()
    await _wait(5)

func _t_front_only() -> void:
    await _await_idle()
    _player.rotation.y = 0.0
    var e := _spawn_enemy("thrall", _player.global_position + Vector3(0, 0, 1.6))
    await _wait(2)
    _player.force_light()
    await _wait(50)
    _ok("attacks only hit in front (behind hp %.0f)" % e.health, is_equal_approx(e.health, 60.0))
    e.queue_free()
    await _wait(5)

func _t_enemy_hits() -> void:
    await _await_idle()
    _player.heal_full()
    _player.invuln_until = 0.0
    _player.rotation.y = 0.0
    var e := _spawn_enemy("thrall", _player.global_position + Vector3(0, 0, -2.0))
    e.rotation.y = PI
    await _wait(2)
    e._do_strike()
    await _wait(10)
    _ok("enemy strike damages the player (hp %.0f)" % _player.health, _player.health < 100.0)
    e.queue_free()
    await _wait(50)

func _t_enemy_cone() -> void:
    await _await_idle()
    _player.heal_full()
    _player.invuln_until = 0.0
    var e := _spawn_enemy("thrall", _player.global_position + Vector3(0, 0, -2.0))
    e.rotation.y = 0.0
    await _wait(2)
    e._do_strike()
    await _wait(10)
    _ok("enemy cone: strike from a turned back misses", _player.health >= 100.0)
    e.queue_free()
    await _wait(5)

func _t_los() -> void:
    await _await_idle()
    _player.heal_full()
    _player.invuln_until = 0.0
    _player.rotation.y = 0.0
    var wall := StaticBody3D.new()
    wall.collision_layer = 4
    wall.collision_mask = 0
    var cs := CollisionShape3D.new()
    var bs := BoxShape3D.new()
    bs.size = Vector3(3, 3, 0.4)
    cs.shape = bs
    wall.add_child(cs)
    _level.add_child(wall)
    wall.global_position = _player.global_position + Vector3(0, 0, -1.4)
    var e := _spawn_enemy("thrall", _player.global_position + Vector3(0, 0, -2.4))
    e.rotation.y = PI
    await _wait(2)
    e._do_strike()
    await _wait(10)
    _ok("line of sight: a wall blocks the strike", _player.health >= 100.0)
    e.queue_free()
    wall.queue_free()
    await _wait(5)

func _t_parry() -> void:
    await _await_idle()
    _player.heal_full()
    _player.invuln_until = 0.0
    _player.rotation.y = 0.0
    var e := _spawn_enemy("thrall", _player.global_position + Vector3(0, 0, -2.0))
    e.rotation.y = PI
    await _wait(2)
    _player.force_parry()
    await _wait(4)
    e._do_strike()
    await _wait(8)
    var ok := _player.health >= 100.0 and e.state == EnemyBase.State.STAGGER
    _ok("parry negates the hit and staggers the attacker", ok)
    e.queue_free()
    await _wait(40)

func _t_unblockable() -> void:
    await _await_idle()
    _player.heal_full()
    _player.invuln_until = 0.0
    _player.rotation.y = 0.0
    var e := _spawn_enemy("warden", _player.global_position + Vector3(0, 0, -2.4))
    e.rotation.y = PI
    await _wait(2)
    _player.force_parry()
    await _wait(4)
    e._do_strike()
    await _wait(8)
    _ok("parry fails vs unblockable grab (hp %.0f)" % _player.health, _player.health < 100.0)
    e.queue_free()
    await _wait(50)

func _t_hitstop() -> void:
    await _await_idle()
    _player.rotation.y = 0.0
    var e := _spawn_enemy("thrall", _player.global_position + Vector3(0, 0, -1.4))
    await _wait(2)
    var before := Juice.trigger_count
    _player.force_light()
    var seen := false
    for i in range(120):
        if Juice.trigger_count > before:
            seen = true
            break
        await get_tree().physics_frame
    var issued := Juice.last_frozen_duration >= 0.05
    for i in range(150):
        if Engine.time_scale >= 1.0:
            break
        await get_tree().physics_frame
    _ok("hit-stop freezes time on connect and restores it (%.3fs)" % Juice.last_frozen_duration,
        seen and issued and Engine.time_scale >= 1.0)
    e.queue_free()
    await _wait(5)

func _t_slash_fx() -> void:
    await _await_idle()
    for i in range(240):
        if get_tree().get_nodes_in_group("fx").size() == 0:
            break
        await get_tree().physics_frame
    _player.rotation.y = 0.0
    _player.force_light()
    var seen := false
    for i in range(120):
        if get_tree().get_nodes_in_group("fx").size() > 0:
            seen = true
            break
        await get_tree().physics_frame
    _ok("slash arc VFX spawns during the swing", seen)
    for i in range(240):
        if get_tree().get_nodes_in_group("fx").size() == 0:
            break
        await get_tree().physics_frame
    await _await_idle()

func _t_stalker_alt() -> void:
    await _await_idle()
    _player.heal_full()
    _player.invuln_until = 0.0
    _player.rotation.y = 0.0
    var e := _spawn_enemy("stalker", _player.global_position + Vector3(0, 0, -2.2))
    e.rotation.y = PI
    await _wait(2)
    e.force_alt_windup()
    await _wait(4)
    var alt := e.is_alt()
    _player.force_parry()
    await _wait(2)
    e._do_strike()
    await _wait(10)
    _ok("stalker leap is unblockable and beats the parry (hp %.0f)" % _player.health,
        alt and _player.health < 100.0)
    e.queue_free()
    await _wait(40)

func _t_enemy_death() -> void:
    var e := _spawn_enemy("thrall", _player.global_position + Vector3(0, 0, -4.0))
    await _wait(2)
    e.take_damage(999.0, _player.global_position, {})
    var died_now := e.is_dead()
    await _wait(240)
    var freed := not is_instance_valid(e)
    _ok("enemy dies at zero hp and is cleaned up", died_now and freed)

# ------------------------------------------------------------- v0.4 checks ----

func _t_skeleton_rigs() -> void:
    var report: Array = []
    var all_ok := true
    for kind in ["thrall", "stalker", "warden", "mage"]:
        var e := _spawn_enemy(kind, _player.global_position + Vector3(4, 0, -4))
        await _wait(6)
        var a := e.actor
        var clips := a.player.get_animation_list().size() if a.player != null else 0
        var weapon_ok := a.weapon != null and a.weapon_tip != null
        var bones := a.skeleton.get_bone_count() if a.skeleton != null else 0
        report.append("%s:%d clips/%d bones/%s" % [kind, clips, bones, "armed" if weapon_ok else "unarmed"])
        if clips < 50 or bones < 30 or not weapon_ok:
            all_ok = false
        e.queue_free()
        await _wait(4)
    _ok("all four skeleton kinds load rig + clips + weapon (%s)" % ", ".join(report), all_ok)

func _t_mage_bolt() -> void:
    var e := _spawn_enemy("mage", _player.global_position + Vector3(0, 0, -9.0))
    e.set_physics_process(true)
    e._wake()
    var seen := false
    for i in range(420):
        await get_tree().physics_frame
        for c in _level.get_children():
            if c is VolleyBolt:
                seen = true
                break
        if seen:
            break
    _ok("ossuary mage casts a bolt from range", seen)
    e.queue_free()
    for c in _level.get_children():
        if c is VolleyBolt:
            c.queue_free()
    await _wait(10)

func _t_sprint() -> void:
    _player.revive()
    # open ground: the Hall of Cinders centre, so nothing blocks the run-up
    _player.global_position = Vector3(0, -20.8, -52.5)
    _player.velocity = Vector3.ZERO
    await _await_idle()
    await _wait(10)
    Input.action_press("move_forward")
    await _wait(25)
    var walk := Vector3(_player.velocity.x, 0.0, _player.velocity.z).length()
    Input.action_press("sprint")
    await _wait(25)
    var run := Vector3(_player.velocity.x, 0.0, _player.velocity.z).length()
    Input.action_release("sprint")
    Input.action_release("move_forward")
    await _await_idle()
    _ok("sprint outruns the walk (%.2f m/s -> %.2f m/s)" % [walk, run], run > walk * 1.08)

func _t_lock_cycle() -> void:
    var a := _spawn_enemy("thrall", _player.global_position + Vector3(3.0, 0, -4.0))
    var b := _spawn_enemy("thrall", _player.global_position + Vector3(-3.0, 0, -4.0))
    await _wait(6)
    _player.lock_target = null
    _player._toggle_lock()
    var first := _player.lock_target
    _player._toggle_lock()
    var second := _player.lock_target
    _ok("lock-on cycles between targets", first != null and second != null and first != second)
    _player.lock_target = null
    a.queue_free()
    b.queue_free()
    await _wait(6)

func _t_awaken() -> void:
    var e := _spawn_enemy("thrall", _player.global_position + Vector3(0, 0, -3.0))
    e.set_physics_process(true)
    e._wake()
    var rising := e.state == EnemyBase.State.RISE
    var clip := e.actor.current()
    var now_chasing := false
    for i in range(420):
        await get_tree().physics_frame
        if e.state == EnemyBase.State.CHASE:
            now_chasing = true
            break
    _ok("skeleton claws out of the floor on wake (%s -> chase %s)" % [clip, now_chasing],
        rising and clip.contains("Awaken") and now_chasing)
    e.queue_free()
    await _wait(6)

func _t_heavy_chain() -> void:
    _player.revive()
    await _await_idle()
    var e := _spawn_enemy("warden", _player.global_position + Vector3(0, 0, -1.6))
    e.max_health = 500.0
    e.health = 500.0
    _player.force_heavy()
    await _wait(40)
    Input.action_press("heavy_attack")
    await _wait(2)
    Input.action_release("heavy_attack")
    await _wait(70)
    await _await_idle()
    var dealt := 500.0 - e.health
    _ok("heavy chains into a second heavy (dealt %.0f)" % dealt, dealt >= 44.0)
    e.queue_free()
    await _wait(6)

func _t_run_attack() -> void:
    _player.revive()
    _player.global_position = Vector3(0, -20.8, -48.0)
    _player.velocity = Vector3.ZERO
    await _await_idle()
    Input.action_press("move_forward")
    Input.action_press("sprint")
    await _wait(30)
    Input.action_press("light_attack")
    await _wait(2)
    Input.action_release("light_attack")
    await _wait(3)
    var running := _player._attack_kind == "run"
    Input.action_release("sprint")
    Input.action_release("move_forward")
    await _await_idle(200)
    _ok("sprinting + light fires the running slash", running)

func _t_combo_hud() -> void:
    _player.revive()
    await _await_idle()
    var hud := get_tree().get_first_node_in_group("hud")
    if hud == null:
        _ok("combo counter registers on connect", false)
        return
    var e := _spawn_enemy("thrall", _player.global_position + Vector3(0, 0, -1.6))
    e.max_health = 400.0
    e.health = 400.0
    _player.force_light()
    await _wait(30)
    var shown: bool = hud._combo_root.modulate.a > 0.5 and hud._combo >= 1
    _ok("combo counter registers on connect (x%d)" % hud._combo, shown)
    e.queue_free()
    await _await_idle()

func _t_boss_moves() -> void:
    var b := get_tree().get_first_node_in_group("boss") as BossChoir
    if b == null:
        _ok("boss runs the skeleton move set", false)
        return
    b.set_physics_process(true)
    b.global_position = _player.global_position + Vector3(0, 0, -3.0)
    b._wake()
    var skeleton_clip := false
    var saw_ring := false
    var guard := 0
    while guard < 600:
        guard += 1
        await get_tree().physics_frame
        var cur: String = b.actor.current()
        if cur.begins_with("2H_") or cur.begins_with("Spellcast_") or cur.begins_with("1H_"):
            skeleton_clip = true
        for fx in get_tree().get_nodes_in_group("fx"):
            if fx is MeshInstance3D and (fx as MeshInstance3D).mesh is TorusMesh:
                saw_ring = true
        if skeleton_clip and saw_ring:
            break
    _ok("boss plays skeleton clips and telegraphs a slam ring (clip=%s ring=%s)"
        % [b.actor.current(), saw_ring], skeleton_clip and saw_ring)
    b.set_physics_process(false)

func _t_music() -> void:
    var boss := get_tree().get_first_node_in_group("boss") as BossChoir
    if boss != null:
        boss.aggroed.emit()
    await _wait(4)
    var switched := AudioManager._music_key
    _ok("music beds play and the boss crossfades in (%s -> %s)" % [_music_at_start, switched],
        _music_at_start == "music_crypt" and switched == "music_boss")

func _t_weapon_gear() -> void:
    await _await_idle()
    var ok := _player.actor != null and _player.actor.weapon != null and _player.actor.hair != null
    var tip := Vector3.ZERO
    if _player.actor != null:
        tip = _player.actor.sword_tip()
    _ok("player wears hair + hand-socketed weapon (tip live %s)" % str(tip != Vector3.ZERO), ok and tip != Vector3.ZERO)

func _t_touch_ui() -> void:
    var tc := get_tree().get_first_node_in_group("touch_ui") as TouchControls
    if tc == null:
        _ok("touch UI exists", false)
        return
    await _await_idle()
    var p0 := _player.global_position
    tc.debug_set_move(Vector2(0, -1))
    await _wait(30)
    tc.debug_set_move(Vector2.ZERO)
    var moved := _player.global_position.distance_to(p0)
    await _await_idle()
    tc.debug_press("light_attack")
    await _wait(6)
    var attacked := _player.state == Player.State.ATTACK
    await _await_idle()
    _ok("touch joystick moves + touch button attacks (%.2f m)" % moved, moved > 1.0 and attacked)
    await _wait(30)

func _t_trail() -> void:
    await _await_idle()
    _player.rotation.y = 0.0
    _player.force_light()
    var seen := false
    for i in range(90):
        if _player.trail != null and _player.trail.active:
            seen = true
            break
        await get_tree().physics_frame
    await _await_idle()
    _ok("blade trail activates during a swing", seen)
    await _wait(20)

func _t_checkpoint() -> void:
    await _await_idle()
    var cps := get_tree().get_nodes_in_group("checkpoint")
    if cps.size() < 2:
        _ok("checkpoint exists", false)
        return
    var cp := cps[1] as Checkpoint
    _player.heal_full()
    _player.invuln_until = 0.0
    _player.take_damage(20.0, _player.global_position + Vector3(0, 0, -1), {})
    await _wait(3)
    var hurt_ok := _player.health <= 80.0
    _player.global_position = cp.global_position + Vector3(0, 0.3, 1.4)
    _player.velocity = Vector3.ZERO
    await _wait(45)
    var lvl := get_tree().get_first_node_in_group("level") as GameLevel
    var respawn_ok := lvl != null and lvl.respawn_pos.distance_to(cp.global_position) < 3.0
    _ok("checkpoint heals and sets respawn", hurt_ok and cp.activated and _player.health >= 100.0 and respawn_ok)

func _t_boss() -> void:
    var boss := get_tree().get_first_node_in_group("boss") as BossChoir
    if boss == null:
        _ok("boss exists", false)
        return
    boss.take_damage(250.0, boss.global_position, {})
    await _wait(5)
    var p2 := boss.phase == 2
    boss.take_damage(200.0, boss.global_position, {})
    await _wait(5)
    var p3 := boss.phase == 3
    _ok("boss phase transitions 1->2->3 (%s, %s)" % [str(p2), str(p3)], p2 and p3)
