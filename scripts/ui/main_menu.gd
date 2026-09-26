extends Control
## Title screen for Vessel of Ash.

func _ready() -> void:
    var bg := ColorRect.new()
    bg.color = Color(0.035, 0.032, 0.038)
    bg.set_anchors_preset(Control.PRESET_FULL_RECT)
    add_child(bg)

    var center := CenterContainer.new()
    center.set_anchors_preset(Control.PRESET_FULL_RECT)
    add_child(center)

    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 12)
    center.add_child(box)

    var title := Label.new()
    title.text = "VESSEL OF ASH"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 64)
    title.add_theme_color_override("font_color", Color(0.93, 0.88, 0.80))
    box.add_child(title)

    var sub := Label.new()
    sub.text = "The Cinderhold — a vertical slice"
    sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    sub.add_theme_font_size_override("font_size", 18)
    sub.add_theme_color_override("font_color", Color(0.62, 0.55, 0.48))
    box.add_child(sub)

    var spacer := Control.new()
    spacer.custom_minimum_size = Vector2(0, 30)
    box.add_child(spacer)

    var begin := Button.new()
    begin.text = "  ENTER THE CINDERHOLD  "
    begin.add_theme_font_size_override("font_size", 22)
    begin.pressed.connect(_begin)
    box.add_child(begin)

    var quit := Button.new()
    quit.text = "  LEAVE  "
    quit.add_theme_font_size_override("font_size", 16)
    quit.pressed.connect(func() -> void: get_tree().quit())
    box.add_child(quit)

    var spacer2 := Control.new()
    spacer2.custom_minimum_size = Vector2(0, 30)
    box.add_child(spacer2)

    var controls := Label.new()
    controls.text = "WASD / stick move  ·  Mouse / drag look  ·  J light  ·  K heavy  ·  L parry\nSpace dodge  ·  Q lock-on  ·  E interact  —  touch: virtual stick + buttons"
    controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    controls.add_theme_font_size_override("font_size", 14)
    controls.add_theme_color_override("font_color", Color(0.52, 0.48, 0.44))
    box.add_child(controls)

    var foot := Label.new()
    foot.text = "vertical slice · v3"
    foot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    foot.add_theme_font_size_override("font_size", 12)
    foot.add_theme_color_override("font_color", Color(0.35, 0.32, 0.30))
    foot.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
    foot.offset_top = -34
    foot.offset_bottom = -10
    add_child(foot)

func _begin() -> void:
    get_tree().change_scene_to_file("res://scenes/level_01.tscn")
