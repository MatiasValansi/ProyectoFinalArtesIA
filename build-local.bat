@echo off
REM Script para build local y preparar para Render

echo 🔨 Building aplicación para Render...

REM Navegar al directorio de Flutter
cd frontend\nestle_application

REM Limpiar y build
flutter clean
flutter pub get
flutter build web --release

echo ✅ Build completado!
echo 📁 Los archivos están en: frontend\nestle_application\build\web\
echo 🚀 Sube estos archivos manualmente a Render como Static Site

pause