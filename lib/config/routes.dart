import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Импортируйте экраны вашего приложения по мере их создания
// import '../features/auth/screens/login_screen.dart';
// import '../features/auth/screens/register_screen.dart';
// import '../features/dashboard/screens/dashboard_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (BuildContext context, GoRouterState state) {
          // Это будет заменено на один из ваших экранов, например WelcomeScreen
          return const Scaffold(
            body: Center(
              child: Text('Стартовый экран IntelectualPath'),
            ),
          );
        },
      ),
      // Маршруты для аутентификации
      // GoRoute(
      //   path: '/login',
      //   builder: (BuildContext context, GoRouterState state) {
      //     return const LoginScreen();
      //   },
      // ),
      // GoRoute(
      //   path: '/register',
      //   builder: (BuildContext context, GoRouterState state) {
      //     return const RegisterScreen();
      //   },
      // ),
      // 
      // // Маршрут для дашборда (главного экрана)
      // GoRoute(
      //   path: '/dashboard',
      //   builder: (BuildContext context, GoRouterState state) {
      //     return const DashboardScreen();
      //   },
      // ),
      // 
      // // Прочие маршруты будут добавлены по мере реализации функционала
    ],
    // Обработка ошибок при маршрутизации
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Ошибка маршрутизации: ${state.error}'),
      ),
    ),
  );
} 