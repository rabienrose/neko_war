ip=8.208.102.164
scp game.gd root@$ip:~/neko_war
scp global.gd root@$ip:~/neko_war
scp home.gd root@$ip:~/neko_war
# scp sys/server.gd root@$ip:~/neko_war/sys/server.gd
scp -r sys root@$ip:~/neko_war
scp -r ui root@$ip:~/neko_war
scp -r configs root@$ip:~/neko_war
scp -r flask root@$ip:~/neko_war
scp -r ai root@$ip:~/neko_war
