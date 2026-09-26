extends Node
## Renders a gear test: character + weapon + hair on a platform, fixed camera.
## Used to tune weapon socket transforms.
## ./tools/gear.sh OUT --weapon=res://... --scale=0.55 --rot=0,-90,0 --hair=... --skin=... --clip=Sword_Regular_A

var out := "/data/shots/gear.png"
var frames := 70
var clip_frames := 22
var weapon := "res://assets/weapons/sword_1handed.gltf"
var wscale := 0.55
var wrot := Vector3.ZERO
var woff := Vector3.ZERO
var hair := "res://assets/hair/Hair_SimpleParted.gltf"
var skin := "res://assets/models/characters/skins/T_Male_KAEL.png"
var clip := ""
var res := Vector2i(900, 900)
var cam_pos := Vector3(1.9, 1.5, 2.6)
var look_at := Vector3(0, 1.05, 0)

func _ready() -> void:
    for a in OS.get_cmdline_user_args():
        if a.begins_with("--out="):
            out = a.substr(6)
        elif a.begins_with("--frames="):
            frames = int(a.substr(9))
        elif a.begins_with("--clipframes="):
            clip_frames = int(a.substr(13))
        elif a.begins_with("--weapon="):
            weapon = a.substr(9)
        elif a.begins_with("--scale="):
            wscale = float(a.substr(8))
        elif a.begins_with("--rot="):
            wrot = _v(a.substr(6))
        elif a.begins_with("--off="):
            woff = _v(a.substr(6))
        elif a.begins_with("--hair="):
            hair = a.substr(7)
        elif a.begins_with("--skin="):
            skin = a.substr(7)
        elif a.begins_with("--clip="):
            clip = a.substr(7)
        elif a.begins_with("--res="):
            var rp := a.substr(6).split("x")
            if rp.size() == 2:
                res = Vector2i(int(rp[0]), int(rp[1]))
        elif a.begins_with("--cam="):
            cam_pos = _v(a.substr(6))
        elif a.begins_with("--look="):
            look_at = _v(a.substr(7))
    var we := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_COLOR
    env.background_color = Color(0.05, 0.05, 0.06)
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color(0.75, 0.70, 0.62)
    env.ambient_light_energy = 1.1
    env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    we.environment = env
    add_child(we)
    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-45, 35, 0)
    sun.light_energy = 1.4
    add_child(sun)
    var plat := MeshInstance3D.new()
    var bm := BoxMesh.new()
    bm.size = Vector3(6, 0.4, 6)
    plat.mesh = bm
    var pm := StandardMaterial3D.new()
    pm.albedo_color = Color(0.30, 0.28, 0.27)
    plat.material_override = pm
    plat.position = Vector3(0, -0.2, 0)
    add_child(plat)
    var cam := Camera3D.new()
    cam.fov = 45.0
    add_child(cam)
    cam.global_position = cam_pos
    cam.look_at(look_at, Vector3.UP)
    cam.current = true
    var actor := AnimatedActor.new()
    actor.model_path = "res://assets/models/characters/Superhero_Male_FullBody.gltf"
    actor.weapon_path = weapon
    actor.weapon_scale = wscale
    actor.weapon_rot = wrot
    actor.weapon_offset = woff
    actor.hair_path = hair
    actor.skin_texture = skin
    add_child(actor)
    await _wait(frames)
    if clip != "":
        actor.play_once(clip, 1.0)
        await _wait(clip_frames)
    await RenderingServer.frame_post_draw
    var img := get_viewport().get_texture().get_image()
    img.save_png(out)
    print("GEAR SHOT: ", out)
    get_tree().quit(0)

func _v(s: String) -> Vector3:
    var parts := s.split(",")
    if parts.size() != 3:
        return Vector3.ZERO
    return Vector3(float(parts[0]), float(parts[1]), float(parts[2]))

func _wait(n: int) -> void:
    for i in range(n):
        await get_tree().process_frame
