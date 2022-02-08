extends HBoxContainer

export (NodePath) var gold_label_path

var gold_label

func on_gold_change(val):
    gold_label.text=str(val)

func _ready():
    gold_label=get_node(gold_label_path)
    Global.connect("money_change",self,"on_gold_change")


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#    pass
