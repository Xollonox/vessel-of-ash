extends Node
## Game-feel global: hit-stop (a brief freeze on impact) and related helpers.
## Usage: Juice.hitstop(0.06) from anywhere.

var trigger_count := 0
var last_frozen_duration := 0.0
var frozen := false
var _gen := 0

func hitstop(duration: float, scale: float = 0.06) -> void:
    if duration <= 0.0:
        return
    trigger_count += 1
    last_frozen_duration = duration
    frozen = true
    _gen += 1
    var g := _gen
    Engine.time_scale = clampf(scale, 0.01, 1.0)
    # ignore_time_scale so the restore itself is not slowed down by the freeze
    var t := get_tree().create_timer(duration, true, false, true)
    await t.timeout
    if g == _gen:
        Engine.time_scale = 1.0
        frozen = false
