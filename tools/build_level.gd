extends Node
## Regenerates scenes/level_01.tscn — The Cinderhold.
## Run as a scene so autoloads exist:
##   godot --headless --path . res://tools/build_level.tscn

const FLOOR := Color(0.40, 0.37, 0.35)
const WALL := Color(0.33, 0.30, 0.29)
const DARK := Color(0.22, 0.20, 0.20)
const WOOD := Color(0.35, 0.25, 0.17)
const BONE := Color(0.75, 0.72, 0.66)
const METAL := Color(0.45, 0.42, 0.40)

var floor_m: StandardMaterial3D
var wall_m: StandardMaterial3D
var dark_m: StandardMaterial3D
var wood_m: StandardMaterial3D
var bone_m: StandardMaterial3D
var metal_m: StandardMaterial3D
var torch_m: StandardMaterial3D
var flame_m: StandardMaterial3D
var rng := RandomNumberGenerator.new()

var root: Node3D

func _ready() -> void:
    rng.seed = 7
    floor_m = LevelKit.mat(FLOOR, 0.92)
    wall_m = LevelKit.mat(WALL, 0.94)
    dark_m = LevelKit.mat(DARK, 0.9)
    wood_m = LevelKit.mat(WOOD, 0.85)
    bone_m = LevelKit.mat(BONE, 0.8)
    metal_m = LevelKit.mat(METAL, 0.55)
    torch_m = LevelKit.mat(Color(0.9, 0.55, 0.25), 0.6, Color(1.0, 0.55, 0.2), 1.15)
    flame_m = LevelKit.mat(Color(0.95, 0.6, 0.3), 0.5, Color(1.0, 0.6, 0.25), 1.3)
    LevelKit.reset_lights()
    root = Node3D.new()
    root.name = "Level"
    root.set_script(load("res://scripts/level/level.gd"))
    # Keep the root orphaned: nothing runs _ready during generation, so the saved
    # scene contains only authored nodes and every runtime rig is built once on load.
    _env()
    _beat1()
    _beat2()
    _beat3()
    _beat4()
    _beat5()
    _beat6()
    _beat7()
    _dressing()
    _actors()
    LevelKit.set_owner_recursive(root, root)
    var ps := PackedScene.new()
    var err := ps.pack(root)
    if err != OK:
        push_error("pack failed: %d" % err)
        get_tree().quit(1)
        return
    err = ResourceSaver.save(ps, "res://scenes/level_01.tscn")
    print("level saved: err=", err, "  lights used=", LevelKit.light_count, "/", LevelKit.LIGHT_BUDGET)
    root.free()
    get_tree().quit(0 if err == OK else 1)

func _torch(parent: Node3D, pos: Vector3) -> void:
    LevelKit.box(parent, "TorchBracket", Vector3(0.22, 0.22, 0.22), pos, dark_m)
    LevelKit.sphere(parent, "TorchCore", 0.17, pos + Vector3(0, 0.34, 0), torch_m)
    LevelKit.add_light(parent, pos + Vector3(0, 0.5, 0), Color(1.0, 0.6, 0.3), 1.95, 7.5)

const PROP := "res://assets/props/dungeon/"

func _p(parent: Node3D, f: String, pos: Vector3, yaw: float = 0.0, s: float = 1.0) -> void:
    LevelKit.prop(parent, PROP + f, pos, yaw, s)

func _dressing() -> void:
    var g := Node3D.new()
    g.name = "Dressing"
    root.add_child(g)
    # ---- Gate of Ash ------------------------------------------------------
    _p(g, "banner_patternA_red.gltf.glb", Vector3(-6.2, 4.4, 8.5), 0.0)
    _p(g, "banner_patternA_red.gltf.glb", Vector3(6.2, 4.4, 8.5), 0.0)
    _p(g, "rubble_large.gltf.glb", Vector3(-6.2, 0.0, -1.5), 0.7)
    _p(g, "rubble_half.gltf.glb", Vector3(5.6, 0.0, 2.6), -0.5)
    _p(g, "barrel_small.gltf.glb", Vector3(7.0, 0.0, -1.0), 0.3)
    _p(g, "crates_stacked.gltf.glb", Vector3(-7.0, 0.0, 4.2), 0.5)
    _p(g, "torch_lit.gltf.glb", Vector3(-7.4, 3.2, 2.0), PI * 0.5)
    _p(g, "torch_lit.gltf.glb", Vector3(7.4, 3.2, 2.0), -PI * 0.5)
    LevelKit.add_light(g, Vector3(-7.0, 3.9, 2.0), Color(1.0, 0.6, 0.3), 1.4, 7.0)
    LevelKit.add_light(g, Vector3(7.0, 3.9, 2.0), Color(1.0, 0.6, 0.3), 1.4, 7.0)
    LevelKit.embers(g, Vector3(0, 2.5, 1.0), 5.0, 16)
    # ---- Long Descent -----------------------------------------------------
    for z in [-11.0, -19.0, -27.0, -35.0]:
        var y := _stair_y(z)
        _p(g, "torch_lit.gltf.glb", Vector3(-4.6, y + 3.0, z), PI * 0.5)
        _p(g, "rubble_half.gltf.glb", Vector3(2.4, y + 0.03, z - 2.0), 0.4)
    # ---- Hall of Cinders --------------------------------------------------
    for z in [-45.0, -51.0, -57.0, -62.0]:
        _p(g, "pillar.gltf.glb", Vector3(-10.8, -21.0, z), 0.0)
        _p(g, "pillar.gltf.glb", Vector3(10.8, -21.0, z), 0.0)
        _p(g, "banner_patternA_red.gltf.glb", Vector3(-11.9, -17.4, z + 1.6), -PI * 0.5)
        _p(g, "banner_patternA_red.gltf.glb", Vector3(11.9, -17.4, z + 1.6), PI * 0.5)
    _p(g, "chest.glb", Vector3(-9.5, -21.0, -49.0), 0.6)
    _p(g, "barrel_large.gltf.glb", Vector3(9.8, -21.0, -49.5), 0.0)
    _p(g, "barrel_small.gltf.glb", Vector3(9.0, -21.0, -47.8), 0.4)
    _p(g, "candle_triple.gltf.glb", Vector3(8.6, -21.0, -43.2), 0.0)
    _p(g, "shelf_large.gltf.glb", Vector3(-11.6, -21.0, -60.0), PI * 0.5)
    LevelKit.embers(g, Vector3(0, -19.0, -52.0), 8.0, 24)
    # ---- Broken Gallery ---------------------------------------------------
    _p(g, "sword_shield.gltf.glb", Vector3(-9.1, -18.6, -75.0), PI * 0.5)
    _p(g, "sword_shield_gold.gltf.glb", Vector3(9.1, -18.6, -85.0), -PI * 0.5)
    _p(g, "rubble_large.gltf.glb", Vector3(2.5, -21.0, -72.0), 0.3)
    _p(g, "rubble_half.gltf.glb", Vector3(-2.0, -21.0, -88.0), -0.6)
    _p(g, "coin_stack_large.gltf.glb", Vector3(-6.5, -17.6, -78.0), 0.0)
    _p(g, "coin_stack_small.gltf.glb", Vector3(-6.0, -17.6, -79.2), 0.0)
    _p(g, "shelf_large.gltf.glb", Vector3(8.9, -21.0, -76.0), -PI * 0.5)
    _p(g, "candle_lit.gltf.glb", Vector3(8.2, -21.0, -79.0), 0.0)
    LevelKit.embers(g, Vector3(0, -19.0, -80.0), 6.0, 18)
    # ---- Ossuary Niche ----------------------------------------------------
    _p(g, "chest_gold.glb", Vector3(0.0, -21.0, -108.5), 0.2)
    _p(g, "coin_stack_large.gltf.glb", Vector3(-1.3, -21.0, -108.9), 0.0)
    _p(g, "candle_triple.gltf.glb", Vector3(-2.4, -21.0, -106.0), 0.0)
    _p(g, "candle_triple.gltf.glb", Vector3(2.4, -21.0, -106.0), 0.0)
    _p(g, "banner_patternC_white.gltf.glb", Vector3(-4.5, -17.4, -112.4), 0.0)
    _p(g, "banner_patternC_white.gltf.glb", Vector3(4.5, -17.4, -112.4), 0.0)
    # ---- Vessel Chamber ---------------------------------------------------
    for sx in [-1.0, 1.0]:
        for z in [-116.0, -128.0]:
            _p(g, "pillar_decorated.gltf.glb", Vector3(sx * 6.8, -21.0, z), 0.0, 0.8)
    _p(g, "candle_triple.gltf.glb", Vector3(-1.9, -21.0, -120.6), 0.0)
    _p(g, "candle_triple.gltf.glb", Vector3(1.9, -21.0, -120.6), 0.0)
    _p(g, "chest.glb", Vector3(-5.6, -21.0, -127.0), -0.4)
    # ---- Choir's Maw ------------------------------------------------------
    _p(g, "floor_tile_big_spikes.glb", Vector3(-6.0, -21.0, -140.0), 0.0)
    _p(g, "floor_tile_big_spikes.glb", Vector3(6.0, -21.0, -140.0), 0.0)
    _p(g, "banner_shield_red.gltf.glb", Vector3(-9.0, -14.6, -158.2), 0.0, 1.2)
    _p(g, "banner_shield_red.gltf.glb", Vector3(9.0, -14.6, -158.2), 0.0, 1.2)
    _p(g, "rubble_large.gltf.glb", Vector3(-9.5, -21.0, -137.0), 0.4)
    _p(g, "rubble_half.gltf.glb", Vector3(9.0, -21.0, -150.0), -0.3)
    LevelKit.embers(g, Vector3(0, -19.0, -145.0), 9.0, 28)

func _stair_y(z: float) -> float:
    var k := (-z - 7.0) / 0.8
    return -0.5 * maxf(k, 0.0)

func _env() -> void:
    var we := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_COLOR
    env.background_color = Color(0.02, 0.018, 0.025)
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color(0.52, 0.45, 0.38)
    env.ambient_light_energy = 1.04
    env.ambient_light_sky_contribution = 0.0
    env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    env.tonemap_white = 1.3
    env.adjustment_enabled = true
    env.adjustment_brightness = 1.26
    env.adjustment_contrast = 1.05
    env.adjustment_saturation = 1.04
    env.fog_enabled = true
    env.fog_light_color = Color(0.07, 0.06, 0.07)
    env.fog_density = 0.014
    env.glow_enabled = true
    env.glow_intensity = 0.3
    env.glow_bloom = 0.1
    env.glow_hdr_threshold = 1.0
    we.environment = env
    root.add_child(we)
    if LevelKit.claim_light():
        var moon := DirectionalLight3D.new()
        moon.rotation_degrees = Vector3(-52.0, 28.0, 0.0)
        moon.light_color = Color(0.55, 0.62, 0.85)
        moon.light_energy = 0.6
        moon.shadow_enabled = false
        root.add_child(moon)

func _beat1() -> void:
    var g := Node3D.new()
    g.name = "Beat1_GateOfAsh"
    root.add_child(g)
    LevelKit.box(g, "Floor", Vector3(16, 0.6, 16), Vector3(0, -0.3, 1), floor_m)
    LevelKit.box(g, "Ceiling", Vector3(16, 0.5, 17), Vector3(0, 6.25, 0.5), dark_m)
    LevelKit.box(g, "WallL", Vector3(0.8, 6, 17), Vector3(-8.4, 3, 0.5), wall_m)
    LevelKit.box(g, "WallR", Vector3(0.8, 6, 17), Vector3(8.4, 3, 0.5), wall_m)
    LevelKit.box(g, "EntryTop", Vector3(9, 2, 0.6), Vector3(0, 5, 9), wall_m)
    LevelKit.box(g, "EntryL", Vector3(3.5, 6, 0.6), Vector3(-6.25, 3, 9), wall_m)
    LevelKit.box(g, "EntryR", Vector3(3.5, 6, 0.6), Vector3(6.25, 3, 9), wall_m)
    LevelKit.cyl(g, "EntryColL", 0.5, 6, Vector3(-4.5, 3, 9), wall_m)
    LevelKit.cyl(g, "EntryColR", 0.5, 6, Vector3(4.5, 3, 9), wall_m)
    LevelKit.box(g, "Lintel", Vector3(9, 0.8, 0.8), Vector3(0, 6.2, 9), dark_m)
    for rz in [-5.0, -1.0, 3.0, 7.0]:
        LevelKit.box(g, "RibL%d" % int(rz), Vector3(0.5, 6, 0.5), Vector3(-7.9, 3, rz), dark_m)
        LevelKit.box(g, "RibR%d" % int(rz), Vector3(0.5, 6, 0.5), Vector3(7.9, 3, rz), dark_m)
    LevelKit.cyl(g, "BrokenColumn", 0.42, 2.2, Vector3(6.6, 1.1, -4.5), wall_m)
    LevelKit.box(g, "Debris1", Vector3(1.4, 0.5, 0.7), Vector3(-5.5, 0.35, -3), dark_m).rotation.z = 0.3
    LevelKit.box(g, "Debris2", Vector3(1.0, 0.4, 0.6), Vector3(5.8, 0.3, 1.5), dark_m).rotation.x = -0.2
    LevelKit.box(g, "Debris3", Vector3(0.9, 0.35, 0.5), Vector3(-3.5, 0.3, 3.2), dark_m).rotation.z = -0.35
    LevelKit.box(g, "Debris4", Vector3(1.2, 0.4, 0.6), Vector3(2.5, 0.28, -5.2), dark_m).rotation.x = 0.25
    _torch(g, Vector3(-7.6, 3.2, 6))
    _torch(g, Vector3(7.6, 3.2, 6))
    _torch(g, Vector3(-7.6, 3.2, -4))

func _beat2() -> void:
    var g := Node3D.new()
    g.name = "Beat2_LongDescent"
    root.add_child(g)
    for k in range(1, 43):
        var top := -0.5 * k
        LevelKit.box(g, "Step%d" % k, Vector3(9, 2.5, 0.82), Vector3(0, top - 1.25, -7.0 - 0.8 * (k - 0.5)), floor_m)
    for j in range(0, 7):
        var zc := -7.0 - 5.0 * j - 2.5
        var yc := -3.0 * j - 3.5
        LevelKit.box(g, "DescentWallL%d" % j, Vector3(0.8, 10, 5.2), Vector3(-5.1, yc, zc), wall_m)
        LevelKit.box(g, "DescentWallR%d" % j, Vector3(0.8, 10, 5.2), Vector3(5.1, yc, zc), wall_m)
    for z in [-12.0, -20.0, -28.0, -36.0]:
        var yf := _stair_y(z)
        LevelKit.cyl(g, "ArchColL%d" % int(z), 0.45, 6, Vector3(-4.2, yf + 3, z), wall_m)
        LevelKit.cyl(g, "ArchColR%d" % int(z), 0.45, 6, Vector3(4.2, yf + 3, z), wall_m)
        LevelKit.box(g, "ArchLintel%d" % int(z), Vector3(9.2, 0.7, 0.9), Vector3(0, yf + 6.3, z), dark_m)
    _torch(g, Vector3(-4.7, _stair_y(-11) + 3.0, -11))
    _torch(g, Vector3(4.7, _stair_y(-19) + 3.0, -19))
    _torch(g, Vector3(-4.7, _stair_y(-27) + 3.0, -27))
    _torch(g, Vector3(4.7, _stair_y(-35) + 3.0, -35))

func _beat3() -> void:
    var g := Node3D.new()
    g.name = "Beat3_HallOfCinders"
    root.add_child(g)
    LevelKit.box(g, "Floor", Vector3(24, 0.6, 25), Vector3(0, -21.3, -52.5), floor_m)
    LevelKit.box(g, "Ceiling", Vector3(24, 0.5, 25), Vector3(0, -12.75, -52.5), dark_m)
    LevelKit.box(g, "WallL", Vector3(0.8, 8, 25), Vector3(-12.4, -17, -52.5), wall_m)
    LevelKit.box(g, "WallR", Vector3(0.8, 8, 25), Vector3(12.4, -17, -52.5), wall_m)
    LevelKit.box(g, "BackL", Vector3(8, 8, 0.8), Vector3(-8, -17, -65), wall_m)
    LevelKit.box(g, "BackR", Vector3(8, 8, 0.8), Vector3(8, -17, -65), wall_m)
    for z in [-45.0, -51.0, -57.0, -62.0]:
        LevelKit.cyl(g, "PillarL%d" % int(z), 0.55, 8, Vector3(-6.5, -17, z), wall_m)
        LevelKit.cyl(g, "PillarR%d" % int(z), 0.55, 8, Vector3(6.5, -17, z), wall_m)
    _torch(g, Vector3(-5.9, -16.2, -47))
    _torch(g, Vector3(5.9, -16.2, -47))
    _torch(g, Vector3(-5.9, -16.2, -58))
    _torch(g, Vector3(5.9, -16.2, -58))
    LevelKit.box(g, "Rubble1", Vector3(1.6, 0.6, 1.0), Vector3(3, -20.7, -44), dark_m).rotation.y = 0.4
    LevelKit.box(g, "Rubble2", Vector3(1.2, 0.5, 0.8), Vector3(-8, -20.75, -55), dark_m).rotation.z = 0.2

func _beat4() -> void:
    var g := Node3D.new()
    g.name = "Beat4_BrokenGallery"
    root.add_child(g)
    LevelKit.box(g, "Floor", Vector3(10, 0.6, 30), Vector3(0, -21.3, -80), floor_m)
    LevelKit.box(g, "Ceiling", Vector3(19, 0.5, 30), Vector3(0, -12.75, -80), dark_m)
    LevelKit.box(g, "BalconyL", Vector3(4.0, 0.6, 28), Vector3(-7, -17.6, -80), floor_m)
    LevelKit.box(g, "BalconyR", Vector3(4.0, 0.6, 28), Vector3(7, -17.6, -80), floor_m)
    LevelKit.box(g, "RailL", Vector3(0.3, 1.2, 28), Vector3(-5.15, -16.7, -80), dark_m)
    LevelKit.box(g, "RailR", Vector3(0.3, 1.2, 28), Vector3(5.15, -16.7, -80), dark_m)
    LevelKit.box(g, "WallL", Vector3(0.8, 8, 30), Vector3(-9.4, -17, -80), wall_m)
    LevelKit.box(g, "WallR", Vector3(0.8, 8, 30), Vector3(9.4, -17, -80), wall_m)
    LevelKit.box(g, "FrontL", Vector3(5, 8, 0.8), Vector3(-6.5, -17, -65), wall_m)
    LevelKit.box(g, "FrontR", Vector3(5, 8, 0.8), Vector3(6.5, -17, -65), wall_m)
    LevelKit.box(g, "BackL", Vector3(5, 8, 0.8), Vector3(-6.5, -17, -95), wall_m)
    LevelKit.box(g, "BackR", Vector3(5, 8, 0.8), Vector3(6.5, -17, -95), wall_m)
    for z in [-72.0, -80.0, -88.0]:
        LevelKit.cyl(g, "ArchColL%d" % int(z), 0.4, 8, Vector3(-4.7, -17, z), wall_m)
        LevelKit.cyl(g, "ArchColR%d" % int(z), 0.4, 8, Vector3(4.7, -17, z), wall_m)
        LevelKit.box(g, "ArchLintel%d" % int(z), Vector3(10, 0.7, 0.9), Vector3(0, -12.9, z), dark_m)
    _torch(g, Vector3(-7, -16.5, -70))
    _torch(g, Vector3(7, -16.5, -78))
    _torch(g, Vector3(-7, -16.5, -88))

func _beat5() -> void:
    var g := Node3D.new()
    g.name = "Beat5_OssuaryNiche"
    root.add_child(g)
    LevelKit.box(g, "Floor", Vector3(18, 0.6, 18), Vector3(0, -21.3, -104), floor_m)
    LevelKit.box(g, "Ceiling", Vector3(18, 0.5, 18), Vector3(0, -14.25, -104), dark_m)
    LevelKit.box(g, "WallL", Vector3(0.8, 7.5, 18), Vector3(-9.4, -17.25, -104), wall_m)
    LevelKit.box(g, "WallR", Vector3(0.8, 7.5, 18), Vector3(9.4, -17.25, -104), wall_m)
    LevelKit.box(g, "FrontL", Vector3(5, 7.5, 0.8), Vector3(-6.5, -17.25, -95), wall_m)
    LevelKit.box(g, "FrontR", Vector3(5, 7.5, 0.8), Vector3(6.5, -17.25, -95), wall_m)
    LevelKit.box(g, "BackL", Vector3(5, 7.5, 0.8), Vector3(-6.5, -17.25, -113), wall_m)
    LevelKit.box(g, "BackR", Vector3(5, 7.5, 0.8), Vector3(6.5, -17.25, -113), wall_m)
    for side in [-1.0, 1.0]:
        for zi in range(0, 10):
            var z := -96.5 - 1.6 * zi
            LevelKit.box(g, "Niche", Vector3(0.4, 1.5, 1.1), Vector3(side * 9.0, -17.5, z), dark_m)
            for bi in range(0, 3):
                var jx := rng.randf_range(-0.1, 0.1)
                var jz := rng.randf_range(-0.25, 0.25)
                LevelKit.box(g, "Bone", Vector3(0.5, 0.16, 0.2), Vector3(side * 8.85 + jx, -17.2 + (bi - 1) * 0.24, z + jz), bone_m)
    _torch(g, Vector3(-8.6, -16.8, -98))
    _torch(g, Vector3(8.6, -16.8, -98))
    LevelKit.add_light(g, Vector3(0, -17.0, -104), Color(0.55, 0.65, 0.85), 1.0, 9.0)

func _beat6() -> void:
    var g := Node3D.new()
    g.name = "Beat6_VesselChamber"
    root.add_child(g)
    LevelKit.box(g, "Floor", Vector3(16, 0.6, 18), Vector3(0, -21.3, -122), floor_m)
    LevelKit.box(g, "Ceiling", Vector3(16, 0.5, 18), Vector3(0, -13.25, -122), dark_m)
    LevelKit.box(g, "WallL", Vector3(0.8, 8, 18), Vector3(-8.4, -17, -122), wall_m)
    LevelKit.box(g, "WallR", Vector3(0.8, 8, 18), Vector3(8.4, -17, -122), wall_m)
    LevelKit.box(g, "FrontL", Vector3(4.4, 8, 0.8), Vector3(-6.2, -17, -113), wall_m)
    LevelKit.box(g, "FrontR", Vector3(4.4, 8, 0.8), Vector3(6.2, -17, -113), wall_m)
    LevelKit.box(g, "BackL", Vector3(8.5, 10, 0.8), Vector3(-8.75, -16, -131), wall_m)
    LevelKit.box(g, "BackR", Vector3(8.5, 10, 0.8), Vector3(8.75, -16, -131), wall_m)
    LevelKit.box(g, "BackLintel", Vector3(9.4, 4, 0.8), Vector3(0, -13, -131), wall_m)
    LevelKit.cyl(g, "Pedestal", 1.3, 1.1, Vector3(0, -20.45, -122), wall_m)
    LevelKit.sphere(g, "Vessel", 0.55, Vector3(0, -19.5, -122), flame_m)
    LevelKit.add_light(g, Vector3(0, -19.4, -122), Color(1.0, 0.7, 0.35), 1.7, 10.0)
    for p in [Vector3(-3, -20.4, -118), Vector3(3, -20.4, -118), Vector3(-3, -20.4, -126), Vector3(3, -20.4, -126)]:
        LevelKit.cyl(g, "Votive", 0.35, 0.8, p, dark_m)
        LevelKit.sphere(g, "VotiveFlame", 0.12, p + Vector3(0, 0.5, 0), torch_m)
    _torch(g, Vector3(-7.6, -16.8, -117))
    _torch(g, Vector3(7.6, -16.8, -117))

func _beat7() -> void:
    var g := Node3D.new()
    g.name = "Beat7_ChoirsMaw"
    root.add_child(g)
    LevelKit.box(g, "Floor", Vector3(26, 0.6, 28), Vector3(0, -21.3, -145), floor_m)
    LevelKit.box(g, "Ceiling", Vector3(26, 0.5, 28), Vector3(0, -11.25, -145), dark_m)
    LevelKit.box(g, "WallL", Vector3(0.8, 10, 28), Vector3(-13.4, -16, -145), wall_m)
    LevelKit.box(g, "WallR", Vector3(0.8, 10, 28), Vector3(13.4, -16, -145), wall_m)
    LevelKit.box(g, "BackWall", Vector3(26, 10, 0.8), Vector3(0, -16, -159), wall_m)
    LevelKit.box(g, "Dais1", Vector3(14, 0.5, 5), Vector3(0, -20.75, -151), dark_m)
    LevelKit.box(g, "Dais2", Vector3(9, 0.5, 3), Vector3(0, -20.25, -153.5), dark_m)
    for p in [Vector3(-10.5, -21, -134), Vector3(10.5, -21, -134), Vector3(-10.5, -21, -148), Vector3(10.5, -21, -148)]:
        LevelKit.cyl(g, "Brazier", 0.5, 1.0, p + Vector3(0, 0.5, 0), dark_m)
        LevelKit.sphere(g, "BrazierFlame", 0.3, p + Vector3(0, 1.15, 0), flame_m)
        LevelKit.add_light(g, p + Vector3(0, 1.5, 0), Color(1.0, 0.6, 0.3), 1.85, 8.5)
    var gate := LevelKit.box(g, "Gate", Vector3(9.0, 5.6, 0.5), Vector3(0, -12.2, -131.2), metal_m)
    gate.add_to_group("gate")

func _actors() -> void:
    var hud := GameHud.new()
    hud.name = "Hud"
    root.add_child(hud)
    var tc := TouchControls.new()
    tc.name = "TouchControls"
    root.add_child(tc)
    var player := Player.new()
    player.name = "Player"
    root.add_child(player)
    player.position = Vector3(0, 0.2, 5)
    var rig := CameraRig.new()
    rig.name = "CameraRig"
    root.add_child(rig)
    rig.position = player.position + Vector3(0, 1.5, 0)
    rig.target = player
    var spawns := [
        ["thrall", Vector3(-3.2, 0.2, -2)],
        ["thrall", Vector3(3.2, 0.2, -2)],
        ["stalker", Vector3(-2, _stair_y(-16) + 0.2, -16)],
        ["stalker", Vector3(2, _stair_y(-30) + 0.2, -30)],
        ["thrall", Vector3(-2, -20.8, -52)],
        ["thrall", Vector3(3, -20.8, -58)],
        ["thrall", Vector3(0, -20.8, -61)],
        ["warden", Vector3(-4, -20.8, -60)],
        ["stalker", Vector3(-2, -20.8, -74)],
        ["stalker", Vector3(2, -20.8, -86)],
        ["thrall", Vector3(0, -20.8, -92)],
        ["thrall", Vector3(-4, -20.8, -104)],
        ["thrall", Vector3(4, -20.8, -106)],
        ["thrall", Vector3(0, -20.8, -109)],
    ]
    for s in spawns:
        var e := EnemyBase.spawn(String(s[0]))
        root.add_child(e)
        e.position = s[1]
    var cps := [Vector3(5.5, 0.0, 3.0), Vector3(9.0, -21.0, -43.0), Vector3(5.5, -21.0, -116.0)]
    for i in cps.size():
        var cp := Checkpoint.new()
        cp.name = "Checkpoint%d" % (i + 1)
        root.add_child(cp)
        cp.position = cps[i]
    var boss := BossChoir.new()
    boss.name = "OssuaryChoir"
    root.add_child(boss)
    boss.position = Vector3(0, -19.9, -153)
