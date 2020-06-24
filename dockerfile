FROM arm32v7/debian

RUN apt-get update
RUN apt-get install -y build-essential libssl-dev libffi-dev python3-dev python3-pip supervisor sqlite3 vim nginx certbot python-certbot-nginx
RUN pip3 install --upgrade pip
RUN pip3 install -U pip setuptools
RUN pip3 install cryptography
RUN pip3 install pyopenssl

RUN pip3 install passlib[bcrypt]
RUN pip3 install flask 
RUN pip3 install SQLAlchemy
RUN pip3 install flask_sqlalchemy
RUN pip3 install Flask-HTTPAuth
RUN pip3 install RPi.GPIO

# Add core project folder
RUN mkdir /pigarage

# Copy core garage python code
COPY templates /pigarage/templates/pin.html
COPY pigarage.py /pigarage/pigarage.py

# Add Config and Default DB
COPY settings/defaultSettings.cfg /pigarage/default/defaultSettings.cfg
COPY settings/defaultPigarage.db /pigarage/default/defaultPigarage.db

# Add proxy config for nginx to flask
COPY settings/flaskSettings /etc/nginx/sites-enabled/flask_settings

# Copy config file for supervisord to start flask 
COPY settings/pigarage_project.conf /etc/supervisor/conf.d/pigarage_project.conf 

# Copy notify code
COPY notify_me.py /pigarage/notify_me.py
COPY settings/defaultnotificationSettings.ini /pigarage/default/defaultnotificationSettings.ini

# Add setup script
COPY entrySetup.sh /pigarage/entrySetup.sh
RUN chmod 700 /pigarage/entrySetup.sh

# Setup NGINX and Letsencrypt
ENV myDomain replacemeENV
ENV myEmail myEmailAddress
ENV myCertBot myCertBot

# Notification Settings
ENV enableNotifications defaultenableNotifications
ENV emailSender defaultemailSender
ENV textTo defaultemailSender

# Start script call with variables
CMD /pigarage/entrySetup.sh ${myDomain} ${myEmail} ${myCertBot} ${enableNotifications} ${emailSender} ${emailSender}
