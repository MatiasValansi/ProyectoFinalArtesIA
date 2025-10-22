import 'package:flutter/material.dart';
import 'package:nestle_application/supabase/user_service.dart';

class TestUserCrudScreen extends StatefulWidget {
  const TestUserCrudScreen({super.key});

  @override
  State<TestUserCrudScreen> createState() => _TestUserCrudScreenState();
}

class _TestUserCrudScreenState extends State<TestUserCrudScreen> {
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

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    try {
      final data = await _userService.getUsers();
      setState(() => _users = data);
    } catch (e) {
      _showSnackBar('Error al obtener usuarios: $e');
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
      _showSnackBar('Usuario creado correctamente ✅');
      _fetchUsers();
    } catch (e) {
      _showSnackBar('Error al crear usuario: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteUser(String userId) async {
    setState(() => _isLoading = true);
    try {
      await _userService.deleteUser(userId);
      _showSnackBar('Usuario eliminado correctamente 🗑️');
      _fetchUsers();
    } catch (e) {
      _showSnackBar('Error al eliminar usuario: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CRUD de Usuarios (Firebase + Supabase)'),
        backgroundColor: const Color(0xFF004B93),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// --- Formulario de creación ---
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email del usuario',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (value) =>
                        (value == null || value.isEmpty)
                            ? 'Ingrese un email'
                            : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Contraseña',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    obscureText: true,
                    validator: (value) =>
                        (value == null || value.length < 6)
                            ? 'Mínimo 6 caracteres'
                            : null,
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: _selectedRole,
                    decoration: const InputDecoration(
                      labelText: 'Rol',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: 'USUARIO', child: Text('USUARIO')),
                      DropdownMenuItem(
                          value: 'SUPERVISOR', child: Text('SUPERVISOR')),
                      DropdownMenuItem(
                          value: 'ADMINISTRADOR',
                          child: Text('ADMINISTRADOR')),
                    ],
                    onChanged: (value) =>
                        setState(() => _selectedRole = value!),
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF004B93),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: _isLoading ? null : _createUser,
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: const Text(
                        'Crear usuario',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),
            const Divider(),
            const Text(
              'Usuarios registrados',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            /// --- Lista de usuarios ---
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _users.isEmpty
                      ? const Center(child: Text('No hay usuarios registrados'))
                      : ListView.builder(
                          itemCount: _users.length,
                          itemBuilder: (context, index) {
                            final user = _users[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              child: ListTile(
                                leading: const Icon(Icons.person_outline),
                                title: Text(user['email'] ?? 'Sin email'),
                                subtitle:
                                    Text('Rol: ${user['rol'] ?? 'Sin rol'}'),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () => _deleteUser(user['id']),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
