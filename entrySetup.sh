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

# letsencrypt Path
letsencryptFolder=/settings/letsencrypt

# Check if letsencrypt folder is present
if [ -d "$letsencryptFolder" ]; then
    echo "$letsencryptFolder exists."
else
    mkdir /settings/letsencrypt
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

# letsencrypt keyfolder
letsencryptKey=/etc/letsencrypt/keys

# Check if letsencrypt folder is present
if [ -d "$letsencryptKey" ]; then
    echo "$letsencryptKey exists."
else
    echo "Cleaning default /etc/letsencrypt folder."
    #If no key is present the clean the old directory and create symlink to settings folder
    rm -rf /etc/letsencrypt
    ln -s /settings/letsencrypt /etc/letsencrypt
fi

# Check if letsencrypt folder is present
if [ -d "$letsencryptKey" ]; then
    echo "$letsencryptKey exists."

    # Start nginx for ingress
    service nginx start
else

    # Create temp cert for SSL so it starts
    mkdir /etc/letsencrypt/temp
    openssl req -subj "/CN=$myDomain/O=$myDomain/C=US" -new -newkey rsa:2048 -days 365 -nodes -x509 -keyout /etc/letsencrypt/temp/privkey.pem -out /etc/letsencrypt/temp/fullchain.cert

    # Start nginx for ingress
    service nginx start

    # Enable real SSL certs via https://letsencrypt.org/
    if $myCertBot ; then
        certbot --nginx --agree-tos --no-redirect --no-eff-email -m $myEmail -d $myDomain
    fi
fi

# Start Supervisor to enable pigarage
service supervisor start

# Run bash so docker doesn't stop
bash
