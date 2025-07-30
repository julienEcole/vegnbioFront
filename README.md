# VegnBio Front

Application Flutter pour VegnBio présentant l'entreprise et ses horaires.

## Prérequis

### Méthode 1 : Installation locale
- Flutter SDK
- Dart SDK
- Un IDE (VS Code ou Android Studio recommandé)

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
```bash
flutter run -d chrome
```

### Méthode 2 : Utilisation de Docker

1. Cloner le projet :
```bash
git clone https://github.com/julienEcole/vegnbioFront.git
cd vegnbioFront
```

2. Construire et lancer avec Docker Compose :
```bash
docker-compose up --build
```

L'application sera accessible à l'adresse : http://localhost:3000

## Structure du projet

```
vegnbioFront/
├── lib/
│   ├── main.dart
│   ├── screens/
│   │   └── home_screen.dart
│   └── widgets/
│       └── navigation_bar.dart
├── test/
│   └── widget_test.dart
├── Dockerfile
├── docker-compose.yml
└── README.md
```

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