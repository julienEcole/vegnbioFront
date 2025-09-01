# Fonctionnalités CRUD et Authentification - VegnBio Frontend

Ce document décrit les nouvelles fonctionnalités implémentées dans le frontend Flutter pour gérer les opérations CRUD (Create, Read, Update, Delete) et l'authentification des utilisateurs.

## 🚀 Nouvelles Fonctionnalités

### 1. Authentification des Utilisateurs

#### Service d'Authentification (`AuthService`)
- **Connexion** : Authentification avec email et mot de passe
- **Inscription** : Création de nouveaux comptes utilisateurs
- **Gestion des tokens** : Stockage et récupération des tokens Bearer
- **Vérification des rôles** : Contrôle d'accès basé sur les rôles utilisateur
- **Déconnexion** : Suppression des données d'authentification

#### Rôles Utilisateur Supportés
- **Client** : Accès en lecture seule aux restaurants et menus
- **Restaurateur** : Gestion de ses propres restaurants et menus
- **Fournisseur** : Gestion des produits et commandes
- **Administrateur** : Accès complet à toutes les fonctionnalités

### 2. Opérations CRUD Complètes

#### Gestion des Restaurants
- **Créer** : Ajout de nouveaux restaurants
- **Lire** : Affichage de la liste des restaurants
- **Modifier** : Mise à jour des informations des restaurants
- **Supprimer** : Suppression des restaurants

#### Gestion des Menus
- **Créer** : Ajout de nouveaux menus avec allergènes
- **Lire** : Affichage de la liste des menus
- **Modifier** : Mise à jour des informations des menus
- **Supprimer** : Suppression des menus

#### Gestion des Images
- **Upload** : Ajout d'images pour restaurants et menus
- **Supprimer** : Suppression d'images
- **Définir comme principale** : Sélection de l'image principale

### 3. Interface Utilisateur

#### Écrans Principaux
- **Écran de Connexion** : Authentification et inscription
- **Écran de Profil** : Informations utilisateur et gestion des comptes
- **Gestion des Restaurants** : Interface CRUD pour les restaurants
- **Gestion des Menus** : Interface CRUD pour les menus

#### Contrôles d'Accès
- **Boutons d'action** : Affichage conditionnel selon le rôle
- **Permissions** : Vérification des droits avant exécution des actions
- **Navigation** : Accès aux fonctionnalités selon les permissions

## 🔧 Configuration et Installation

### Dépendances Ajoutées
```yaml
dependencies:
  shared_preferences: ^2.2.2  # Stockage local des tokens
```

### Installation
```bash
cd vegnbioFront
flutter pub get
```

## 📱 Utilisation

### 1. Connexion Utilisateur
1. Accéder à l'écran de profil
2. Cliquer sur "Se connecter"
3. Saisir email et mot de passe
4. Valider la connexion

### 2. Création d'un Restaurant
1. Se connecter avec un rôle approprié (admin/restaurateur)
2. Accéder à la gestion des restaurants
3. Cliquer sur le bouton "+" (FAB)
4. Remplir le formulaire
5. Valider la création

### 3. Modification d'un Menu
1. Se connecter avec un rôle approprié (admin/restaurateur)
2. Accéder à la gestion des menus
3. Cliquer sur le menu à modifier
4. Sélectionner "Modifier" dans le menu contextuel
5. Modifier les informations
6. Valider les modifications

### 4. Suppression d'Éléments
1. Se connecter avec un rôle approprié
2. Accéder à l'élément à supprimer
3. Sélectionner "Supprimer" dans le menu contextuel
4. Confirmer la suppression

## 🔐 Sécurité et Authentification

### Token Bearer
- **Format** : `Bearer <token>`
- **Stockage** : Stockage local sécurisé via SharedPreferences
- **Validation** : Vérification côté serveur avec middleware d'authentification
- **Expiration** : Gestion automatique des tokens expirés

### Contrôle d'Accès
- **Middleware** : Vérification des rôles côté serveur
- **Frontend** : Affichage conditionnel des fonctionnalités
- **Validation** : Double vérification client/serveur

## 🌐 API Endpoints Utilisés

### Authentification
- `POST /api/auth/login` - Connexion utilisateur
- `POST /api/auth/register` - Inscription utilisateur

### Restaurants
- `GET /api/restaurants` - Liste des restaurants
- `POST /api/restaurants` - Créer un restaurant
- `PUT /api/restaurants/:id` - Modifier un restaurant
- `DELETE /api/restaurants/:id` - Supprimer un restaurant

### Menus
- `GET /api/menus` - Liste des menus
- `POST /api/menus` - Créer un menu
- `PUT /api/menus/:id` - Modifier un menu
- `DELETE /api/menus/:id` - Supprimer un menu

### Images
- `POST /api/restaurants/:id/image` - Upload image restaurant
- `POST /api/menus/:id/image` - Upload image menu
- `DELETE /api/images/restaurant/:restaurantId/:imageId` - Supprimer image
- `PUT /api/images/restaurant/:restaurantId/:imageId/primary` - Image principale

## 🎯 Fonctionnalités Avancées

### Gestion des Allergènes
- **Parsing automatique** : Séparation par virgules
- **Validation** : Vérification des formats
- **Affichage** : Présentation claire des allergènes

### Gestion des Dates
- **Sélecteur de date** : Interface utilisateur intuitive
- **Format ISO** : Compatibilité avec l'API
- **Validation** : Vérification des dates valides

### Gestion des Relations
- **Restaurant-Menu** : Liaison automatique
- **Images** : Association avec les entités
- **Cascade** : Suppression en cascade si nécessaire

## 🚨 Gestion des Erreurs

### Types d'Erreurs
- **Connexion** : Erreurs réseau et authentification
- **Validation** : Erreurs de format et données manquantes
- **Permissions** : Accès refusé selon le rôle
- **Serveur** : Erreurs 4xx et 5xx

### Gestion des Erreurs
- **Affichage** : Messages d'erreur clairs
- **Retry** : Boutons de réessai automatiques
- **Fallback** : États de fallback en cas d'erreur
- **Logging** : Traçage des erreurs pour le débogage

## 🔄 État de l'Application

### Gestion d'État
- **Riverpod** : Gestion d'état réactive
- **Providers** : Séparation des responsabilités
- **Notifiers** : Mise à jour automatique de l'UI
- **Persistence** : Sauvegarde locale des données

### Synchronisation
- **API** : Synchronisation avec le backend
- **Cache** : Mise en cache des données
- **Offline** : Gestion des états hors ligne
- **Refresh** : Actualisation manuelle des données

## 📋 Tests et Validation

### Tests Recommandés
- **Authentification** : Connexion/déconnexion
- **CRUD** : Création, lecture, modification, suppression
- **Permissions** : Vérification des droits d'accès
- **Validation** : Tests des formulaires
- **Erreurs** : Gestion des cas d'erreur

### Validation
- **Formulaires** : Validation côté client
- **API** : Validation côté serveur
- **Sécurité** : Tests de sécurité et permissions
- **Performance** : Tests de charge et réactivité

## 🚀 Déploiement

### Prérequis
- Backend API fonctionnel
- Base de données configurée
- Variables d'environnement définies
- Certificats SSL configurés

### Étapes
1. Vérifier la configuration de l'API
2. Tester l'authentification
3. Valider les opérations CRUD
4. Déployer l'application
5. Monitorer les performances

## 📞 Support et Maintenance

### Maintenance
- **Mise à jour** : Mise à jour régulière des dépendances
- **Sécurité** : Mise à jour des tokens et clés
- **Performance** : Optimisation continue
- **Monitoring** : Surveillance des erreurs et performances

### Support
- **Documentation** : Mise à jour de la documentation
- **Formation** : Formation des utilisateurs
- **Assistance** : Support technique en cas de problème
- **Évolution** : Ajout de nouvelles fonctionnalités

---

**Note** : Ce document est mis à jour régulièrement. Pour toute question ou suggestion, veuillez contacter l'équipe de développement.
