#!/bin/bash

# Script de build para Render
echo "🔨 Iniciando build para Render..."

# Instalar Flutter
echo "📦 Instalando Flutter..."
cd /tmp
git clone https://github.com/flutter/flutter.git -b stable --depth 1
export PATH="/tmp/flutter/bin:$PATH"
flutter doctor

# Volver al directorio del proyecto
cd $RENDER_PROJECT_ROOT

# Navegar al directorio de Flutter
cd frontend/nestle_application

# Limpiar y obtener dependencias
flutter clean
flutter pub get

# Build para web
echo "🌐 Building para web..."
flutter build web --release

# Copiar archivos build al directorio público
echo "📁 Copiando archivos..."
cp -r build/web/* /opt/render/project/src/public/

echo "✅ Build completado!"