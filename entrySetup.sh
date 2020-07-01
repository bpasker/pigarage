#!/bin/bash

myDomain=$1 
myEmail=$2
myCertBot=$3
enableNotifications=$4
emailSender=$5
textTo=$6

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

    # Restore backup of flask_settings so cert path is correct
    cp /settings/letsencrypt/flask_settings_backup /etc/nginx/sites-enabled/flask_settings

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

    cp /etc/nginx/sites-enabled/flask_settings /settings/letsencrypt/flask_settings_backup
fi

# Start Supervisor to enable pigarage
service supervisor start

#
/pigarage/default/notificationSettings.ini

# defaultnotificationSettings file
defaultnotificationSettings=/settings/notificationSettings.ini

# Check if defaultnotificationSettings file is present
if [ -f "$defaultnotificationSettings" ]; then
    echo "$defaultnotificationSettings exists."
else
    echo "Adding $defaultnotificationSettings"
    cp /pigarage/default/defaultnotificationSettings.ini /settings/notificationSettings.ini
fi

# pickel file
pickle=/pigarage/token.pickle

# Check if defaultnotificationSettings file is present
if [ -f "$pickle" ]; then
    echo "$pickle exists."
else
    echo "Adding $pickle"
    cp /settings/token.pickle /pigarage/token.pickle
fi

# Replace email sender
sed -i "s/user@gmail.com/$emailSender/g" /settings/notificationSettings.ini
sed -i "s/000000000@vtext.com/$textTo/g" /settings/notificationSettings.ini

# Run bash so docker doesn't stop
bash
