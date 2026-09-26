extends Node
## Focused diagnostic for the sprint path.
## Run: godot --headless --path . res://tools/dbg_sprint.tscn

func _ready() -> void:
    var level: Node = (load("res://scenes/level_01.tscn") as PackedScene).instantiate()
    add_child(level)
    await _wait(30)
    var p := get_tree().get_first_node_in_group("player") as Player
    p.revive()
    p.global_position = Vector3(0, -20.8, -48.0)
    p.velocity = Vector3.ZERO
    await _wait(20)
    print("start pos=", p.global_position, " state=", p.state, " floor=", p.is_on_floor())
    Input.action_press("move_forward")
    await _wait(25)
    print("walk  vel=", p.velocity, " state=", p.state, " sprinting=", p._sprinting)
    Input.action_press("sprint")
    await _wait(25)
    print("run   vel=", p.velocity, " state=", p.state, " sprinting=", p._sprinting,
        " action=", Input.is_action_pressed("sprint"))
    await _wait(25)
    print("run2  vel=", p.velocity, " state=", p.state, " sprinting=", p._sprinting)
    get_tree().quit(0)

func _wait(n: int) -> void:
    for i in range(n):
        await get_tree().physics_frame