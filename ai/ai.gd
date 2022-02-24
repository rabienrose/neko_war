extends Node

var game

var start_seg=[]
var start_ind=-1

func _ready():
    pass        
    
func ai_get_op():
    var temp_hk_config=game.ai_chara_hotkey
    # if start_ind>=start_seg and start_ind>=0:
    #     if 
    for i in range(len(temp_hk_config)):
        var item=temp_hk_config[i]
        var chara_info=Global.chara_tb[item["name"]]
        if item["countdown"]<=0 and chara_info["build_cost"]<=game.gold_enemy:
            var op={"type":"chara"}
            op["ind"]=i
            print(i)
            return op
    return null

func init(_game, ai_info):
    game=_game
    game.ai_chara_hotkey=ai_info["charas"]
    for item in game.ai_chara_hotkey:
        item["countdown"]=0
        item["lv"]=10



