extends Node
func _ready() -> void:
    var a := AnimatedActor.new()
    add_child(a)
    await get_tree().process_frame
    await get_tree().process_frame
    if a.skeleton != null:
        var names := []
        for i in a.skeleton.get_bone_count():
            names.append(a.skeleton.get_bone_name(i))
        print("BONES: ", names)
    get_tree().quit(0)
