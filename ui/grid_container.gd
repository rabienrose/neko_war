extends GridContainer

func _ready():
    pass # Replace with function body.

func clear_highlight():
    for c in get_children():
        c.set_highlight(false)
