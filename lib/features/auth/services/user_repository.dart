import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';

class UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  
  // Коллекция пользователей в Firestore
  CollectionReference get _usersCollection => _firestore.collection('users');
  
  // Получить документ пользователя по ID
  DocumentReference _userDocument(String userId) => _usersCollection.doc(userId);
  
  // Сохранить пользователя в Firestore
  Future<User?> saveUser(User user, {bool merge = true}) async {
    try {
      await _userDocument(user.id).set(
        {
          ...user.toJson(),
          'lastLoginAt': FieldValue.serverTimestamp(),
          'createdAt': merge ? FieldValue.serverTimestamp() : user.toJson()['createdAt'],
        },
        SetOptions(merge: merge)
      );
      
      // Получаем обновленные данные пользователя
      final docSnapshot = await _userDocument(user.id).get();
      if (!docSnapshot.exists) return user;
      
      // Создаем обновленную модель пользователя с данными из Firestore
      final Map<String, dynamic> data = docSnapshot.data() as Map<String, dynamic>;
      return User.fromJson(data);
    } catch (e) {
      print('UserRepository: Ошибка при сохранении пользователя: $e');
      return null;
    }
  }
  
  // Получить данные текущего пользователя из Firestore
  Future<User?> getCurrentUser() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return null;
    
    try {
      final docSnapshot = await _userDocument(currentUser.uid).get();
      
      if (docSnapshot.exists) {
        final Map<String, dynamic> data = docSnapshot.data() as Map<String, dynamic>;
        return User.fromJson(data);
      } else {
        // Если пользователь еще не сохранен в Firestore, создаем базовую модель
        final basicUser = User(
          id: currentUser.uid,
          email: currentUser.email ?? '',
          name: currentUser.displayName ?? currentUser.email?.split('@').first ?? 'Пользователь',
          photoUrl: currentUser.photoURL,
          isEmailVerified: currentUser.emailVerified,
        );
        
        // Сохраняем базового пользователя
        return saveUser(basicUser);
      }
    } catch (e) {
      print('UserRepository: Ошибка при получении пользователя: $e');
      return null;
    }
  }
  
  // Обновить данные пользователя
  Future<bool> updateUserData(String userId, Map<String, dynamic> data) async {
    try {
      await _userDocument(userId).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('UserRepository: Ошибка при обновлении пользователя: $e');
      return false;
    }
  }
} 