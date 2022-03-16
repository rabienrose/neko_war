export PATH=/Users/ziliwang/Documents/mongodb-macos-x86_64-5.0.6/bin:$PATH     
mongod --dbpath /Users/ziliwang/Documents/mongdb_data/data --logpath /Users/ziliwang/Documents/mongdb_data/log/mongo.log --fork
ps aux | grep -v grep | grep mongod
                                                
