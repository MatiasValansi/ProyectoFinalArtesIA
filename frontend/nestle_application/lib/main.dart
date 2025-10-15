import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:nestle_application/core/router/app_router.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await dotenv.load(fileName: "../../.env");
  } catch (e) {
    // Si no se puede cargar el .env, continuar con valores por defecto
    debugPrint('No se pudo cargar el archivo .env: $e');
  }
  
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Nestlé Application',
      routerConfig: appRouter,
    );
  }
}
