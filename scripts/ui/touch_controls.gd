class_name TouchControls
extends CanvasLayer
## Virtual joystick + action buttons for touchscreens (phones, tablets, web).
## Drives the same Input actions the keyboard uses, so gameplay code is shared.
##
## - Left thumb: floating joystick (analog strength feeds the move actions)
## - Right thumb: drag anywhere that is not a button to orbit the camera
## - Buttons: light / heavy / parry / dodge / lock-on / interact

const DEADZONE := 0.16
const JOY_RADIUS := 86.0
const MOVE_ACTIONS := ["move_left", "move_right", "move_forward", "move_back"]

var debug_mouse := false

const BUTTONS := [
    {"action": "light_attack", "label": "LIGHT", "dx": 122.0, "dy": 122.0, "r": 56.0, "col": Color(0.9, 0.55, 0.3, 0.5)},
    {"action": "heavy_attack", "label": "HEAVY", "dx": 250.0, "dy": 158.0, "r": 48.0, "col": Color(0.85, 0.35, 0.25, 0.45)},
    {"action": "parry", "label": "PARRY", "dx": 148.0, "dy": 250.0, "r": 48.0, "col": Color(0.65, 0.65, 0.8, 0.45)},
    {"action": "dodge", "label": "DODGE", "dx": 274.0, "dy": 278.0, "r": 44.0, "col": Color(0.55, 0.72, 0.5, 0.45)},
    {"action": "lock_on", "label": "LOCK", "dx": 96.0, "dy": 336.0, "r": 36.0, "col": Color(0.72, 0.66, 0.5, 0.4)},
    {"action": "interact", "label": "USE", "dx": 358.0, "dy": 202.0, "r": 36.0, "col": Color(0.62, 0.62, 0.62, 0.4)},
]

var _joy_id := -1
var _joy_origin := Vector2.ZERO
var _joy_knob := Vector2.ZERO
var _joy_vec := Vector2.ZERO
var _look_id := -1
var _look_last := Vector2.ZERO
var _btn_touch: Dictionary = {}
var _release_at: Dictionary = {}
var _cam: CameraRig
var _ctl: Control
var _font: Font

func _ready() -> void:
    add_to_group("touch_ui")
    layer = 9
    _font = ThemeDB.fallback_font
    _ctl = Control.new()
    _ctl.name = "Draw"
    _ctl.set_anchors_preset(Control.PRESET_FULL_RECT)
    _ctl.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(_ctl)
    _ctl.draw.connect(_draw_ui)
    visible = DisplayServer.is_touchscreen_available()

func _size() -> Vector2:
    return get_viewport().get_visible_rect().size

func _btn_center(b: Dictionary) -> Vector2:
    var s := _size()
    return Vector2(s.x - float(b.dx), s.y - float(b.dy))

func _input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        if not visible:
            visible = true
        if event.pressed:
            _begin(event.index, event.position)
        else:
            _end(event.index)
    elif event is InputEventScreenDrag:
        _move(event.index, event.position)
    elif debug_mouse:
        if event is InputEventMouseButton:
            if event.pressed:
                _begin(0, event.position)
            else:
                _end(0)
        elif event is InputEventMouseMotion and _joy_id == 0:
            _move(0, event.position)

func _begin(idx: int, pos: Vector2) -> void:
    var s := _size()
    if pos.x < s.x * 0.5 and pos.y > s.y * 0.35:
        _joy_id = idx
        _joy_origin = pos
        _joy_knob = pos
        _joy_vec = Vector2.ZERO
        return
    for b in BUTTONS:
        if pos.distance_to(_btn_center(b)) <= float(b.r) + 12.0:
            _btn_touch[idx] = b.action
            _release_at.erase(b.action)
            Input.action_press(b.action, 1.0)
            return
    _look_id = idx
    _look_last = pos

func _move(idx: int, pos: Vector2) -> void:
    if idx == _joy_id:
        var d := pos - _joy_origin
        if d.length() > JOY_RADIUS:
            d = d.normalized() * JOY_RADIUS
        _joy_knob = _joy_origin + d
        _joy_vec = d / JOY_RADIUS
        _apply_move(_joy_vec)
    elif idx == _look_id:
        var d := pos - _look_last
        _look_last = pos
        if _cam == null or not is_instance_valid(_cam):
            _cam = get_tree().get_first_node_in_group("camera_rig") as CameraRig
        if _cam != null:
            _cam.apply_look(d.x * 2.2, d.y * 2.2)

func _end(idx: int) -> void:
    if idx == _joy_id:
        _joy_id = -1
        _joy_vec = Vector2.ZERO
        for a in MOVE_ACTIONS:
            Input.action_release(a)
        return
    if idx == _look_id:
        _look_id = -1
        return
    if _btn_touch.has(idx):
        var action: String = _btn_touch[idx]
        _btn_touch.erase(idx)
        _release_at[action] = Time.get_ticks_msec() + 80

func _process(_delta: float) -> void:
    if not visible:
        if _sprinting:
            _sprinting = false
            Input.action_release("sprint")
        return
    _ctl.queue_redraw()
    var now := Time.get_ticks_msec()
    for a in _release_at.keys():
        if now >= int(_release_at[a]):
            _release_at.erase(a)
            Input.action_release(a)

func _apply_move(v: Vector2) -> void:
    _axis("move_right", "move_left", v.x)
    _axis("move_back", "move_forward", v.y)
    # pushing the stick to the rim sprints - the mobile equivalent of holding Shift
    if v.length() >= SPRINT_RIM:
        if not _sprinting:
            _sprinting = true
            Input.action_press("sprint", 1.0)
    elif _sprinting:
        _sprinting = false
        Input.action_release("sprint")

func _axis(pos_action: String, neg_action: String, value: float) -> void:
    if value > DEADZONE:
        Input.action_press(pos_action, clampf(value, 0.0, 1.0))
        Input.action_release(neg_action)
    elif value < -DEADZONE:
        Input.action_press(neg_action, clampf(-value, 0.0, 1.0))
        Input.action_release(pos_action)
    else:
        Input.action_release(pos_action)
        Input.action_release(neg_action)

func _draw_ui() -> void:
    if not visible:
        return
    var s := _size()
    var base := _joy_origin if _joy_id >= 0 else Vector2(120.0, s.y - 136.0)
    var knob := _joy_knob if _joy_id >= 0 else base
    _ctl.draw_circle(base, JOY_RADIUS, Color(0.10, 0.09, 0.11, 0.40))
    _ctl.draw_arc(base, JOY_RADIUS, 0, TAU, 48, Color(0.85, 0.72, 0.55, 0.35), 2.0)
    _ctl.draw_circle(knob, 34.0, Color(0.85, 0.72, 0.55, 0.30))
    _ctl.draw_arc(knob, 34.0, 0, TAU, 32, Color(0.95, 0.85, 0.65, 0.5), 2.0)
    for b in BUTTONS:
        var c := _btn_center(b)
        var r := float(b.r)
        var held: bool = _btn_touch.values().has(b.action)
        var col: Color = b.col
        _ctl.draw_circle(c, r, col if held else Color(col.r, col.g, col.b, col.a * 0.62))
        _ctl.draw_arc(c, r, 0, TAU, 40, Color(0.95, 0.88, 0.72, 0.55), 2.0)
        var txt: String = b.label
        var w := _font.get_string_size(txt, HORIZONTAL_ALIGNMENT_CENTER, -1, 13).x
        _ctl.draw_string(_font, c + Vector2(-w * 0.5, 5.0), txt, HORIZONTAL_ALIGNMENT_CENTER, -1, 13, Color(0.98, 0.94, 0.86, 0.9))

# ------------------------------------------------------------- test hooks ----

var _sprinting := false
const SPRINT_RIM := 0.88

func debug_set_move(v: Vector2) -> void:
    visible = true
    _joy_vec = v
    _apply_move(v)

func debug_press(action: String) -> void:
    visible = true
    _release_at.erase(action)
    Input.action_press(action, 1.0)
    _release_at[action] = Time.get_ticks_msec() + 90
