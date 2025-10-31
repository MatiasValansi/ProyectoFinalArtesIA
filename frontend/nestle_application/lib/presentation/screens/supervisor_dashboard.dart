import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth/auth_service.dart';
import '../../database/cases_service.dart';

class SupervisorDashboard extends StatefulWidget {
  const SupervisorDashboard({super.key});

  @override
  State<SupervisorDashboard> createState() => _SupervisorDashboardState();
}

class _SupervisorDashboardState extends State<SupervisorDashboard> {
  final AuthService _authService = AuthService();
  final CasesService _casesService = CasesService();
  
  String _userEmail = 'Supervisor';
  List<Map<String, dynamic>> _allCasesWithUsers = [];
  bool _isLoading = true;
  String _filterStatus = 'all'; // all, pending, approved, rejected
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _initializeDashboard();
  }

  Future<void> _initializeDashboard() async {
    try {
      await _getUserInfo();
      await _loadAllCases();
    } catch (e) {
      print('Error inicializando dashboard del supervisor: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _getUserInfo() async {
    try {
      final userEmail = await _authService.getCurrentUserEmail();
      if (mounted) {
        setState(() {
          _userEmail = userEmail ?? 'Supervisor';
        });
      }
    } catch (e) {
      print('Error obteniendo información del usuario: $e');
    }
  }

  Future<void> _loadAllCases() async {
    try {
      final casesData = await _casesService.getAllCasesWithUserInfo();
      if (mounted) {
        setState(() {
          _allCasesWithUsers = casesData;
        });
      }
    } catch (e) {
      print('Error cargando casos: $e');
      // En caso de error, usar método alternativo
      try {
        final casesData = await _casesService.getAllCases();
        if (mounted) {
          setState(() {
            _allCasesWithUsers = casesData.map((caseData) {
              // Agregar información básica del usuario si no está disponible
              return {
                ...caseData,
                'users': {
                  'name': 'Usuario ${caseData['user_id']?.toString().substring(0, 8) ?? 'Desconocido'}',
                  'email': 'usuario@empresa.com',
                  'role': 'user',
                }
              };
            }).toList();
          });
        }
      } catch (fallbackError) {
        print('Error en método alternativo: $fallbackError');
      }
    }
  }

  Future<void> _refreshCases() async {
    setState(() {
      _isLoading = true;
    });
    await _loadAllCases();
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _handleLogout() async {
    try {
      await _authService.signOut();
      if (mounted) {
        context.pushReplacement('/login');
      }
    } catch (e) {
      print('Error al cerrar sesión: $e');
    }
  }

  List<Map<String, dynamic>> get _filteredCases {
    var filtered = _allCasesWithUsers.where((caseData) {
      // Filtro por búsqueda
      if (_searchQuery.isNotEmpty) {
        final caseName = caseData['name']?.toString().toLowerCase() ?? '';
        final userName = caseData['users']?['name']?.toString().toLowerCase() ?? '';
        final userEmail = caseData['users']?['email']?.toString().toLowerCase() ?? '';
        
        if (!caseName.contains(_searchQuery.toLowerCase()) &&
            !userName.contains(_searchQuery.toLowerCase()) &&
            !userEmail.contains(_searchQuery.toLowerCase())) {
          return false;
        }
      }

      // Filtro por estado (simulado por ahora)
      if (_filterStatus != 'all') {
        // Por ahora simularemos estados basados en la fecha de creación
        final createdAt = DateTime.tryParse(caseData['created_at']?.toString() ?? '');
        if (createdAt != null) {
          final daysSinceCreation = DateTime.now().difference(createdAt).inDays;
          switch (_filterStatus) {
            case 'pending':
              return daysSinceCreation <= 1; // Casos recientes como pendientes
            case 'approved':
              return daysSinceCreation > 1 && daysSinceCreation <= 7; // Casos de la semana como aprobados
            case 'rejected':
              return daysSinceCreation > 7; // Casos más antiguos como rechazados
          }
        }
      }

      return true;
    }).toList();

    // Ordenar por fecha de creación (más recientes primero)
    filtered.sort((a, b) {
      final dateA = DateTime.tryParse(a['created_at']?.toString() ?? '') ?? DateTime.now();
      final dateB = DateTime.tryParse(b['created_at']?.toString() ?? '') ?? DateTime.now();
      return dateB.compareTo(dateA);
    });

    return filtered;
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
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white.withOpacity(0.2),
              child: const Icon(Icons.supervisor_account, size: 20, color: Colors.white),
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
                const Text(
                  'Supervisor',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshCases,
            tooltip: 'Actualizar',
          ),
          IconButton(
            icon: const Icon(Icons.home, color: Colors.white),
            onPressed: () => context.go('/home'),
            tooltip: 'Inicio',
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _handleLogout,
            tooltip: 'Cerrar Sesión',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Panel de estadísticas
          _buildStatisticsPanel(),
          
          // Controles de filtro y búsqueda
          _buildFilterControls(),
          
          // Lista de casos
          Expanded(
            child: _isLoading
                ? _buildLoadingWidget()
                : _buildCasesList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsPanel() {
    final totalCases = _allCasesWithUsers.length;
    final pendingCases = _allCasesWithUsers.where((c) {
      final createdAt = DateTime.tryParse(c['created_at']?.toString() ?? '');
      return createdAt != null && DateTime.now().difference(createdAt).inDays <= 1;
    }).length;
    final approvedCases = _allCasesWithUsers.where((c) {
      final createdAt = DateTime.tryParse(c['created_at']?.toString() ?? '');
      return createdAt != null && DateTime.now().difference(createdAt).inDays > 1 && DateTime.now().difference(createdAt).inDays <= 7;
    }).length;
    final rejectedCases = _allCasesWithUsers.where((c) {
      final createdAt = DateTime.tryParse(c['created_at']?.toString() ?? '');
      return createdAt != null && DateTime.now().difference(createdAt).inDays > 7;
    }).length;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
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
          const Text(
            'Panel de Supervisión - Todos los Proyectos',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF004B93),
            ),
          ),
          const SizedBox(height: 16),
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
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Pendientes',
                  pendingCases.toString(),
                  Icons.pending,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Aprobados',
                  approvedCases.toString(),
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
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

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterControls() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
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
        children: [
          // Búsqueda
          TextField(
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Buscar por proyecto, usuario o email...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF004B93)),
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Filtros de estado
          Row(
            children: [
              const Text(
                'Filtrar por estado:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('Todos', 'all'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Pendientes', 'pending'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Aprobados', 'approved'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Rechazados', 'rejected'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterStatus == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filterStatus = value;
        });
      },
      selectedColor: const Color(0xFF004B93).withOpacity(0.2),
      checkmarkColor: const Color(0xFF004B93),
    );
  }

  Widget _buildLoadingWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Color(0xFF004B93),
          ),
          SizedBox(height: 16),
          Text(
            'Cargando proyectos...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCasesList() {
    final filteredCases = _filteredCases;
    
    if (filteredCases.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchQuery.isNotEmpty || _filterStatus != 'all'
                  ? Icons.search_off
                  : Icons.folder_open,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty || _filterStatus != 'all'
                  ? 'No se encontraron proyectos con los filtros aplicados'
                  : 'No hay proyectos disponibles',
              style: const TextStyle(
                fontSize: 18,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            if (_searchQuery.isNotEmpty || _filterStatus != 'all') ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  setState(() {
                    _searchQuery = '';
                    _filterStatus = 'all';
                  });
                },
                child: const Text('Limpiar filtros'),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredCases.length,
      itemBuilder: (context, index) {
        final caseData = filteredCases[index];
        return _buildProjectCard(caseData);
      },
    );
  }

  Widget _buildProjectCard(Map<String, dynamic> caseData) {
    final caseName = caseData['name']?.toString() ?? 'Proyecto sin nombre';
    final userName = caseData['users']?['name']?.toString() ?? 'Usuario desconocido';
    final userEmail = caseData['users']?['email']?.toString() ?? '';
    final isActive = caseData['active'] ?? true;
    final createdAt = DateTime.tryParse(caseData['created_at']?.toString() ?? '') ?? DateTime.now();
    final serenityId = caseData['serenity_id']?.toString();
    final caseId = caseData['id']?.toString();
    
    // Simular estado basado en fecha
    String status;
    Color statusColor;
    IconData statusIcon;
    final daysSinceCreation = DateTime.now().difference(createdAt).inDays;
    
    if (daysSinceCreation <= 1) {
      status = 'Pendiente de revisión';
      statusColor = Colors.orange;
      statusIcon = Icons.pending;
    } else if (daysSinceCreation <= 7) {
      status = 'Aprobado';
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
    } else {
      status = 'Requiere atención';
      statusColor = Colors.red;
      statusIcon = Icons.warning;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        caseName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF004B93),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.person, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            userName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (userEmail.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Text(
                              '($userEmail)',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.schedule, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(createdAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: statusColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            statusIcon,
                            size: 16,
                            color: statusColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            status,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isActive ? Colors.green.withOpacity(0.15) : Colors.red.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isActive ? 'Activo' : 'Inactivo',
                        style: TextStyle(
                          color: isActive ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    String url = '/analysis/${Uri.encodeComponent(caseName)}';
                    if (serenityId != null) {
                      url += '?serenityId=${Uri.encodeComponent(serenityId)}';
                    }
                    context.go(url);
                  },
                  icon: const Icon(Icons.analytics, size: 16),
                  label: const Text('Ver análisis'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF004B93),
                    side: const BorderSide(color: Color(0xFF004B93)),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {
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
                  icon: const Icon(Icons.rate_review, size: 16),
                  label: const Text('Revisar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF004B93),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}