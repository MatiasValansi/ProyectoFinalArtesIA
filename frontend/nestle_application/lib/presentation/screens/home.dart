import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/auth/auth_service.dart';
import '../../database/cases_service.dart';
import '../../database/user_service.dart';
import '../../models/case_model.dart';
import '../../models/user_model.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final AuthService _authService = AuthService();
  final CasesService _casesService = CasesService();
  final UserService _userService = UserService();
  
  bool _isAdmin = false;
  String _userRole = '';
  String _userEmail = 'Usuario';
  List<CaseModel> _userCases = [];
  bool _isLoading = true;
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _initializeHomeData();
  }

  Future<void> _initializeHomeData() async {
    try {
      await _getUserInfo();
      await _checkUserRole();
      await _loadUserCases();
    } catch (e) {
      print('Error inicializando datos del home: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _getUserInfo() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null && firebaseUser.uid.isNotEmpty) {
      try {
        // Obtener el usuario de Supabase usando el authUid de Firebase
        final user = await _userService.getUserByAuthUidAsModel(firebaseUser.uid);
        if (mounted && user != null) {
          setState(() {
            _currentUser = user;
            _userEmail = user.email;
          });
        }
      } catch (e) {
        print('Error obteniendo información del usuario: $e');
        // Fallback al email de Firebase si hay error
        if (mounted) {
          setState(() {
            _userEmail = firebaseUser.email ?? 'Usuario';
          });
        }
      }
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

  Future<void> _loadUserCases() async {
    if (_currentUser?.id == null) return;
    
    try {
      final casesData = await _casesService.getCasesByUser(_currentUser!.id!);
      final cases = casesData.map((json) => CaseModel.fromJson(json)).toList();
      
      if (mounted) {
        setState(() {
          _userCases = cases;
        });
      }
    } catch (e) {
      print('Error cargando casos del usuario: $e');
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
                      Row(
                        children: [
                          const Text("Mis Proyectos",
                              style: TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.bold)),
                        ],
                      ),
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
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF004B93),
                              ),
                            ),
                          )
                        : _userCases.isEmpty
                            ? const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.folder_open,
                                      size: 64,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'No tienes proyectos asignados',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.grey,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Los proyectos asignados a ti aparecerán aquí',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                itemCount: _userCases.length,
                                itemBuilder: (context, index) {
                                  final caseModel = _userCases[index];
                                  return _projectRow(
                                    caseModel.name,
                                    (caseModel.approved ?? false) ? "Activo" : "Inactivo",
                                    (caseModel.approved ?? false) ? Colors.green : Colors.red,
                                    context,
                                    caseModel,
                                  );
                                },
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
  Widget _projectRow(String nombre, String estado, Color color, 
      BuildContext context, CaseModel caseModel) {
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
            context.go('/analysis/${Uri.encodeComponent(nombre)}?serenityId=${Uri.encodeComponent(caseModel.serenityId)}');
          },
          child: const Text("Ver detalles"),
        ),
      ),
    );
  }
}