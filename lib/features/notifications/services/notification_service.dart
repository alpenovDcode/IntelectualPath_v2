import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  // Инициализация уведомлений
  Future<void> initialize() async {
    // Запрос разрешений на уведомления
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Получение токена устройства
    String? token = await _firebaseMessaging.getToken();
    print('FCM Token: $token');

    // Обработка уведомлений в фоновом режиме
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Обработка уведомлений в активном режиме
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Получено уведомление: ${message.notification?.title}');
      // TODO: Показать уведомление пользователю
    });
  }

  // Отправка уведомления о новом курсе
  Future<void> sendNewCourseNotification(String userId, String courseTitle) async {
    // TODO: Отправка уведомления через Firebase Cloud Messaging
  }

  // Отправка уведомления о прогрессе
  Future<void> sendProgressNotification(String userId, int completedLessons) async {
    // TODO: Отправка уведомления через Firebase Cloud Messaging
  }

  // Отправка уведомления о серии дней
  Future<void> sendStreakNotification(String userId, int streakDays) async {
    // TODO: Отправка уведомления через Firebase Cloud Messaging
  }
}

// Обработчик уведомлений в фоновом режиме
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Получено уведомление в фоне: ${message.notification?.title}');
  // TODO: Обработка уведомления в фоновом режиме
} 