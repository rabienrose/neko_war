extends Node

var game
var rng
var opponent_charas=[]

func _ready():
    rng = RandomNumberGenerator.new()    
    rng.randomize()
    
func ai_get_op():
    var rand_i = rng.randi_range(0,4)
    var item=game.chara_hotkey[1][rand_i]
    var chara_info=Global.chara_tb[item["name"]]
    if item["countdown"]<=0 and game.check_chara_build(chara_info["build_cost"], 1):
        return [rand_i]
    return []

func init(_game):
    game=_game



