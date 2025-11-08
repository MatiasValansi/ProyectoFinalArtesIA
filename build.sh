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

# Verificar estructura de directorios
echo "📁 Estructura del proyecto:"
ls -la

# Navegar al directorio de Flutter
echo "🔍 Navegando a frontend/nestle_application..."
cd frontend/nestle_application

# Verificar que estamos en el directorio correcto
echo "📂 Directorio actual:"
pwd
echo "📋 Contenido:"
ls -la

# Limpiar y obtener dependencias
flutter clean
flutter pub get

# Build para web
echo "🌐 Building para web..."
flutter build web --release

# Verificar que el build se completó
echo "� Verificando build..."
ls -la build/web/

# Los archivos ya están en build/web, Render los tomará automáticamente desde staticPublishPath

echo "✅ Build completado!"