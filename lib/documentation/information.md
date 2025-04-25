# Système de jeux - Spécifications détaillées

**IMPORTANT**: Toute modification du fonctionnement du système de jeux doit être mise à jour dans ce document.

## Architecture générale

Le système de jeux est conçu pour être modulaire et extensible, permettant d'intégrer facilement différents types de jeux tout en maintenant une base commune.

### Structure à deux phases

Chaque jeu est divisé en deux phases distinctes :

1. **Phase de jeu** : Les joueurs participent activement au jeu et répondent/interagissent
2. **Phase de résultat** : Affichage des résultats et du classement

### Jeu en temps réel et persistance

- Les jeux se déroulent en temps réel avec tous les joueurs du lobby
- En cas de déconnexion d'un joueur, le système permet de reprendre la partie en cours
- L'état du jeu est sauvegardé régulièrement pour permettre cette reprise

### Création et participation

- Tout joueur peut créer un jeu dans un lobby
- Les paramètres du jeu sont définis par le créateur
- Tous les joueurs du lobby peuvent participer

## Système de résultats

### Podium

Un podium visuel est affiché à la fin de chaque jeu avec :

- Les 3 premiers joueurs mis en avant
- Avatar, couleur de profil et nom de chaque joueur
- Points obtenus durant la partie

### Classement complet

- Liste complète de tous les joueurs classés par score
- Visualisation claire du positionnement du joueur actuel
- Affichage des points de chaque joueur

## Types de jeux

### Jeu 1 : Quiz

Un quiz est composé de plusieurs questions qui peuvent être de différents types.

#### Éléments de question

Chaque question peut contenir un ou plusieurs des éléments suivants :

- **Texte** : Énoncé principal de la question
- **Image** : Support visuel complémentaire
- **Son** : Clip audio à écouter
- **Vidéo** : Séquence vidéo à regarder
- **Lien** : Contenu web chargé dans un encart de la page

#### Types de réponses

- **Choix multiples** : Sélection d'une ou plusieurs options parmi une liste prédéfinie
- **Réponse libre** : Saisie d'un texte sans contraintes
- **Slider** : Sélection d'une valeur sur un intervalle continu
- **Date** : Sélection d'une date spécifique

#### Validation des réponses

La méthode de validation dépend du type de réponse :

**Pour les choix multiples** :

- Validation automatique basée sur les réponses prédéfinies lors de la création de la question

**Pour les sliders et dates** :

- Validation exacte ou avec marge d'erreur définie par le créateur du quiz

**Pour les réponses libres** :

- **Option 1 - Validation par les joueurs** :

  - Phase de validation après le quiz
  - Système de vote (like/dislike)
  - Seuil de validation à 70% de votes positifs
  - Chaque joueur dispose d'un "super like" par partie pour attribuer des points bonus à une réponse

- **Option 2 - Validation par IA** :
  - Envoi des réponses à l'API Gemini sous forme de prompts
  - L'IA évalue et détermine quelles réponses sont acceptables
  - Attribution automatique des points selon l'évaluation

#### Interface du créateur

Si le créateur du quiz est présent dans la partie, il a accès à des fonctionnalités supplémentaires :

- Interface de suivi en temps réel des réponses des joueurs
- Visualisation de la progression (questions déjà répondues)
- Possibilité d'attribuer des points bonus durant la phase de correction

#### Statistiques et analytics

Lors de l'affichage des réponses, le système montre :

- Le pourcentage de joueurs ayant choisi chaque réponse dans le lobby actuel
- Le pourcentage global basé sur toutes les sessions de ce quiz
- Ces statistiques permettent une analyse comparative de la performance
