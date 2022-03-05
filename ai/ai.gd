extends Node

var game

var start_seg=[]
var start_ind=-1

var team_id

func _ready():
    pass        
    
func ai_get_op():
    var temp_hk_config=game.chara_hotkey[team_id]
    for i in range(len(temp_hk_config)):
        var item=temp_hk_config[i]
        var chara_info=Global.chara_tb[item["name"]]
        if item["countdown"]<=0 and game.check_chara_build(chara_info["build_cost"], team_id):
            var op={"type":"chara"}
            op["ind"]=i
            return op
    return null

func init(_game, ai_info, _team_id, chara_lv):
    team_id=_team_id
    game=_game
    for i in range(len(ai_info)):
        var hk_info={}
        hk_info["countdown"]=0
        hk_info["lv"]=chara_lv
        hk_info["name"]=ai_info[i]
        game.chara_hotkey[team_id][i]=hk_info



