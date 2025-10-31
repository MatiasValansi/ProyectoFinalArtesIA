import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nestle_application/presentation/screens/login.dart';
import 'package:nestle_application/presentation/screens/home.dart';
import 'package:nestle_application/presentation/screens/new_art.dart';
import 'package:nestle_application/presentation/screens/analysis_result.dart';
import 'package:nestle_application/presentation/screens/admin_users.dart';
import 'package:nestle_application/presentation/screens/supervisor_analysis_review.dart';
import 'package:nestle_application/presentation/screens/supervisor_dashboard.dart';

final appRouter = GoRouter(
  initialLocation: '/login',
  redirect: (context, state) {
    final firebaseAuth = FirebaseAuth.instance;
    final isLoggedIn = firebaseAuth.currentUser != null;
    final isGoingToLogin = state.matchedLocation == '/login';

    // redirigir al login si no esta logeado
    if (!isLoggedIn && !isGoingToLogin) {
      return '/login';
    }

    // redirigir al home si ya esta logeado
    if (isLoggedIn && isGoingToLogin) {
      return '/home';
    }

    return null;
  },
  routes: [
    GoRoute(path: '/login', builder: (context, state) => Login()),
    GoRoute(path: '/home', builder: (context, state) => const Home()),
    GoRoute(path: '/new-art', builder: (context, state) => const NewArt()),
    GoRoute(path: '/analysis/:projectName', builder: (context, state) {
      final projectName = state.pathParameters['projectName']!;
      final serenityId = state.uri.queryParameters['serenityId'];
      return AnalysisResult(projectName: projectName, serenityId: serenityId);
    }),
    GoRoute(
      path: '/admin-users',
      builder: (context, state) => const AdminUsersScreen(),
    ),
    GoRoute(
      path: '/supervisor-review/:projectName',
      builder: (context, state) {
        final projectName = state.pathParameters['projectName']!;
        final serenityId = state.uri.queryParameters['serenityId'];
        final caseId = state.uri.queryParameters['caseId'];
        return SupervisorAnalysisReview(
          projectName: projectName, 
          serenityId: serenityId,
          caseId: caseId
        );
      },
    ),
    GoRoute(
      path: '/supervisor-dashboard',
      builder: (context, state) => const SupervisorDashboard(),
    ),


  ],
); // GoRouter