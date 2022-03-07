from bson.objectid import ObjectId
import config
from user import UserInfo

class Rank:
    def pvp_summary(self, token1, token2, diamond1, diamond2, result):
        ret=True
        user1=UserInfo(token1)
        user2=UserInfo(token2)
        if result=="team1":
            if user2.change_diamond(-diamond2):
                user1.change_diamond(diamond2)
            else:
                ret=False
        else:
            if user2.change_diamond(-diamond1):
                user2.change_diamond(diamond1)
            else:
                ret=False
        user1.set_last_pvp()
        user2.set_last_pvp()
        return ret

    def get_ranks(self):
        query_re = config.user_table.find({},{"_id":0,"diamond":1,"last_pvp":1,"nickname":1}).sort([("diamond",-1)]).limit(10)
        rank_list=[]
        for x in query_re:
            rank_list.append(x)
        return rank_list