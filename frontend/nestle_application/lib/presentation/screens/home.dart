import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth/auth_service.dart';

class Home extends StatefulWidget  {
  
  
  final  String recivedText;

  Home({super.key, this.recivedText = 'Usuario'});
  //Home({super.key, required this.recivedText});
  




  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool isCollapsed = false; // controla si el sidebar está contraído
  final AuthService _authService = AuthService();
  bool _isAdmin = false;
  String _userRole = '';

  @override
  void initState() {
    super.initState();
    _checkUserRole();
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

      body: Row(
        children: [
          // Sidebar
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: isCollapsed ? 70 : 220,
            color: Colors.white,
            child: Column(
              children: [
                const SizedBox(height: 20),

                // Botón para colapsar/expandir
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: Icon(
                      isCollapsed ? Icons.arrow_forward_ios : Icons.arrow_back_ios,
                      size: 18,
                      color: const Color(0xFF004B93),
                    ),
                    onPressed: () {
                      setState(() {
                        isCollapsed = !isCollapsed;
                      });
                    },
                  ),
                ),

                const SizedBox(height: 10),

                // Avatar y nombre
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.blueGrey,
                  child: const Icon(Icons.person, size: 35, color: Colors.white),
                ),
                if (!isCollapsed) ...[
                  const SizedBox(height: 12),
                  Text(
                    widget.recivedText,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(_userRole.isNotEmpty ? _userRole : "Cargando...",
                      style: TextStyle(color: Colors.grey)),
                ],
                const SizedBox(height: 30),

                // Opciones de menú
                _menuItem(Icons.folder, "Mis proyectos", null),
                
                if (_isAdmin) ...[
                  _menuItem(Icons.admin_panel_settings, "Administrar Usuarios", () {
                    context.go('/admin-users');
                  }),
                ],

                const Spacer(),

                // Botón logout solo si el sidebar está expandido
                if (!isCollapsed)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF004B93),
                        minimumSize: Size(double.infinity, 40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _handleLogout,
                      icon: const Icon(Icons.logout, size: 20.0),
                      label: const Text("Cerrar sesión", style: TextStyle(color: Colors.white)),
                    ),
                  ),
              ],
            ),
          ),

          // Contenido principal
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  height: 70,
                  color: const Color(0xFF004B93),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  alignment: Alignment.centerLeft,
                  child: const Text(
                    "Nestlé Validation Tool",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold),
                  ),
                ),

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
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget menú lateral
  Widget _menuItem(IconData icon, String text, VoidCallback? onTap) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF004B93)),
      title: isCollapsed
          ? null
          : Text(text, style: const TextStyle(fontSize: 14)),
      onTap: onTap ?? () {},
      dense: true,
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