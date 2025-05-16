import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class PushNotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> init(BuildContext context) async {
    // Запрашиваем разрешение на уведомления
    await _messaging.requestPermission();

    // Получаем токен устройства (можно отправить на сервер)
    final token = await _messaging.getToken();
    print('FCM Token: $token');

    // Обработка уведомлений в фоне и при открытом приложении
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        final notification = message.notification!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(notification.title ?? 'Уведомление')),
        );
      }
    });

    // Обработка уведомлений при запуске из закрытого состояния
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // Здесь можно реализовать переход на нужный экран
      print('Открыто уведомление: ${message.data}');
    });
  }
} 