import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nestle_application/presentation/screens/login.dart';
import 'package:nestle_application/presentation/screens/home.dart';
import 'package:nestle_application/presentation/screens/new_art.dart';
import 'package:nestle_application/presentation/screens/analysis_result.dart';
import 'package:nestle_application/presentation/screens/admin_users.dart';

final appRouter = GoRouter(
  initialLocation: '/login',
  redirect: (context, state) {
    final firebaseAuth = FirebaseAuth.instance;
    final isLoggedIn = firebaseAuth.currentUser != null;
    final isGoingToLogin = state.matchedLocation == '/login';

    // Si no está logueado y no va al login, redirigir a login
    if (!isLoggedIn && !isGoingToLogin) {
      return '/login';
    }

    // Si está logueado y va al login, redirigir a home
    if (isLoggedIn && isGoingToLogin) {
      return '/home';
    }

    // No redirigir en otros casos
    return null;
  },
  routes: [
    GoRoute(path: '/login', builder: (context, state) => Login()),
    GoRoute(path: '/home', builder: (context, state) => const Home()),
    GoRoute(path: '/new-art', builder: (context, state) => const NewArt()),
    GoRoute(path: '/analysis/:projectName', builder: (context, state) {
      final projectName = state.pathParameters['projectName']!;
      return AnalysisResult(projectName: projectName);
    }),
    GoRoute(
      path: '/admin-users',
      builder: (context, state) => const AdminUsersScreen(),
    ),


  ],
); // GoRouter