import os
from flask import Flask, abort, request, jsonify, g, url_for, render_template
from flask_sqlalchemy import SQLAlchemy
from flask_httpauth import HTTPBasicAuth
from passlib.apps import custom_app_context as pwd_context
from itsdangerous import (TimedJSONWebSignatureSerializer
                          as Serializer, BadSignature, SignatureExpired)
from time import sleep
import RPi.GPIO as GPIO
app = Flask(__name__)

#Get all my config files
#Set your config file path export PIGARAGE_SETTINGS=/path/to/your/settings/settings.cfg
app.config.from_object(__name__)
app.config.from_envvar('PIGARAGE_SETTINGS')

#Load context for SSL cert and key
context = (app.config['SSL_CRT'], app.config['SSL_KEY'])

#Setup DB for users
# extensions
db = SQLAlchemy(app)
auth = HTTPBasicAuth()

#Setup GPIO for PI
GPIO.setmode(GPIO.BCM)

#Get status of a pin on the PI
@app.route("/readPin/<pin>")
@auth.login_required
def readPin(pin):
   try:
      GPIO.setup(int(pin), GPIO.IN)
      if GPIO.input(int(pin)) == True:
         response = "Pin number " + pin + " is high!"
      else:
         response = "Pin number " + pin + " is low!"
   except:
      response = "There was an error reading pin " + pin + "."

   templateData = {
      'title' : 'Status of Pin' + pin,
      'response' : response
      }

   return render_template('pin.html', **templateData)

#Return pin status in JSON
@app.route("/api/readPin/<pin>")
@auth.login_required
def readPinJSON(pin):
   try:
      GPIO.setup(int(pin), GPIO.IN)
      if GPIO.input(int(pin)) == True:
         response = {
                     'pin': pin,
                     'status': 'high'
         }
      else:
         response = {
                     'pin': pin,
                     'status': 'low'
         }
   except:
      response = {
                     'pin': pin,
                     'status': 'error'
         }

   return jsonify(response)

#Trigger garage change
#Pin 1 is for the relay
#Pin 2 is for the reed switch
@app.route("/api/triggerPin/<int:pin>/<int:pin2>")
@auth.login_required
def triggerPinJSON(pin,pin2):
   try:
      GPIO.setup(pin, GPIO.OUT)
      GPIO.setup(pin2, GPIO.IN)

      if GPIO.input(pin2) == True:
         GPIO.output(pin, GPIO.LOW)
         sleep(.5)
         GPIO.output(pin, GPIO.HIGH)
         response = {
            'status': 'Opening'
         }
      elif GPIO.input(pin2) == False:
         GPIO.output(pin, GPIO.LOW)
         sleep(.5)
         GPIO.output(pin, GPIO.HIGH)
         response = {
            'status': 'Closing'
         }
      else:
         response = {
            'status': 'Failed to get pin2 state'
         }
   except:
      response = {
                     'pin': pin,
                     'status': 'error'
         }
         
   return jsonify(response)

#User Management
class User(db.Model):
    __tablename__ = 'users'
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(32), index=True)
    password_hash = db.Column(db.String(64))

    def hash_password(self, password):
        self.password_hash = pwd_context.encrypt(password)

    def verify_password(self, password):
        return pwd_context.verify(password, self.password_hash)

    def generate_auth_token(self, expiration=600):
        s = Serializer(app.config['SECRET_KEY'], expires_in=expiration)
        return s.dumps({'id': self.id})

    @staticmethod
    def verify_auth_token(token):
        s = Serializer(app.config['SECRET_KEY'])
        try:
            data = s.loads(token)
        except SignatureExpired:
            return None    # valid token, but expired
        except BadSignature:
            return None    # invalid token
        user = User.query.get(data['id'])
        return user


@auth.verify_password
def verify_password(username_or_token, password):
    # first try to authenticate by token
    user = User.verify_auth_token(username_or_token)
    if not user:
        # try to authenticate with username/password
        user = User.query.filter_by(username=username_or_token).first()
        if not user or not user.verify_password(password):
            return False
    g.user = user
    return True


@app.route('/api/users', methods=['POST'])
@auth.login_required
def new_user():
    username = request.json.get('username')
    password = request.json.get('password')
    if username is None or password is None:
        abort(400)    # missing arguments
    if User.query.filter_by(username=username).first() is not None:
        abort(400)    # existing user
    user = User(username=username)
    user.hash_password(password)
    db.session.add(user)
    db.session.commit()
    return (jsonify({'username': user.username}), 201,
            {'Location': url_for('get_user', id=user.id, _external=True)})


@app.route('/api/users/<int:id>')
def get_user(id):
    user = User.query.get(id)
    if not user:
        abort(400)
    return jsonify({'username': user.username})


@app.route('/api/token')
@auth.login_required
def get_auth_token():
    token = g.user.generate_auth_token(600)
    return jsonify({'token': token.decode('ascii'), 'duration': 600})


@app.route('/api/resource')
@auth.login_required
def get_resource():
    return jsonify({'data': 'Hello, %s!' % g.user.username})

if __name__ == "__main__":
   app.run(host='0.0.0.0', port=443, debug=True, ssl_context=context)