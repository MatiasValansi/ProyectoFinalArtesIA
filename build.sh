#!/bin/bash

# Script de build para Render
echo "🔨 Iniciando build para Render..."

# Instalar Flutter
echo "📦 Instalando Flutter..."
cd /tmp
git clone https://github.com/flutter/flutter.git -b stable --depth 1
export PATH="/tmp/flutter/bin:$PATH"
flutter config --enable-web
flutter doctor

# Volver al directorio del proyecto
cd $RENDER_PROJECT_ROOT

# Verificar si estamos en src
if [ -d "src" ]; then
  cd src
fi

# Navegar al directorio de Flutter
if [ -d "frontend/nestle_application" ]; then
  cd frontend/nestle_application
else
  echo "❌ No se encuentra frontend/nestle_application"
  exit 1
fi

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

echo "✅ Build completado!"