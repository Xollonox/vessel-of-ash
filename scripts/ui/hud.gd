class_name GameHud
extends CanvasLayer
## Combat HUD: health, dodge pip, boss bar, lock-on bar, toasts, beat titles,
## damage flash, and the defeat / victory overlays.

var _hp_fill: ColorRect
var _dodge_pip: ColorRect
var _boss_root: Control
var _boss_fill: ColorRect
var _boss_name: Label
var _lock_root: Control
var _lock_fill: ColorRect
var _lock_name: Label
var _toasts: VBoxContainer
var _beat: Label
var _beat_tween: Tween
var _parry: Label
var _flash: ColorRect
var _low: ColorRect
var _defeat_root: Control
var _victory_root: Control
var _victory_stats: Label
var _player: Player
var _time := 0.0

func _ready() -> void:
    add_to_group("hud")
    layer = 10
    _flash = _mk_full_rect(Color(0.7, 0.06, 0.05, 0.0))
    _low = _mk_full_rect(Color(0.6, 0.02, 0.02, 0.0))
    _build_health()
    _build_boss()
    _build_lock()
    _build_toasts()
    _build_beat()
    _build_parry()
    _build_defeat()
    _build_victory()

func _mk_full_rect(c: Color) -> ColorRect:
    var r := ColorRect.new()
    r.color = c
    r.set_anchors_preset(Control.PRESET_FULL_RECT)
    r.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(r)
    return r

func _build_health() -> void:
    var root := Control.new()
    root.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
    root.offset_left = 26.0
    root.offset_top = -54.0
    root.offset_right = 296.0
    root.offset_bottom = -34.0
    root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(root)
    var bg := ColorRect.new()
    bg.color = Color(0.05, 0.045, 0.05, 0.85)
    bg.set_anchors_preset(Control.PRESET_FULL_RECT)
    root.add_child(bg)
    _hp_fill = ColorRect.new()
    _hp_fill.color = Color(0.72, 0.18, 0.12)
    _hp_fill.position = Vector2(2, 2)
    _hp_fill.size = Vector2(266, 16)
    root.add_child(_hp_fill)
    var name_l := Label.new()
    name_l.text = "KAEL ARDYN"
    name_l.add_theme_font_size_override("font_size", 13)
    name_l.add_theme_color_override("font_color", Color(0.85, 0.8, 0.72))
    name_l.position = Vector2(0, -21)
    root.add_child(name_l)
    _dodge_pip = ColorRect.new()
    _dodge_pip.color = Color(0.4, 0.36, 0.3)
    _dodge_pip.position = Vector2(278, 6)
    _dodge_pip.size = Vector2(9, 9)
    root.add_child(_dodge_pip)

func _build_boss() -> void:
    _boss_root = Control.new()
    _boss_root.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
    _boss_root.offset_left = 320.0
    _boss_root.offset_right = -320.0
    _boss_root.offset_top = -86.0
    _boss_root.offset_bottom = -66.0
    _boss_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(_boss_root)
    var bg := ColorRect.new()
    bg.color = Color(0.05, 0.045, 0.05, 0.85)
    bg.set_anchors_preset(Control.PRESET_FULL_RECT)
    _boss_root.add_child(bg)
    _boss_fill = ColorRect.new()
    _boss_fill.color = Color(0.66, 0.14, 0.1)
    _boss_fill.position = Vector2(2, 2)
    _boss_fill.size = Vector2(636, 16)
    _boss_root.add_child(_boss_fill)
    _boss_name = Label.new()
    _boss_name.text = ""
    _boss_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _boss_name.add_theme_font_size_override("font_size", 15)
    _boss_name.add_theme_color_override("font_color", Color(0.9, 0.82, 0.7))
    _boss_name.position = Vector2(0, -24)
    _boss_name.size = Vector2(640, 22)
    _boss_root.add_child(_boss_name)
    _boss_root.visible = false

func _build_lock() -> void:
    _lock_root = Control.new()
    _lock_root.set_anchors_preset(Control.PRESET_TOP_WIDE)
    _lock_root.offset_left = 480.0
    _lock_root.offset_right = -480.0
    _lock_root.offset_top = 26.0
    _lock_root.offset_bottom = 40.0
    _lock_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(_lock_root)
    var bg := ColorRect.new()
    bg.color = Color(0.05, 0.045, 0.05, 0.8)
    bg.set_anchors_preset(Control.PRESET_FULL_RECT)
    _lock_root.add_child(bg)
    _lock_fill = ColorRect.new()
    _lock_fill.color = Color(0.72, 0.2, 0.14)
    _lock_fill.position = Vector2(2, 2)
    _lock_fill.size = Vector2(316, 10)
    _lock_root.add_child(_lock_fill)
    _lock_name = Label.new()
    _lock_name.text = ""
    _lock_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _lock_name.add_theme_font_size_override("font_size", 14)
    _lock_name.add_theme_color_override("font_color", Color(0.88, 0.8, 0.7))
    _lock_name.position = Vector2(0, -22)
    _lock_name.size = Vector2(320, 20)
    _lock_root.add_child(_lock_name)
    _lock_root.visible = false

func _build_toasts() -> void:
    _toasts = VBoxContainer.new()
    _toasts.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
    _toasts.offset_left = 400.0
    _toasts.offset_right = -400.0
    _toasts.offset_top = -200.0
    _toasts.offset_bottom = -104.0
    _toasts.alignment = BoxContainer.ALIGNMENT_END
    _toasts.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(_toasts)

func _build_beat() -> void:
    _beat = Label.new()
    _beat.set_anchors_preset(Control.PRESET_CENTER)
    _beat.offset_left = -420.0
    _beat.offset_right = 420.0
    _beat.offset_top = -120.0
    _beat.offset_bottom = -60.0
    _beat.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _beat.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    _beat.add_theme_font_size_override("font_size", 38)
    _beat.add_theme_color_override("font_color", Color(0.93, 0.87, 0.76))
    _beat.modulate.a = 0.0
    _beat.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(_beat)

func _build_parry() -> void:
    _parry = Label.new()
    _parry.text = "PARRY"
    _parry.set_anchors_preset(Control.PRESET_CENTER)
    _parry.offset_left = -100.0
    _parry.offset_right = 100.0
    _parry.offset_top = 30.0
    _parry.offset_bottom = 70.0
    _parry.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _parry.add_theme_font_size_override("font_size", 30)
    _parry.add_theme_color_override("font_color", Color(0.95, 0.72, 0.3))
    _parry.pivot_offset = Vector2(100, 20)
    _parry.modulate.a = 0.0
    _parry.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(_parry)

func _build_defeat() -> void:
    _defeat_root = Control.new()
    _defeat_root.set_anchors_preset(Control.PRESET_FULL_RECT)
    _defeat_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(_defeat_root)
    var bg := ColorRect.new()
    bg.color = Color(0.02, 0.015, 0.02, 0.72)
    bg.set_anchors_preset(Control.PRESET_FULL_RECT)
    _defeat_root.add_child(bg)
    var box := VBoxContainer.new()
    box.set_anchors_preset(Control.PRESET_CENTER)
    box.offset_left = -300.0
    box.offset_right = 300.0
    box.offset_top = -70.0
    box.offset_bottom = 70.0
    _defeat_root.add_child(box)
    var title := Label.new()
    title.text = "FALLEN"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 62)
    title.add_theme_color_override("font_color", Color(0.66, 0.22, 0.16))
    box.add_child(title)
    var sub := Label.new()
    sub.text = "The Cinderhold reclaims you — returning to the last ember"
    sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    sub.add_theme_font_size_override("font_size", 16)
    sub.add_theme_color_override("font_color", Color(0.72, 0.66, 0.6))
    box.add_child(sub)
    _defeat_root.visible = false

func _build_victory() -> void:
    _victory_root = Control.new()
    _victory_root.set_anchors_preset(Control.PRESET_FULL_RECT)
    _victory_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(_victory_root)
    var bg := ColorRect.new()
    bg.color = Color(0.03, 0.025, 0.02, 0.78)
    bg.set_anchors_preset(Control.PRESET_FULL_RECT)
    _victory_root.add_child(bg)
    var box := VBoxContainer.new()
    box.set_anchors_preset(Control.PRESET_CENTER)
    box.offset_left = -400.0
    box.offset_right = 400.0
    box.offset_top = -90.0
    box.offset_bottom = 90.0
    _victory_root.add_child(box)
    var title := Label.new()
    title.text = "THE CHOIR IS SILENT"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 48)
    title.add_theme_color_override("font_color", Color(0.95, 0.86, 0.68))
    box.add_child(title)
    _victory_stats = Label.new()
    _victory_stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _victory_stats.add_theme_font_size_override("font_size", 18)
    _victory_stats.add_theme_color_override("font_color", Color(0.85, 0.78, 0.68))
    box.add_child(_victory_stats)
    var foot := Label.new()
    foot.text = "Vessel of Ash — vertical slice"
    foot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    foot.add_theme_font_size_override("font_size", 13)
    foot.add_theme_color_override("font_color", Color(0.55, 0.5, 0.45))
    box.add_child(foot)
    _victory_root.visible = false

# ------------------------------------------------------------------ API ----

func set_health(cur: float, maxv: float) -> void:
    _hp_fill.size = Vector2(266.0 * clampf(cur / maxf(maxv, 0.01), 0.0, 1.0), 16.0)

func show_boss(name: String) -> void:
    _boss_name.text = name
    _boss_root.visible = true

func set_boss(cur: float, maxv: float) -> void:
    _boss_fill.size = Vector2(636.0 * clampf(cur / maxf(maxv, 0.01), 0.0, 1.0), 16.0)

func hide_boss() -> void:
    _boss_root.visible = false

func set_lock(name: String, cur: float, maxv: float) -> void:
    _lock_name.text = name
    _lock_fill.size = Vector2(316.0 * clampf(cur / maxf(maxv, 0.01), 0.0, 1.0), 10.0)
    _lock_root.visible = true

func clear_lock() -> void:
    _lock_root.visible = false

func toast(text: String) -> void:
    var l := Label.new()
    l.text = text
    l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    l.add_theme_font_size_override("font_size", 16)
    l.add_theme_color_override("font_color", Color(0.88, 0.8, 0.66))
    l.modulate.a = 0.0
    l.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _toasts.add_child(l)
    while _toasts.get_child_count() > 3:
        var old := _toasts.get_child(0)
        _toasts.remove_child(old)
        old.queue_free()
    var tw := l.create_tween()
    tw.tween_property(l, "modulate:a", 1.0, 0.25)
    tw.tween_interval(2.6)
    tw.tween_property(l, "modulate:a", 0.0, 0.6)
    tw.tween_callback(l.queue_free)

func beat_title(text: String) -> void:
    _beat.text = text
    if _beat_tween != null and _beat_tween.is_valid():
        _beat_tween.kill()
    _beat.modulate.a = 0.0
    _beat_tween = _beat.create_tween()
    _beat_tween.tween_property(_beat, "modulate:a", 1.0, 0.5)
    _beat_tween.tween_interval(1.9)
    _beat_tween.tween_property(_beat, "modulate:a", 0.0, 0.8)

func parry_popup() -> void:
    _parry.modulate.a = 1.0
    _parry.scale = Vector2(1.35, 1.35)
    var tw := _parry.create_tween()
    tw.set_parallel(true)
    tw.tween_property(_parry, "scale", Vector2.ONE, 0.16)
    tw.tween_property(_parry, "modulate:a", 0.0, 0.55).set_delay(0.2)

func damage_flash() -> void:
    _flash.color = Color(0.7, 0.06, 0.05, 0.34)
    var tw := _flash.create_tween()
    tw.tween_property(_flash, "color:a", 0.0, 0.5)

func defeat() -> void:
    _defeat_root.visible = true

func hide_defeat() -> void:
    _defeat_root.visible = false

func victory(stats: String) -> void:
    _victory_stats.text = stats
    _victory_root.visible = true

func _process(delta: float) -> void:
    _time += delta
    if _player == null or not is_instance_valid(_player):
        _player = get_tree().get_first_node_in_group("player") as Player
    if _player != null and is_instance_valid(_player):
        var ready := Time.get_ticks_msec() / 1000.0 >= _player.dodge_ready_at
        _dodge_pip.color = Color(0.9, 0.62, 0.28) if ready else Color(0.34, 0.3, 0.28)
        if _player.health < 30.0 and not _player.is_dead():
            _low.color = Color(0.6, 0.02, 0.02, 0.10 + 0.06 * sin(_time * 5.0))
        else:
            _low.color = Color(0.6, 0.02, 0.02, 0.0)
