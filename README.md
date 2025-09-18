# Veg'N Bio Frontend

Application Flutter pour la consultation des restaurants et menus Veg'N Bio.

## 🚀 Fonctionnalités implémentées

### 📍 Consultation des restaurants
- Liste complète des restaurants Veg'N Bio
- Affichage des informations détaillées :
  - Nom et localisation (quartier)
  - Adresse complète
  - Horaires d'ouverture par jour
  - Équipements disponibles
- Interface avec cards élégantes
- Gestion des états de chargement et d'erreur

### 🍽️ Consultation des menus
- Liste de tous les menus disponibles
- Informations détaillées par menu :
  - Titre et description
  - Date de disponibilité
  - Restaurant associé
  - Allergènes présents
- **Fonctionnalité de recherche avancée** :
  - Recherche par titre de menu
  - Recherche par allergène
  - Filtres en temps réel
- Interface intuitive avec chips pour les allergènes

## 🛠️ Architecture technique

### Dépendances ajoutées
```yaml
dependencies:
  http: ^1.1.0              # Requêtes HTTP vers l'API
  flutter_riverpod: ^2.4.9  # Gestion d'état réactive
```

### Structure du code

```
lib/
├── models/
│   ├── restaurant.dart    # Modèle Restaurant + Horaire + Equipement
│   └── menu.dart         # Modèle Menu avec méthodes utilitaires
├── services/
│   └── api_service.dart  # Service HTTP pour l'API backend
├── providers/
│   ├── restaurant_provider.dart  # Providers Riverpod pour restaurants
│   └── menu_provider.dart        # Providers Riverpod pour menus
└── screens/
    ├── restaurants_screen.dart    # Écran consultation restaurants
    └── menu_screen.dart          # Écran consultation menus avec recherche
```

### Gestion d'état avec Riverpod

- **FutureProvider** : Gestion asynchrone des appels API
- **StateProvider** : Gestion des paramètres de recherche
- **Provider** : Injection de dépendances (ApiService)

## 🔌 Connexion avec le backend

### Configuration API
L'application se connecte au backend sur `http://localhost:3000/api`

### Endpoints utilisés
- `GET /restaurants` - Liste des restaurants
- `GET /restaurants/:id` - Restaurant par ID
- `GET /menus` - Liste des menus
- `GET /menus/:id` - Menu par ID
- `GET /menus/restaurant/:id` - Menus d'un restaurant
- `GET /menus/search` - Recherche de menus

## 🚀 Lancement de l'application

### Prérequis
- Flutter SDK (>=3.0.0)
- Dart SDK
- Backend Veg'N Bio API en cours d'exécution

### Option 1 : Développement local (recommandé)

### Installation et démarrage

1. **Installer les dépendances :**
   ```bash
   flutter pub get
   ```

2. **Lancer le backend API :**
   ```bash
   cd ../vegnbio-api
   docker-compose up --build
   ```

3. **Lancer l'application Flutter :**

   **Pour le web (Chrome) :**
   ```bash
   flutter run -d chrome
   ```

   **Pour Android (émulateur ou appareil connecté) :**
   ```bash
   flutter run -d android
   ```

   **Pour iOS (macOS uniquement) :**
   ```bash
   flutter run -d ios
   ```

   **Auto-détection de plateforme :**
   ```bash
   flutter run
   ```

### Option 2 : Avec Docker

Le projet inclut des configurations Docker pour le web et Android.

#### 🌐 Version Web avec Docker

**Méthode 1 - Docker Compose (recommandé) :**
```bash
# Lancer uniquement la version web
docker-compose up flutter_web

# En arrière-plan
docker-compose up -d flutter_web
```

**Méthode 2 - Docker direct :**
```bash
# Construire l'image
docker build -f Dockerfile.web -t vegnbio-front-web .

# Lancer le conteneur
docker run -p 4200:4200 vegnbio-front-web
```

**Accès :** http://localhost:4200

#### 📱 Version Android (APK) avec Docker

**Méthode 1 - Docker Compose (recommandé) :**
```bash
# Générer l'APK
docker-compose up flutter_android

# L'APK sera dans ./build/app/outputs/flutter-apk/app-debug.apk
```

**Méthode 2 - Docker direct :**
```bash
# Construire l'image
docker build -f Dockerfile.android -t vegnbio-front-android .

# Générer l'APK
docker run -v $(pwd)/build:/app/build vegnbio-front-android
```

#### 🛑 Arrêter les conteneurs

```bash
# Arrêter tous les services
docker-compose down

# Arrêter uniquement le web
docker-compose down flutter_web
```

### Commandes rapides

#### 🚀 Développement local
**Chrome uniquement :**
```bash
flutter pub get && flutter run -d chrome
```

**Générer APK directement :**
```bash
flutter pub get && flutter build apk --release
```

**Serveur web local :**
```bash
flutter run -d web-server --web-port 8080
```
Puis ouvrir http://localhost:8080

#### 🐋 Docker rapide

**Lancer version web :**
```bash
docker-compose up -d flutter_web
```
→ Accès sur http://localhost:4200

**Générer APK :**
```bash
docker-compose up flutter_android
```
→ APK dans `./build/app/outputs/flutter-apk/app-debug.apk`

**Tout nettoyer :**
```bash
docker-compose down && docker system prune -f
```

**Reconstruire après mise à jour :**
```bash
# Linux/macOS
chmod +x rebuild-docker.sh && ./rebuild-docker.sh

# Windows
rebuild-docker.bat
```

## 🎨 Interface utilisateur

### Écran Restaurants
- Liste scrollable avec cards
- Affichage des horaires en tableau
- Chips pour les équipements
- Gestion d'erreur avec bouton "Réessayer"

### Écran Menus
- Barre de recherche dépliable (icône search)
- Filtres par titre et allergène
- Affichage de la date formatée
- Information du restaurant associé
- Chips d'allergènes avec icônes warning

### Gestion des erreurs
- Indicateurs de chargement (CircularProgressIndicator)
- Messages d'erreur explicites
- Boutons "Réessayer" pour relancer les requêtes
- Gestion des états vides (aucune donnée)

## 🛠️ Dépannage

### Erreurs Content Security Policy (CSP)

Si tu vois des erreurs comme :
- `Refused to load script because it violates CSP directive`
- `Failed to download CanvasKit URLs`
- `X-Frame-Options may only be set via HTTP header`

**Solutions :**

1. **Pour le développement local :**
   ```bash
   flutter run -d chrome --web-browser-flag "--disable-web-security"
   ```

2. **Pour Docker :**
   ```bash
   # Reconstruire l'image avec les corrections CSP
   ./rebuild-docker.sh  # ou rebuild-docker.bat sur Windows
   ```

3. **Configuration manuelle nginx :**
   Les en-têtes CSP sont maintenant configurés dans `nginx.conf` pour autoriser :
   - Google Fonts (`fonts.googleapis.com`, `fonts.gstatic.com`)
   - Flutter CanvasKit (`www.gstatic.com`)
   - API locale (`localhost:3000`)

### Erreurs de connexion API

Si l'API n'est pas accessible :
```bash
# Vérifier que l'API backend est en cours d'exécution
cd ../vegnbio-api
docker-compose ps

# Redémarrer l'API si nécessaire
docker-compose restart
```

## 🔧 Développement

### Ajout de nouvelles fonctionnalités

Pour ajouter une nouvelle entité :

1. **Créer le modèle** dans `lib/models/`
2. **Ajouter les endpoints** dans `ApiService`
3. **Créer les providers** dans `lib/providers/`
4. **Implémenter l'écran** dans `lib/screens/`

### Tests
```bash
flutter test
```

### Build de production

**Pour le web :**
```bash
flutter build web
```
Les fichiers seront générés dans `build/web/`

**Pour Android (APK) :**
```bash
flutter build apk
```
L'APK sera généré dans `build/app/outputs/flutter-apk/app-release.apk`

**Pour Android (App Bundle - recommandé pour Play Store) :**
```bash
flutter build appbundle
```

**Pour iOS (macOS uniquement) :**
```bash
flutter build ios
```

## 📱 Navigation

L'application utilise une navigation simple avec MaterialApp :
- Écran d'accueil par défaut
- Navigation via les widgets et boutons
- Pas de routing complexe implémenté
- `/profil` - Profil utilisateur

## 🎯 Prochaines étapes

- [ ] Authentification utilisateur
- [ ] Réservation de tables
- [ ] Commande de menus
- [ ] Notifications push
- [ ] Mode hors ligne avec cache
- [ ] Géolocalisation des restaurants
- [ ] Système de favoris