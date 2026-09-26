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
    _architecture()
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
    LevelKit.add_light(parent, pos + Vector3(0, 0.5, 0), Color(1.0, 0.62, 0.32), 2.35, 9.0)

func _torch_shadow(parent: Node3D, pos: Vector3) -> void:
    LevelKit.box(parent, "TorchBracket", Vector3(0.22, 0.22, 0.22), pos, dark_m)
    LevelKit.sphere(parent, "TorchCore", 0.17, pos + Vector3(0, 0.34, 0), torch_m)
    LevelKit.add_light(parent, pos + Vector3(0, 0.5, 0), Color(1.0, 0.62, 0.32), 2.45, 10.0, true)

const PROP := "res://assets/props/dungeon/"

func _p(parent: Node3D, f: String, pos: Vector3, yaw: float = 0.0, s: float = 1.0) -> void:
    LevelKit.prop(parent, PROP + f, pos, yaw, s)

# ---------------------------------------------------------------- kit grid ----
# KayKit Dungeon Remastered is a 4x4x4 modular kit: floor tiles are 4x4 with the
# pivot on the (+x, +z) corner, walls are 4 wide x 4 tall x 1 thick with the pivot
# on the (+x, +z) corner of the base, so everything snaps to a 4 m grid.

const TILE := 4.0

func _kit(parent: Node3D, base: String, pos: Vector3, yaw: float = 0.0, s: float = 1.0) -> Node3D:
    var path := PROP + base + ".gltf.glb"
    if not ResourceLoader.exists(path):
        path = PROP + base + ".glb"
    return LevelKit.prop(parent, path, pos, yaw, s)

## Covers a rectangle with 4x4 floor tiles. `style` picks the tile family so each
## beat reads differently: tile / dirt / wood / grate.
func _floor_area(parent: Node3D, cx: float, cz: float, w: float, d: float, y: float,
        style: String = "tile", wear: float = 0.35) -> void:
    var nx := int(ceil(w / TILE))
    var nz := int(ceil(d / TILE))
    var x0 := cx - 0.5 * w
    var z0 := cz - 0.5 * d
    for i in nx:
        for j in nz:
            var px := x0 + TILE * float(i + 1)
            var pz := z0 + TILE * float(j + 1)
            var r := rng.randf()
            var base := "floor_tile_large"
            match style:
                "dirt":
                    base = "floor_dirt_large" if r > 0.22 else "floor_dirt_large_rocky"
                "wood":
                    base = "floor_wood_large" if r > 0.3 else "floor_wood_large_dark"
                "grate":
                    base = "floor_tile_large" if r > 0.25 else "floor_tile_big_grate"
                _:
                    if r < wear * 0.16:
                        base = "floor_tile_small_broken_A"
                    elif r < wear * 0.3:
                        base = "floor_tile_small_weeds_A"
                    elif r < wear * 0.4:
                        base = "floor_tile_large_rocks"
                    elif r < wear * 0.5:
                        base = "floor_tile_big_grate"
            _kit(parent, base, Vector3(px, y, pz))

## One 4 m wall segment, pivot on the (+x, +z) corner of its 4x4x1 slab:
##   yaw   0  -> occupies x[P.x-4, P.x]  z[P.z-1, P.z]   (wall running along x)
##   yaw  90  -> occupies x[P.x-1, P.x]  z[P.z, P.z+4]   (wall running along +z)
##   yaw 180  -> occupies x[P.x, P.x+4]  z[P.z, P.z+1]   (wall running along -x)
##   yaw -90  -> occupies x[P.x, P.x+1]  z[P.z-4, P.z]   (wall running along -z)
func _wall_seg(parent: Node3D, kind: String, pos: Vector3, yaw: float = 0.0) -> Node3D:
    return _kit(parent, kind, pos, yaw)

## Full room dress-up: floor tiles plus perimeter walls with optional door gaps.
## `doors` maps side name -> [center, half_width] measured along that side's axis.
func _room(parent: Node3D, cx: float, cz: float, hx: float, hz: float, y: float,
        style: String = "tile", kind: String = "wall", arch_every: int = 0,
        doors: Dictionary = {}) -> void:
    _floor_area(parent, cx, cz, hx * 2.0, hz * 2.0, y, style)
    var x0 := cx - hx
    var z0 := cz - hz
    var nx := int(ceil(hx * 2.0 / TILE))
    var nz := int(ceil(hz * 2.0 / TILE))
    for i in nx:
        var px_lo := x0 + TILE * float(i)
        var px_hi := x0 + TILE * float(i + 1)
        var c := 0.5 * (px_lo + px_hi)
        var k := _arch_pick(kind, i, arch_every)
        if not _in_door(doors.get("north"), c, hx):
            # north wall (-z): occupies z[z0-1, z0], runs +x
            _wall_seg(parent, k, Vector3(px_hi, y, z0), 0.0)
        if not _in_door(doors.get("south"), c, hx):
            # south wall (+z): occupies z[z0+2hz, z0+2hz+1], runs -x
            _wall_seg(parent, _arch_pick(kind, i + 1, arch_every), Vector3(px_lo, y, z0 + hz * 2.0), PI)
    for j in nz:
        var pz_lo := z0 + TILE * float(j)
        var pz_hi := z0 + TILE * float(j + 1)
        var c2 := 0.5 * (pz_lo + pz_hi)
        var k2 := _arch_pick(kind, j, arch_every)
        if not _in_door(doors.get("west"), c2, hz):
            # west wall (-x): occupies x[x0-1, x0], runs +z
            _wall_seg(parent, k2, Vector3(x0 - 1.0, y, pz_lo), PI * 0.5)
        if not _in_door(doors.get("east"), c2, hz):
            # east wall (+x): occupies x[x0+2hx, x0+2hx+1], runs -z
            _wall_seg(parent, _arch_pick(kind, j + 1, arch_every),
                Vector3(x0 + hx * 2.0 + 1.0, y, pz_hi), -PI * 0.5)

func _in_door(gap: Variant, c: float, _half: float) -> bool:
    if gap == null:
        return false
    var g: Array = gap
    return absf(c - float(g[0])) <= float(g[1])

func _arch_pick(kind: String, i: int, arch_every: int) -> String:
    if arch_every > 0 and i % arch_every == arch_every / 2:
        return "wall_arched"
    return kind

## Corridor wall on the +x or -x side, running down -z. `side` is -1 (west) or +1 (east).
func _corridor_side(parent: Node3D, side: float, x_face: float, z_from: float, z_to: float,
        y_at: Callable, kind: String = "wall", arch_every: int = 0) -> void:
    var length := absf(z_to - z_from)
    var segs := int(ceil(length / TILE))
    for i in segs:
        var z_hi := z_from - TILE * float(i)
        var z_lo := z_hi - TILE
        var zc := 0.5 * (z_hi + z_lo)
        var y: float = y_at.call(zc)
        var k := _arch_pick(kind, i, arch_every)
        if side < 0.0:
            _wall_seg(parent, k, Vector3(x_face, y, z_lo), PI * 0.5)
        else:
            _wall_seg(parent, k, Vector3(x_face, y, z_hi), -PI * 0.5)

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
    # drifting ash in every room: cheap atmosphere that reads at any distance
    LevelKit.ash_motes(g, Vector3(0, 2.5, 1.0), 7.0, 34)
    LevelKit.ash_motes(g, Vector3(0, _stair_y(-20) + 2.0, -20.0), 4.0, 30)
    LevelKit.ash_motes(g, Vector3(0, -19.5, -52.5), 11.0, 44)
    LevelKit.ash_motes(g, Vector3(0, -19.5, -80.0), 5.0, 30)
    LevelKit.ash_motes(g, Vector3(0, -19.5, -104.0), 8.0, 34)
    LevelKit.ash_motes(g, Vector3(0, -19.5, -122.0), 7.0, 32)
    LevelKit.ash_motes(g, Vector3(0, -19.5, -145.0), 12.0, 50)
    # lived-in clutter: crypt goods, stores and a little treasure trail
    _p(g, "trunk_large_A.gltf.glb", Vector3(-6.4, 0.0, -1.2), 0.3)
    _p(g, "trunk_medium_B.gltf.glb", Vector3(6.6, 0.0, 4.4), -0.6)
    _p(g, "shelf_small.gltf.glb", Vector3(-11.6, -21.0, -46.0), PI * 0.5)
    _p(g, "table_long.gltf.glb", Vector3(10.4, -21.0, -56.0), -PI * 0.5)
    _p(g, "chair.gltf.glb", Vector3(9.2, -21.0, -54.4), 0.9)
    _p(g, "keg.gltf.glb", Vector3(-10.6, -21.0, -62.0), 0.2)
    _p(g, "bottle_A_green.gltf.glb", Vector3(-10.2, -21.0, -61.6), 0.0)
    _p(g, "plate_food_A.gltf.glb", Vector3(10.2, -21.2, -55.4), 0.0)
    _p(g, "keyring_hanging.gltf.glb", Vector3(-8.7, -18.6, -76.0), PI * 0.5)
    _p(g, "trunk_small_C.gltf.glb", Vector3(4.2, -21.0, -86.0), -0.4)
    _p(g, "box_small.gltf.glb", Vector3(-4.0, -21.0, -92.0), 0.7)
    _p(g, "candle_thin_lit.gltf.glb", Vector3(8.6, -21.0, -104.0), 0.0)
    _p(g, "candle_thin_lit.gltf.glb", Vector3(-8.6, -21.0, -106.0), 0.0)
    _p(g, "bed_floor.gltf.glb", Vector3(-6.6, -21.0, -118.0), 0.1)
    _p(g, "stool.gltf.glb", Vector3(-5.2, -21.0, -117.0), 0.5)
    _p(g, "keyring.gltf.glb", Vector3(-6.0, -17.6, -128.0), 0.0)
    _p(g, "coin.gltf.glb", Vector3(5.2, -21.0, -138.0), 0.0)
    _p(g, "coin.gltf.glb", Vector3(-5.6, -21.0, -142.0), 0.0)
    _p(g, "plate.gltf.glb", Vector3(7.4, -21.0, -152.0), 0.0)
    _p(g, "bottle_B_brown.gltf.glb", Vector3(-7.8, -21.0, -156.0), 0.0)
    _p(g, "shelves.gltf.glb", Vector3(12.2, -21.0, -140.0), -PI * 0.5)
    _p(g, "box_stacked.gltf.glb", Vector3(-12.0, -21.0, -133.0), 0.4)

func _stair_y(z: float) -> float:
    var k := (-z - 7.0) / 0.8
    return -0.5 * maxf(k, 0.0)

# ----------------------------------------------------------- architecture ----
## Dresses the box-built rooms with the KayKit modular stone kit: textured floor
## tiles, wall slabs with arched bays, risers on the long stair and balcony rails.
func _architecture() -> void:
    var g := Node3D.new()
    g.name = "Architecture"
    root.add_child(g)

    # --- Beat 1: Gate of Ash (16x16, floor top y=0) ---
    _room(g, 0.0, 1.0, 8.0, 8.5, 0.0, "tile", "wall", 2, {"north": [0.0, 3.2]})

    # --- Beat 2: Long Descent (9 wide, steps down to y=-21) ---
    for k in range(1, 43):
        var top := -0.5 * float(k)
        var zc := -7.0 - 0.8 * (float(k) - 0.5)
        for sx in [-0.5, 4.5]:
            var t := _kit(g, "floor_tile_large", Vector3(sx, top, zc + 0.41))
            t.scale = Vector3(1.25, 1.0, 0.2)
    var y_at := func(z: float) -> float: return _stair_y(z)
    _corridor_side(g, -1.0, -4.7, -7.0, -40.0, y_at, "wall", 2)
    _corridor_side(g, 1.0, 4.7, -7.0, -40.0, y_at, "wall", 2)
    # arch frames marching down the stair
    for z in [-11.0, -19.0, -27.0, -35.0]:
        var yf := _stair_y(z)
        _kit(g, "wall_arched", Vector3(-4.7, yf, z + 2.0), PI * 0.5)
        _kit(g, "wall_arched", Vector3(4.7, yf, z), -PI * 0.5)

    # --- Beat 3: Hall of Cinders (24 wide x 25 deep at y=-21) ---
    _room(g, 0.0, -52.5, 12.0, 12.5, -21.0, "tile", "wall", 3,
        {"north": [0.0, 4.0], "south": [0.0, 4.0]})

    # --- Beat 4: Broken Gallery (10 wide corridor + two balconies) ---
    _room(g, 0.0, -80.0, 5.0, 15.0, -21.0, "tile", "wall_broken", 2,
        {"north": [0.0, 3.0], "south": [0.0, 3.0]})
    for side in [-1.0, 1.0]:
        _floor_area(g, side * 7.0, -80.0, 4.0, 28.0, -17.3, "wood", 0.2)
        # balcony rails from the kit barrier pieces
        for i in 7:
            _kit(g, "barrier", Vector3(side * 5.15, -17.3, -94.0 + TILE * float(i + 1)),
                PI * 0.5 if side > 0.0 else -PI * 0.5)
        for i in 7:
            _kit(g, "barrier", Vector3(side * 9.0, -17.3, -94.0 + TILE * float(i + 1)),
                -PI * 0.5 if side > 0.0 else PI * 0.5)

    # --- Beat 5: Ossuary Niche (18x18, bone dust floor) ---
    _room(g, 0.0, -104.0, 9.0, 9.0, -21.0, "dirt", "wall_broken", 0,
        {"north": [0.0, 3.0], "south": [0.0, 3.0]})

    # --- Beat 6: Vessel Chamber (16x18) ---
    _room(g, 0.0, -122.0, 8.0, 9.0, -21.0, "tile", "wall", 2,
        {"north": [0.0, 2.5], "south": [0.0, 5.0]})

    # --- Beat 7: Choir's Maw (26x28 ritual floor) ---
    _room(g, 0.0, -145.0, 13.0, 14.0, -21.0, "grate", "wall", 3,
        {"north": [0.0, 5.0]})

func _env() -> void:
    var we := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_COLOR
    env.background_color = Color(0.018, 0.016, 0.024)
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color(0.46, 0.42, 0.42)
    env.ambient_light_energy = 1.28
    env.ambient_light_sky_contribution = 0.0
    env.tonemap_mode = Environment.TONE_MAPPER_ACES
    env.tonemap_white = 1.35
    env.adjustment_enabled = true
    env.adjustment_brightness = 1.44
    env.adjustment_contrast = 1.09
    env.adjustment_saturation = 1.08
    env.fog_enabled = true
    env.fog_light_color = Color(0.09, 0.07, 0.075)
    env.fog_density = 0.015
    env.fog_aerial_perspective = 0.0
    env.fog_sky_affect = 0.0
    env.glow_enabled = true
    env.glow_intensity = 0.55
    env.glow_bloom = 0.22
    env.glow_hdr_threshold = 0.82
    env.glow_hdr_scale = 2.0
    env.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
    env.glow_strength = 1.15
    env.set("glow_levels/3", 0.4)
    env.set("glow_levels/4", 0.8)
    env.set("glow_levels/5", 1.0)
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
    _torch(g, Vector3(4.7, _stair_y(-15) + 3.0, -15))
    _torch(g, Vector3(4.7, _stair_y(-19) + 3.0, -19))
    _torch(g, Vector3(-4.7, _stair_y(-23) + 3.0, -23))
    _torch(g, Vector3(-4.7, _stair_y(-27) + 3.0, -27))
    _torch(g, Vector3(4.7, _stair_y(-31) + 3.0, -31))
    _torch(g, Vector3(4.7, _stair_y(-35) + 3.0, -35))
    _torch(g, Vector3(-4.7, _stair_y(-39) + 3.0, -39))

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
        LevelKit.add_light(g, p + Vector3(0, 1.5, 0), Color(1.0, 0.62, 0.32), 2.4, 11.0)
    # the two braziers flanking the dais cast real shadows onto the ritual floor
    _torch_shadow(g, Vector3(-4.6, -20.2, -150.0))
    _torch_shadow(g, Vector3(4.6, -20.2, -150.0))
    LevelKit.add_light(g, Vector3(-9.0, -15.0, -157.0), Color(1.0, 0.55, 0.28), 1.9, 12.0)
    LevelKit.add_light(g, Vector3(9.0, -15.0, -157.0), Color(1.0, 0.55, 0.28), 1.9, 12.0)
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
        ["mage", Vector3(8, -20.8, -47)],
        ["stalker", Vector3(-2, -20.8, -74)],
        ["stalker", Vector3(2, -20.8, -86)],
        ["thrall", Vector3(0, -20.8, -92)],
        ["mage", Vector3(7, -17.1, -76)],
        ["thrall", Vector3(-4, -20.8, -104)],
        ["thrall", Vector3(4, -20.8, -106)],
        ["thrall", Vector3(0, -20.8, -109)],
        ["mage", Vector3(-6, -20.8, -118)],
        ["stalker", Vector3(6, -20.8, -126)],
        ["thrall", Vector3(-8, -20.8, -136)],
        ["thrall", Vector3(8, -20.8, -140)],
        ["mage", Vector3(0, -20.8, -160)],
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
