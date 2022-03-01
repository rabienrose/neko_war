extends Camera2D

func _ready():
    pass # Replace with function body.

func _input(event):
    if event is InputEventScreenDrag:
        var new_pos=position.x-event.relative.x
        if new_pos>0 and new_pos<1500:
            position.x=new_pos


func _physics_process(delta):
    pass       
