#!/bin/bash

# Settings Path
settingsFile=/settings/settings.cfg

# Create default settings if it wasn't written
if [ -f "$settingsFile" ]; then
    echo "$settingsFile exists."
else
    cp /pigarage/default/defaultsettings.cfg /settings/settings.cfg
    supervisorctl restart pigarage
fi

# Create default DB with default user
defaultDB=/settings/pigarage.db
if [ -f "$defaultDB" ]; then
    echo "$defaultDB exists."
else
    cp /pigarage/default/defaultpigarage.db /settings/pigarage.db
    supervisorctl restart pigarage
    supervisorctl 
fi

service supervisor start

bash
