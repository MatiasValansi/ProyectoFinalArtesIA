import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Widget de ejemplo que muestra cómo navegar a la pantalla de revisión del supervisor
/// Este widget puede ser usado como botón en otras pantallas donde sea necesario
class SupervisorReviewButton extends StatelessWidget {
  final String projectName;
  final String? serenityId;
  final String? caseId;
  final String label;
  final IconData icon;

  const SupervisorReviewButton({
    super.key,
    required this.projectName,
    this.serenityId,
    this.caseId,
    this.label = 'Revisar como Supervisor',
    this.icon = Icons.supervisor_account,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () {
        // Construir la URL con parámetros
        String url = '/supervisor-review/${Uri.encodeComponent(projectName)}';
        
        // Agregar query parameters si están disponibles
        List<String> queryParams = [];
        if (serenityId != null) {
          queryParams.add('serenityId=${Uri.encodeComponent(serenityId!)}');
        }
        if (caseId != null) {
          queryParams.add('caseId=${Uri.encodeComponent(caseId!)}');
        }
        
        if (queryParams.isNotEmpty) {
          url += '?${queryParams.join('&')}';
        }
        
        context.go(url);
      },
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF004B93),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

/// Widget de ejemplo que muestra una tarjeta para revisar un caso como supervisor
class SupervisorReviewCard extends StatelessWidget {
  final String projectName;
  final String userName;
  final DateTime submissionDate;
  final String status;
  final String? serenityId;
  final String? caseId;

  const SupervisorReviewCard({
    super.key,
    required this.projectName,
    required this.userName,
    required this.submissionDate,
    required this.status,
    this.serenityId,
    this.caseId,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    IconData statusIcon;
    
    switch (status.toLowerCase()) {
      case 'pending_review':
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        break;
      case 'approved':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
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
                        projectName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF004B93),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Usuario: $userName',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Enviado: ${_formatDate(submissionDate)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
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
                        _getStatusText(status),
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (status.toLowerCase() == 'pending_review') ...[
                  SupervisorReviewButton(
                    projectName: projectName,
                    serenityId: serenityId,
                    caseId: caseId,
                    label: 'Revisar',
                    icon: Icons.rate_review,
                  ),
                ] else ...[
                  OutlinedButton.icon(
                    onPressed: () {
                      String url = '/supervisor-review/${Uri.encodeComponent(projectName)}';
                      List<String> queryParams = [];
                      if (serenityId != null) {
                        queryParams.add('serenityId=${Uri.encodeComponent(serenityId!)}');
                      }
                      if (caseId != null) {
                        queryParams.add('caseId=${Uri.encodeComponent(caseId!)}');
                      }
                      if (queryParams.isNotEmpty) {
                        url += '?${queryParams.join('&')}';
                      }
                      context.go(url);
                    },
                    icon: const Icon(Icons.visibility),
                    label: const Text('Ver detalles'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF004B93),
                      side: const BorderSide(color: Color(0xFF004B93)),
                    ),
                  ),
                ],
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

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending_review':
        return 'Pendiente';
      case 'approved':
        return 'Aprobado';
      case 'rejected':
        return 'Rechazado';
      default:
        return 'Desconocido';
    }
  }
}

/// Ejemplo de cómo usar los widgets en una pantalla
class ExampleSupervisorDashboard extends StatelessWidget {
  const ExampleSupervisorDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    // Datos de ejemplo
    final List<Map<String, dynamic>> casesForReview = [
      {
        'projectName': 'Campaña Nestlé Verano 2024',
        'userName': 'Juan Pérez',
        'submissionDate': DateTime.now().subtract(const Duration(hours: 2)),
        'status': 'pending_review',
        'serenityId': 'SER-001',
        'caseId': 'CASE-001',
      },
      {
        'projectName': 'Arte KitKat Nueva Línea',
        'userName': 'María González',
        'submissionDate': DateTime.now().subtract(const Duration(days: 1)),
        'status': 'approved',
        'serenityId': 'SER-002',
        'caseId': 'CASE-002',
      },
      {
        'projectName': 'Packaging Nescafé Limited',
        'userName': 'Carlos López',
        'submissionDate': DateTime.now().subtract(const Duration(days: 2)),
        'status': 'rejected',
        'serenityId': 'SER-003',
        'caseId': 'CASE-003',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Supervisor'),
        backgroundColor: const Color(0xFF004B93),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Header con estadísticas
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Pendientes',
                    casesForReview.where((c) => c['status'] == 'pending_review').length.toString(),
                    Colors.orange,
                    Icons.pending,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    'Aprobados',
                    casesForReview.where((c) => c['status'] == 'approved').length.toString(),
                    Colors.green,
                    Icons.check_circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    'Rechazados',
                    casesForReview.where((c) => c['status'] == 'rejected').length.toString(),
                    Colors.red,
                    Icons.cancel,
                  ),
                ),
              ],
            ),
          ),
          
          // Lista de casos
          Expanded(
            child: ListView.builder(
              itemCount: casesForReview.length,
              itemBuilder: (context, index) {
                final caseData = casesForReview[index];
                return SupervisorReviewCard(
                  projectName: caseData['projectName'],
                  userName: caseData['userName'],
                  submissionDate: caseData['submissionDate'],
                  status: caseData['status'],
                  serenityId: caseData['serenityId'],
                  caseId: caseData['caseId'],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
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
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}