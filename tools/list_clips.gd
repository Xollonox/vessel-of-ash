extends Node
func _ready() -> void:
    var a := AnimatedActor.new()
    add_child(a)
    await get_tree().process_frame
    await get_tree().process_frame
    if a.player != null:
        var names := a.player.get_animation_list()
        print("CLIPCOUNT ", names.size())
        for n in names:
            print("CLIP ", n)
    else:
        print("NO PLAYER")
    get_tree().quit(0)
