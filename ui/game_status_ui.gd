extends HBoxContainer

export (NodePath) var gold_label_path

var gold_label
var anim_player
var last_gold=-1

func on_gold_change(val):
    gold_label.text=str(val)
    if last_gold!=-1 and last_gold<val:
        anim_player.play("shake")
    last_gold=val

func _ready():
    gold_label=get_node(gold_label_path)
    anim_player=get_node("AnimationPlayer")
    Global.connect("money_change",self,"on_gold_change")


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#    pass
