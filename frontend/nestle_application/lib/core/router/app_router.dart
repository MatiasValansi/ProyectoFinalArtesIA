import 'package:go_router/go_router.dart';
import 'package:nestle_application/presentation/screens/login.dart';
import 'package:nestle_application/presentation/screens/home.dart';
import 'package:nestle_application/presentation/screens/new_art.dart';
import 'package:nestle_application/presentation/screens/analysis_result.dart';
import 'package:nestle_application/presentation/screens/test_user_crud.dart';
import 'package:nestle_application/presentation/screens/admin_users.dart';

final appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(path: '/login', builder: (context, state) => Login()),
    GoRoute(path: '/home', builder: (context, state) => Home(recivedText: state.extra as String? ?? 'Usuario')),
    GoRoute(path: '/new-art', builder: (context, state) => const NewArt()),
    GoRoute(path: '/analysis/:projectName', builder: (context, state) {
      final projectName = state.pathParameters['projectName']!;
      return AnalysisResult(projectName: projectName);
    }),
    GoRoute(
      path: '/test-users',
      builder: (context, state) => const TestUserCrudScreen(),
    ),
    GoRoute(
      path: '/admin-users',
      builder: (context, state) => const AdminUsersScreen(),
    ),


  ],
); // GoRouter