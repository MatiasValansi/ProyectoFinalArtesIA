# NestléArtesIA - Sistema de Análisis de Arte con IA

## 📋 Descripción del Proyecto

NestléArtesIA es una aplicación desarrollada en Flutter que permite a los usuarios acreditados por la compañía analizar piezas de arte utilizando inteligencia artificial parametrizada a medida de sus requerimientos. La aplicación combina la seguridad de Firebase para autenticación, Supabase para gestión de datos y la API de Serenity Star para análisis de imágenes con IA.

## 🚀 Características Principales

### 🔐 Sistema de Autenticación y Gestión de Usuarios
- **Autenticación con Firebase**: Login seguro con email y contraseña
- **Gestión de Roles**: Sistema de roles jerárquico (Usuario, Supervisor, Administrador)
- **Administración de Usuarios**: Panel completo para crear, editar y eliminar usuarios
- **Seguridad**: Validación de permisos y acceso basado en roles

### 🎨 Análisis de Arte con IA
- **Carga de Imágenes**: Interfaz para subir piezas de arte
- **Análisis Inteligente**: Integración con API Serenity Star para análisis de imágenes
- **Resultados Detallados**: Visualización completa de los análisis realizados
- **Historial de Proyectos**: Gestión de casos y seguimiento de análisis

### 💬 Sistema de Chat Interactivo
- **Chat en Tiempo Real**: Comunicación fluida durante el análisis
- **Interfaz Intuitiva**: Diseño moderno y responsivo para conversaciones
- **Integración con IA**: Respuestas inteligentes basadas en el análisis

### 📊 Dashboard y Gestión de Proyectos
- **Panel de Usuario**: Vista personalizada según el rol del usuario
- **Gestión de Casos**: Creación, seguimiento y administración de proyectos
- **Estados de Proyecto**: Control de estados (Aprobado/Desaprobado/En curso)
- **Navegación Intuitiva**: Sistema de routing con Go Router

## 🛠️ Tecnologías Utilizadas

### Frontend (Flutter)
- **Flutter**: Framework principal para desarrollo móvil multiplataforma
- **Dart**: Lenguaje de programación
- **Material Design**: Sistema de diseño de Google para UI/UX consistente

### Backend y Servicios
- **Firebase Authentication**: Gestión de usuarios y autenticación
- **Supabase**: Base de datos PostgreSQL en tiempo real
- **Serenity Star API**: Servicio de análisis de imágenes con IA
- **Row Level Security (RLS)**: Seguridad a nivel de fila en Supabase

### Gestión de Estado y Navegación
- **Go Router**: Enrutamiento declarativo y tipado
- **StatefulWidget**: Gestión de estado local
- **Provider Pattern**: Servicios inyectados para lógica de negocio

## 📱 Funcionalidades por Pantalla

### 🏠 Pantalla Principal (Home)
- **Vista Personalizada**: Contenido adaptado al rol del usuario
- **Lista de Proyectos**: Visualización de todos los casos asignados (según rol)
- **Acceso Rápido**: Botones para crear nuevos proyectos y administrar usuarios
- **Información de Usuario**: Avatar, email y rol en la barra superior
- **Estados Visuales**: Indicadores de estado de proyectos

### 🔑 Pantalla de Login
- **Autenticación Segura**: Validación de credenciales con Firebase
- **Diseño Responsivo**: Interfaz adaptable a diferentes tamaños de pantalla
- **Manejo de Errores**: Mensajes claros de error de autenticación
- **Redirección Automática**: Navegación automática según estado de autenticación

### 🎨 Nueva Obra de Arte
- **Carga de Archivos**: Pantalla de carga de imágenes
- **Validación de Formatos**: Soporte para múltiples formatos de imagen
- **Vista Previa**: Visualización de la/s imagen/es antes y durante del análisis
- **Configuración de Proyecto**: Definición de parámetros de análisis según lineamientos generales. Adaptables por el administrador del sistema

### 📈 Resultados de Análisis
- **Visualización Completa**: Presentación detallada de resultados de IA
- **Chat Integrado**: Agente conversacional integrado en los resultados del análisis
- **Datos Estructurados**: Información organizada y fácil de interpretar
- **Historial**: Registro de casos histórico
- **Supervisión**: Aprobación o rechazo del proyecto supeditada a los usuarios Supervisores

### 👥 Administración de Usuarios (Solo Administradores)
- **Gestión Completa**: Crear, editar y eliminar usuarios
- **Asignación de Roles**: Control granular de permisos
- **Vista de Lista**: Tabla organizada con información de usuarios
- **Filtros y Búsqueda**: Herramientas para encontrar usuarios específicos

## 🔧 Arquitectura del Proyecto

### 📁 Estructura de Carpetas
```
lib/
├── core/
│   ├── auth/           # Servicios de autenticación
│   ├── config/         # Configuraciones de la app
│   ├── router/         # Configuración de rutas
│   └── services/       # Servicios externos (Serenity API)
├── database/
│   ├── cases_service.dart     # Gestión de casos/proyectos
│   ├── user_service.dart      # Gestión de usuarios
│   └── supabase_config.dart   # Configuración de Supabase
├── models/
│   ├── case_model.dart        # Modelo de datos para casos
│   └── user_model.dart        # Modelo de datos para usuarios
└── presentation/
    ├── screens/        # Pantallas de la aplicación
    └── widgets/        # Componentes reutilizables
```

### 🔄 Flujo de Datos
1. **Autenticación**: Firebase maneja login/logout
2. **Datos de Usuario**: Supabase almacena los datos de la APP
3. **Análisis IA**: Serenity API procesa imágenes
4. **Estado Local**: StatefulWidgets gestionan UI reactiva

## 🎯 Roles de Usuario

### 👤 Usuario Estándar
- Crear y gestionar sus propios proyectos de análisis
- Subir imágenes para análisis con IA
- Ver resultados de sus análisis
- Interactuar con el chat de IA

### 👨‍💼 Supervisor
- Todas las funcionalidades de Usuario
- Supervisar proyectos de otros usuarios
- Acceso a métricas y reportes básicos

### 🔧 Administrador
- Todas las funcionalidades de Supervisor
- Gestión completa de usuarios (crear, editar, eliminar)
- Asignación y modificación de roles

## 🚀 Instalación y Configuración

### Prerrequisitos
- Flutter SDK (versión 3.0+)
- Dart SDK
- Firebase CLI
- Cuenta de Firebase
- Cuenta de Supabase
- Acceso a la API de Serenity

### Pasos de Instalación

1. **Clonar el Repositorio**
```bash
git clone https://github.com/MatiasValansi/ProyectoFinalArtesIA.git
cd ProyectoFinalArtesIA/frontend/nestle_application
```

2. **Instalar Dependencias**
```bash
flutter pub get
```

3. **Configurar Firebase**
```bash
firebase login
firebase init
```

4. **Configurar Variables de Entorno**
Crear archivo `.env` con:
```env
SUPABASE_URL=tu_supabase_url
SUPABASE_ANON_KEY=tu_supabase_anon_key
SERENITY_API_URL=tu_serenity_api_url
```

5. **Ejecutar la Aplicación**
```bash
flutter run
```

## 📦 Dependencias Principales

```yaml
dependencies:
  flutter:
    sdk: flutter
  firebase_auth: ^5.7.0
  cloud_firestore: ^5.6.12
  firebase_core: ^3.15.2
  go_router: ^16.2.4
  supabase_flutter: ^2.8.3
  flutter_dotenv: ^5.2.1
  http: ^1.2.2
  crypto: ^3.0.5
```

## 🔒 Seguridad

### Autenticación
- Firebase Authentication para gestión segura de usuarios
- Tokens JWT para validación de sesiones
- Logout automático en caso de tokens expirados

### Base de Datos
- Row Level Security (RLS) en Supabase
- Políticas de acceso basadas en roles
- Encriptación de datos sensibles

### API
- Validación de requests con tokens
- Rate limiting para prevenir abuso
- Manejo seguro de archivos subidos

## 🧪 Testing

### Tipos de Testing Implementados
- **Unit Tests**: Testing de servicios y modelos
- **Widget Tests**: Testing de componentes UI
- **Integration Tests**: Testing de flujos completos

### Ejecutar Tests
```bash
flutter test
```

## 📈 Métricas y Monitoreo

### Analytics
- Firebase Analytics para tracking de uso
- Seguimiento de errores con Firebase Crashlytics

### Logging
- Sistema de logs estructurado
- Tracking de acciones de usuario
- Monitoreo de llamadas a API

## 🔄 Actualizaciones Recientes

### Versión 2.0 (Octubre 2025)
- ✅ Implementación completa del sistema de roles
- ✅ Panel de administración de usuarios
- ✅ Mejoras en la interfaz de usuario
- ✅ Optimización de la gestión de estado
- ✅ Integración mejorada con Serenity API
- ✅ Sistema de chat más robusto
- ✅ Corrección de errores de navegación

## 🤝 Contribución

### Guías de Contribución de desarrollo interno
1. Fork del repositorio
2. Crear una rama para la nueva funcionalidad
3. Implementar cambios con tests
4. Enviar Pull Request con descripción detallada

### Estándares de Código
- Seguir convenciones de Dart/Flutter
- Documentar funciones públicas
- Mantener coverage de tests > 80%
- Usar linter de Flutter


### Issues y Bugs
- Reportar bugs en GitHub Issues
- Incluir logs y pasos para reproducir
- Especificar versión de Flutter y dispositivo
---


*Desarrollado con ❤️😁 del equipo de Trabajo Final para Nestlé*