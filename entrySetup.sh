#!/bin/bash

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

service supervisor start

bash
