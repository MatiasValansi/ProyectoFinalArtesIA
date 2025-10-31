# Funcionalidad de Supervisión - Nestlé Validation Tool

Esta documentación explica la funcionalidad completa de supervisión para la aplicación Nestlé Validation Tool.

## Descripción

El sistema de supervisión incluye dos pantallas principales:

1. **`SupervisorDashboard`**: Dashboard principal que muestra todos los proyectos de todos los usuarios
2. **`SupervisorAnalysisReview`**: Pantalla de revisión detallada para aprobar/rechazar proyectos individuales

## Nuevas Funcionalidades Implementadas

### 🔍 **Dashboard del Supervisor** (`supervisor_dashboard.dart`)

**Características principales:**
- **Vista de todos los proyectos**: Los supervisores pueden ver proyectos de todos los usuarios
- **Información del usuario autor**: Cada proyecto muestra el nombre y email del usuario que lo creó
- **Panel de estadísticas**: Resumen con total de proyectos, pendientes, aprobados y rechazados
- **Sistema de filtros**: Filtrar por estado (todos, pendientes, aprobados, rechazados)
- **Búsqueda avanzada**: Buscar por nombre de proyecto, usuario o email
- **Estados visuales**: Códigos de color para identificar rápidamente el estado de cada proyecto

**Acceso:** Los supervisores verán un nuevo botón en la barra superior del home que los lleva a `/supervisor-dashboard`

### 📊 **Pantalla de Revisión** (`supervisor_analysis_review.dart`)

**Funcionalidades existentes mejoradas:**
- **Información del proyecto**: Nombre, usuario que lo envió, fecha de envío
- **Resumen del análisis**: Total de imágenes, imágenes válidas, problemas encontrados, puntuación de la IA
- **Última imagen subida**: Visualización de la imagen más reciente del proyecto
- **Problemas detectados**: Lista detallada de issues encontrados por la IA
- **Recomendaciones de la IA**: Sugerencias automáticas para mejorar el arte
- **Opciones de decisión**: Botones para aprobar o rechazar con comentarios opcionales

## Archivos Creados/Modificados

### Nuevos Archivos

1. **`supervisor_dashboard.dart`** - Dashboard principal del supervisor
2. **`supervisor_widgets.dart`** - Widgets reutilizables para supervisores

### Archivos Modificados

1. **`cases_service.dart`** - Agregado método `getAllCasesWithUserInfo()`
2. **`auth_service.dart`** - Agregado método `isCurrentUserSupervisor()`
3. **`home.dart`** - Agregado botón de acceso al dashboard del supervisor
4. **`app_router.dart`** - Agregadas rutas `/supervisor-dashboard` y `/supervisor-review/:projectName`

## Nuevas Rutas

```dart
// Dashboard principal del supervisor
GoRoute(
  path: '/supervisor-dashboard',
  builder: (context, state) => const SupervisorDashboard(),
),

// Revisión individual de proyectos
GoRoute(
  path: '/supervisor-review/:projectName',
  builder: (context, state) {
    final projectName = state.pathParameters['projectName']!;
    final serenityId = state.uri.queryParameters['serenityId'];
    final caseId = state.uri.queryParameters['caseId'];
    return SupervisorAnalysisReview(
      projectName: projectName, 
      serenityId: serenityId,
      caseId: caseId,
    );
  },
),
```

## Navegación

### Acceso al Dashboard del Supervisor
Los usuarios con rol "SUPERVISOR" verán automáticamente un botón en la barra superior del home:
```dart
// El botón aparece automáticamente basado en el rol del usuario
if (_isSupervisor) ...[
  IconButton(
    icon: const Icon(Icons.supervisor_account, color: Colors.white),
    onPressed: () => context.go('/supervisor-dashboard'),
    tooltip: 'Dashboard de Supervisor',
  ),
],
```

### Navegación Programática
```dart
// Ir al dashboard del supervisor
context.go('/supervisor-dashboard');

// Ir a revisar un proyecto específico
context.go('/supervisor-review/${Uri.encodeComponent(projectName)}?serenityId=SER-001&caseId=CASE-001');
```

## Características del Dashboard

### 📈 **Panel de Estadísticas**
- **Total de proyectos**: Contador de todos los proyectos en el sistema
- **Pendientes**: Proyectos que requieren revisión (simulado por fecha de creación)
- **Aprobados**: Proyectos aprobados por supervisores
- **Rechazados**: Proyectos que necesitan correcciones

### 🔍 **Sistema de Filtros**
- **Filtro por estado**: Chips seleccionables para filtrar por estado
- **Búsqueda de texto**: Campo de búsqueda que filtra por:
  - Nombre del proyecto
  - Nombre del usuario autor
  - Email del usuario autor

### 📋 **Información Detallada de Proyectos**
Cada tarjeta de proyecto muestra:
- **Nombre del proyecto** (título principal)
- **Información del usuario autor**:
  - Nombre completo del usuario
  - Email del usuario
- **Fecha de creación**
- **Estado actual** (con código de color)
- **Estado activo/inactivo**
- **Botones de acción**:
  - "Ver análisis": Va a la pantalla de análisis estándar
  - "Revisar": Va a la pantalla de revisión del supervisor

## Base de Datos

### Nuevo Método en CasesService

```dart
/// Obtener todos los casos con información del usuario para supervisores
Future<List<Map<String, dynamic>>> getAllCasesWithUserInfo() async {
  try {
    final response = await client
        .from('cases')
        .select('''
          *,
          users!inner(
            id,
            name,
            email,
            role
          )
        ''')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  } catch (e) {
    throw Exception('Error al obtener casos con información de usuario: $e');
  }
}
```

Este método realiza un JOIN entre las tablas `cases` y `users` para obtener toda la información necesaria.

## Gestión de Roles

### Verificación de Supervisor

```dart
/// En AuthService
Future<bool> isCurrentUserSupervisor() async {
  final userData = await getCurrentUserData();
  return userData?['rol']?.toString().toUpperCase() == 'SUPERVISOR';
}
```

### Roles Soportados
- **ADMINISTRADOR**: Acceso completo + gestión de usuarios
- **SUPERVISOR**: Acceso a dashboard de supervisión + revisión de todos los proyectos
- **USER**: Acceso básico a sus propios proyectos

## Estados de Proyectos (Simulados)

Por ahora, los estados se simulan basándose en la fecha de creación:
- **Pendiente**: Proyectos creados en las últimas 24 horas
- **Aprobado**: Proyectos creados entre 1-7 días atrás
- **Requiere atención**: Proyectos creados hace más de 7 días

## Cómo Usar

### Para Supervisores
1. **Iniciar sesión** con una cuenta de rol "SUPERVISOR"
2. **Hacer clic** en el botón del supervisor en la barra superior
3. **Explorar** el dashboard con todos los proyectos
4. **Usar filtros** para encontrar proyectos específicos
5. **Hacer clic en "Revisar"** para ver detalles y tomar decisiones

### Para Desarrolladores

```dart
// Verificar si el usuario actual es supervisor
final isSupervisor = await AuthService().isCurrentUserSupervisor();

// Obtener todos los casos con información de usuario
final casesWithUsers = await CasesService().getAllCasesWithUserInfo();

// Usar widgets reutilizables
SupervisorReviewCard(
  projectName: 'Mi Proyecto',
  userName: 'Juan Pérez',
  submissionDate: DateTime.now(),
  status: 'pending_review',
)
```

## Próximos Pasos

1. **Estados reales**: Implementar tabla de estados en la base de datos
2. **Notificaciones**: Sistema de notificaciones para usuarios
3. **Comentarios del supervisor**: Guardar y mostrar comentarios de revisiones
4. **Historial de revisiones**: Registro de todas las decisiones tomadas
5. **Métricas avanzadas**: Estadísticas más detalladas y reportes
6. **Filtros por fecha**: Filtros de rango de fechas
7. **Exportación**: Exportar listas de proyectos a CSV/Excel

## Dependencias

No se agregaron nuevas dependencias. Se utilizan las existentes:
- `flutter/material.dart`
- `go_router`
- `supabase_flutter` (a través de los servicios existentes)
- `firebase_auth` (a través de AuthService)