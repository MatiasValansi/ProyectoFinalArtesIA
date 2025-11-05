import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/auth/auth_service.dart';
import '../../database/cases_service.dart';
import '../../database/user_service.dart';
import '../../models/case_model.dart';
import '../../models/user_model.dart';
import '../widgets/filter_controls.dart';
import '../widgets/loading_widget.dart';
import '../widgets/unified_project_card.dart';

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
  bool _isSupervisor = false;
  String _userRole = '';
  String _userEmail = 'Usuario';
  List<CaseModel> _userCases = [];
  List<Map<String, dynamic>> _allCasesWithUsers = [];
  bool _isLoading = true;
  UserModel? _currentUser;
  String _searchQuery = '';
  String _filterStatus = 'all';
  String _userSearchQuery = '';
  String _userFilterStatus = 'all';

  @override
  void initState() {
    super.initState();
    _initializeHomeData();
  }

  Future<void> _initializeHomeData() async {
    try {
      await _getUserInfo();
      await _checkUserRole();
      if (_isSupervisor) {
        await _loadAllCasesForSupervisor();
      } else {
        await _loadUserCases();
      }
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
        final user = await _userService.getUserByAuthUidAsModel(
          firebaseUser.uid,
        );
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
      final isSupervisor = await _authService.isCurrentUserSupervisor();
      final role = await _authService.getCurrentUserRole();
      if (mounted) {
        setState(() {
          _isAdmin = isAdmin;
          _isSupervisor = isSupervisor;
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

  Future<void> _loadAllCasesForSupervisor() async {
    try {
      final casesData = await _casesService.getAllCasesWithUserInfo();
      if (mounted) {
        setState(() {
          _allCasesWithUsers = casesData;
        });
      }
    } catch (e) {
      print('Error cargando casos para supervisor: $e');
      // En caso de error, usar método alternativo
      try {
        final casesData = await _casesService.getAllCases();
        if (mounted) {
          setState(() {
            _allCasesWithUsers = casesData.map((caseData) {
              // Agregar información básica del usuario si no está disponible
              return {
                ...caseData,
                'user_id': {
                  'id': caseData['user_id']?.toString() ?? 'unknown',
                  'email': 'usuario@empresa.com',
                  'rol': 'user',
                },
              };
            }).toList();
          });
        }
      } catch (fallbackError) {
        print('Error en método alternativo: $fallbackError');
      }
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
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
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
      body: _isLoading
          ? const LoadingWidget()
          : _isSupervisor
              ? _buildSupervisorDashboard()
              : _buildUserProjects(),
    );
  }

  Widget _buildUserProjects() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Mis Proyectos",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        context.go('/new-art');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF004B93),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
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

                // Controles de filtro
                if (_userCases.isNotEmpty) ...[
                  _buildFilterControls(isForUserView: true),
                  const SizedBox(height: 16),
                ],

                Expanded(
                  child: _buildProjectsList(isForUserView: true),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSupervisorDashboard() {
    return Column(
      children: [
        // Panel de estadísticas (solo para supervisores)
        if (_isSupervisor) _buildStatisticsPanel(),

        // Controles de filtro y búsqueda
        _buildFilterControls(),

        // Lista de casos
        Expanded(child: _buildProjectsList()),
      ],
    );
  }

  Widget _buildStatisticsPanel() {
    final totalCases = _allCasesWithUsers.length;
    final pendingCases = _allCasesWithUsers.where((c) {
      return c['approved'] == null; // null significa pendiente de revisión
    }).length;
    final approvedCases = _allCasesWithUsers.where((c) {
      return c['approved'] == true; // true significa aprobado
    }).length;
    final rejectedCases = _allCasesWithUsers.where((c) {
      return c['approved'] == false; // false significa rechazado
    }).length;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF004B93).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.dashboard,
                  color: Color(0xFF004B93),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'Panel de Supervisión - Todos los Proyectos',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF004B93),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total',
                  totalCases.toString(),
                  Icons.folder,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Pendientes',
                  pendingCases.toString(),
                  Icons.pending,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Aprobados',
                  approvedCases.toString(),
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Rechazados',
                  rejectedCases.toString(),
                  Icons.cancel,
                  Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterControls({bool isForUserView = false}) {
    return FilterControls(
      isForUserView: isForUserView,
      searchQuery: isForUserView ? _userSearchQuery : _searchQuery,
      filterStatus: isForUserView ? _userFilterStatus : _filterStatus,
      onSearchChanged: (value) {
        setState(() {
          if (isForUserView) {
            _userSearchQuery = value;
          } else {
            _searchQuery = value;
          }
        });
      },
      onFilterChanged: (value) {
        setState(() {
          if (isForUserView) {
            _userFilterStatus = value;
          } else {
            _filterStatus = value;
          }
        });
      },
    );
  }

  List<Map<String, dynamic>> get _filteredCases {
    var filtered = _allCasesWithUsers.where((caseData) {
      // Filtro por búsqueda
      if (_searchQuery.isNotEmpty) {
        final caseName = caseData['name']?.toString().toLowerCase() ?? '';
        final userInfo = caseData['user_id'] as Map<String, dynamic>;
        final userName = (userInfo['email']?.toString() ?? '').toLowerCase();
        final userEmail = (userInfo['email']?.toString() ?? '').toLowerCase();

        if (!caseName.contains(_searchQuery.toLowerCase()) &&
            !userName.contains(_searchQuery.toLowerCase()) &&
            !userEmail.contains(_searchQuery.toLowerCase())) {
          return false;
        }
      }

      // Filtro por estado usando el campo approved
      if (_filterStatus != 'all') {
        final approved = caseData['approved'];
        switch (_filterStatus) {
          case 'pending':
            return approved == null;
          case 'approved':
            return approved == true;
          case 'rejected':
            return approved == false;
        }
      }

      return true;
    }).toList();

    // Ordenar por fecha de creación (más recientes primero)
    filtered.sort((a, b) {
      final dateA =
          DateTime.tryParse(a['created_at']?.toString() ?? '') ??
          DateTime.now();
      final dateB =
          DateTime.tryParse(b['created_at']?.toString() ?? '') ??
          DateTime.now();
      return dateB.compareTo(dateA);
    });

    return filtered;
  }

  List<CaseModel> get _filteredUserCases {
    var filtered = _userCases.where((caseModel) {
      // Filtro por búsqueda en nombre del proyecto
      if (_userSearchQuery.isNotEmpty) {
        final caseName = caseModel.name.toLowerCase();
        if (!caseName.contains(_userSearchQuery.toLowerCase())) {
          return false;
        }
      }

      // Filtro por estado usando el campo approved
      if (_userFilterStatus != 'all') {
        final approved = caseModel.approved;
        switch (_userFilterStatus) {
          case 'pending':
            return approved == null;
          case 'approved':
            return approved == true;
          case 'rejected':
            return approved == false;
        }
      }

      return true;
    }).toList();

    // Ordenar por fecha de creación (más recientes primero)
    filtered.sort((a, b) {
      final dateA = a.createdAt ?? DateTime.now();
      final dateB = b.createdAt ?? DateTime.now();
      return dateB.compareTo(dateA);
    });

    return filtered;
  }

  Widget _buildProjectsList({bool isForUserView = false}) {
    late final List items;
    late final bool hasSearchQuery;
    late final bool hasFilterStatus;

    if (isForUserView) {
      items = _filteredUserCases;
      hasSearchQuery = _userSearchQuery.isNotEmpty;
      hasFilterStatus = _userFilterStatus != 'all';
    } else {
      items = _filteredCases;
      hasSearchQuery = _searchQuery.isNotEmpty;
      hasFilterStatus = _filterStatus != 'all';
    }

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasSearchQuery || hasFilterStatus
                  ? Icons.search_off
                  : Icons.folder_open,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              hasSearchQuery || hasFilterStatus
                  ? 'No se encontraron proyectos con los filtros aplicados'
                  : isForUserView
                      ? (_userCases.isEmpty
                          ? 'No tienes proyectos asignados'
                          : 'No se encontraron proyectos')
                      : 'No hay proyectos disponibles',
              style: const TextStyle(
                fontSize: 18,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            if (hasSearchQuery || hasFilterStatus) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  setState(() {
                    if (isForUserView) {
                      _userSearchQuery = '';
                      _userFilterStatus = 'all';
                    } else {
                      _searchQuery = '';
                      _filterStatus = 'all';
                    }
                  });
                },
                child: const Text('Limpiar filtros'),
              ),
            ] else if (isForUserView && _userCases.isEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'Los proyectos asignados a ti aparecerán aquí',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: isForUserView ? EdgeInsets.zero : const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        if (isForUserView) {
          final caseModel = items[index] as CaseModel;
          return UnifiedProjectCard(
            projectName: caseModel.name,
            userEmail: null,
            createdAt: caseModel.createdAt ?? DateTime.now(),
            approved: caseModel.approved,
            onTap: () {
              context.go(
                '/analysis/${Uri.encodeComponent(caseModel.name)}?serenityId=${Uri.encodeComponent(caseModel.serenityId)}',
              );
            },
            isForUserView: true,
          );
        } else {
          final caseData = items[index] as Map<String, dynamic>;
          return UnifiedProjectCard(
            projectName: caseData['name']?.toString() ?? 'Proyecto sin nombre',
            userEmail: (caseData['user_id'] as Map<String, dynamic>)['email']?.toString(),
            createdAt: DateTime.tryParse(caseData['created_at']?.toString() ?? '') ?? DateTime.now(),
            approved: caseData['approved'],
            onTap: () {
              final caseName = caseData['name']?.toString() ?? 'Proyecto sin nombre';
              final serenityId = caseData['serenity_id']?.toString();
              final caseId = caseData['id']?.toString();

              String url = '/supervisor-review/${Uri.encodeComponent(caseName)}';
              List<String> queryParams = [];
              if (serenityId != null) {
                queryParams.add('serenityId=${Uri.encodeComponent(serenityId)}');
              }
              if (caseId != null) {
                queryParams.add('caseId=${Uri.encodeComponent(caseId)}');
              }
              if (queryParams.isNotEmpty) {
                url += '?${queryParams.join('&')}';
              }
              context.go(url);
            },
            isForUserView: false,
          );
        }
      },
    );
  }
}