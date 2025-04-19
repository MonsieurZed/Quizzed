@echo off
echo ======================================
echo Déploiement de Quizzed sur Firebase
echo ======================================
echo.
echo 1. Construction de l'application Flutter web...
flutter clean
flutter build web --release --web-renderer canvaskit
echo.
echo 2. Déploiement sur Firebase...

REM Demande à l'utilisateur ce qu'il souhaite déployer
echo Que souhaitez-vous déployer ?
echo A. Tout (Hosting, Storage, Firestore)
echo B. Seulement l'hébergement (Hosting)
echo C. Seulement les règles (Storage et Firestore)

choice /C ABC /M "Choisissez une option : "

if errorlevel 3 goto rules
if errorlevel 2 goto hosting
if errorlevel 1 goto all

:all
echo.
echo Déploiement complet en cours...
firebase deploy
goto end

:hosting
echo.
echo Déploiement de l'hébergement en cours...
firebase deploy --only hosting
goto end

:rules
echo.
echo Déploiement des règles en cours...
firebase deploy --only firestore:rules,storage
goto end

:end
echo.
echo ======================================
echo Déploiement terminé !
echo ======================================
