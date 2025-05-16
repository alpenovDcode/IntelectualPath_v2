import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/auth/services/auth_service.dart';
import '../../features/notifications/services/notification_service.dart';
import '../../intelectual_path_app.dart';

class AppInitializer {
  static Future<void> initialize() async {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Инициализация Firebase
    await Firebase.initializeApp();
    
    // Инициализация сервисов
    final authService = AuthService();
    final notificationService = NotificationService();
    
    // Инициализация push-уведомлений
    await notificationService.initialize();
    
    // Инициализация BLoC
    final authBloc = AuthBloc(authService: authService);
    
    // Запуск приложения
    runApp(
      MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: authBloc),
        ],
        child: const IntelectualPathApp(),
      ),
    );
  }
} 