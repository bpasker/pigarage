from flask import Flask, render_template
import datetime
import RPi.GPIO as GPIO
app = Flask(__name__)

#Get all my config files
app.config.from_object(__name__) # load config from this file 
app.config.from_envvar('PIGARAGE_SETTINGS')

#Setup system for SSL
from OpenSSL import SSL
context = SSL.Context(SSL.SSLv23_METHOD)
context.use_privatekey_file(app.config['SSL_KEY'])
context.use_certificate_file(app.config['SSL_CRT'])

#Setup GPIO for PI
GPIO.setmode(GPIO.BCM)

@app.route("/")
def hello():
   now = datetime.datetime.now()
   timeString = now.strftime("%Y-%m-%d %H:%M")
   templateData = {
      'title' : 'HELLO!',
      'time': timeString
      }
   return render_template('main.html', **templateData)

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


if __name__ == "__main__":
   app.run(host='0.0.0.0', port=443, debug=True, ssl_context=context)