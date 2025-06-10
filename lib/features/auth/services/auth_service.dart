import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import 'user_repository.dart';

class AuthResult {
  final User? user;
  final String? error;

  AuthResult({this.user, this.error});
  
  bool get isSuccess => user != null && error == null;
}

class AuthService {
  final firebase_auth.FirebaseAuth _firebaseAuth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final GoogleSignIn _googleSignIn = GoogleSignIn(
    // Укажем scopes для получения необходимых данных пользователя
    scopes: [
      'email',
      'profile',
    ],
    clientId: kIsWeb ? '462772008865-qqeqcgeoi1l92b0v3e32o8o0efjbg42v.apps.googleusercontent.com' : null,
  );
  
  // Репозиторий для работы с пользователями
  late final UserRepository _userRepository = UserRepository();
  
  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();
  
  // Stream для отслеживания изменений пользователя
  Stream<User?> get userStream => 
    _firebaseAuth.authStateChanges().map(_userFromFirebase);
  
  // Текущий пользователь
  User? get currentUser => _userFromFirebase(_firebaseAuth.currentUser);

  // Инициализация сервиса
  bool _isInitialized = false;
  
  Future<void> init() async {
    // Если уже инициализировано, не выполняем повторно
    if (_isInitialized) {
      print("AuthService: init() пропущен, так как уже инициализирован");
      return;
    }
    
    print("AuthService: init() вызван");
    
    // Ничего дополнительно не делаем, так как Firebase Auth автоматически восстанавливает сессию
    _isInitialized = true;
  }
  
  // Конвертирование Firebase User в нашу модель User
  User? _userFromFirebase(firebase_auth.User? firebaseUser) {
    if (firebaseUser == null) {
      return null;
    }
    
    return User(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      name: firebaseUser.displayName ?? firebaseUser.email?.split('@').first ?? 'Пользователь',
      photoUrl: firebaseUser.photoURL,
      isEmailVerified: firebaseUser.emailVerified,
    );
  }
  
  // Сохранение пользователя в Firestore
  Future<User?> _saveUserToFirestore(User user) async {
    try {
      return await _userRepository.saveUser(user);
    } catch (e) {
      print("AuthService: ошибка при сохранении пользователя в Firestore: $e");
      return user; // Возвращаем оригинального пользователя, если не удалось сохранить
    }
  }
  
  // Регистрация пользователя
  Future<AuthResult> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    print("AuthService: signUp() вызван с email=$email, name=$name");
    try {
      // Создание пользователя в Firebase
      firebase_auth.UserCredential credential = 
          await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Обновление имени пользователя
      await credential.user?.updateDisplayName(name);
      
      // Перезагружаем пользователя чтобы получить обновленные данные
      await credential.user?.reload();
      final updatedUser = _firebaseAuth.currentUser;
      
      // Конвертируем в нашу модель и сохраняем в Firestore
      final user = _userFromFirebase(updatedUser);
      final savedUser = user != null ? await _saveUserToFirestore(user) : null;
      
      print("AuthService: signUp() успешно завершен");
      return AuthResult(user: savedUser ?? user);
    } on firebase_auth.FirebaseAuthException catch (e) {
      print("AuthService: ошибка Firebase при регистрации: ${e.code}");
      String errorMessage;
      
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = 'Пользователь с таким email уже существует';
          break;
        case 'invalid-email':
          errorMessage = 'Неверный формат email';
          break;
        case 'weak-password':
          errorMessage = 'Пароль слишком слабый';
          break;
        default:
          errorMessage = 'Ошибка при регистрации: ${e.message}';
      }
      
      return AuthResult(error: errorMessage);
    } catch (e) {
      print("AuthService: ошибка при регистрации: $e");
      return AuthResult(error: 'Ошибка при регистрации: $e');
    }
  }
  
  // Вход пользователя
  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    print("AuthService: signIn() вызван с email=$email");
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Конвертируем в нашу модель и сохраняем в Firestore
      final user = _userFromFirebase(credential.user);
      final savedUser = user != null ? await _saveUserToFirestore(user) : null;
      
      print("AuthService: signIn() успешно завершен");
      return AuthResult(user: savedUser ?? user);
    } on firebase_auth.FirebaseAuthException catch (e) {
      print("AuthService: ошибка Firebase при входе: ${e.code}");
      String errorMessage;
      
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'Пользователь не найден';
          break;
        case 'wrong-password':
          errorMessage = 'Неверный пароль';
          break;
        case 'invalid-email':
          errorMessage = 'Неверный формат email';
          break;
        case 'user-disabled':
          errorMessage = 'Аккаунт отключен';
          break;
        default:
          errorMessage = 'Ошибка при входе: ${e.message}';
      }
      
      return AuthResult(error: errorMessage);
    } catch (e) {
      print("AuthService: ошибка при входе: $e");
      return AuthResult(error: 'Ошибка при входе: $e');
    }
  }
  
  // Вход с Google
  Future<AuthResult> signInWithGoogle() async {
    print("AuthService: signInWithGoogle() вызван");
    try {
      // Если это веб-платформа, используем специальный подход для веба
      if (kIsWeb) {
        // Создаем провайдер Google
        firebase_auth.GoogleAuthProvider googleProvider = firebase_auth.GoogleAuthProvider();
        
        // Добавляем запрашиваемые разрешения (scopes)
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        
        // Указываем параметры для авторизации
        googleProvider.setCustomParameters({
          'login_hint': 'user@example.com',
          'prompt': 'select_account'
        });
        
        // Запускаем поток авторизации через popup
        final userCredential = await _firebaseAuth.signInWithPopup(googleProvider);
        
        // Конвертируем в нашу модель и сохраняем в Firestore
        final user = _userFromFirebase(userCredential.user);
        final savedUser = user != null ? await _saveUserToFirestore(user) : null;
        
        print("AuthService: signInWithGoogle() через веб успешно завершен");
        return AuthResult(user: savedUser ?? user);
      } 
      // Для мобильных платформ используем стандартный подход
      else {
        // Запускаем процесс аутентификации в Google
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        
        if (googleUser == null) {
          print("AuthService: пользователь отменил вход через Google");
          return AuthResult(error: 'Вход отменен пользователем');
        }
        
        // Получаем аутентификационные данные из запроса
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        
        // Создаем новый объект учетных данных
        final credential = firebase_auth.GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        
        // Входим в систему с учетными данными
        final userCredential = await _firebaseAuth.signInWithCredential(credential);
        
        // Конвертируем в нашу модель и сохраняем в Firestore
        final user = _userFromFirebase(userCredential.user);
        final savedUser = user != null ? await _saveUserToFirestore(user) : null;
        
        print("AuthService: signInWithGoogle() успешно завершен");
        return AuthResult(user: savedUser ?? user);
      }
    } catch (e) {
      print("AuthService: ошибка при входе через Google: $e");
      return AuthResult(error: 'Ошибка при входе через Google: $e');
    }
  }
  
  // Выход пользователя
  Future<void> signOut() async {
    print("AuthService: signOut() вызван");
    try {
      await _googleSignIn.signOut(); // Выход из Google, если был вход через Google
      await _firebaseAuth.signOut(); // Выход из Firebase
      print("AuthService: пользователь вышел");
    } catch (e) {
      print("AuthService: ошибка при выходе: $e");
      throw Exception('Ошибка при выходе: $e');
    }
  }
  
  // Сброс пароля
  Future<AuthResult> resetPassword(String email) async {
    print("AuthService: resetPassword() вызван для email=$email");
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      print("AuthService: сброс пароля инициирован");
      return AuthResult(user: null);
    } on firebase_auth.FirebaseAuthException catch (e) {
      print("AuthService: ошибка Firebase при сбросе пароля: ${e.code}");
      String errorMessage;
      
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'Пользователь с таким email не найден';
          break;
        case 'invalid-email':
          errorMessage = 'Неверный формат email';
          break;
        default:
          errorMessage = 'Ошибка при сбросе пароля: ${e.message}';
      }
      
      return AuthResult(error: errorMessage);
    } catch (e) {
      print("AuthService: ошибка при сбросе пароля: $e");
      return AuthResult(error: 'Ошибка при сбросе пароля: $e');
    }
  }
  
  // Обновление данных пользователя
  Future<AuthResult> updateUser(User user) async {
    print("AuthService: updateUser() вызван для пользователя ${user.id}");
    try {
      final currentFirebaseUser = _firebaseAuth.currentUser;
      if (currentFirebaseUser == null) {
        return AuthResult(error: 'Пользователь не авторизован');
      }
      
      // Обновляем displayName в Firebase Auth если изменилось
      if (currentFirebaseUser.displayName != user.name) {
        await currentFirebaseUser.updateDisplayName(user.name);
      }
      
      // Сохраняем обновленные данные в Firestore
      final savedUser = await _saveUserToFirestore(user);
      
      print("AuthService: updateUser() успешно завершен");
      return AuthResult(user: savedUser ?? user);
    } catch (e) {
      print("AuthService: ошибка при обновлении пользователя: $e");
      return AuthResult(error: 'Ошибка при обновлении данных: $e');
    }
  }
} 