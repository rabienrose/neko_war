import config
from user import UserInfo

user = UserInfo("6215d036f4dd0f8cae7847c7")
# user.create_user("asdadsd")
user.reset_user()
print(user.get_info())
