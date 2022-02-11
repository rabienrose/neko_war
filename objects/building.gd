extends Character

func on_die(_chara):
    if team_id==0:
        game.stop_game(false)
    else:
        game.stop_game(true)
    .on_die(_chara)
