

ip=8.208.28.127
ssh root@$ip
mkdir neko_war
pip3 install flask
pip3 install oss2
pip3 install pymongo

exit
scp -r neko_war root@$ip:~