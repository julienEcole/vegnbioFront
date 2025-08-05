#!/bin/bash

# Configurer Git pour éviter les erreurs de dubious ownership
git config --global --add safe.directory '*'
git config --global --add safe.directory /home/developer/flutter
git config --global --add safe.directory /app

# Exécuter la commande passée en paramètre
exec "$@"