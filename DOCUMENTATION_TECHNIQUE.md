# Documentation Technique - MarketMboa

## 1. Présentation Générale
MarketMboa est une application mobile de type "Marketplace" (marché en ligne) permettant la mise en relation entre acheteurs et vendeurs au Cameroun. Elle s'inspire du modèle "Le Bon Coin" tout en intégrant des spécificités locales comme le paiement par Mobile Money.

## 2. Architecture Technique
L'application suit une architecture **"Feature-First"** (par fonctionnalités) pour garantir la scalabilité et la maintenabilité du code.

### Structure du projet (lib/)
- **core/** : Éléments transversaux (constantes de couleurs, thèmes, widgets globaux).
- **features/** : Modules métiers indépendants.
    - `auth/` : Gestion de l'authentification.
    - `home/` : Écran principal, recherche et filtrage.
    - `messages/` : Messagerie temps réel (Chat).
    - `payment/` : Intégration des paiements (NotchPay, USSD).
    - `profile/` : Gestion du compte et des annonces utilisateur.
    - `publish/` : Tunnel de création d'annonces.
- **models/** : Définition des objets de données (User, Listing, Message).
- **services/** : Logique de communication avec les API et bases de données.

## 3. Technologies Utilisées
- **Frontend** : Flutter (Dart) - Framework cross-platform.
- **Backend (BaaS)** : Firebase
    - `FirebaseAuth` : Authentification sécurisée par email/mot de passe.
    - `Firestore` : Base de données NoSQL en temps réel.
    - `Firebase Messaging` : Système de notifications push.
- **Stockage d'images** : Cloudinary (API tierce pour l'hébergement et l'optimisation des photos).
- **Paiements** : 
    - `NotchPay API` : Agrégateur pour Orange Money et MTN MoMo.
    - `Protocole USSD` : Solution de secours pour débit réel immédiat.

## 4. Fonctionnalités Clés & Implémentation
### 4.1 Recherche et Filtrage
Le système de filtrage est implémenté côté client dans le `HomePageState`. Il permet de combiner :
- Recherche textuelle (Titre, Description).
- Filtrage par catégorie (Smartphone, Auto, Immo, etc.).
- Filtrage par plage de prix (Min/Max).

### 4.2 Messagerie Temps Réel
Utilise les `Streams` de Firestore pour une mise à jour instantanée des messages. Chaque message inclut un `senderUid`, un `receiverId` et un statut de lecture.

### 4.3 Publication d'Annonces
Un assistant (Stepper) en plusieurs étapes guide l'utilisateur pour :
- Saisir les informations du produit (titre, prix, description).
- Choisir la catégorie et l'état de l'objet (via un pourcentage de qualité de 1 à 100%).
- Saisir des informations de sécurité uniques selon la catégorie (ex: Numéro de châssis pour l'Auto, IMEI pour les Smartphones).
- Téléverser plusieurs photos vers Cloudinary.
- Associer l'annonce à son compte utilisateur via Firebase.

### 4.4 Gestion des Annonces
L'utilisateur a un contrôle total sur ses publications :
- **Suppression d'annonces** : Le propriétaire d'une annonce (ou un administrateur) peut supprimer une publication directement depuis la page de détail. Cette action nettoie les données dans Firestore et le cache local de l'application.
- **Marquer comme vendu** : Le propriétaire peut marquer son produit comme "Vendu", ce qui le retire de l'accueil et le déplace dans la section **Archives/Produits vendus**.
- **Statut de vente** : Les annonces portent un statut (`active`, `sold`) permettant de filtrer l'affichage.

### 4.5 Module Administrateur
Module permettant la gestion et la supervision de la plateforme :
- **Gestion des utilisateurs** : Consultation de la liste complète des utilisateurs et possibilité de **bloquer/débloquer** des comptes en cas de fraude.
- **Modération** : Suppression directe des annonces non conformes depuis le tableau de bord admin.
- **Accès sécurisé** : Le panneau d'administration n'est accessible qu'aux comptes ayant le rôle `admin` dans Firestore, sans bouton visible publiquement à l'inscription.
- **Archives Globales** : Vue sur l'ensemble des produits vendus sur la plateforme pour un suivi des transactions.

### 4.6 Module Système
Intelligence "invisible" de l'application :
- **Notifications automatiques** : Alertes push lors de la réception d'un message ou d'une vente.
- **Vérification de paiement** : Synchronisation avec NotchPay pour confirmer les transactions.
- **Gestion de la base de données** : Nettoyage périodique et optimisation des index.

### 4.6 Sécurité
- Validation Regex des adresses email.
- Gestion des rôles (User / Admin) intégrée dans le modèle utilisateur.
- Persistence de session via `SharedPreferences`.

## 5. Guide de Déploiement
1. Configurer le projet sur la console Firebase.
2. Télécharger et intégrer le fichier `google-services.json` (Android).
3. Configurer les clés API NotchPay et Cloudinary dans le dossier `lib/config/`.
4. Lancer `flutter build apk` pour générer l'application.
