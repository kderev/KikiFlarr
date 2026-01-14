# KikiFlarr

Application iOS native pour centraliser la gestion de vos services médias : **Radarr**, **Sonarr**, **qBittorrent** et **Overseerr** — le tout dans une seule application élégante. Incluant un système de **Collection** avec suivi des films/séries vus et **badges gamifiés** pour suivre vos progrès de cinéphile !

![iOS 17+](https://img.shields.io/badge/iOS-17%2B-blue)
![Swift 5.9](https://img.shields.io/badge/Swift-5.9-orange)
![SwiftUI](https://img.shields.io/badge/UI-SwiftUI-green)
![qBittorrent v4 & v5](https://img.shields.io/badge/qBittorrent-v4%20%26%20v5-brightgreen)

## Fonctionnalités principales

### 🔍 Recherche & Découverte
- Recherche unifiée de films et séries via Overseerr
- Affichage des affiches et métadonnées (synopsis, année, note, genres)
- Badges de disponibilité (disponible, demandé, en attente)
- Section "Découvrir" avec les tendances du moment

### 🎬 Gestion des Films (Radarr)
- Ajout de films à votre bibliothèque Radarr
- Sélection du profil de qualité
- Choix du dossier de destination
- Affichage de la bibliothèque existante
- Détails complets des films (cast, durée, studio, etc.)

### 📺 Gestion des Séries (Sonarr)
- Ajout de séries à votre bibliothèque Sonarr
- Sélection des saisons à surveiller
- Choix du profil de qualité et du type de série
- Affichage de la bibliothèque avec progression des épisodes
- Détails par saison et épisode

### ⬇️ Gestion des Téléchargements (qBittorrent)
- **Compatible qBittorrent v4.x ET v5.x** (détection automatique de l'API)
- Liste en temps réel de tous les torrents
- Statistiques globales (vitesse DL/UL, nombre de torrents actifs)
- Actions sur les torrents :
  - ▶️ Reprendre un torrent en pause
  - ⏸️ Mettre en pause un torrent actif
  - 🗑️ Supprimer (avec option de supprimer les fichiers)
  - 🔄 Vérifier l'intégrité
- Filtres avancés (tous, en cours, en seed, terminés, en pause, erreur)
- Rafraîchissement automatique (5 secondes) et pull-to-refresh
- Affichage détaillé par torrent :
  - Progression avec barre visuelle
  - Vitesse de téléchargement/envoi
  - ETA estimé
  - Ratio de partage
  - État avec icône colorée

### 🏆 Collection & Badges Gamifiés
- **Suivi personnel des films et séries vus**
  - Marquez vos films/séries comme "vus" depuis votre bibliothèque
  - Recherche et ajout manuel via TMDB (si configuré)
  - Notes personnelles (1-5 étoiles) et commentaires
  - Affichage des posters et métadonnées
  - Suppression par swipe

- **Statistiques détaillées**
  - Nombre total de films, séries et épisodes vus
  - Temps total passé à regarder (films + séries combinés)
  - Répartition par genre avec compteurs
  - Films/épisodes cette semaine et ce mois
  - Streak actuel et meilleur streak (jours consécutifs)

- **Système de badges avec 6 catégories**
  - 🏆 **Collectionneur** : Basé sur le nombre de films vus (1 à 1000+)
  - 📺 **Collectionneur Séries** : Basé sur les séries et épisodes vus
  - 🎭 **Genre** : Badges par genre (Action, Comedy, Horror, etc.)
  - 🔥 **Marathon** : Films regardés en un jour/semaine
  - ❤️ **Dévotion** : Streaks de visionnage (3 à 100+ jours)
  - ✨ **Spécial** : Défis uniques (Noctambule, Lève-tôt, Éclectique, etc.)

- **5 niveaux de rareté**
  - Commun, Peu commun, Rare, Épique, Légendaire
  - Effets visuels avec glow selon la rareté
  - Animation de déblocage en temps réel
  - Fiche détaillée par badge avec date de déblocage

- **Intégration TMDB directe** (optionnelle)
  - Recherche de films en dehors de votre bibliothèque
  - Ajout de films vus manuellement
  - Métadonnées enrichies (runtime, genres, etc.)

### 🏠 Multi-instances
- Support de plusieurs serveurs simultanément
- Idéal pour environnements local + seedbox distant
- Chaque service peut avoir plusieurs instances
- Basculement facile entre les instances

### 🔐 Sécurité
- Stockage sécurisé des clés API dans le Keychain iOS
- Authentification par cookie pour qBittorrent
- Support HTTPS pour les connexions distantes

### 🎨 Interface utilisateur
- Design moderne et natif iOS avec SwiftUI
- Mode sombre supporté
- Animations fluides
- Feedback visuel lors des actions
- Onboarding guidé au premier lancement

## Compatibilité qBittorrent

L'application supporte automatiquement les deux versions majeures de l'API qBittorrent :

| Version qBittorrent | API Pause/Resume | Détection |
|---------------------|------------------|-----------|
| v4.x et antérieur   | `/torrents/pause` & `/torrents/resume` | Automatique |
| v5.0+               | `/torrents/stop` & `/torrents/start` | Automatique |

La version est détectée automatiquement à la connexion, avec fallback si nécessaire.

## Architecture

```
KikiFlarr/
├── App/
│   ├── KikiFlarrApp.swift          # Point d'entrée
│   └── ContentView.swift          # Vue principale + navigation
├── Models/
│   ├── ServiceInstance.swift      # Modèle d'instance de service
│   ├── InstanceGroup.swift        # Groupement d'instances
│   ├── RadarrModels.swift         # Types Radarr API v3
│   ├── SonarrModels.swift         # Types Sonarr API v3
│   ├── QBittorrentModels.swift    # Types qBittorrent Web API v2
│   ├── OverseerrModels.swift      # Types Overseerr API
│   ├── TMDBModels.swift           # Types TMDB API
│   └── WatchedModels.swift        # Films/Séries vus et Badges
├── Services/
│   ├── NetworkError.swift         # Gestion des erreurs réseau
│   ├── APIClient.swift            # Client HTTP générique
│   ├── RadarrService.swift        # Service Radarr
│   ├── SonarrService.swift        # Service Sonarr
│   ├── QBittorrentService.swift   # Service qBittorrent (v4 & v5)
│   ├── OverseerrService.swift     # Service Overseerr
│   ├── TMDBService.swift          # Service TMDB direct
│   └── WatchedStorageService.swift # Stockage local films/badges vus
├── ViewModels/
│   ├── SearchViewModel.swift      # Logique de recherche
│   ├── DiscoverViewModel.swift    # Logique découverte/tendances
│   ├── DetailsViewModel.swift     # Logique des détails + ajout
│   ├── LibraryViewModel.swift     # Logique bibliothèque
│   ├── DownloadsViewModel.swift   # Logique des téléchargements
│   ├── WatchedViewModel.swift     # Logique collection & badges
│   └── SettingsViewModel.swift    # Logique des paramètres
├── Views/
│   ├── Components/
│   │   ├── AsyncImageView.swift   # Chargement d'images async
│   │   ├── TorrentCard.swift      # Carte de torrent avec actions
│   │   ├── SearchResultCard.swift # Carte de résultat de recherche
│   │   └── InstanceRow.swift      # Ligne d'instance dans settings
│   ├── Search/
│   │   └── SearchView.swift       # Écran de recherche
│   ├── Discover/
│   │   └── DiscoverView.swift     # Écran découverte
│   ├── Details/
│   │   └── DetailsView.swift      # Écran de détails média
│   ├── Library/
│   │   ├── LibraryView.swift      # Écran bibliothèque
│   │   ├── MovieDetailView.swift  # Détails d'un film
│   │   └── SeriesDetailView.swift # Détails d'une série
│   ├── Downloads/
│   │   └── DownloadsView.swift    # Écran des téléchargements
│   ├── Collection/
│   │   ├── CollectionView.swift   # Écran collection & badges
│   │   └── TMDBSearchView.swift   # Recherche TMDB directe
│   └── Settings/
│       ├── SettingsView.swift     # Écran des paramètres
│       └── OnboardingView.swift   # Écran d'accueil/configuration
├── Utilities/
│   ├── KeychainManager.swift      # Gestion du Keychain
│   ├── InstanceManager.swift      # Gestion des instances
│   ├── ImageCache.swift           # Cache d'images
│   ├── ResponseCache.swift        # Cache de réponses API
│   └── Formatters.swift           # Utilitaires de formatage
└── Resources/
    └── Config.example.swift       # Configuration exemple
```

## Prérequis

- **Xcode 15+** (pour iOS 17 et Swift 5.9)
- **iOS 17+** sur simulateur ou appareil
- Services configurés :
  - Overseerr avec clé API (pour la recherche)
  - Radarr et/ou Sonarr avec clés API (pour l'ajout de médias)
  - qBittorrent v4.x ou v5.x avec Web UI activée (optionnel, pour le suivi des téléchargements)
  - TMDB API key (optionnel, pour recherche et ajout manuel de films dans la Collection)

## Installation

### 1. Créer le projet Xcode

1. Ouvrez Xcode
2. **File > New > Project**
3. Choisissez **iOS > App**
4. Configurez :
   - **Product Name** : `KikiFlarr`
   - **Organization Identifier** : `com.votreorg`
   - **Interface** : SwiftUI
   - **Language** : Swift
   - **Minimum Deployments** : iOS 17.0

### 2. Ajouter les fichiers sources

1. Supprimez les fichiers générés par défaut (`ContentView.swift`, etc.)
2. Créez l'arborescence de dossiers comme indiqué ci-dessus
3. Glissez-déposez tous les fichiers `.swift` dans les dossiers correspondants
4. Assurez-vous que tous les fichiers sont ajoutés à la target `KikiFlarr`

### 3. Configurer le projet

Dans **Project Settings > KikiFlarr target** :

1. **General** :
   - Minimum Deployments : iOS 17.0
   - Device : iPhone

2. **Signing & Capabilities** :
   - Activez la signature automatique
   - Sélectionnez votre équipe de développement

3. **Info.plist** (pour les connexions HTTP locales) :
   ```xml
   <key>NSAppTransportSecurity</key>
   <dict>
       <key>NSAllowsArbitraryLoads</key>
       <true/>
   </dict>
   ```
   > ⚠️ Nécessaire uniquement pour les connexions HTTP locales (192.168.x.x)

### 4. Build & Run

```bash
# Via Xcode : Cmd + R
# Ou via ligne de commande :
xcodebuild -scheme KikiFlarr -destination 'platform=iOS Simulator,name=iPhone 15 Pro' build
```

## Configuration des services

### Overseerr

1. Allez dans **Settings > General**
2. Copiez l'**API Key**
3. URL type : `http://192.168.1.100:5055` ou `https://overseerr.votredomaine.com`

### Radarr / Sonarr

1. Allez dans **Settings > General > Security**
2. Copiez l'**API Key**
3. URLs types :
   - Local : `http://192.168.1.100:7878` (Radarr) / `:8989` (Sonarr)
   - Seedbox : `https://radarr.votreseedbox.com`

### qBittorrent

1. Activez **Web UI** dans **Tools > Options > Web UI**
2. Définissez un port (défaut : 8080)
3. URL type : `http://192.168.1.100:8080`
4. Identifiants : username/password configurés dans Web UI
5. **Important pour v5+** : L'application détecte automatiquement la version et utilise les bons endpoints

### TMDB (optionnel)

Pour activer la recherche et l'ajout manuel de films dans la Collection :

1. Créez un compte sur [The Movie Database](https://www.themoviedb.org/)
2. Allez dans **Settings > API**
3. Demandez une clé API (gratuit pour usage personnel)
4. Dans KikiFlarr, allez dans **Paramètres > TMDB**
5. Entrez votre clé API
6. Vous pourrez maintenant utiliser le bouton **+** dans l'onglet Collection pour rechercher n'importe quel film

## Utilisation

### Premier lancement

1. L'application affiche un **onboarding** pour configurer vos instances
2. Ajoutez au minimum :
   - Une instance **Overseerr** (pour la recherche)
   - Une instance **Radarr** ou **Sonarr** (pour les demandes)
3. Optionnel : ajoutez **qBittorrent** pour le suivi des téléchargements

### Navigation

L'application utilise une barre d'onglets avec 5 sections :

| Onglet | Fonction |
|--------|----------|
| ✨ Découvrir | Tendances et suggestions Overseerr |
| 📚 Bibliothèque | Vos médias Radarr/Sonarr |
| 🏆 Collection | Films/séries vus & badges gamifiés |
| ⬇️ Transferts | Suivi qBittorrent en temps réel |
| ⚙️ Paramètres | Configuration des instances |

### Recherche & Ajout

1. Tapez le nom d'un film ou d'une série
2. Les résultats s'affichent avec affiches et informations
3. Les badges indiquent si le média est déjà disponible ou demandé
4. Appuyez sur un résultat pour voir les détails
5. Sélectionnez l'instance cible (Radarr/Sonarr)
6. Choisissez le profil de qualité et le dossier
7. Pour les séries : sélectionnez les saisons souhaitées
8. Appuyez sur "Ajouter"

### Gestion des téléchargements

1. L'onglet "Transferts" affiche tous vos torrents
2. Rafraîchissement automatique toutes les 5 secondes
3. Pull-to-refresh pour forcer le rafraîchissement
4. Utilisez les filtres pour affiner la vue
5. Actions disponibles sur chaque torrent :
   - **Pause/Reprendre** : Contrôle de l'état du torrent
   - **Supprimer** : Avec confirmation et option de supprimer les fichiers

### Collection & Suivi Personnel

#### Marquer comme vu
1. Depuis votre **Bibliothèque**, appuyez sur un film ou série
2. Appuyez sur le bouton "Marquer comme vu"
3. Optionnel : Ajoutez une note (1-5 étoiles) et un commentaire

#### Ajouter manuellement via TMDB
1. Configurez une clé API TMDB dans les **Paramètres** (optionnel)
2. Dans l'onglet **Collection**, appuyez sur **+**
3. Recherchez n'importe quel film
4. Ajoutez-le à votre collection avec note et commentaire

#### Badges & Progression
1. Accédez à l'onglet **Collection**
2. Basculez vers **Badges** avec le sélecteur en haut
3. Consultez votre progression globale et par catégorie
4. Appuyez sur un badge pour voir ses détails
5. Les badges se débloquent automatiquement selon vos progrès
6. Une notification toast apparaît lors du déblocage d'un nouveau badge

#### Statistiques
1. Dans l'onglet **Collection**, appuyez sur l'icône 📊 en haut
2. Consultez vos statistiques détaillées :
   - Vue d'ensemble (films, séries, épisodes)
   - Temps total passé
   - Streaks (actuel et meilleur)
   - Répartition par genre
   - Films/épisodes cette semaine et ce mois
   - Progression des badges par rareté

## Gestion des erreurs

| Code | Description | Solution |
|------|-------------|----------|
| 401  | Non autorisé | Vérifiez la clé API |
| 403  | Accès refusé | Vérifiez les permissions ou les identifiants |
| 404  | Non trouvé | Vérifiez l'URL de base |
| 500+ | Erreur serveur | Vérifiez que le service fonctionne |
| Timeout | Délai dépassé | Vérifiez la connectivité réseau |

## Personnalisation

### Ajouter un nouveau service

1. Créez les modèles dans `Models/NouveauServiceModels.swift`
2. Créez le service dans `Services/NouveauService.swift`
3. Ajoutez le type dans `ServiceType` (ServiceInstance.swift)
4. Mettez à jour `InstanceManager` pour créer le service

### Modifier les timeouts

Dans `APIClient.swift` :
```swift
init(timeoutInterval: TimeInterval = 30) // Modifiez cette valeur
```

### Modifier l'intervalle de rafraîchissement

Dans `DownloadsViewModel.swift` :
```swift
func startAutoRefresh(interval: TimeInterval = 5) // Modifiez cette valeur
```

## Dépannage

### L'app ne se connecte pas aux services locaux

1. Vérifiez que votre iPhone/simulateur est sur le même réseau
2. Vérifiez les règles de pare-feu
3. Ajoutez l'exception ATS dans Info.plist

### Les images ne s'affichent pas

Les images proviennent de TMDB via Overseerr. Vérifiez :
1. La connexion Internet
2. Que Overseerr a accès à TMDB

### qBittorrent : Les boutons pause/reprendre ne fonctionnent pas

1. Vérifiez la version de qBittorrent installée
2. L'app détecte automatiquement v4 vs v5, mais un redémarrage peut être nécessaire
3. Testez la connexion dans les paramètres

### qBittorrent déconnecte fréquemment

La session expire après un certain temps. L'app se reconnecte automatiquement, mais vous pouvez :
1. Augmenter la durée de session dans qBittorrent Web UI
2. Désactiver "Bypass authentication for clients on localhost" si vous êtes en local

## Changelog

### v2.0.0 - Collection & Badges
- 🏆 **Nouvelle fonctionnalité Collection** : Suivez vos films et séries vus
  - Marquez les films/séries comme "vus" depuis votre bibliothèque
  - Ajout de notes personnelles (1-5 étoiles) et commentaires
  - Suppression par swipe
- 🎮 **Système de badges gamifiés** avec 6 catégories :
  - Collectionneur (films et séries)
  - Genre (Action, Comedy, Horror, etc.)
  - Marathon (visionnages intensifs)
  - Dévotion (streaks consécutifs)
  - Spécial (défis uniques)
- 📊 **Statistiques détaillées** :
  - Nombre total de films, séries et épisodes vus
  - Temps total passé (films + séries)
  - Streaks de visionnage (actuel et meilleur)
  - Répartition par genre
  - Progression par période (semaine, mois)
- 🎬 **Intégration TMDB directe** (optionnelle) :
  - Recherche de films en dehors de votre bibliothèque
  - Ajout manuel de films vus avec métadonnées enrichies
- ✨ **Interface améliorée** :
  - Nouvel onglet "Collection" avec onglet "Films vus" et "Badges"
  - Animation de déblocage des badges en temps réel
  - Fiches détaillées par badge avec date de déblocage
  - Effets visuels avec glow selon la rareté des badges
- 💾 **Cache optimisé** :
  - Cache d'images pour chargement plus rapide
  - Cache de réponses API pour réduire les requêtes
- 🔄 **Navigation mise à jour** :
  - Renommage "Téléchargements" → "Transferts"
  - Ordre des onglets optimisé pour une meilleure UX

### v1.1.0
- ✅ Support complet de qBittorrent v5.x (nouveaux endpoints stop/start)
- ✅ Détection automatique de la version de qBittorrent
- ✅ Fallback automatique si un endpoint échoue
- ✅ Feedback visuel amélioré lors des actions sur les torrents
- ✅ Boutons désactivés pendant les opérations pour éviter les clics multiples

### v1.0.0
- 🎉 Version initiale
- Recherche via Overseerr
- Intégration Radarr et Sonarr
- Suivi des téléchargements qBittorrent v4.x
- Multi-instances
- Stockage sécurisé des clés API

## Contribution

1. Fork le projet
2. Créez une branche (`git checkout -b feature/amelioration`)
3. Commitez (`git commit -am 'Ajout d'une fonctionnalité'`)
4. Push (`git push origin feature/amelioration`)
5. Ouvrez une Pull Request

## Licence

MIT License - voir [LICENSE](LICENSE)

---

Inspiré par [Homarr](https://github.com/ajnart/homarr) pour la gestion centralisée des services *arr.
