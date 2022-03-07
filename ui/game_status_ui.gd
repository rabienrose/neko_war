extends HBoxContainer

export (NodePath) var gold_label_path
export (NodePath) var diamond_label_path

var anim_player
var last_gold=-1

func set_gold(val):
    get_node(gold_label_path).text=str(val)

func set_diamond(val):
    get_node(diamond_label_path).text=str(val)

func _ready():
    pass
