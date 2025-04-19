@echo off
echo Building Flutter web app for deployment...
flutter build web --release
echo.
echo Deploying to Firebase Hosting...
firebase deploy --only hosting
echo.
echo Deployment complete!
