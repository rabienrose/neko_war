extends Node2D

export (Resource) var fct_res

var travel = Vector2(0, -180)
var duration = 2
var spread = PI/4

func show_value(value, crit=false):
    var fct = fct_res.instance()
    add_child(fct)
    fct.show_value(str(value), travel, duration, spread, crit)
