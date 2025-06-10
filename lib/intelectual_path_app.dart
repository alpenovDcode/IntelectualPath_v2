import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'config/theme.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/screens/auth_screen.dart';
import 'features/dashboard/screens/dashboard_screen.dart';
import 'features/onboarding/screens/splash_screen.dart';

class IntelectualPathApp extends StatelessWidget {
  const IntelectualPathApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IntelectualPath',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is AuthInitialState || state is AuthLoadingState) {
            return const SplashScreen();
          }
          if (state is AuthAuthenticatedState) {
            return const DashboardScreen();
          }
          return const AuthScreen();
        },
      ),
    );
  }
} 