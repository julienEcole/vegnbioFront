@echo off
echo 🛠️  Reconstruction de l'image Docker Flutter Web avec les corrections CSP...

REM Arrêter les conteneurs existants
echo 🛑 Arrêt des conteneurs existants...
docker-compose down

REM Supprimer les images existantes pour forcer la reconstruction
echo 🗑️  Suppression des images existantes...
docker rmi vegnbioffront_flutter_web 2>nul
docker rmi vegnbio-front-web 2>nul

REM Nettoyer le cache Docker
echo 🧹 Nettoyage du cache Docker...
docker builder prune -f

REM Reconstruire et lancer
echo 🏗️  Reconstruction et lancement...
docker-compose up --build flutter_web

echo ✅ Terminé ! L'application devrait maintenant fonctionner sur http://localhost:4200
pause
