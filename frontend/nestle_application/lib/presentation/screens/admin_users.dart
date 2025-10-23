import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../supabase/user_service.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = 'USUARIO';

  final UserService _userService = UserService();
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    try {
      final data = await _userService.getUsers();
      setState(() => _users = data);
    } catch (e) {
      _showSnackBar('Error al obtener usuarios: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await _userService.createUser(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        rol: _selectedRole,
      );
      _emailController.clear();
      _passwordController.clear();
      _selectedRole = 'USUARIO';
      _showSnackBar('Usuario creado correctamente', Colors.green);
      _fetchUsers();
    } catch (e) {
      _showSnackBar('Error al crear usuario: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateUserRole(String userId, String currentRole) async {
    String? newRole = await _showRoleSelectionDialog(currentRole);
    if (newRole == null || newRole == currentRole) return;

    setState(() => _isLoading = true);
    try {
      await _userService.updateUserRole(userId, newRole);
      _showSnackBar('Rol actualizado correctamente', Colors.green);
      _fetchUsers();
    } catch (e) {
      _showSnackBar('Error al actualizar rol: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteUser(String userId, String email) async {
    bool? confirm = await _showDeleteConfirmationDialog(email);
    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await _userService.deleteUser(userId);
      _showSnackBar('Usuario eliminado correctamente', Colors.orange);
      _fetchUsers();
    } catch (e) {
      _showSnackBar('Error al eliminar usuario: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<String?> _showRoleSelectionDialog(String currentRole) async {
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        String selectedRole = currentRole;
        return AlertDialog(
          title: const Text('Cambiar Rol'),
          content: DropdownButtonFormField<String>(
            value: selectedRole,
            decoration: const InputDecoration(
              labelText: 'Nuevo rol',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'USUARIO', child: Text('USUARIO')),
              DropdownMenuItem(value: 'SUPERVISOR', child: Text('SUPERVISOR')),
              DropdownMenuItem(value: 'ADMINISTRADOR', child: Text('ADMINISTRADOR')),
            ],
            onChanged: (value) => selectedRole = value!,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(selectedRole),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF004B93)),
              child: const Text('Actualizar', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<bool?> _showDeleteConfirmationDialog(String email) async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar eliminación'),
          content: Text('¿Estás seguro de que deseas eliminar al usuario $email?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toUpperCase()) {
      case 'ADMINISTRADOR':
        return Colors.red;
      case 'SUPERVISOR':
        return Colors.orange;
      case 'USUARIO':
      default:
        return Colors.blue;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role.toUpperCase()) {
      case 'ADMINISTRADOR':
        return Icons.admin_panel_settings;
      case 'SUPERVISOR':
        return Icons.supervisor_account;
      case 'USUARIO':
      default:
        return Icons.person;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: const Color(0xFF004B93),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/home'),
        ),
        title: const Text(
          "Administración de Usuarios",
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Panel izquierdo - Crear usuario
            Expanded(
              flex: 1,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Crear Nuevo Usuario',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _emailController,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.email_outlined),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Ingrese un email';
                                }
                                if (!value.contains('@')) {
                                  return 'Ingrese un email válido';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 15),
                            TextFormField(
                              controller: _passwordController,
                              decoration: const InputDecoration(
                                labelText: 'Contraseña',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.lock_outline),
                              ),
                              obscureText: true,
                              validator: (value) {
                                if (value == null || value.length < 6) {
                                  return 'Mínimo 6 caracteres';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 15),
                            DropdownButtonFormField<String>(
                              value: _selectedRole,
                              decoration: const InputDecoration(
                                labelText: 'Rol',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.badge_outlined),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'USUARIO',
                                  child: Text('USUARIO'),
                                ),
                                DropdownMenuItem(
                                  value: 'SUPERVISOR',
                                  child: Text('SUPERVISOR'),
                                ),
                                DropdownMenuItem(
                                  value: 'ADMINISTRADOR',
                                  child: Text('ADMINISTRADOR'),
                                ),
                              ],
                              onChanged: (value) =>
                                  setState(() => _selectedRole = value!),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF004B93),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 15,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onPressed: _isLoading ? null : _createUser,
                                icon: const Icon(Icons.add, color: Colors.white),
                                label: const Text(
                                  'Crear Usuario',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(width: 20),
            
            // Panel derecho - Lista de usuarios
            Expanded(
              flex: 2,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Usuarios Registrados',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            onPressed: _fetchUsers,
                            icon: const Icon(Icons.refresh),
                            tooltip: 'Actualizar lista',
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : _users.isEmpty
                                ? const Center(
                                    child: Text(
                                      'No hay usuarios registrados',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  )
                                : ListView.builder(
                                    itemCount: _users.length,
                                    itemBuilder: (context, index) {
                                      final user = _users[index];
                                      final role = user['rol']?.toString() ?? 'USUARIO';
                                      
                                      return Card(
                                        margin: const EdgeInsets.symmetric(vertical: 4),
                                        child: ListTile(
                                          leading: CircleAvatar(
                                            backgroundColor: _getRoleColor(role).withOpacity(0.2),
                                            child: Icon(
                                              _getRoleIcon(role),
                                              color: _getRoleColor(role),
                                            ),
                                          ),
                                          title: Text(
                                            user['email'] ?? 'Sin email',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          subtitle: Container(
                                            margin: const EdgeInsets.only(top: 4),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _getRoleColor(role).withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              role,
                                              style: TextStyle(
                                                color: _getRoleColor(role),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.edit),
                                                onPressed: () => _updateUserRole(
                                                  user['id'].toString(),
                                                  role,
                                                ),
                                                tooltip: 'Cambiar rol',
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.delete, color: Colors.red),
                                                onPressed: () => _deleteUser(
                                                  user['id'].toString(),
                                                  user['email'] ?? 'Sin email',
                                                ),
                                                tooltip: 'Eliminar usuario',
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}