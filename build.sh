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

# Verificar si estamos en src
echo "🔍 Verificando si estamos en src..."
if [ -d "src" ]; then
  echo "✅ Detectado directorio src, navegando..."
  cd src
  echo "📂 Ahora en:"
  pwd
  ls -la
fi

# Navegar al directorio de Flutter
echo "🔍 Navegando a frontend/nestle_application..."
if [ -d "frontend/nestle_application" ]; then
  cd frontend/nestle_application
  echo "✅ Encontrado directorio Flutter"
else
  echo "❌ No se encuentra frontend/nestle_application"
  echo "📋 Estructura actual:"
  find . -name "pubspec.yaml" -type f 2>/dev/null
  exit 1
fi

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
flutter build web --release \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
  --dart-define=IA_API_BASE_URL="$IA_API_BASE_URL" \
  --dart-define=IA_API_KEY="$IA_API_KEY" \
  --dart-define=IA_NESTLE_CHECK_AGENT_ENDPOINT="$IA_NESTLE_CHECK_AGENT_ENDPOINT" \
  --dart-define=IA_VOLATILE_KNOWLEDGE_ENDPOINT="$IA_VOLATILE_KNOWLEDGE_ENDPOINT"

# Verificar que el build se completó
echo "� Verificando build..."
ls -la build/web/

# Los archivos ya están en build/web, Render los tomará automáticamente desde staticPublishPath

echo "✅ Build completado!"