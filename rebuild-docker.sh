#!/bin/bash

echo "🛠️  Reconstruction de l'image Docker Flutter Web avec les corrections CSP..."

# Arrêter les conteneurs existants
echo "🛑 Arrêt des conteneurs existants..."
docker-compose down

# Supprimer les images existantes pour forcer la reconstruction
echo "🗑️  Suppression des images existantes..."
docker rmi vegnbioffront_flutter_web 2>/dev/null || true
docker rmi vegnbio-front-web 2>/dev/null || true

# Nettoyer le cache Docker
echo "🧹 Nettoyage du cache Docker..."
docker builder prune -f

# Reconstruire et lancer
echo "🏗️  Reconstruction et lancement..."
docker-compose up --build flutter_web

echo "✅ Terminé ! L'application devrait maintenant fonctionner sur http://localhost:4200"
