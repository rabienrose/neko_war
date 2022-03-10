from bson.objectid import ObjectId
import config
from user import UserInfo
import json

class Game:

    def get_game_data(self):
        game_data={}
        for x in config.game_table.find({}):
            game_data=x
            break
        return game_data

    def load_static_data(self):
        f=open("../configs/global.json",'r')
        return json.load(f)

    def set_cul_level(self,level_id):
        game_data=self.get_game_data()
        config.game_table.update_one({"_id":game_data["_id"]},{"$set":{"cul_level":level_id}})

    def get_cul_level(self):
        game_data=self.get_game_data()
        return game_data["cul_level"]

    def update_level_rank(self, total_pass, user_id):
        game_data = self.get_game_data()
        update_info={}
        if "level_top" not in game_data or game_data["level_top"]["num"]<total_pass:
            update_info["num"]=total_pass
            update_info["user"]=user_id
            config.game_table.update_one({"_id":game_data["_id"]},{"$set":{"level_top":update_info}})

    def get_level_top(self):
        game_data = self.get_game_data()
        top_info={}
        if "level_top" in game_data:
            user = UserInfo(game_data["level_top"]["user"])
            nickname=user.get_nickname()
            top_info["num"]=game_data["level_top"]["num"]
            top_info["user"]=nickname
        return top_info

    def check_update(self):
        pass