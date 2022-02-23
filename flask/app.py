
from flask import Flask, request, Response
from bson.objectid import ObjectId
import json
import hashlib
from datetime import datetime
import time


app = Flask(__name__)

@app.route('/test_port',methods=['GET','POST'])
def test_port():
    print(request.remote_addr,request.environ.get('REMOTE_PORT'))
    return json.dumps(["ok"])

@app.route('/user_regist',methods=['GET','POST'])
def user_regist():
    return json.dumps({})


if __name__ == '__main__':
    app.config['SECRET_KEY'] = 'xxx'
    app.config['UPLOAD_FOLDER'] = './raw'
    app.debug = True
    app.run('0.0.0.0', port=9100)
