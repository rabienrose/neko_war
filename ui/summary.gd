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

func _ready():
    pass # Replace with function body.

func show_summary(star_num, b_show, gold):
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
        else:
            get_node(star_path).visible=false
            get_node(ske_head_path).visible=true
            get_node(title_text_path).text="DEFEAT"
        get_node(gold_head_path).text=str(gold)


func _on_Replay_gui_input(event):
    if event is InputEventScreenTouch:
        if event.pressed:
            pass
