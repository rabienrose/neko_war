extends Control

export (NodePath) var star1_path
export (NodePath) var star2_path
export (NodePath) var star3_path
export (NodePath) var star1e_path
export (NodePath) var star2e_path
export (NodePath) var star3e_path
export (NodePath) var title_text_path
export (NodePath) var ske_head_path
export (NodePath) var gold_head_path
export (NodePath) var next_btn_path

func _ready():
    pass # Replace with function body.

func show_summary(b_win, b_show, gold, b_show_next):
    get_tree().paused = true
    if b_show:
        visible=true
        if b_win:
            get_node(ske_head_path).visible=false
            get_node(title_text_path).text="YOU WIN!"
            if b_show_next:
                get_node(next_btn_path).visible=true
            else:
                get_node(next_btn_path).visible=false
        else:
            get_node(ske_head_path).visible=true
            get_node(title_text_path).text="DEFEAT"
            get_node(next_btn_path).visible=false
        get_node(gold_head_path).text=str(gold)


func _on_Replay_gui_input(event):
    if event is InputEventScreenTouch:
        if event.pressed:
            get_tree().paused = false
            Global.emit_signal("request_battle", Global.sel_level)

func _on_Next_gui_input(event):
    if event is InputEventScreenTouch:
        if event.pressed:
            get_tree().paused = false
            Global.emit_signal("request_battle", Global.sel_level+1)

func _on_Home_gui_input(event):
    if event is InputEventScreenTouch:
        if event.pressed:
            get_tree().paused = false
            Global.emit_signal("request_go_home")
