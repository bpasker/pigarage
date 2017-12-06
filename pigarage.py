from flask import Flask, render_template
import datetime
from time import sleep
import RPi.GPIO as GPIO
from flask import jsonify
app = Flask(__name__)

#Get all my config files
#Set your config file path export PIGARAGE_SETTINGS=/path/to/your/settings/settings.cfg
app.config.from_object(__name__)
app.config.from_envvar('PIGARAGE_SETTINGS')

#Load context for SSL cert and key
context = (app.config['SSL_CRT'], app.config['SSL_KEY'])

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
@app.route("/triggerPinJSON/<int:pin>/<int:pin2>")
def triggerPinJSON(pin,pin2):
   try:
      GPIO.setup(pin, GPIO.OUT)
      GPIO.setup(pin2, GPIO.IN)

      if GPIO.input(int(pin2)) == True:
         GPIO.output(int(pin), GPIO.HIGH)
         sleep(.5)
         GPIO.output(int(pin), GPIO.LOW)
         response = {
            'status': 'Opening'
         }
      elif GPIO.input(int(pin2)) == False:
         GPIO.output(int(pin), GPIO.HIGH)
         sleep(.5)
         GPIO.output(int(pin), GPIO.LOW)
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

if __name__ == "__main__":
   app.run(host='0.0.0.0', port=443, debug=True, ssl_context=context)