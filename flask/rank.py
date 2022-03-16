from bson.objectid import ObjectId
import config
from user import UserInfo
from game import Game

class Rank:
    def pvp_summary(self, token1, token2, diamond1, diamond2):
        ret=True
        user1=UserInfo(token1)
        if token2!="":
            user2=UserInfo(token2)
            user1.change_diamond(diamond1)
            user2.change_diamond(diamond2)
            user1.set_last_pvp()
            user2.set_last_pvp()
        else:
            print(diamond1)
            user1.change_diamond(diamond1)
            user1.set_last_pvp()
        return ret

    def get_ranks(self):
        query_re = config.user_table.find({"last_pvp":{"$exists":True}},{"_id":0,"diamond":1,"last_pvp":1,"nickname":1,"setting.note":1}).sort([("diamond",-1)]).limit(10)
        rank_list=[]
        for x in query_re:
            rank_list.append(x)
        return rank_list

    def notify_start_pvp(self, token):
        user=UserInfo(token)
        game=Game()
        g_data = game.load_static_data()
        user.change_diamond(-g_data["pvp_price"])