FROM arm32v7/debian

RUN apt-get update
RUN apt-get install -y build-essential libssl-dev libffi-dev python3-dev python3-pip supervisor sqlite3 systemd
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

RUN mkdir /pigarage
COPY templates /pigarage/templates/pin.html
COPY pigarage.py /pigarage/pigarage.py

#Copy config file for supervisord
COPY pigarage_project.conf /etc/supervisor/conf.d/pigarage_project.conf 

RUN systemctl enable supervisor

#RUN supervisorctl start pigarage