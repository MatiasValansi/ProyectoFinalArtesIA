import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth/auth_service.dart';
import '../../core/controllers/cases_controller.dart';
import '../../core/controllers/role_controller.dart';
import '../../core/controllers/user_controller.dart';
import '../../database/cases_service.dart';
import '../../database/user_service.dart';
import '../../models/case_model.dart';
import '../../models/user_model.dart';
import '../widgets/filter_controls.dart';
import '../widgets/loading_widget.dart';
import '../widgets/unified_project_card.dart';
import '../widgets/statistics_panel.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final UserController _userController = UserController(UserService());
  final RoleController _roleController = RoleController(AuthService());
  final CasesController _casesController = CasesController(CasesService());

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
      final user = await _userController.getUserInfo();
      if (user != null) {
        setState(() {
          _currentUser = user;
          _userEmail = user.email;
        });
      }

      final roleData = await _roleController.getUserRole();
      setState(() {
        _isAdmin = roleData['isAdmin'];
        _isSupervisor = roleData['isSupervisor'];
        _userRole = roleData['role'];
      });

      if (_isSupervisor) {
        final cases = await _casesController.getAllCasesForSupervisor();
        setState(() {
          _allCasesWithUsers = cases;
        });
      } else if (_currentUser != null) {
        final userCases = await _casesController.getUserCases(_currentUser!.id!);
        setState(() {
          _userCases = userCases;
        });
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

  Future<void> _handleLogout() async {
    try {
      await _roleController.signOut(); // Usar el controlador para cerrar sesión
      if (mounted) {
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
        if (_isSupervisor)
          StatisticsPanel(
            totalCases: _allCasesWithUsers.length,
            pendingCases: _allCasesWithUsers.where((c) => c['approved'] == null).length,
            approvedCases: _allCasesWithUsers.where((c) => c['approved'] == true).length,
            rejectedCases: _allCasesWithUsers.where((c) => c['approved'] == false).length,
          ),

        // Controles de filtro y búsqueda
        _buildFilterControls(),

        // Lista de casos
        Expanded(child: _buildProjectsList()),
      ],
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