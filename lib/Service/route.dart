import 'package:go_router/go_router.dart';
import 'package:hagzcoora/screens/homescreen.dart';

final GoRoute app_routes = GoRoute(
  path: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const HomePage(),
    )
  ]
);