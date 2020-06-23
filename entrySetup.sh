#!/bin/bash

myDomain=$1 
myEmail=$2
myCertBot=$3

# Settings Path
settingsFile=/settings/settings.cfg

# Create default settings if it wasn't written
if [ -f "$settingsFile" ]; then
    echo "$settingsFile exists."
else
    cp /pigarage/default/defaultSettings.cfg /settings/settings.cfg
fi

# Create default DB with default user
defaultDB=/settings/pigarage.db

if [ -f "$defaultDB" ]; then
    echo "$defaultDB exists."
else
    cp /pigarage/default/defaultPigarage.db /settings/pigarage.db
fi

# Replace your domain the the flask settings
sed -i "s/replaceme/$myDomain/g" /etc/nginx/sites-enabled/flask_settings

# Create temp cert for SSL so it starts
mkdir /etc/letsencrypt/temp
openssl req -subj "/CN=$myDomain/O=$myDomain/C=US" -new -newkey rsa:2048 -days 365 -nodes -x509 -keyout /etc/letsencrypt/temp/privkey.pem -out /etc/letsencrypt/temp/fullchain.cert

# Start nginx for ingress
service nginx start

# Enable real SSL certs via https://letsencrypt.org/
if [ $myCertBot=true ] ; then
    certbot --nginx --agree-tos --no-redirect --no-eff-email -m $myEmail -d $myDomain
fi

# Start Supervisor to enable pigarage
service supervisor start

# Run bash so docker doesn't stop
bash
