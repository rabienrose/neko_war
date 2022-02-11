extends Control

export (NodePath) var star1_path
export (NodePath) var star2_path
export (NodePath) var star3_path
export (NodePath) var star1e_path
export (NodePath) var star2e_path
export (NodePath) var star3e_path
export (NodePath) var title_text_path
export (NodePath) var star_path
export (NodePath) var ske_head_path
export (NodePath) var gold_head_path
export (NodePath) var next_btn_path

func _ready():
    pass # Replace with function body.

func show_summary(star_num, b_show, gold, b_show_next):
    get_tree().paused = true
    if b_show:
        visible=true
        if star_num>=0:
            get_node(star_path).visible=true
            get_node(ske_head_path).visible=false
            get_node(title_text_path).text="YOU WIN!"
            if star_num==0:
                get_node(star1_path).visible=false
                get_node(star1e_path).visible=true
                get_node(star2_path).visible=false
                get_node(star2e_path).visible=true
                get_node(star3_path).visible=false
                get_node(star3e_path).visible=true
            elif star_num==1:
                get_node(star1_path).visible=true
                get_node(star1e_path).visible=false
                get_node(star2_path).visible=false
                get_node(star2e_path).visible=true
                get_node(star3_path).visible=false
                get_node(star3e_path).visible=true
            elif star_num==2:
                get_node(star1_path).visible=true
                get_node(star1e_path).visible=false
                get_node(star2_path).visible=true
                get_node(star2e_path).visible=false
                get_node(star3_path).visible=false
                get_node(star3e_path).visible=true
            elif star_num==3:
                get_node(star1_path).visible=true
                get_node(star1e_path).visible=false
                get_node(star2_path).visible=true
                get_node(star2e_path).visible=false
                get_node(star3_path).visible=true
                get_node(star3e_path).visible=false
            if b_show_next:
                get_node(next_btn_path).visible=true
            else:
                get_node(next_btn_path).visible=false
        else:
            get_node(star_path).visible=false
            get_node(ske_head_path).visible=true
            get_node(title_text_path).text="DEFEAT"
            get_node(next_btn_path).visible=false
        get_node(gold_head_path).text=str(gold)


func _on_Replay_gui_input(event):
    if event is InputEventScreenTouch:
        if event.pressed:
            print("replay")
            get_tree().paused = false
            Global.emit_signal("request_battle", Global.sel_level)

func _on_Next_gui_input(event):
    if event is InputEventScreenTouch:
        if event.pressed:
            print("next")
            get_tree().paused = false
            Global.emit_signal("request_battle", Global.sel_level+1)

func _on_Home_gui_input(event):
    if event is InputEventScreenTouch:
        if event.pressed:
            print("home")
            get_tree().paused = false
            Global.emit_signal("request_go_home")
