extends Node
## Headless screenshot tool. Run:
##   godot --path . res://tools/shot.tscn -- --out=/data/shots/hero.png --cam=0,4,14 --look=0,2,0
## Optional: --frames=N --player=x,y,z --attack --boss

var out := "/data/shots/shot.png"
var frames := 110
var cam_pos := Vector3(0, 4, 14)
var look_at := Vector3(0, 2, 0)
var player_pos := Vector3(INF, INF, INF)
var attack := false
var boss_shot := false
var combat := false

func _ready() -> void:
    for a in OS.get_cmdline_user_args():
        if a.begins_with("--out="):
            out = a.substr(6)
        elif a.begins_with("--frames="):
            frames = int(a.substr(9))
        elif a.begins_with("--cam="):
            cam_pos = _v(a.substr(6))
        elif a.begins_with("--look="):
            look_at = _v(a.substr(7))
        elif a.begins_with("--player="):
            player_pos = _v(a.substr(9))
        elif a == "--attack":
            attack = true
        elif a == "--combat":
            combat = true
        elif a == "--boss":
            boss_shot = true
    var inst := (load("res://scenes/level_01.tscn") as PackedScene).instantiate()
    add_child(inst)
    await get_tree().process_frame
    var p := get_tree().get_first_node_in_group("player") as Player
    if p != null and player_pos.x != INF:
        p.global_position = player_pos
        p.velocity = Vector3.ZERO
    var rig := get_tree().get_first_node_in_group("camera_rig") as Node
    if rig != null:
        rig.queue_free()
    var c := Camera3D.new()
    c.fov = 58.0
    add_child(c)
    c.global_position = cam_pos
    c.look_at(look_at, Vector3.UP)
    c.current = true
    if boss_shot:
        var b := get_tree().get_first_node_in_group("boss") as BossChoir
        if b != null and p != null:
            p.global_position = b.global_position + Vector3(0, 0.2, 7)
            p.rotation.y = 0.0
            b.take_damage(1.0, b.global_position, {})
    if combat and p != null:
        var e := EnemyBase.spawn("thrall")
        inst.add_child(e)
        e.global_position = p.global_position + Vector3(0, 0, -1.5)
        e.rotation.y = PI
        e.set_physics_process(false)
        await _wait(maxi(frames - 45, 20))
        var stop_before := Juice.trigger_count
        p.force_light()
        var guard := 0
        while Juice.trigger_count == stop_before and guard < 900:
            guard += 1
            await get_tree().process_frame
        guard = 0
        while Juice.frozen and guard < 300:
            guard += 1
            await get_tree().process_frame
        await _wait(2)
    elif attack and p != null:
        await _wait(maxi(frames - 14, 10))
        p.force_light()
        await _wait(12)
    else:
        await _wait(frames)
    await RenderingServer.frame_post_draw
    var img := get_viewport().get_texture().get_image()
    img.save_png(out)
    print("SHOT SAVED: ", out)
    get_tree().quit(0)

func _v(s: String) -> Vector3:
    var parts := s.split(",")
    if parts.size() != 3:
        return Vector3.ZERO
    return Vector3(float(parts[0]), float(parts[1]), float(parts[2]))

func _wait(n: int) -> void:
    for i in range(n):
        await get_tree().process_frame
