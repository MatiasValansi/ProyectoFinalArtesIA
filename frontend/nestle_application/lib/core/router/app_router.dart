import 'package:go_router/go_router.dart';
import 'package:nestle_application/presentation/screens/login.dart';
import 'package:nestle_application/presentation/screens/home.dart';
import 'package:nestle_application/presentation/screens/new_art.dart';

final appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(path: '/login', builder: (context, state) => Login()),
    GoRoute(path: '/home', builder: (context, state) => Home(recivedText: state.extra as String? ?? 'Usuario')),
    GoRoute(path: '/new-art', builder: (context, state) => const NewArt()),
    //GoRoute(path: '/home/:text',
      //  builder: (context, state) {
        //  final text = state.pathParameters['text']!;
          //return Home(recivedText: text);
        //} )

  ],
); // GoRouter