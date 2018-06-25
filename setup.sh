#!/bin/bash

sudo apt-get install -y build-essential libssl-dev libffi-dev python-dev python3-dev python-pip supervisor sqlite3
sudo pip install --upgrade pip
pip install -U pip setuptools
sudo pip install cryptography
sudo pip install pyopenssl

sudo pip install passlib[bcrypt]
sudo pip install flask 
sudo pip install flask-ask
sudo pip install SQLAlchemy
sudo pip install Flask-HTTPAuth
