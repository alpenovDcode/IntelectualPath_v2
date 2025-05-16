class AppConfig {
  // Общие настройки приложения
  static const String appName = 'IntelectualPath';
  static const String appVersion = '1.0.0';
  
  // API URL
  static const String apiBaseUrl = 'https://api.intellectualpath.com';
  
  // Настройки Firebase
  static const bool useFirebaseAnalytics = true;
  static const bool useFirebaseCrashlytics = true;
  
  // Настройки кэширования
  static const Duration cacheDuration = Duration(days: 7);
  
  // Прочие настройки
  static const int maxOfflineLessons = 10;
  static const int defaultAnimationDuration = 300; // миллисекунды
} 