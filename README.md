# VegnBio Front

Application Flutter pour VegnBio présentant l'entreprise et ses horaires.

## Prérequis

### Méthode 1 : Installation locale
- Flutter SDK
- Dart SDK
- Un IDE (VS Code ou Android Studio recommandé)
- Java JDK (pour Android)
- Android SDK (pour Android)

### Méthode 2 : Docker
- Docker
- Docker Compose

## Installation et démarrage

### Méthode 1 : Installation locale avec Flutter

1. Cloner le projet :
```bash
git clone https://github.com/julienEcole/vegnbioFront.git
cd vegnbioFront
```

2. Installer les dépendances :
```bash
flutter pub get
```

3. Lancer l'application :

#### Version Web
```bash
flutter run -d chrome
```
L'application sera accessible à l'adresse : http://localhost:4200

#### Version Android
Pour lancer l'application sur un émulateur ou un appareil Android :
```bash
flutter run -d android
```

Pour créer un APK de debug :
```bash
flutter build apk --debug
```

Pour créer un APK signé pour la production :
1. Configurer la signature (à faire une seule fois) :
```bash
# Créer les dossiers nécessaires
mkdir -p android/app

# Générer le keystore
keytool -genkey -v -keystore android/app/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

2. Créer le fichier `android/key.properties` avec vos informations de signature :
```properties
storePassword=votre_mot_de_passe_keystore
keyPassword=votre_mot_de_passe_keystore
keyAlias=upload
storeFile=app/upload-keystore.jks
```

3. Builder l'APK signé :
```bash
flutter build apk --release
```
L'APK sera disponible dans `build/app/outputs/flutter-apk/app-release.apk`

### Méthode 2 : Utilisation de Docker

1. Cloner le projet :
```bash
git clone https://github.com/julienEcole/vegnbioFront.git
cd vegnbioFront
```

2. Version Web :
```bash
docker-compose up --build
```
L'application sera accessible à l'adresse : http://localhost:4200

3. Version Android :
```bash
# Configurer d'abord la signature comme décrit dans la méthode 1
docker-compose run flutter_android
```
L'APK sera disponible dans `build/app/outputs/flutter-apk/app-release.apk`

## Structure du projet

```
vegnbioFront/
├── lib/
│   ├── main.dart
│   ├── screens/
│   │   ├── home_screen.dart
│   │   ├── menu_screen.dart
│   │   ├── events_screen.dart
│   │   ├── services_screen.dart
│   │   ├── restaurants_screen.dart
│   │   └── profile_screen.dart
│   ├── theme/
│   │   └── app_theme.dart
│   └── widgets/
│       └── navigation_bar.dart
├── android/
│   ├── app/
│   │   └── upload-keystore.jks (généré lors de la signature)
│   └── key.properties (à créer pour la signature)
├── test/
│   └── widget_test.dart
├── Dockerfile
├── docker-compose.yml
└── README.md
```

## Sécurité

⚠️ Important : Ne jamais commiter dans Git :
- Le fichier `android/key.properties`
- Le fichier `android/app/upload-keystore.jks`
- Les mots de passe de signature

Ces fichiers doivent être conservés en sécurité en dehors du projet.

## Tests

Pour exécuter les tests :

### Avec Flutter local :
```bash
flutter test
```

### Avec Docker :
```bash
docker-compose run flutter_web flutter test
```