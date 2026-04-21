@echo off
echo Regenerating iOS app icons with custom logo...
echo.

REM Make sure we're in the project directory
cd /d "%~dp0"

REM Clean old icons
echo Cleaning old iOS icons...
del "ios\Runner\Assets.xcassets\AppIcon.appiconset\*.png" /q

REM Run flutter launcher icons generation
echo Running Flutter launcher icons generation...
flutter pub get
flutter pub run flutter_launcher_icons:main

echo.
echo Icons regenerated successfully!
echo The new icons should now use your custom logo.png file.
echo.
echo Next steps:
echo 1. Rebuild your iOS app
echo 2. Sideload the new IPA to your iPhone
echo 3. The app should now show your custom logo
echo.

pause
