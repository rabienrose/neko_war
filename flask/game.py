from bson.objectid import ObjectId
import config

class Game:

    def get_game_data(self):
        game_data={}
        for x in config.game_table.find({}):
            game_data=x
            break
        return game_data

    def set_cul_level(self,level_id):
        game_data=self.get_game_data()
        config.game_table.update_one({"_id":game_data["_id"]},{"$set":{"cul_level":level_id}})

    def get_cul_level(self):
        game_data=self.get_game_data()
        return game_data["cul_level"]

    def check_update(self):
        pass