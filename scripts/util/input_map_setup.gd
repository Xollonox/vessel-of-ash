extends Node
## Registers the game's input actions at startup so project.godot stays portable
## between machines and editor sessions.

func _enter_tree() -> void:
    _add("move_forward", [_k(KEY_W), _k(KEY_UP), _j(1, -1.0)])
    _add("move_back", [_k(KEY_S), _k(KEY_DOWN), _j(1, 1.0)])
    _add("move_left", [_k(KEY_A), _k(KEY_LEFT), _j(0, -1.0)])
    _add("move_right", [_k(KEY_D), _k(KEY_RIGHT), _j(0, 1.0)])
    _add("dodge", [_k(KEY_SPACE), _jb(0)])
    _add("light_attack", [_k(KEY_J), _m(MOUSE_BUTTON_LEFT), _jb(2)])
    _add("heavy_attack", [_k(KEY_K), _m(MOUSE_BUTTON_RIGHT), _jb(3)])
    _add("parry", [_k(KEY_L), _jb(1)])
    _add("lock_on", [_k(KEY_Q), _m(MOUSE_BUTTON_MIDDLE)])
    _add("interact", [_k(KEY_E)])
    _add("pause", [_k(KEY_ESCAPE), _jb(6)])
    _add("sprint", [_k(KEY_SHIFT), _jb(7)])
    _add("look_left", [_j(2, -1.0)])
    _add("look_right", [_j(2, 1.0)])
    _add("look_up", [_j(3, -1.0)])
    _add("look_down", [_j(3, 1.0)])

func _add(action: String, events: Array) -> void:
    if not InputMap.has_action(action):
        InputMap.add_action(action, 0.2)
    for e in events:
        InputMap.action_add_event(action, e)

func _k(code: int) -> InputEventKey:
    var e := InputEventKey.new()
    e.physical_keycode = code
    return e

func _m(btn: int) -> InputEventMouseButton:
    var e := InputEventMouseButton.new()
    e.button_index = btn
    return e

func _j(axis: int, value: float) -> InputEventJoypadMotion:
    var e := InputEventJoypadMotion.new()
    e.axis = axis
    e.axis_value = value
    return e

func _jb(btn: int) -> InputEventJoypadButton:
    var e := InputEventJoypadButton.new()
    e.button_index = btn
    return e
