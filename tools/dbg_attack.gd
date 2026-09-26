extends Node
## Smoke test: loads the level, swings, prints the stack status, quits.
## Catches parse/runtime errors that --headless --quit alone would miss.

func _ready() -> void:
    var inst := (load("res://scenes/level_01.tscn") as PackedScene).instantiate()
    add_child(inst)
    await get_tree().create_timer(0.6).timeout
    var p := get_tree().get_first_node_in_group("player") as Player
    print("player: ", p, "  state=", p.state if p != null else -1)
    if p != null:
        p.force_light()
    await get_tree().create_timer(0.5).timeout
    if p != null:
        p.force_heavy()
    await get_tree().create_timer(0.8).timeout
    var enemies := get_tree().get_nodes_in_group("enemy")
    var boss := get_tree().get_first_node_in_group("boss")
    print("enemies: ", enemies.size(), "  boss: ", boss)
    print("player pos: ", p.global_position if p != null else "none")
    print("audio loaded: ", AudioManager.has_sfx("boss_roar"), " ", AudioManager.has_sfx("parry"), " ", AudioManager.has_sfx("ambient"))
    print("DBG OK")
    get_tree().quit(0)
