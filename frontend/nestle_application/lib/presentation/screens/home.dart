import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/auth/auth_service.dart';

class Home extends StatefulWidget  {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final AuthService _authService = AuthService();
  bool _isAdmin = false;
  String _userRole = '';
  String _userEmail = 'Usuario';

  @override
  void initState() {
    super.initState();
    _checkUserRole();
    _getUserInfo();
  }

  void _getUserInfo() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email != null) {
      setState(() {
        _userEmail = user.email!;
      });
    }
  }

  Future<void> _checkUserRole() async {
    try {
      final isAdmin = await _authService.isCurrentUserAdmin();
      final role = await _authService.getCurrentUserRole();
      if (mounted) {
        setState(() {
          _isAdmin = isAdmin;
          _userRole = role ?? '';
        });
      }
    } catch (e) {
      print('Error obteniendo rol del usuario: $e');
    }
  }

  Future<void> _handleLogout() async {
    try {
      await _authService.signOut();
      if (mounted) {
        // Usar pushReplacement para evitar que el usuario pueda volver
        context.pushReplacement('/login');
      }
    } catch (e) {
      print('Error al cerrar sesión: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: const Color(0xFF004B93),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            // Avatar y nombre del usuario
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white.withOpacity(0.2),
              child: const Icon(Icons.person, size: 20, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _userEmail,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _userRole.isNotEmpty ? _userRole : "Cargando...",
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Botón Administrar Usuarios (solo para admins)
          if (_isAdmin) ...[
            IconButton(
              icon: const Icon(Icons.admin_panel_settings, color: Colors.white),
              onPressed: () => context.go('/admin-users'),
              tooltip: 'Administrar Usuarios',
            ),
          ],
          // Botón Cerrar Sesión
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _handleLogout,
            tooltip: 'Cerrar Sesión',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Lista de proyectos
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Proyectos Activos",
                          style: TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold)),
                      ElevatedButton.icon(
                        onPressed: () {
                          context.go('/new-art');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF004B93),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text("Agregar Proyecto"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Expanded(
                    child: ListView(
                      children: [
                        _projectRow("Proyecto Nido", "Aprobado",
                            Colors.green, context),
                        _projectRow("Proyecto Nescafé", "Pendiente",
                            Colors.orange, context),
                        _projectRow("Proyecto Nesquik", "Observado",
                            Colors.red, context),
                        _projectRow("Proyecto KitKat", "Aprobado",
                            Colors.green, context),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget fila de proyecto
  Widget _projectRow(
      String nombre, String estado, Color color, BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        title: Text(nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                estado,
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        trailing: TextButton(
          onPressed: () {
            context.go('/analysis/${Uri.encodeComponent(nombre)}');
          },
          child: const Text("Ver detalles"),
        ),
      ),
    );
  }
}