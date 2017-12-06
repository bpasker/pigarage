from flask import Flask, render_template
import datetime
from time import sleep
import RPi.GPIO as GPIO
from flask import jsonify
from flask_sqlalchemy import SQLAlchemy
from passlib.apps import custom_app_context as pwd_context
app = Flask(__name__)

#Get all my config files
#Set your config file path export PIGARAGE_SETTINGS=/path/to/your/settings/settings.cfg
app.config.from_object(__name__)
app.config.from_envvar('PIGARAGE_SETTINGS')

#Load context for SSL cert and key
context = (app.config['SSL_CRT'], app.config['SSL_KEY'])

#Setup DB for users
db = SQLAlchemy(pigarage)

#Setup GPIO for PI
GPIO.setmode(GPIO.BCM)

#Get status of a pin on the PI
@app.route("/readPin/<pin>")
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
@app.route("/readPinJSON/<pin>")
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
@app.route("/triggerPinJSON/<int:pin>/<int:pin2>")
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
@app.route('/api/users', methods = ['POST'])
def new_user():
    username = request.json.get('username')
    password = request.json.get('password')
    if username is None or password is None:
        abort(400) # missing arguments
    if User.query.filter_by(username = username).first() is not None:
        abort(400) # existing user
    user = User(username = username)
    user.hash_password(password)
    db.session.add(user)
    db.session.commit()
    return jsonify({ 'username': user.username }), 201, {'Location': url_for('get_user', id = user.id, _external = True)}

class User(db.Model):
    __tablename__ = 'users'
    id = db.Column(db.Integer, primary_key = True)
    username = db.Column(db.String(32), index = True)
    password_hash = db.Column(db.String(128))''

   def hash_password(self, password):
        self.password_hash = pwd_context.encrypt(password)

   def verify_password(self, password):
        return pwd_context.verify(password, self.password_hash)

if __name__ == "__main__":
   app.run(host='0.0.0.0', port=443, debug=True, ssl_context=context)