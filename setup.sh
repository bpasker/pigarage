#!/bin/bash

sudo apt-get install -y build-essential libssl-dev libffi-dev python-dev python3-dev python-pip supervisor sqlite3
sudo pip install --upgrade pip
sudo pip install -U pip setuptools
sudo pip install cryptography
sudo pip install pyopenssl

sudo pip install passlib[bcrypt]
sudo pip install flask 
sudo pip install flask-ask
sudo pip install SQLAlchemy
sudo pip install flask_sqlalchemy
sudo pip install Flask-HTTPAuth

mkdir settings
mkdir SSL

sudo bash -c 'echo "[program:pigarage]
command = python pigarage.py
directory = $(pwd)
autostart = true
autorestart = true
environment=PIGARAGE_SETTINGS=\"$(pwd)/settings/settings.cfg\"" > /etc/supervisor/conf.d/pigarage_project.conf'

sudo bash -c 'echo "import os
basedir = os.path.abspath(os.path.dirname(__file__))

SECRET_KEY = '"'"'Type a lot of info so you have a good secret'"'"'
SQLALCHEMY_DATABASE_URI = '"'"'sqlite:///'"'"' + os.path.join(basedir, '"'"'pigarage.db'"'"')
SQLALCHEMY_MIGRATE_REPO = os.path.join(basedir, '"'"'db_repository'"'"')

#SSL Config
SSL_KEY = '"'"'$(pwd)/SSL/server.key'"'"'
SSL_CRT = '"'"'$(pwd)/SSL/server.crt'"'"'" >> $(pwd)/settings/settings.cfg'


sqlite3 settings/pigarage.db <<EOF
BEGIN; CREATE TABLE users(id INTEGER PRIMARY KEY ASC, username TEXT, password_hash TEXT); COMMIT;
EOF

